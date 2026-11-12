from src.extensions import db
from src.models import Recipe, User

SAMPLE_RECIPES = [
    {
        "title": "Spaghetti Carbonara",
        "description": "Classic Roman pasta with eggs, pecorino, guanciale and black pepper.",
        "ingredients": [
            "400g spaghetti",
            "150g guanciale or pancetta",
            "4 egg yolks + 1 whole egg",
            "80g pecorino romano, grated",
            "Freshly ground black pepper",
            "Salt for the pasta water",
        ],
        "instructions": (
            "Boil the spaghetti in well-salted water until al dente.\n"
            "Fry the guanciale in a cold pan until crisp and golden.\n"
            "Whisk the eggs, pecorino and plenty of black pepper.\n"
            "Toss the drained pasta with the guanciale off the heat.\n"
            "Add the egg mixture with a splash of pasta water and stir until creamy."
        ),
        "prep_time": 10,
        "cook_time": 15,
        "servings": 4,
        "difficulty": "Medium",
        "category": "Dinner",
        "cuisine": "Italian",
        "image_url": "",
    },
    {
        "title": "Shakshuka",
        "description": "Eggs poached in a spiced tomato and pepper sauce.",
        "ingredients": [
            "2 tbsp olive oil",
            "1 onion, diced",
            "1 red bell pepper, diced",
            "3 cloves garlic",
            "1 can (400g) crushed tomatoes",
            "1 tsp cumin",
            "1 tsp paprika",
            "4 eggs",
        ],
        "instructions": (
            "Saute the onion and pepper in olive oil until soft.\n"
            "Add garlic and spices and cook for one minute.\n"
            "Pour in the tomatoes and simmer for 10 minutes.\n"
            "Make wells in the sauce and crack in the eggs.\n"
            "Cover and cook until the whites are set. Serve with bread."
        ),
        "prep_time": 10,
        "cook_time": 20,
        "servings": 2,
        "difficulty": "Easy",
        "category": "Breakfast",
        "cuisine": "Arabic",
        "image_url": "",
    },
    {
        "title": "Chicken Tikka Masala",
        "description": "Grilled marinated chicken in a creamy spiced tomato sauce.",
        "ingredients": [
            "600g chicken breast, cubed",
            "1 cup plain yogurt",
            "2 tbsp tikka masala spice",
            "1 onion, diced",
            "1 can (400g) tomato puree",
            "1/2 cup cream",
            "Fresh coriander",
        ],
        "instructions": (
            "Marinate the chicken in yogurt and half the spices for at least 1 hour.\n"
            "Sear the chicken in a hot pan and set aside.\n"
            "Cook the onion, remaining spices and tomato puree for 10 minutes.\n"
            "Stir in the cream and return the chicken to the pan.\n"
            "Simmer for 10 minutes and finish with coriander."
        ),
        "prep_time": 70,
        "cook_time": 30,
        "servings": 4,
        "difficulty": "Medium",
        "category": "Dinner",
        "cuisine": "Indian",
        "image_url": "",
    },
]


def seed_database():
    if Recipe.query.count() > 0:
        return

    demo = User.query.filter_by(username="demo").first()
    if not demo:
        demo = User(
            username="demo",
            email="demo@example.com",
            first_name="Demo",
            last_name="Chef",
        )
        demo.set_password("demo123")
        db.session.add(demo)
        db.session.flush()

    for item in SAMPLE_RECIPES:
        db.session.add(Recipe(user_id=demo.id, **item))
    db.session.commit()
