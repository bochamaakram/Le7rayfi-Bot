#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="${PORT:-8080}"
HOST="${HOST:-127.0.0.1}"
DIST="$DIR/HraifiBot_Mini_V1"

if [ ! -d "$DIST" ]; then
  echo "HraifiBot_Mini_V1 not found in $DIR"
  exit 1
fi

echo "Starting le7raifiBot Mini V1 on http://$HOST:$PORT"
cd "$DIST"
exec python3 -m http.server "$PORT" --bind "$HOST"
