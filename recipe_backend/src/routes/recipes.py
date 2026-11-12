from flask import Blueprint, request
from flask_jwt_extended import get_jwt_identity, jwt_required
from sqlalchemy import or_

from src.extensions import db
from src.models import Favorite, Recipe
from src.utils import error, success

recipes_bp = Blueprint("recipes", __name__, url_prefix="/api/recipes")
DIFFICULTIES = {"Easy", "Medium", "Hard"}


def _parse_payload(data, partial=False):
    problems = []
    clean = {}

    def wanted(key):
        return (not partial) or key in data

    if wanted("title"):
        title = (data.get("title") or "").strip()
        if not title:
            problems.append("Title is required.")
        clean["title"] = title

    if wanted("ingredients"):
        raw = data.get("ingredients") or []
        if isinstance(raw, str):
            raw = raw.splitlines()
        items = [str(i).strip() for i in raw if str(i).strip()]
        if not items:
            problems.append("At least one ingredient is required.")
        clean["ingredients"] = items

    if wanted("instructions"):
        instructions = (data.get("instructions") or "").strip()
        if not instructions:
            problems.append("Instructions are required.")
        clean["instructions"] = instructions

    for key in ("prep_time", "cook_time", "servings"):
        if key in data:
            try:
                value = int(data[key])
                if value < 0:
                    raise ValueError
                clean[key] = value
            except (TypeError, ValueError):
                problems.append(f"{key} must be a non-negative integer.")

    if "difficulty" in data:
        if data["difficulty"] in DIFFICULTIES:
            clean["difficulty"] = data["difficulty"]
        else:
            problems.append("Difficulty must be Easy, Medium or Hard.")

    for key in ("description", "category", "cuisine", "image_url"):
        if key in data:
            clean[key] = (data[key] or "").strip()

    return clean, problems


@recipes_bp.get("")
def list_recipes():
    query = Recipe.query

    search = request.args.get("search", "").strip()
    if search:
        like = f"%{search}%"
        query = query.filter(
            or_(
                Recipe.title.ilike(like),
                Recipe.description.ilike(like),
                db.cast(Recipe.ingredients, db.String).ilike(like),
            )
        )
    for field in ("category", "cuisine", "difficulty"):
        value = request.args.get(field, "").strip()
        if value:
            query = query.filter(getattr(Recipe, field) == value)

    page = max(request.args.get("page", 1, type=int), 1)
    per_page = min(max(request.args.get("per_page", 10, type=int), 1), 50)
    result = query.order_by(Recipe.created_at.desc(), Recipe.id.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )

    return success(
        {
            "recipes": [r.to_dict() for r in result.items],
            "pagination": {
                "page": result.page,
                "per_page": result.per_page,
                "total": result.total,
                "pages": result.pages,
                "has_next": result.has_next,
            },
        }
    )


@recipes_bp.get("/<int:recipe_id>")
def get_recipe(recipe_id):
    recipe = db.session.get(Recipe, recipe_id)
    if not recipe:
        return error("Not found", "Recipe not found.", 404)
    return success({"recipe": recipe.to_dict()})


@recipes_bp.post("")
@jwt_required()
def create_recipe():
    data = request.get_json(silent=True) or {}
    clean, problems = _parse_payload(data)
    if problems:
        return error("Validation failed", " ".join(problems), 400)

    recipe = Recipe(user_id=int(get_jwt_identity()), **clean)
    db.session.add(recipe)
    db.session.commit()
    return success({"recipe": recipe.to_dict()}, "Recipe created", 201)


@recipes_bp.put("/<int:recipe_id>")
@jwt_required()
def update_recipe(recipe_id):
    recipe = db.session.get(Recipe, recipe_id)
    if not recipe:
        return error("Not found", "Recipe not found.", 404)
    if recipe.user_id != int(get_jwt_identity()):
        return error("Forbidden", "You can only edit your own recipes.", 403)

    data = request.get_json(silent=True) or {}
    clean, problems = _parse_payload(data, partial=True)
    if problems:
        return error("Validation failed", " ".join(problems), 400)

    for key, value in clean.items():
        setattr(recipe, key, value)
    db.session.commit()
    return success({"recipe": recipe.to_dict()}, "Recipe updated")


@recipes_bp.delete("/<int:recipe_id>")
@jwt_required()
def delete_recipe(recipe_id):
    recipe = db.session.get(Recipe, recipe_id)
    if not recipe:
        return error("Not found", "Recipe not found.", 404)
    if recipe.user_id != int(get_jwt_identity()):
        return error("Forbidden", "You can only delete your own recipes.", 403)

    Favorite.query.filter_by(recipe_id=recipe.id).delete()
    db.session.delete(recipe)
    db.session.commit()
    return success(None, "Recipe deleted")
