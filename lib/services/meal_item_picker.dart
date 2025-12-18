//lib/services/meal_item_picker.dart
import 'package:flutter/material.dart';

import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/screens/recipe/recipe_list_screen.dart';
import 'package:planty_flutter_starter/screens/ingredient/ingredients_list_screen.dart';


// ===================================================================
// PICK MODE
// ===================================================================
enum ListPickMode {
  none,
  mealSelect,
}


// ===================================================================
// RESULT MODEL
// ===================================================================
sealed class SelectedMealItem {
  const SelectedMealItem();

  factory SelectedMealItem.recipe(int recipeId) =
      _SelectedMealRecipe;

  factory SelectedMealItem.ingredient(int ingredientId) =
      _SelectedMealIngredient;

  T when<T>({
    required T Function(int recipeId) recipe,
    required T Function(int ingredientId) ingredient,
  }) {
    final self = this;
    if (self is _SelectedMealRecipe) {
      return recipe(self.recipeId);
    }
    if (self is _SelectedMealIngredient) {
      return ingredient(self.ingredientId);
    }
    throw StateError('Unhandled SelectedMealItem: $self');
  }
}


class _SelectedMealRecipe extends SelectedMealItem {
  final int recipeId;
  const _SelectedMealRecipe(this.recipeId);
}

class _SelectedMealIngredient extends SelectedMealItem {
  final int ingredientId;
  const _SelectedMealIngredient(this.ingredientId);
}


// ===================================================================
// 🔁 ZENTRALER PICKER (DIALOG + NAVIGATION)
// ===================================================================
class MealItemPicker {
    static Future<SelectedMealItem?> pick({
    required BuildContext context,
    required DateTime day,
    int? mealCategoryId, // ✅ nullable
  }) {
    return showDialog<SelectedMealItem>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ---------------------------
                // Titel
                // ---------------------------
                const Text(
                  'Was hinzufügen?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------------------
                // Auswahl
                // ---------------------------
                Row(
                  children: [
                    // ===== Rezept =====
                    Expanded(
                      child: _PickerChoiceTile(
                        title: 'Rezept',
                        icon: Icons.list_alt,
                        onTap: () async {
                          final result =
                              await Navigator.of(dialogCtx).push<SelectedMealItem>(
                            MaterialPageRoute(
                              builder: (_) => RecipeListScreen(
                                pickMode: ListPickMode.mealSelect,
                                mealDay: day,
                                mealCategoryId: mealCategoryId,
                              ),
                            ),
                          );

                          Navigator.of(dialogCtx).pop(result);
                        },
                      ),
                    ),

                    const SizedBox(width: 16),

                    // ===== Zutat =====
                    Expanded(
                      child: _PickerChoiceTile(
                        title: 'Zutat',
                        icon: Icons.eco,
                        onTap: () async {
                          final result =
                              await Navigator.of(dialogCtx).push<SelectedMealItem>(
                            MaterialPageRoute(
                              builder: (_) => IngredientsListScreen(
                                category: 'Alle Zutaten',
                                pickMode: ListPickMode.mealSelect,
                                mealDay: day,
                                mealCategoryId: mealCategoryId,
                              ),
                            ),
                          );

                          Navigator.of(dialogCtx).pop(result);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


// ===================================================================
// UI-Kachel (lokal, privat)
// ===================================================================
class _PickerChoiceTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerChoiceTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
