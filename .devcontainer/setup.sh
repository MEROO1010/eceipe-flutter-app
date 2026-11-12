#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo ">>> Backend: virtualenv + dependencies"
cd "$ROOT/recipe_backend"
python3 -m venv venv
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -r requirements.txt

echo ">>> Flutter SDK"
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
fi
export PATH="$PATH:$HOME/flutter/bin"
flutter config --no-analytics --enable-web
flutter precache --web

echo ">>> Flutter project"
cd "$ROOT/recipe_app"
if [ ! -d web ]; then
  flutter create . --project-name recipe_app --platforms=web
fi
flutter pub get

echo ">>> Done. Run: bash scripts/start-backend.sh  then  bash scripts/start-web.sh"
