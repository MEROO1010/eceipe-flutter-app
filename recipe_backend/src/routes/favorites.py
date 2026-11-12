from flask import Blueprint, request
from flask_jwt_extended import get_jwt_identity, jwt_required

from src.extensions import db
from src.models import Favorite, Recipe
from src.utils import error, success

favorites_bp = Blueprint("favorites", __name__, url_prefix="/api/favorites")


@favorites_bp.get("")
@jwt_required()
def list_favorites():
    user_id = int(get_jwt_identity())
    recipes = (
        Recipe.query.join(Favorite, Favorite.recipe_id == Recipe.id)
        .filter(Favorite.user_id == user_id)
        .order_by(Favorite.created_at.desc())
        .all()
    )
    return success({"recipes": [r.to_dict() for r in recipes]})


@favorites_bp.post("")
@jwt_required()
def add_favorite():
    user_id = int(get_jwt_identity())
    data = request.get_json(silent=True) or {}
    try:
        recipe_id = int(data.get("recipe_id"))
    except (TypeError, ValueError):
        return error("Validation failed", "recipe_id is required.", 400)

    if not db.session.get(Recipe, recipe_id):
        return error("Not found", "Recipe not found.", 404)

    existing = Favorite.query.filter_by(user_id=user_id, recipe_id=recipe_id).first()
    if existing:
        return success(None, "Already in favorites")

    db.session.add(Favorite(user_id=user_id, recipe_id=recipe_id))
    db.session.commit()
    return success(None, "Added to favorites", 201)


@favorites_bp.delete("/<int:recipe_id>")
@jwt_required()
def remove_favorite(recipe_id):
    user_id = int(get_jwt_identity())
    deleted = Favorite.query.filter_by(user_id=user_id, recipe_id=recipe_id).delete()
    db.session.commit()
    if not deleted:
        return error("Not found", "Recipe is not in your favorites.", 404)
    return success(None, "Removed from favorites")
