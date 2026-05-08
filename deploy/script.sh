#!/usr/bin/env bash
set -Eeuo pipefail

APP_NAME="${APP_NAME:-taskboard-app}"
DB_NAME="${DB_NAME:-taskboard-db-prod}"
NETWORK_NAME="${NETWORK_NAME:-taskboard-prod}"
IMAGE_NAME="${IMAGE_NAME:?IMAGE_NAME is required, for example ghcr.io/owner/repo}"
IMAGE_TAG="${IMAGE_TAG:?IMAGE_TAG is required, for example the Git commit SHA}"
IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"

DB_USER="${DB_USER:-taskboard}"
DB_PASSWORD="${DB_PASSWORD:-taskboard123}"
DB_DATABASE="${DB_DATABASE:-taskboard}"
JWT_SECRET="${JWT_SECRET:?JWT_SECRET is required}"
APP_PORT="${APP_PORT:-3000}"
HEALTH_URL="${HEALTH_URL:-http://localhost:${APP_PORT}/health}"

cleanup_old_app() {
  if docker ps -a --format '{{.Names}}' | grep -Fxq "${APP_NAME}"; then
    docker rm -f "${APP_NAME}" >/dev/null
  fi
}

wait_for_db() {
  for attempt in $(seq 1 30); do
    if docker exec "${DB_NAME}" pg_isready -U "${DB_USER}" -d "${DB_DATABASE}" >/dev/null 2>&1; then
      echo "Database is ready"
      return 0
    fi
    echo "Database pending (${attempt}/30)"
    sleep 2
  done

  echo "Database did not become ready" >&2
  docker logs --tail=100 "${DB_NAME}" >&2 || true
  return 1
}

wait_for_health() {
  for attempt in $(seq 1 30); do
    if docker exec "${APP_NAME}" wget -qO- "${HEALTH_URL}" >/dev/null 2>&1; then
      echo "Healthcheck OK: ${HEALTH_URL}"
      return 0
    fi
    echo "Healthcheck pending (${attempt}/30)"
    sleep 2
  done

  echo "Healthcheck failed after deployment" >&2
  docker logs --tail=100 "${APP_NAME}" >&2 || true
  return 1
}

echo "Deploying ${IMAGE}"

if [ -n "${GHCR_USERNAME:-}" ] && [ -n "${GHCR_TOKEN:-}" ]; then
  echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USERNAME}" --password-stdin >/dev/null
fi

docker network create "${NETWORK_NAME}" >/dev/null 2>&1 || true

if ! docker ps -a --format '{{.Names}}' | grep -Fxq "${DB_NAME}"; then
  docker run -d \
    --name "${DB_NAME}" \
    --network "${NETWORK_NAME}" \
    --restart unless-stopped \
    -e POSTGRES_USER="${DB_USER}" \
    -e POSTGRES_PASSWORD="${DB_PASSWORD}" \
    -e POSTGRES_DB="${DB_DATABASE}" \
    -v taskboard-postgres-data:/var/lib/postgresql/data \
    postgres:16 >/dev/null
else
  docker start "${DB_NAME}" >/dev/null
  docker network connect "${NETWORK_NAME}" "${DB_NAME}" >/dev/null 2>&1 || true
fi

wait_for_db

if [ "${SKIP_PULL:-0}" = "1" ]; then
  echo "Skipping docker pull for local deployment test"
else
  docker pull "${IMAGE}"
fi

cleanup_old_app

docker run -d \
  --name "${APP_NAME}" \
  --network "${NETWORK_NAME}" \
  --restart unless-stopped \
  -p "${APP_PORT}:3000" \
  -e PORT=3000 \
  -e DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@${DB_NAME}:5432/${DB_DATABASE}" \
  -e JWT_SECRET="${JWT_SECRET}" \
  "${IMAGE}" >/dev/null

wait_for_health
echo "Deployment finished"
