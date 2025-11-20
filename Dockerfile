FROM python:3.12

ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && \
    apt-get install -y curl gnupg libmagic1 && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create app directory and copy requirements
WORKDIR /app
COPY ./requirements.txt /app/requirements.txt

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create non-root user and home directory
RUN groupadd -r django && useradd -r -g django -m django && \
    mkdir -p /home/django && chown django:django /home/django

# Copy project files and fix ownership
COPY . /app
RUN chown -R django:django /app

# Set npm cache to a writable location
ENV npm_config_cache=/tmp/.npm

# Switch to non-root user
USER django

# Clean npm cache and install JS dependencies
RUN rm -rf node_modules package-lock.json && \
    npm cache clean --force && \
    npm install --legacy-peer-deps

# Build Oscar sandbox
RUN make build_sandbox

# Patch missing image
RUN cp --remove-destination /app/src/oscar/static/oscar/img/image_not_found.jpg /app/sandbox/public/media/

# Set working directory and launch
WORKDIR /app/sandbox
CMD ["uwsgi", "--ini", "uwsgi.ini"]



