"""
Minimal read-only WebSocket client using stdlib only.
Connects, prints each text frame it receives, writes to ws_frames.txt.
Exits after `idle_timeout` seconds with no new frame.
Usage: python ws_listener.py <listing_id> [idle_timeout_seconds]
"""
import base64
import hashlib
import json
import os
import socket
import struct
import sys
from datetime import datetime

LISTING_ID = sys.argv[1]
IDLE = int(sys.argv[2]) if len(sys.argv) > 2 else 45
HOST = "localhost"
PORT = 8000
PATH = f"/ws/auctions/{LISTING_ID}/"
OUT = os.path.join(os.path.dirname(__file__), "ws_frames.txt")


def _ws_key():
    return base64.b64encode(os.urandom(16)).decode()


def _accept(key):
    magic = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    return base64.b64encode(
        hashlib.sha1((key + magic).encode()).digest()
    ).decode()


def _handshake(sock, key):
    req = (
        f"GET {PATH} HTTP/1.1\r\n"
        f"Host: {HOST}:{PORT}\r\n"
        "Upgrade: websocket\r\n"
        "Connection: Upgrade\r\n"
        f"Sec-WebSocket-Key: {key}\r\n"
        "Sec-WebSocket-Version: 13\r\n"
        "\r\n"
    )
    sock.sendall(req.encode())
    resp = b""
    while b"\r\n\r\n" not in resp:
        resp += sock.recv(4096)
    if b"101" not in resp:
        raise RuntimeError(f"Handshake failed:\n{resp.decode()}")
    expected = _accept(key)
    if expected.encode() not in resp:
        raise RuntimeError(f"Bad Sec-WebSocket-Accept. Expected {expected}")


def _read_frame(sock):
    """Read one WebSocket frame. Returns (opcode, payload_bytes) or None on close."""
    def recv_exact(n):
        buf = b""
        while len(buf) < n:
            chunk = sock.recv(n - len(buf))
            if not chunk:
                raise ConnectionResetError("Server closed connection")
            buf += chunk
        return buf

    header = recv_exact(2)
    fin = (header[0] & 0x80) != 0       # noqa: F841 — we accept fragmented frames for tests
    opcode = header[0] & 0x0F
    masked = (header[1] & 0x80) != 0    # server→client frames are never masked per spec
    length = header[1] & 0x7F

    if length == 126:
        length = struct.unpack(">H", recv_exact(2))[0]
    elif length == 127:
        length = struct.unpack(">Q", recv_exact(8))[0]

    mask_key = recv_exact(4) if masked else None
    payload = recv_exact(length)

    if masked:
        payload = bytes(b ^ mask_key[i % 4] for i, b in enumerate(payload))

    return opcode, payload


def log(msg, f):
    print(msg, flush=True)
    f.write(msg + "\n")
    f.flush()


def main():
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(IDLE)
    sock.connect((HOST, PORT))

    key = _ws_key()
    _handshake(sock, key)

    with open(OUT, "a") as f:
        log(f"=== Connected to {PATH} at {datetime.now().isoformat()} ===", f)
        print("Connected — waiting for frames...", flush=True)
        try:
            while True:
                try:
                    opcode, payload = _read_frame(sock)
                except socket.timeout:
                    log(f"[TIMEOUT] No frame in {IDLE}s — exiting.", f)
                    break

                if opcode == 0x8:   # Close frame
                    log("[CLOSE frame received]", f)
                    break
                if opcode == 0x9:   # Ping
                    sock.sendall(b"\x8a\x00")  # Pong
                    continue
                if opcode in (0x1, 0x2):  # Text or Binary
                    ts = datetime.now().isoformat()
                    try:
                        parsed = json.loads(payload)
                        line = f"[{ts}] FRAME:\n{json.dumps(parsed, indent=2)}"
                    except Exception:
                        line = f"[{ts}] RAW: {payload!r}"
                    log(line, f)
                    log("---", f)
        finally:
            sock.close()


main()
