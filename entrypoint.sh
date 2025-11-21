#!/bin/sh
set -e

echo "Waiting for PostgreSQL to be available..."
until nc -z db 5432; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

echo "PostgreSQL is up - continuing"

cd /app/sandbox

echo "Running Django migrations..."
python manage.py migrate

echo "Collecting static files..."
python manage.py collectstatic --noinput

if [ "$#" -gt 0 ]; then
  echo "Executing passed command: $@"
  exec "$@"
else
  echo "No command passed to entrypoint. Falling back to default CMD."
  exec uwsgi --ini uwsgi.ini
fi

