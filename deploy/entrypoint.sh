#!/usr/bin/env bash
set -euo pipefail

if [ -S /var/run/docker.sock ]; then
  docker_gid="$(stat -c '%g' /var/run/docker.sock)"
  if ! getent group docker-host >/dev/null 2>&1; then
    groupadd -g "${docker_gid}" docker-host 2>/dev/null || true
  fi
  usermod -aG "${docker_gid}" deployer 2>/dev/null || true
fi

exec "$@"
