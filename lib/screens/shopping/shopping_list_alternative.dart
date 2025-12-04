// lib/screens/shopping/shopping_list_alternative.dart
import 'package:flutter/material.dart';
import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';

class ShoppingListAlternativeScreen extends StatefulWidget {
  final Ingredient ingredient;

  const ShoppingListAlternativeScreen({
    super.key,
    required this.ingredient,
  });

  @override
  State<ShoppingListAlternativeScreen> createState() =>
      _ShoppingListAlternativeScreenState();
}

class _ShoppingListAlternativeScreenState
    extends State<ShoppingListAlternativeScreen> {
  List<Ingredient> alternativeIngredients = [];

  @override
  void initState() {
    super.initState();
    _loadAlternatives();
  }

  Future<void> _loadAlternatives() async {
    final altRows = await (appDb.select(appDb.ingredientAlternatives)
          ..where((t) => t.ingredientId.equals(widget.ingredient.id))
          ..where((t) => t.alternativesId.isIn([2, 3, 4])))
        .get();

    final ids = altRows.map((a) => a.relatedIngredientId).toSet().toList();

    final ingredients = <Ingredient>[];

    for (final id in ids) {
      final ing = await (appDb.select(appDb.ingredients)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (ing != null) ingredients.add(ing);
    }

    setState(() {
      alternativeIngredients = ingredients;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ingredient = widget.ingredient;

    final img = (ingredient.picture == null || ingredient.picture!.isEmpty)
        ? "assets/images/placeholder.jpg"
        : ingredient.picture!;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Alternative wählen"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----- Aktuell ausgewählt -----
            const Text(
              "Aktuell ausgewählt",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 8),

            _ingredientBox(ingredient),

            const SizedBox(height: 28),

            // ----- Alternative Zutaten -----
            const Text(
              "Alternative Zutaten",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 8),

            if (alternativeIngredients.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(
                  child: Text(
                    "Keine Alternativen vorhanden.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),

            ...alternativeIngredients.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ingredientBox(i, isTapable: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------
  // REZEPT-/INGREDIENT-BOX – 1:1 wie deine _ImageListView Box
  // ----------------------------------------------------------------------
  Widget _ingredientBox(Ingredient ing, {bool isTapable = false}) {
    final img = (ing.picture == null || ing.picture!.isEmpty)
        ? "assets/images/placeholder.jpg"
        : ing.picture!;

    final box = Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 45,
              height: 45,
              color: Colors.black,
              child: Image.asset(
                img,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ing.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );

    if (!isTapable) return box;

    return InkWell(
      onTap: () => Navigator.pop(context, ing),
      splashColor: Colors.white10,
      highlightColor: Colors.white10,
      child: box,
    );
  }
}
