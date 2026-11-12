#!/usr/bin/env bash
# Starts the Flask API on port 5000 and makes the port public so the
# Flutter web app (a different origin) can call it from the browser.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ -n "$CODESPACE_NAME" ]; then
  ( sleep 6 && gh codespace ports visibility 5000:public -c "$CODESPACE_NAME" ) &
fi

cd "$ROOT/recipe_backend"
source venv/bin/activate
python src/main.py
