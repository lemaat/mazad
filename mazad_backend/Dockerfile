# 1. Start from an official image: Debian Linux with Python 3.14 preinstalled
FROM python:3.14-slim

# 2. Two Python settings that suit containers:
#    don't write .pyc files, and print logs immediately (no buffering)
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 3. Everything after this happens inside /app in the container
WORKDIR /app

# 4. Copy ONLY requirements.txt first, then install
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 5. Now copy the rest of your code
COPY . .

# 6. Document that the server listens on port 8000
EXPOSE 8000

# 7. The command that runs when the container starts
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]