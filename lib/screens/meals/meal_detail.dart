// lib/screens/meals/meal_detail.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';

import 'package:planty_flutter_starter/services/meal_item_picker.dart';
import 'package:planty_flutter_starter/widgets/meal_plan_assign_dialog.dart';
import 'package:planty_flutter_starter/widgets/ingredient_plan_assign_dialog.dart';
import 'package:planty_flutter_starter/widgets/multi_day_picker.dart';

Color _parseHexColor(String? hex) {
  if (hex == null) return Colors.grey;
  String c = hex.replaceAll('#', '');
  if (c.length == 6) c = 'FF$c';
  return Color(int.parse(c, radix: 16));
}

class MealDetailScreen extends StatefulWidget {
  final DateTime day;
  final MealCategoryData category;

  const MealDetailScreen({
    super.key,
    required this.day,
    required this.category,
  });

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class MealIngredientEntry {
  final MealData meal;
  final Ingredient ingredient;
  final Recipe? recipe;

  const MealIngredientEntry({
    required this.meal,
    required this.ingredient,
    this.recipe,
  });
}


class _MealDetailScreenState extends State<MealDetailScreen> {
  late MealCategoryData _selectedCategory;

  List<MealCategoryData> _allCategories = [];
  int _currentCategoryIndex = 0;

  DateTime? _timeConsumed;


  DateTime get _dayStart =>
    DateTime(widget.day.year, widget.day.month, widget.day.day);

  DateTime get _dayEnd => _dayStart.add(const Duration(days: 1));


  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
    _loadEarliestTimeConsumed();
    _initCategories();
  }


  String _formatDate(DateTime d) {
    return DateFormat('dd.MM.yyyy').format(d);
  }

  String _formatTime(DateTime d) {
    return DateFormat('HH:mm').format(d);
  }

  String _formatAmount(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  Future<void> _initCategories() async {
  final cats = await (appDb.select(appDb.mealCategory)
        ..orderBy([(c) => d.OrderingTerm.asc(c.id)]))
      .get();

  final idx = cats.indexWhere((c) => c.id == widget.category.id);

  setState(() {
    _allCategories = cats;
    _currentCategoryIndex = idx >= 0 ? idx : 0;
    _selectedCategory = cats[_currentCategoryIndex];
  });

  await _loadEarliestTimeConsumed();
}

void _goToPreviousCategory() {
  if (_currentCategoryIndex <= 0) return;

  setState(() {
    _currentCategoryIndex--;
    _selectedCategory = _allCategories[_currentCategoryIndex];
    _timeConsumed = null; // ✅ WICHTIG
  });

  _loadEarliestTimeConsumed();
}


void _goToNextCategory() {
  if (_currentCategoryIndex >= _allCategories.length - 1) return;

  setState(() {
    _currentCategoryIndex++;
    _selectedCategory = _allCategories[_currentCategoryIndex];
    _timeConsumed = null; // ✅ WICHTIG
  });

  _loadEarliestTimeConsumed();
}




  Future<void> _loadEarliestTimeConsumed() async {
  final start = DateTime(widget.day.year, widget.day.month, widget.day.day);
  final end = start.add(const Duration(days: 1));

  final rows = await (appDb.select(appDb.meal)
        ..where((m) =>
            m.mealCategoryId.equals(_selectedCategory.id) &
            m.date.isBiggerOrEqualValue(start) &
            m.date.isSmallerThanValue(end) &
            m.timeConsumed.isNotNull())
        ..orderBy([
          (m) => d.OrderingTerm.asc(m.timeConsumed),
        ])
        ..limit(1))
      .get();

  if (!mounted) return;

  setState(() {
    _timeConsumed = rows.isNotEmpty ? rows.first.timeConsumed : null;
  });
}

Future<void> _deleteWholeSlot() async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          'Mahlzeit löschen',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Alle Einträge für "${_selectedCategory.name}" '
          'am ${_formatDate(widget.day)} werden gelöscht.\n\n'
          'Diese Aktion kann nicht rückgängig gemacht werden.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Löschen',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return;

  final start = DateTime(
    widget.day.year,
    widget.day.month,
    widget.day.day,
  );
  final end = start.add(const Duration(days: 1));

  // 🔥 ALLE Meals dieses Slots löschen
  await (appDb.delete(appDb.meal)
        ..where((m) =>
            m.mealCategoryId.equals(_selectedCategory.id) &
            m.date.isBiggerOrEqualValue(start) &
            m.date.isSmallerThanValue(end)))
      .go();

  if (!mounted) return;

  Navigator.of(context).pop();
}

Future<void> _onPlanForward() async {
  // --------------------------------------------------
  // 1) Tage auswählen
  // --------------------------------------------------
  final pickedDays = await MultiDayPicker.showMealPlan(
    context,
    portionLimit: 30, // leicht begrenzt
  );


  if (pickedDays == null || pickedDays.isEmpty) return;

  // --------------------------------------------------
  // 2) Alle Meals des aktuellen Slots laden
  // --------------------------------------------------
  final sourceMeals = await _loadMealsOfCurrentSlot();
  if (sourceMeals.isEmpty) return;

  // --------------------------------------------------
  // 3) Assign-Dialog (nur für Kategorie + Faktor)
  // --------------------------------------------------
  final assignment = await showDialog<MealPlanAssignmentResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => MealPlanAssignDialog(
      selectedDays: pickedDays,
      recipeId: -1, // ⚠️ Dummy – wird NICHT benutzt
      recipePortionNumber: 1,
    ),
  );

