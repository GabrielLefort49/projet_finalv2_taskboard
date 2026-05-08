#!/usr/bin/env bash
set -euo pipefail

LOCAL_SSH_PORT="${LOCAL_SSH_PORT:-2222}"
REMOTE_PORT="${REMOTE_PORT:-80}"
LOCALHOST_RUN_USER="${LOCALHOST_RUN_USER:-nokey}"

echo "Opening localhost.run tunnel to local SSH server on 127.0.0.1:${LOCAL_SSH_PORT}"
echo "Keep this terminal open while GitHub Actions deploys."

ssh \
  -o ServerAliveInterval=60 \
  -o ExitOnForwardFailure=yes \
  -R "${REMOTE_PORT}:127.0.0.1:${LOCAL_SSH_PORT}" \
  "${LOCALHOST_RUN_USER}@localhost.run"
