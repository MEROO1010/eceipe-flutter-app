import os
import sys

# Allow `python src/main.py` to resolve `src.*` imports.
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BASE_DIR)

from datetime import timedelta  # noqa: E402

from flask import Flask  # noqa: E402
from flask_cors import CORS  # noqa: E402
from flask_jwt_extended import JWTManager  # noqa: E402

from src.extensions import db  # noqa: E402
from src.routes.auth import auth_bp  # noqa: E402
from src.routes.favorites import favorites_bp  # noqa: E402
from src.routes.recipes import recipes_bp  # noqa: E402
from src.seed import seed_database  # noqa: E402
from src.utils import error, success  # noqa: E402


def create_app():
    app = Flask(__name__)

    db_dir = os.path.join(BASE_DIR, "database")
    os.makedirs(db_dir, exist_ok=True)
    default_db = "sqlite:///" + os.path.join(db_dir, "app.db").replace("\\", "/")

    app.config.update(
        SQLALCHEMY_DATABASE_URI=os.getenv("DATABASE_URL", default_db),
        SQLALCHEMY_TRACK_MODIFICATIONS=False,
        JWT_SECRET_KEY=os.getenv("JWT_SECRET_KEY", "change-me-in-production-please-32b"),
        JWT_ACCESS_TOKEN_EXPIRES=timedelta(days=7),
    )

    CORS(app, resources={r"/api/*": {"origins": "*"}})
    db.init_app(app)
    jwt = JWTManager(app)

    @jwt.unauthorized_loader
    def _missing_token(_reason):
        return error("Unauthorized", "Authentication required.", 401)

    @jwt.invalid_token_loader
    def _invalid_token(_reason):
        return error("Invalid token", "Invalid authentication token.", 401)

    @jwt.expired_token_loader
    def _expired_token(_header, _payload):
        return error("Token expired", "Session expired. Please log in again.", 401)

    app.register_blueprint(auth_bp)
    app.register_blueprint(recipes_bp)
    app.register_blueprint(favorites_bp)

    @app.get("/api/health")
    def health():
        return success({"status": "ok"})

    @app.errorhandler(404)
    def _not_found(_e):
        return error("Not found", "Resource not found.", 404)

    @app.errorhandler(500)
    def _server_error(_e):
        return error("Server error", "Something went wrong on the server.", 500)

    with app.app_context():
        db.create_all()
        seed_database()

    return app


app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", 5000)), debug=True)
