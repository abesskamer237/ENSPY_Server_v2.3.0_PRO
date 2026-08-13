#!/bin/sh
set -eu

echo "[entrypoint] Preparing ENSPY runtime directories..."
mkdir -p /app/uploads /app/logs
chown -R node:node /app/uploads /app/logs

echo "[entrypoint] Starting API as user node..."
exec su-exec node "$@"