  if (assignment == null) return;

  // --------------------------------------------------
  // 4) Kopieren
  // --------------------------------------------------
  await _duplicateSlotMeals(
    sourceMeals: sourceMeals,
    assignments: assignment.entries,
  );

  if (!mounted) return;
  setState(() {});
}

Future<List<MealData>> _loadMealsOfCurrentSlot() async {
  return (appDb.select(appDb.meal)
        ..where((m) =>
            m.mealCategoryId.equals(_selectedCategory.id) &
            m.date.isBiggerOrEqualValue(_dayStart) &
            m.date.isSmallerThanValue(_dayEnd)))
      .get();
}

Future<void> _duplicateSlotMeals({
  required List<MealData> sourceMeals,
  required List<MealPlanDayEntry> assignments,
}) async {
  for (final target in assignments) {
    for (final m in sourceMeals) {
      // ---------------------------------------------
      // preparation_list nur wenn REZEPT vorhanden
      // ---------------------------------------------
      int? prepId;
      if (m.recipeId != null) {
        prepId = await appDb.into(appDb.preparationList).insert(
          PreparationListCompanion.insert(
            recipeId: m.recipeId!,          // ✅ int (NICHT d.Value)
            timePrepared: const d.Value(null),
          ),
        );
      }

      // ---------------------------------------------
      // Meal kopieren
      // ---------------------------------------------
      await appDb.into(appDb.meal).insert(
        MealCompanion.insert(
          date: d.Value(target.date),
          mealCategoryId: d.Value(target.categoryId),

          recipeId: d.Value(m.recipeId),
          recipePortionNumber: d.Value(m.recipePortionNumber),
          recipePortionUnit: d.Value(m.recipePortionUnit),

          preparationListId: d.Value(prepId),

          ingredientId: d.Value(m.ingredientId),
          ingredientUnitCode: d.Value(m.ingredientUnitCode),

          ingredientAmount: d.Value(
            (m.ingredientAmount ?? 0) * target.portions,
          ),

          prepared: const d.Value(false),
          timeConsumed: const d.Value(null),
        ),
      );
    }
  }
}




