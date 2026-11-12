#!/usr/bin/env bash
# Runs the Flutter web app on port 8080, pointed at the Codespaces API URL.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$PATH:$HOME/flutter/bin"

if [ -n "$CODESPACE_NAME" ]; then
  API_URL="https://${CODESPACE_NAME}-5000.${GITHUB_CODESPACES_PORT_FORWARDING_DOMAIN}/api"
else
  API_URL="http://localhost:5000/api"
fi
echo "API: $API_URL"

cd "$ROOT/recipe_app"
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 \
  --dart-define=API_BASE_URL="$API_URL"
