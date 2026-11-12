import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/recipe.dart';
import '../providers/recipe_provider.dart';

class RecipeFormScreen extends StatefulWidget {
  const RecipeFormScreen({super.key, this.recipe});

  /// When provided, the form edits this recipe instead of creating one.
  final Recipe? recipe;

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _ingredients;
  late final TextEditingController _instructions;
  late final TextEditingController _prep;
  late final TextEditingController _cook;
  late final TextEditingController _servings;
  late final TextEditingController _imageUrl;
  late String _difficulty;
  String? _category;
  String? _cuisine;
  bool _busy = false;

  bool get _isEditing => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _title = TextEditingController(text: r?.title ?? '');
    _description = TextEditingController(text: r?.description ?? '');
    _ingredients = TextEditingController(text: r?.ingredients.join('\n') ?? '');
    _instructions = TextEditingController(text: r?.instructions ?? '');
    _prep = TextEditingController(text: '${r?.prepTime ?? 10}');
    _cook = TextEditingController(text: '${r?.cookTime ?? 20}');
    _servings = TextEditingController(text: '${r?.servings ?? 4}');
    _imageUrl = TextEditingController(text: r?.imageUrl ?? '');
    _difficulty = r?.difficulty ?? 'Medium';
    _category = kCategories.contains(r?.category) ? r!.category : null;
    _cuisine = kCuisines.contains(r?.cuisine) ? r!.cuisine : null;
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _description,
      _ingredients,
      _instructions,
      _prep,
      _cook,
      _servings,
      _imageUrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);

    final payload = {
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'ingredients': _ingredients.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      'instructions': _instructions.text.trim(),
      'prep_time': int.parse(_prep.text.trim()),
      'cook_time': int.parse(_cook.text.trim()),
      'servings': int.parse(_servings.text.trim()),
      'difficulty': _difficulty,
      'category': _category ?? '',
      'cuisine': _cuisine ?? '',
      'image_url': _imageUrl.text.trim(),
    };

    final provider = context.read<RecipeProvider>();
    final err = _isEditing
        ? await provider.updateRecipe(widget.recipe!.id, payload)
        : await provider.createRecipe(payload);

    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      Navigator.of(context).pop(true);
    }
  }

  String? _requiredNumber(String? v) {
    final n = int.tryParse(v?.trim() ?? '');
    return (n == null || n < 0) ? 'Enter a valid number' : null;
  }

  String? _required(String? v, String message) =>
      (v == null || v.trim().isEmpty) ? message : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit recipe' : 'New recipe'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(
                        labelText: 'Title', border: OutlineInputBorder()),
                    validator: (v) => _required(v, 'Title is required'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _description,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ingredients,
                    minLines: 4,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      labelText: 'Ingredients (one per line)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        _required(v, 'Add at least one ingredient'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _instructions,
                    minLines: 4,
                    maxLines: 12,
                    decoration: const InputDecoration(
                      labelText: 'Instructions (one step per line)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => _required(v, 'Instructions are required'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _prep,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Prep (min)',
                              border: OutlineInputBorder()),
                          validator: _requiredNumber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _cook,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Cook (min)',
                              border: OutlineInputBorder()),
                          validator: _requiredNumber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _servings,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Servings',
                              border: OutlineInputBorder()),
                          validator: _requiredNumber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _difficulty,
                    decoration: const InputDecoration(
                        labelText: 'Difficulty', border: OutlineInputBorder()),
                    items: kDifficulties
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _difficulty = v!),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                        labelText: 'Category', border: OutlineInputBorder()),
                    items: kCategories
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _cuisine,
                    decoration: const InputDecoration(
                        labelText: 'Cuisine', border: OutlineInputBorder()),
                    items: kCuisines
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => _cuisine = v),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _imageUrl,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                        labelText: 'Image URL (optional)',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _save,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(_isEditing ? 'Save changes' : 'Create recipe'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