Future<void> _onAddPressed() async {
  final picked = await MealItemPicker.pick(
    context: context,
    day: widget.day,
    mealCategoryId: _selectedCategory.id,
  );

  if (picked == null || !mounted) return;

  final pickedDays = <DateTime>[widget.day];

  await picked.when(

    // ======================================================
    // 🟩 REZEPT
    // ======================================================
    recipe: (recipeId) async {
      final assignment = await showDialog<MealPlanAssignmentResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => MealPlanAssignDialog(
          selectedDays: pickedDays,
          recipeId: recipeId,
          recipePortionNumber: 1,
        ),
      );

      if (assignment == null) return;

      final recipe = await (appDb.select(appDb.recipes)
            ..where((r) => r.id.equals(recipeId)))
          .getSingleOrNull();
      if (recipe == null) return;

      final ingRows = await (appDb.select(appDb.recipeIngredients)
            ..where((t) => t.recipeId.equals(recipe.id)))
          .get();

      final basePortions = recipe.portionNumber ?? 1;
      final portionUnit = recipe.portionUnit;

      final prepId = await appDb.into(appDb.preparationList).insert(
        PreparationListCompanion.insert(
          recipeId: recipe.id,
          recipePortionNumberBase: d.Value(basePortions),
          recipePortionNumberLeft: d.Value(basePortions),
          timePrepared: const d.Value(null),
        ),
      );

      for (final entry in assignment.entries) {
        for (final ing in ingRows) {
          final scaledAmount =
              (entry.portions / basePortions) * (ing.amount ?? 0);

          await appDb.into(appDb.meal).insert(
            MealCompanion.insert(
              date: d.Value(entry.date),
              mealCategoryId: d.Value(entry.categoryId),

              recipeId: d.Value(recipe.id),
              recipePortionNumber: d.Value(entry.portions),
              recipePortionUnit: d.Value(portionUnit),
              preparationListId: d.Value(prepId),

              ingredientId: d.Value(ing.ingredientId),
              ingredientUnitCode: d.Value(ing.unitCode),
              ingredientAmount: d.Value(scaledAmount),

              prepared: const d.Value(false),
              timeConsumed: const d.Value(null),
            ),
          );
        }
      }

      await _askAddToShoppingForRecipe(ingRows);
    },

    // ======================================================
    // 🟦 ZUTAT
    // ======================================================
    ingredient: (ingredientId) async {
      final ingredient = await (appDb.select(appDb.ingredients)
            ..where((i) => i.id.equals(ingredientId)))
          .getSingle();

      final iuRows = await (appDb.select(appDb.ingredientUnits)
            ..where((u) => u.ingredientId.equals(ingredientId)))
          .get();

      final iuCodes = iuRows.map((e) => e.unitCode).toSet();
      final allUnits = await appDb.select(appDb.units).get();

      final units = [
        for (final u in allUnits)
          if (iuCodes.contains(u.code)) u,
      ];

      final entries = await showDialog<List<IngredientDayEntry>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => IngredientPlanAssignDialog(
          pickedDays: pickedDays,
          ingredient: ingredient,
          units: units,
          defaultMealCategoryId: _selectedCategory.id,
        ),
      );

      if (entries == null) return;

      for (final e in entries) {
        await appDb.into(appDb.meal).insert(
          MealCompanion.insert(
            date: d.Value(e.date),
            mealCategoryId: d.Value(e.categoryId),

            recipeId: const d.Value(null),
            preparationListId: const d.Value(null),
            recipePortionNumber: const d.Value(null),
            recipePortionUnit: const d.Value(null),

            ingredientId: d.Value(ingredientId),
            ingredientUnitCode: d.Value(e.unitCode),
            ingredientAmount: d.Value(e.amount),

            prepared: const d.Value(false),
            timeConsumed: const d.Value(null),
          ),
        );
      }

      await _askAddToShoppingForIngredient(entries, ingredientId);
    },
  );

  if (mounted) setState(() {});
}

Future<void> _askAddToShoppingForRecipe(
  List<RecipeIngredient> ingRows,
) async {
  final add = await _confirmAddToShopping();
  if (!add) return;

  final targetId = await _selectShoppingList();
  if (targetId == null) return;

  for (final ing in ingRows) {
    await appDb.into(appDb.shoppingListIngredient).insert(
      ShoppingListIngredientCompanion.insert(
        shoppingListId: targetId,
        ingredientIdNominal: d.Value(ing.ingredientId),
        ingredientAmountNominal: d.Value(ing.amount),
        ingredientUnitCodeNominal: d.Value(ing.unitCode),
      ),
    );
  }
}

Future<void> _askAddToShoppingForIngredient(
  List<IngredientDayEntry> entries,
  int ingredientId,
) async {
  final add = await _confirmAddToShopping();
  if (!add) return;

  final targetId = await _selectShoppingList();
  if (targetId == null) return;

  final totalAmount =
      entries.fold<double>(0, (s, e) => s + e.amount);
  final unitCode = entries.first.unitCode;

  await appDb.into(appDb.shoppingListIngredient).insert(
    ShoppingListIngredientCompanion.insert(
      shoppingListId: targetId,
      ingredientIdNominal: d.Value(ingredientId),
      ingredientAmountNominal: d.Value(totalAmount),
      ingredientUnitCodeNominal: d.Value(unitCode),
    ),
  );
}

