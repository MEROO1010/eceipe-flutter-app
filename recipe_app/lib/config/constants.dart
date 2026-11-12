import 'package:flutter/material.dart';

const List<String> kDifficulties = ['Easy', 'Medium', 'Hard'];

const List<String> kCategories = [
  'Breakfast',
  'Lunch',
  'Dinner',
  'Dessert',
  'Snack',
  'Drink',
  'Salad',
  'Soup',
];

const List<String> kCuisines = [
  'Italian',
  'Arabic',
  'Indian',
  'Mexican',
  'Chinese',
  'Japanese',
  'French',
  'American',
  'Other',
];

Color difficultyColor(String difficulty) {
  switch (difficulty) {
    case 'Easy':
      return Colors.green;
    case 'Hard':
      return Colors.red;
    default:
      return Colors.orange;
  }
}
