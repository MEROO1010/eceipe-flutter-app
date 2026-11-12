import re

from flask import Blueprint, request
from flask_jwt_extended import create_access_token, get_jwt_identity, jwt_required
from sqlalchemy import or_

from src.extensions import db
from src.models import User
from src.utils import error, success

auth_bp = Blueprint("auth", __name__, url_prefix="/api/auth")
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


@auth_bp.post("/register")
def register():
    data = request.get_json(silent=True) or {}
    username = (data.get("username") or "").strip()
    email = (data.get("email") or "").strip().lower()
    password = data.get("password") or ""

    problems = []
    if len(username) < 3:
        problems.append("Username must be at least 3 characters.")
    if not EMAIL_RE.match(email):
        problems.append("A valid email is required.")
    if len(password) < 6:
        problems.append("Password must be at least 6 characters.")
    if problems:
        return error("Validation failed", " ".join(problems), 400)

    if User.query.filter(db.func.lower(User.username) == username.lower()).first():
        return error("Username taken", "This username is already taken.", 409)
    if User.query.filter_by(email=email).first():
        return error("Email taken", "This email is already registered.", 409)

    user = User(
        username=username,
        email=email,
        first_name=(data.get("first_name") or "").strip(),
        last_name=(data.get("last_name") or "").strip(),
    )
    user.set_password(password)
    db.session.add(user)
    db.session.commit()

    token = create_access_token(identity=str(user.id))
    return success(
        {"user": user.to_dict(), "access_token": token},
        "Registration successful",
        201,
    )


@auth_bp.post("/login")
def login():
    data = request.get_json(silent=True) or {}
    identifier = (data.get("username") or data.get("email") or "").strip()
    password = data.get("password") or ""
    if not identifier or not password:
        return error("Missing credentials", "Username and password are required.", 400)

    user = User.query.filter(
        or_(User.username == identifier, User.email == identifier.lower())
    ).first()
    if not user or not user.check_password(password):
        return error("Invalid credentials", "Incorrect username or password.", 401)
    if not user.is_active:
        return error("Inactive account", "This account is disabled.", 403)

    token = create_access_token(identity=str(user.id))
    return success({"user": user.to_dict(), "access_token": token}, "Login successful")


@auth_bp.get("/profile")
@jwt_required()
def profile():
    user = db.session.get(User, int(get_jwt_identity()))
    if not user:
        return error("Not found", "User not found.", 404)
    return success({"user": user.to_dict()})