Future<bool> _confirmAddToShopping() async {
  if (!mounted) return false;

  final res = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.black87,
      title: const Text(
        "Zur Einkaufsliste hinzufügen?",
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        "Sollen die benötigten Zutaten zu einer Einkaufsliste hinzugefügt werden?",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("Nein", style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text("Ja", style: TextStyle(color: Colors.greenAccent)),
        ),
      ],
    ),
  );

  return res == true;
}

Future<int?> _selectShoppingList() async {
  if (!mounted) return null;

  return showDialog<int>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _SelectTargetShoppingListDialog(),
  );
}







Future<List<MealIngredientEntry>> _loadMealIngredients() async {
  final start = DateTime(
    widget.day.year,
    widget.day.month,
    widget.day.day,
  );
  final end = start.add(const Duration(days: 1));

  final m = appDb.meal;
  final i = appDb.ingredients;
  final r = appDb.recipes;

  final rows = await (appDb.select(m)
        ..where((t) =>
            t.mealCategoryId.equals(_selectedCategory.id) &
            t.date.isBiggerOrEqualValue(start) &
            t.date.isSmallerThanValue(end) &
            t.ingredientId.isNotNull()))
      .join([
    d.innerJoin(i, i.id.equalsExp(m.ingredientId)),
    d.leftOuterJoin(r, r.id.equalsExp(m.recipeId)),
  ]).get();

  return rows.map((row) {
    return MealIngredientEntry(
      meal: row.readTable(m),
      ingredient: row.readTable(i),
      recipe: row.readTableOrNull(r),
    );
  }).toList();
}

