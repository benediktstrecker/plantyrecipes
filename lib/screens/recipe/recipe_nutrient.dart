// lib/screens/recipe/recipe_nutrient.dart
import 'package:flutter/material.dart';

class RecipeNutrientScreen extends StatelessWidget {
  final int recipeId;
  final String title;
  final String? imagePath;

  const RecipeNutrientScreen({
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
          'Nährwerte folgen',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
