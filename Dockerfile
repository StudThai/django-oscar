# Base image
FROM python:3.12

# Environment settings
ENV PYTHONUNBUFFERED=1 \
    npm_config_cache=/tmp/.npm \
    PYTHONPATH=/app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y curl gnupg libmagic1 netcat-openbsd postgresql-client && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create app directory
WORKDIR /app

# Copy project files
COPY . /app

# Copy requirements explicitly (ensures correct file is used)
COPY requirements.txt /app/requirements.txt

# Install Python dependencies
RUN pip install --no-cache-dir -r /app/requirements.txt && pip check

# Create non-root user
RUN groupadd -r django && useradd -r -g django -m django && \
    mkdir -p /home/django && chown django:django /home/django && \
    chown -R django:django /app

# Copy entrypoint script and make it executable
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to non-root user
USER django

# Install JS dependencies inside sandbox
WORKDIR /app/sandbox
RUN rm -rf node_modules package-lock.json && \
    npm cache clean --force && \
    npm install --legacy-peer-deps

# Ensure media directory exists
RUN mkdir -p /app/sandbox/public/media

# Patch missing image (skip if not found)
RUN test -f /app/src/oscar/static/oscar/img/image_not_found.jpg && \
    cp --remove-destination /app/src/oscar/static/oscar/img/image_not_found.jpg /app/sandbox/public/media/ || true

# Final working directory and launch
WORKDIR /app/sandbox
ENTRYPOINT ["/entrypoint.sh"]
CMD ["uwsgi", "--ini", "uwsgi.ini"]




