import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}

class ApiClient {
  const ApiClient({required this.host, this.port = 8000, this.token});
  final String host;
  final int port;
  final String? token;

  /// Every request race against this — without it, a hung connection (dropped
  /// wifi, a server that never answers) leaves callers awaiting forever with
  /// no error and no way for the UI to recover. Found via the live-auction
  /// room getting stuck on "Loading..." indefinitely.
  static const _timeout = Duration(seconds: 15);

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.http('$host:$port', path, query);
    final client = HttpClient();
    try {
      final req = await client.getUrl(uri).timeout(_timeout);
      _addAuth(req);
      final res = await req.close().timeout(_timeout);
      final body = await res.transform(utf8.decoder).join().timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) return jsonDecode(body);
      _throwFromBody(body, res.statusCode);
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } finally {
      client.close();
    }
  }

  Future<dynamic> postMultipart(
    String path,
    Map<String, File> files, {
    Map<String, String>? fields,
  }) async {
    final uri = Uri.http('$host:$port', path);
    final boundary = 'mazad${DateTime.now().millisecondsSinceEpoch}';
    final client = HttpClient();
    try {
      // Uploads can legitimately take longer than a plain JSON request.
      final req = await client.postUrl(uri).timeout(const Duration(seconds: 60));
      _addAuth(req);
      req.headers.set('Content-Type', 'multipart/form-data; boundary=$boundary');

      final body = <int>[];

      if (fields != null) {
        for (final e in fields.entries) {
          body.addAll(utf8.encode('--$boundary\r\n'));
          body.addAll(utf8.encode('Content-Disposition: form-data; name="${e.key}"\r\n\r\n'));
          body.addAll(utf8.encode('${e.value}\r\n'));
        }
      }

      for (final e in files.entries) {
        final filename = e.value.path.split(RegExp(r'[/\\]')).last;
        body.addAll(utf8.encode('--$boundary\r\n'));
        body.addAll(utf8.encode(
          'Content-Disposition: form-data; name="${e.key}"; filename="$filename"\r\n',
        ));
        body.addAll(utf8.encode('Content-Type: application/octet-stream\r\n\r\n'));
        body.addAll(await e.value.readAsBytes());
        body.addAll(utf8.encode('\r\n'));
      }

      body.addAll(utf8.encode('--$boundary--\r\n'));

      req.contentLength = body.length;
      req.add(body);

      final res = await req.close().timeout(const Duration(seconds: 60));
      final responseBody =
          await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 60));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return responseBody.isEmpty ? null : jsonDecode(responseBody);
      }
      _throwFromBody(responseBody, res.statusCode);
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } finally {
      client.close();
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = Uri.http('$host:$port', path);
    final client = HttpClient();
    try {
      final req = await client.postUrl(uri).timeout(_timeout);
      _addAuth(req);
      final bytes = utf8.encode(jsonEncode(body));
      req.headers.contentType = ContentType.json;
      req.contentLength = bytes.length;
      req.add(bytes);
      final res = await req.close().timeout(_timeout);
      final responseBody = await res.transform(utf8.decoder).join().timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) return jsonDecode(responseBody);
      _throwFromBody(responseBody, res.statusCode);
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } finally {
      client.close();
    }
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final uri = Uri.http('$host:$port', path);
    final client = HttpClient();
    try {
      final req = await client.patchUrl(uri).timeout(_timeout);
      _addAuth(req);
      final bytes = utf8.encode(jsonEncode(body));
      req.headers.contentType = ContentType.json;
      req.contentLength = bytes.length;
      req.add(bytes);
      final res = await req.close().timeout(_timeout);
      final responseBody = await res.transform(utf8.decoder).join().timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return responseBody.isEmpty ? null : jsonDecode(responseBody);
      }
      _throwFromBody(responseBody, res.statusCode);
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } finally {
      client.close();
    }
  }

  Future<void> delete(String path) async {
    final uri = Uri.http('$host:$port', path);
    final client = HttpClient();
    try {
      final req = await client.deleteUrl(uri).timeout(_timeout);
      _addAuth(req);
      final res = await req.close().timeout(_timeout);
      if (res.statusCode >= 200 && res.statusCode < 300) return;
      final body = await res.transform(utf8.decoder).join().timeout(_timeout);
      _throwFromBody(body, res.statusCode);
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } finally {
      client.close();
    }
  }

  void _addAuth(HttpClientRequest req) {
    if (token != null) req.headers.set('Authorization', 'Token $token');
  }

  Never _throwFromBody(String body, int statusCode) {
    try {
      final d = jsonDecode(body) as Map<String, dynamic>;
      final detail = d['detail'] as String?;
      if (detail != null) throw ApiException(detail, statusCode: statusCode);
      final nonField =
          (d['non_field_errors'] as List?)?.whereType<String>().join('; ');
      if (nonField != null && nonField.isNotEmpty) {
        throw ApiException(nonField, statusCode: statusCode);
      }
      final messages = d.values
          .whereType<List>()
          .expand((l) => l.whereType<String>())
          .join('; ');
      throw ApiException(
        messages.isNotEmpty ? messages : 'Request failed ($statusCode).',
        statusCode: statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Request failed ($statusCode).', statusCode: statusCode);
    }
  }
}
