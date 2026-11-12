# Comprehensive Recipe App (Flutter + Flask)

```
recipe_app_project/
├── recipe_backend/   # Flask + SQLAlchemy + JWT + bcrypt
└── recipe_app/       # Flutter (Provider, http, shared_preferences)
```

## 1) Backend

```bash
cd recipe_backend
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
python src/main.py              # http://localhost:5000
```

- Database (SQLite) and sample recipes are created on first run.
- Demo account: `demo` / `demo123`
- Optional env vars: `JWT_SECRET_KEY`, `DATABASE_URL`, `PORT`
- Health check: `GET /api/health`

## 2) Flutter app

The source only contains `lib/`, `test/` and `pubspec.yaml`. Generate the
platform folders once (web/android/ios) from inside `recipe_app/`:

```bash
cd recipe_app
flutter create . --project-name recipe_app --platforms=web,android,ios
flutter pub get
flutter run -d chrome
```

API address:
- Web / iOS simulator: `http://localhost:5000/api` (default)
- Android emulator: `http://10.0.2.2:5000/api` (automatic)
- Real device or deployed server:
  `flutter run --dart-define=API_BASE_URL=http://<IP>:5000/api`

Build for web: `flutter build web`

## API

| Method | Endpoint | Auth |
|---|---|---|
| POST | /api/auth/register | - |
| POST | /api/auth/login | - |
| GET | /api/auth/profile | JWT |
| GET | /api/recipes?page=&per_page=&search=&category=&cuisine=&difficulty= | - |
| POST | /api/recipes | JWT |
| GET | /api/recipes/{id} | - |
| PUT / DELETE | /api/recipes/{id} | JWT (owner) |
| GET / POST | /api/favorites | JWT |
| DELETE | /api/favorites/{recipe_id} | JWT |

Responses: `{"success": true, "data": ..., "message": "..."}` or
`{"success": false, "error": "...", "message": "..."}`.

## GitHub Codespaces

1. Push this folder to a GitHub repo (the `.devcontainer/` folder must be at the repo root).
2. Repo page → **Code** → **Codespaces** → **Create codespace on main**.
3. Wait for setup to finish (installs Python deps + Flutter SDK, a few minutes).
4. Terminal 1: `bash scripts/start-backend.sh`
5. Terminal 2: `bash scripts/start-web.sh` → open port **8080** from the Ports tab.
