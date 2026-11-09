FROM python:3.11-slim

# Install system dependencies: JRE, apksigner, curl
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    apksigner \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Setup debug keystore for APK signing
RUN mkdir -p /root/.android && \
    keytool -genkey -v -keystore /root/.android/debug.keystore \
    -storepass android -alias androiddebugkey -keypass android \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US"

# Install Python requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

# Ensure APKEditor.jar is present
RUN if [ ! -f APKEditor.jar ]; then \
    curl -sL -o APKEditor.jar "https://github.com/REAndroid/APKEditor/releases/download/V1.4.1/APKEditor-1.4.1.jar"; \
    fi

ENV PROTOCOL_BUFFERS_PYTHON_IMPLEMENTATION=python
ENV PORT=5000
ENV HOST=0.0.0.0

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

CMD ["gunicorn", "-c", "gunicorn.conf.py", "server:app"]
