#!/usr/bin/env bash
set -euo pipefail
cd "${ENSPY_APP_DIR:-/opt/enspy}"
echo "=== SERVICES ==="
docker compose ps
echo
echo "=== NETWORK ==="
docker network inspect enspy_network --format '{{range .Containers}}{{.Name}} -> {{.IPv4Address}}{{"\n"}}{{end}}' 2>/dev/null || true
echo
echo "=== PORTS ==="
ss -ltnp | grep -E ':(80|443|8080)\s' || true
echo
echo "=== API DIRECT ==="
curl -i --max-time 5 http://127.0.0.1:8080/api/healthz || true
echo
echo "=== API VIA NGINX HTTP ==="
curl -i --max-time 5 http://127.0.0.1/api/healthz || true
echo
echo "=== API VIA NGINX HTTPS ==="
PUBLIC_IP="$(curl -4fsS --max-time 5 https://api.ipify.org 2>/dev/null || true)"
[[ -n "$PUBLIC_IP" ]] && curl -ki --max-time 8 "https://$PUBLIC_IP/api/healthz" || true
echo
echo "=== CERTIFICATE ==="
ls -l certbot/conf/live/enspy-ip/ 2>/dev/null || true
echo
echo "=== NGINX LOGS ==="
docker compose logs --tail=100 nginx
echo
echo "=== API LOGS ==="
docker compose logs --tail=100 api
