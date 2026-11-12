class Recipe {
  final int id;
  final String title;
  final String description;
  final List<String> ingredients;
  final String instructions;
  final int prepTime;
  final int cookTime;
  final int servings;
  final String difficulty;
  final String category;
  final String cuisine;
  final String imageUrl;
  final int userId;
  final String? author;

  const Recipe({
    required this.id,
    required this.title,
    this.description = '',
    this.ingredients = const [],
    this.instructions = '',
    this.prepTime = 0,
    this.cookTime = 0,
    this.servings = 1,
    this.difficulty = 'Medium',
    this.category = '',
    this.cuisine = '',
    this.imageUrl = '',
    required this.userId,
    this.author,
  });

  int get totalTime => prepTime + cookTime;

  List<String> get steps => instructions
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  static int _int(dynamic v, [int fallback = 0]) =>
      v is int ? v : int.tryParse('$v') ?? fallback;

  factory Recipe.fromJson(Map<String, dynamic> json) => Recipe(
        id: _int(json['id']),
        title: (json['title'] ?? '') as String,
        description: (json['description'] ?? '') as String,
        ingredients: ((json['ingredients'] ?? []) as List)
            .map((e) => e.toString())
            .toList(),
        instructions: (json['instructions'] ?? '') as String,
        prepTime: _int(json['prep_time']),
        cookTime: _int(json['cook_time']),
        servings: _int(json['servings'], 1),
        difficulty: (json['difficulty'] ?? 'Medium') as String,
        category: (json['category'] ?? '') as String,
        cuisine: (json['cuisine'] ?? '') as String,
        imageUrl: (json['image_url'] ?? '') as String,
        userId: _int(json['user_id']),
        author: json['author'] as String?,
      );
}