Widget _buildIngredientRow(MealIngredientEntry e) {
  final img = (e.ingredient.picture == null || e.ingredient.picture!.isEmpty)
      ? 'assets/images/placeholder.jpg'
      : e.ingredient.picture!;

  final amount = e.meal.ingredientAmount ?? 0;

  return Container(
    margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white24),
    ),
    child: Row(
      children: [
        // =========================
        // LINKS: Bild + Name
        // =========================
        Expanded(
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  img,
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  e.ingredient.name,
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
        ),

        // =========================
        // RECHTS: – / 🗑 / EDIT / +
        // =========================
        Row(
          children: [
            // 🔴 MINUS ODER MÜLL
            GestureDetector(
              onTap: () async {
                if (amount <= 1) {
                final deleted = e.meal;

                await (appDb.delete(appDb.meal)
                      ..where((m) => m.id.equals(e.meal.id)))
                    .go();

                if (!mounted) return;

                setState(() {});

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${e.ingredient.name} gelöscht'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () async {
                        await appDb.into(appDb.meal).insert(deleted);
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                );
              } else {
                  await (appDb.update(appDb.meal)
                        ..where((m) => m.id.equals(e.meal.id)))
                      .write(
                    MealCompanion(
                      ingredientAmount: d.Value((amount - 1).toDouble()),
                    ),
                  );

                  if (!mounted) return;
                  setState(() {}); // 🔄 erzwingt Reload des FutureBuilders
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  amount <= 1
                      ? Icons.delete_outline
                      : Icons.remove_circle_outline,
                  color:
                      amount <= 1 ? Colors.redAccent : Colors.white,
                ),
              ),
            ),

            // 🔢 EDIT FELD
            Container(
              width: 75,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: GestureDetector(
                onTap: () async {
                  final controller = TextEditingController(
                    text: _formatAmount(amount),
                  );

                  final result = await showModalBottomSheet<double>(
                    context: context,
                    backgroundColor: Colors.black87,
                    isScrollControlled: true,
                    builder: (ctx) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(ctx).viewInsets.bottom,
                          left: 20,
                          right: 20,
                          top: 20,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: controller,
                              autofocus: true,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Neue Menge',
                                hintStyle: TextStyle(color: Colors.white54),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                final v = double.tryParse(
                                  controller.text.replaceAll(',', '.'),
                                );
                                Navigator.pop(ctx, v);
                              },
                              child: const Text('Übernehmen'),
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  if (result != null) {
                    await (appDb.update(appDb.meal)
                          ..where((m) => m.id.equals(e.meal.id)))
                        .write(
                      MealCompanion(
                        ingredientAmount: d.Value(result < 0 ? 0 : result),
                      ),
                    );

                    if (mounted) setState(() {});
                  }
                },
                child: Container(
                  width: 75,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '${_formatAmount(amount)} ${e.meal.ingredientUnitCode ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

            ),

            // ➕ PLUS
            GestureDetector(
              onTap: () async {
                await (appDb.update(appDb.meal)
                    ..where((m) => m.id.equals(e.meal.id)))
                  .write(
                MealCompanion(
                  ingredientAmount: d.Value((amount + 1).toDouble()),
                ),
              );

              if (!mounted) return;
              setState(() {}); // 🔄 erzwingt Reload des FutureBuilders
              },
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          // ➕ Meal / Zutat hinzufügen
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _onAddPressed,
          ),

          IconButton(
            icon: const Icon(Icons.next_plan, color: Colors.white),
            onPressed: _onPlanForward,
          ),

          // 📷 Kamera (vorbereitet)
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              // TODO: Kamera / Scan / Foto hinzufügen
            },
          ),

          // 🗑 Alle Meals dieses Slots löschen
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteWholeSlot,
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onHorizontalDragEnd: (details) {
          final v = details.primaryVelocity ?? 0;

          if (v < -120) {
            _goToNextCategory();      // ➡️ swipe left
          } else if (v > 120) {
            _goToPreviousCategory();  // ⬅️ swipe right
          }
        },
        child: Padding(

          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // =====================================================
              // 1️⃣ MEAL CATEGORY DROPDOWN (zentriert)
              // =====================================================
              FutureBuilder<List<MealCategoryData>>(
                future: appDb.select(appDb.mealCategory).get(),
                builder: (context, snap) {
                  final cats = snap.data ?? [];

                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<MealCategoryData>(
                          value: _selectedCategory,
                          dropdownColor: Colors.black,
                          iconEnabledColor: Colors.white70,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          items: cats.map((c) {
                            final isSelected = c.id == _selectedCategory.id;
                            return DropdownMenuItem(
                              value: c,
                              child: Text(
                                c.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (c) async {
                            if (c == null) return;

                            final oldCategory = _selectedCategory;
                            final newCategory = c;

                            if (oldCategory.id == newCategory.id) return;

                            // 🔄 ALLE Meals dieses Slots in neue Kategorie verschieben
                            await (appDb.update(appDb.meal)
                                  ..where((m) =>
                                      m.mealCategoryId.equals(oldCategory.id) &
                                      m.date.isBiggerOrEqualValue(_dayStart) &
                                      m.date.isSmallerThanValue(_dayEnd)))
                                .write(
                              MealCompanion(
                                mealCategoryId: d.Value(newCategory.id),
                              ),
                            );

                            if (!mounted) return;

                            // 🔁 Screen im neuen Slot neu aufbauen
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (_) => MealDetailScreen(
                                  day: widget.day,
                                  category: newCategory,
                                ),
                              ),
                            );
                          },

                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // =====================================================
              // 2️⃣ DATUM + UHRZEIT
              // =====================================================
              Row(
                children: [
                  // 📅 DATUM
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                      DateTime selectedDate = widget.day;

                      final pickedDate = await showDialog<DateTime>(
                        context: Navigator.of(context, rootNavigator: true).context,
                        builder: (ctx) {
                          return StatefulBuilder(
                            builder: (ctx, setStateDialog) {
                              return AlertDialog(
                                backgroundColor: Colors.black87,
                                title: const Text(
                                  "Datum wählen",
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: Colors.green,
                                        onPrimary: Colors.white,
                                        onSurface: Colors.white,
                                        surface: Colors.black,
                                      ),
                                    ),
                                    child: CalendarDatePicker(
                                      initialDate: selectedDate,
                                      firstDate:
                                          DateTime.now().subtract(const Duration(days: 365)),
                                      lastDate:
                                          DateTime.now().add(const Duration(days: 365)),
                                      onDateChanged: (d) {
                                        setStateDialog(() => selectedDate = d);
                                      },
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text("Abbrechen",
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, selectedDate),
                                    child: const Text("OK",
                                        style: TextStyle(color: Colors.green)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );

                      if (pickedDate == null) return;

                      // 🔄 Alle Meals auf neues Datum verschieben
                      await (appDb.update(appDb.meal)
                            ..where((m) =>
                                m.mealCategoryId.equals(_selectedCategory.id) &
                                m.date.isBiggerOrEqualValue(_dayStart) &
                                m.date.isSmallerThanValue(_dayEnd)))
                          .write(
                        MealCompanion(
                          date: d.Value(pickedDate),
                        ),
                      );

                      if (!mounted) return;

                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => MealDetailScreen(
                            day: pickedDate,
                            category: _selectedCategory,
                          ),
                        ),
                      );
                    },

                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatDate(widget.day),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ⏰ ZEIT
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final initialTime = _timeConsumed != null
                            ? TimeOfDay.fromDateTime(_timeConsumed!)
                            : const TimeOfDay(hour: 12, minute: 0);

                        final picked = await showTimePicker(
                          context: context,
                          initialTime: initialTime,
                          builder: (ctx, child) {
                            return Theme(
                              data: Theme.of(ctx).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Colors.green,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.white,
                                ),
                                dialogBackgroundColor: Colors.black,
                              ),
                              child: child!,
                            );
                          },
                        );

                        if (picked == null) return;

                        final newTime = DateTime(
                          widget.day.year,
                          widget.day.month,
                          widget.day.day,
                          picked.hour,
                          picked.minute,
                        );

                        // 🔄 alle Meals dieses Slots aktualisieren
                        await (appDb.update(appDb.meal)
                              ..where((m) =>
                                  m.mealCategoryId.equals(_selectedCategory.id) &
                                  m.date.isBiggerOrEqualValue(_dayStart) &
                                  m.date.isSmallerThanValue(_dayEnd)))
                            .write(
                          MealCompanion(
                            timeConsumed: d.Value(newTime),
                            prepared: const d.Value(true),
                          ),
                        );

                        if (!mounted) return;

                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => MealDetailScreen(
                              day: DateTime(
                                widget.day.year,
                                widget.day.month,
                                widget.day.day,
                                newTime.hour,
                                newTime.minute,
                              ),
                              category: _selectedCategory,
                            ),
                          ),
                        );
                      },


                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _timeConsumed == null
                              ? 'wann gegessen?'
                              : _formatTime(_timeConsumed!),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _timeConsumed == null
                                ? Colors.white38
                                : Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // =====================================================
              // 3️⃣ KALORIEN BOX
              // =====================================================
              GestureDetector(
                onTap: () {
                  // TODO: Kalorien bearbeiten
                },
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Kalorien',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // =====================================================
              // 4️⃣ SCROLLBARE LISTE (PLATZHALTER)
              // =====================================================
              Expanded(
                child: FutureBuilder<List<MealIngredientEntry>>(
                  key: ValueKey(_selectedCategory.id),
                  future: _loadMealIngredients(),
                  builder: (context, snap) {
                    final entries = snap.data ?? [];

                    if (entries.isEmpty) {
                      return const Center(
                        child: Text(
                          'Keine Zutaten',
                          style: TextStyle(color: Colors.white38),
                        ),
                      );
                    }

                    // Gruppierung
                    final standalone =
                        entries.where((e) => e.recipe == null).toList();

                    final byRecipe = <int, List<MealIngredientEntry>>{};
                    for (final e in entries.where((e) => e.recipe != null)) {
                      byRecipe.putIfAbsent(e.recipe!.id, () => []).add(e);
                    }

                    return ListView(
                      padding: const EdgeInsets.only(top: 12),
                      children: [
                        // ----------------------------
                        // OHNE REZEPT
                        // ----------------------------
                        ...standalone.map(_buildIngredientRow),

                        // ----------------------------
                        // MIT REZEPT
                        // ----------------------------
                        for (final group in byRecipe.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
                            child: Text(
                              group.value.first.recipe!.name,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...group.value.map(_buildIngredientRow),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),  
    );
  }
}

class _SelectTargetShoppingListDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ShoppingListData>>(
      future: (appDb.select(appDb.shoppingList)
            ..where((t) => t.done.equals(false)))
          .get(),
      builder: (ctx, snap) {
        final lists = snap.data ?? [];

        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text("Einkaufsliste wählen",
              style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final sl in lists)
                  GestureDetector(
                    onTap: () => Navigator.pop(context, sl.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              sl.name,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                          ),
                          if (sl.marketId != null) _buildMarketIconSmall(sl.marketId!)
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Kleine Hilfsfunktion aus deinem Shopping-Code
Widget _buildMarketIconSmall(int marketId) {
  return FutureBuilder<Market?>(
    future: (appDb.select(appDb.markets)
          ..where((m) => m.id.equals(marketId)))
        .getSingleOrNull(),
    builder: (ctx, snap) {
      final m = snap.data;
      if (m == null) return const SizedBox(width: 32);
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _parseHexColor(m.color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(m.picture ?? "assets/images/shop/placeholder.png",
              fit: BoxFit.cover),
        ),
      );
    },
  );
}



