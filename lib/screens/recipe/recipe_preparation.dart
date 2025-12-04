// lib/screens/recipe/recipe_preparation.dart
import 'package:flutter/material.dart';

class RecipePreparationScreen extends StatelessWidget {
  final int recipeId;
  final String title;
  final String? imagePath;

  const RecipePreparationScreen({
    super.key,
    required this.recipeId,
    required this.title,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          'Zubereitung folgt',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
