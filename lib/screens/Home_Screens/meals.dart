import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/utils/easy_swipe_nav.dart';
import 'package:planty_flutter_starter/design/drawer.dart';

import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';

// Zielseiten
import 'package:planty_flutter_starter/screens/Home_Screens/recipes.dart'
    as screen_rec;
import 'package:planty_flutter_starter/screens/Home_Screens/ingredients.dart'
    as screen_ing;
import 'package:planty_flutter_starter/screens/Home_Screens/shopping.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/nutrition.dart';

import 'package:planty_flutter_starter/screens/meals/calendar.dart';
import 'package:planty_flutter_starter/screens/meals/meal_detail.dart';
import 'package:planty_flutter_starter/screens/meals/meal_stock.dart';

import 'package:planty_flutter_starter/services/meal_item_picker.dart';
import 'package:planty_flutter_starter/widgets/ingredient_plan_assign_dialog.dart';
import 'package:planty_flutter_starter/widgets/meal_plan_assign_dialog.dart';


Color _parseHexColor(String? hex) {
  if (hex == null) return Colors.grey;
  String c = hex.replaceAll('#', '');
  if (c.length == 6) c = 'FF$c';
  return Color(int.parse(c, radix: 16));
}


// ===================================================================
// AGGREGATED MODEL (GENAU DAS – NICHTS MEHR)
// ===================================================================
class AggregatedMealEntry {
  final MealData meal;
  final Recipe? recipe;
  final Ingredient? ingredient;

  const AggregatedMealEntry({
    required this.meal,
    this.recipe,
    this.ingredient,
  });
}

// ===================================================================
// SCREEN
// ===================================================================
class Meals extends StatefulWidget {
  const Meals({super.key});

  @override
  State<Meals> createState() => _MealsState();
}

class _MealsState extends State<Meals> with EasySwipeNav<Meals> {
  int _selectedIndex = 3;
  static const Duration _slideDuration = Duration(milliseconds: 280);
  Map<int, MealCategoryData> _mealCategories = {};
  
  @override
  int get currentIndex => _selectedIndex;


  @override
  void initState() {
    super.initState();
    _loadMealCategories();
  }


  // -------------------------------------------------
  // Bottom Navigation Targets
  // -------------------------------------------------
  Widget _widgetForIndex(int index) {
    switch (index) {
      case 0:
        return const screen_ing.Ingredients();
      case 1:
        return const Shopping();
      case 2:
        return const screen_rec.Recipes();
      case 3:
        return const Meals();
      case 4:
      default:
        return const Nutrition();
    }
  }

  void _slideToIndex(int index, {required bool fromRight}) {
  if (!mounted || index < 0 || index > 4) return;

  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => _widgetForIndex(index),
      transitionDuration: _slideDuration,
      reverseTransitionDuration: _slideDuration,
      transitionsBuilder: (_, animation, __, child) {
        final begin = fromRight ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
        final tween = Tween<Offset>(begin: begin, end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    ),
  );

  setState(() => _selectedIndex = index);
}


  void _navigateToPage(int index) {
    if (!mounted || index == _selectedIndex) return;
    final fromRight = index > _selectedIndex;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _widgetForIndex(index),
        transitionDuration: _slideDuration,
        reverseTransitionDuration: _slideDuration,
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween<Offset>(
            begin: Offset(fromRight ? 1 : -1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOut));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );

    setState(() => _selectedIndex = index);
  }

  @override
    void goToIndex(int index) {
      _slideToIndex(index, fromRight: index > _selectedIndex);
    }


  // ===================================================================
  // DB: Anzahl Meal-Kategorien
  // ===================================================================
  Future<int> _loadMealCategoryCount() async {
    final rows = await (appDb.select(appDb.mealCategory)
          ..orderBy([(t) => d.OrderingTerm.asc(t.id)]))
        .get();
    return rows.length;
  }

  // ===================================================================
  // DB: Meals eines Tages → nach Kategorie gruppiert
  // ===================================================================
  Future<Map<int, List<AggregatedMealEntry>>> _loadDayMealsByCategory(
      DateTime day) async {
    final mealTbl = appDb.meal;
    final recipeTbl = appDb.recipes;
    final ingredientTbl = appDb.ingredients;

    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final rows = await (appDb.select(mealTbl)
          ..where((m) =>
              m.date.isBiggerOrEqualValue(start) &
              m.date.isSmallerThanValue(end)))
        .join([
      d.leftOuterJoin(recipeTbl, recipeTbl.id.equalsExp(mealTbl.recipeId)),
      d.leftOuterJoin(
        ingredientTbl,
        ingredientTbl.id.equalsExp(mealTbl.ingredientId),
      ),
    ]).get();

    final Map<int, List<AggregatedMealEntry>> out = {};

    for (final row in rows) {
      final meal = row.readTable(mealTbl);
      final catId = meal.mealCategoryId;

      if (catId == null) continue;

      out.putIfAbsent(catId, () => []);

      out[catId]!.add(
        AggregatedMealEntry(
          meal: meal,
          recipe: row.readTableOrNull(recipeTbl),
          ingredient: row.readTableOrNull(ingredientTbl),
        ),
      );
    }

    return out;
  }

  Future<void> _loadMealCategories() async {
    final rows = await appDb.select(appDb.mealCategory).get(); // rows = List<MealCategoryData>
    setState(() {
      _mealCategories = { for (final c in rows) c.id: c };
    });
  }


  // ===================================================================
  // BUILD
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: onSwipeStart,
      onHorizontalDragUpdate: onSwipeUpdate,
      onHorizontalDragEnd: onSwipeEnd,
      child: Scaffold(
        backgroundColor: darkgreen,
        appBar: AppBar(
          title: const Text(
            "Planty Planning",
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: darkgreen,
        ),
        drawer: const AppDrawer(currentIndex: 3),

        // -------------------------------------------------
        // Bottom Navigation
        // -------------------------------------------------
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
          child: GNav(
            backgroundColor: darkgreen,
            tabBackgroundColor: darkdarkgreen,
            padding: const EdgeInsets.all(16),
            gap: 8,
            selectedIndex: _selectedIndex,
            onTabChange: _navigateToPage,
            tabs: const [
              GButton(icon: Icons.eco, text: 'Zutaten'),
              GButton(icon: Icons.storefront, text: 'Einkauf'),
              GButton(icon: Icons.list_alt, text: 'Rezepte'),
              GButton(icon: Icons.calendar_month, text: 'Mahlzeiten'),
              GButton(icon: Icons.stacked_bar_chart, text: 'Nährwerte'),
            ],
          ),
        ),

        // -------------------------------------------------
        // BODY
        // -------------------------------------------------
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraint) {
              const gap = 12.0;
              final availableHeight =
                  constraint.maxHeight - gap * 2;

              final h1 = availableHeight * 0.2;
              final h2 = availableHeight * 0.6;
              final h3 = availableHeight * 0.2;

              return Column(
                children: [
                  // -----------------------------
                  // Vorbereitung
                  // -----------------------------
                  _buildTile(
                    height: h1,
                    title: "Vorbereitung",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MealStockScreen(),
                        ),
                      );
                    },

                    child: const Center(
                      child: Icon(
                        Icons.kitchen,
                        size: 48,
                        color: Colors.white70,
                      ),
                    ),
                  ),

                  const SizedBox(height: gap),

                  // -----------------------------
                  // Heutige Mahlzeiten
                  // -----------------------------
                  _buildTile(
                    height: h2,
                    title: "Heutige Mahlzeiten",
                    onTap: null,
                    child: _mealCategories.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _DailyMealsView(
                          day: DateTime.now(),
                          mealCategories: _mealCategories,
                          loadDayMealsByCategory: _loadDayMealsByCategory,
                        ),

                  ),

                  const SizedBox(height: gap),

                  // -----------------------------
                  // Kalender / Planen
                  // -----------------------------
                  SizedBox(
                    height: h3,
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTile(
                            height: double.infinity,
                            title: "Kalender",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const MealsCalendarScreen(),
                                ),
                              );
                            },
                            child: const Center(
                              child: Icon(
                                Icons.calendar_month,
                                size: 42,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        Expanded(
                          child: _buildTile(
                            height: double.infinity,
                            title: "Planen",
                            onTap: () {},
                            child: const Center(
                              child: Icon(
                                Icons.next_plan,
                                size: 42,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ===================================================================
  // TILE HELPER
  // ===================================================================
  Widget _buildTile({
    required double height,
    required String title,
    VoidCallback? onTap,
    required Widget child,
  }) {
    final tile = Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: darkdarkgreen,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: tile,
    );
  }
}

// ===================================================================
// DAILY MEALS VIEW (LOKAL, UNABHÄNGIG)
// ===================================================================
class _DailyMealsView extends StatelessWidget {
  final DateTime day;
  final Map<int, MealCategoryData> mealCategories;
  final Future<Map<int, List<AggregatedMealEntry>>> Function(DateTime day)
      loadDayMealsByCategory;

  const _DailyMealsView({
  required this.day,
  required this.mealCategories,
  required this.loadDayMealsByCategory,
});


  @override
    Widget build(BuildContext context) {
      return _buildCategoryBoxes();
    }


  Widget _buildCategoryBoxes() {
    return FutureBuilder<Map<int, List<AggregatedMealEntry>>>(
      future: loadDayMealsByCategory(day),
      builder: (context, snap) {
        final data = snap.data ?? {};

        final visibleCategories = mealCategories.values.where((cat) {
          final items = data[cat.id] ?? [];
          return items.isNotEmpty || cat.favorite;
        }).toList()
          ..sort((a, b) => a.id.compareTo(b.id));


        if (visibleCategories.isEmpty) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final effectiveCount =
                visibleCategories.length < 5 ? 5 : visibleCategories.length;

            final rowHeight =
                constraints.maxHeight / effectiveCount;


            return Column(
              children: visibleCategories.map((cat) {
                final items = data[cat.id] ?? [];

                return SizedBox(
                  height: rowHeight,
                  child: _DailyCategoryRow(
                    items: items,
                    day: day,
                    mealCategoryId: cat.id,
                    category: cat,
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }


  String _formatDay(DateTime d) {
    const names = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ];
    return '${names[d.weekday - 1]}, ${d.day}.${d.month}.${d.year}';
  }
}

class _DailyCategoryRow extends StatelessWidget {
  final List<AggregatedMealEntry> items;
  final DateTime day;
  final int mealCategoryId;
  final MealCategoryData category;

  const _DailyCategoryRow({
    required this.items,
    required this.day,
    required this.mealCategoryId,
    required this.category,
  });


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 8), // oben Platz für Label
          decoration: BoxDecoration(
            color: Colors.transparent, //Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white24,
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // ================================
              // LINKER BEREICH → NAVIGATION
              // ================================
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 260),
                        reverseTransitionDuration: const Duration(milliseconds: 220),
                        opaque: false,
                        barrierColor: Colors.transparent,
                        pageBuilder: (_, __, ___) => MealDetailScreen(
                          day: day,
                          category: category,
                        ),
                        transitionsBuilder: (_, animation, __, child) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            ),
                          );

                          final fade = Tween<double>(
                            begin: 0.8,
                            end: 1.0,
                          ).animate(animation);

                          return FadeTransition(
                            opacity: fade,
                            child: SlideTransition(
                              position: slide,
                              child: child,
                            ),
                          );
                        },
                      ),
                    );
                  },

                  child: Row(
                    children: [
                      // 1️⃣ kcal-Kreis
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.transparent,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'kcal',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // 2️⃣ Bilder + PLUS direkt daneben
                      Expanded(
                        child: _DailyImages(
                          items: items,
                          onAddTap: () async {
                            final result = await MealItemPicker.pick(
                              context: context,
                              day: day,
                              mealCategoryId: mealCategoryId,
                            );

                            if (result == null) return;

                            final pickedDays = <DateTime>[day];

                            // 👉 HIER: meal INSERT 

                            await result.when(

                            // ======================================================
                            // 🟩 REZEPT
                            // ======================================================
                            recipe: (recipeId) async {
                              final assign = await showDialog<MealPlanAssignmentResult>(
                                context: context,
                                builder: (_) => MealPlanAssignDialog(
                                  selectedDays: pickedDays,
                                  recipeId: recipeId,
                                  recipePortionNumber: 1,
                                ),
                              );

                              if (assign == null) return;

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

                              for (final entry in assign.entries) {
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

                              // ---------- ShoppingList ----------
                              if (!context.mounted) return;

                              final add = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.black87,
                                  title: const Text(
                                    "Zur Einkaufsliste hinzufügen?",
                                    style: TextStyle(color: Colors.white),
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

                              if (add != true) return;


                              final listId = await showDialog<int>(
                                context: context,
                                builder: (_) => _SelectTargetShoppingListDialog(),
                              );
                              if (listId == null) return;

                              for (final ing in ingRows) {
                                await appDb.into(appDb.shoppingListIngredient).insert(
                                  ShoppingListIngredientCompanion.insert(
                                    shoppingListId: listId,
                                    ingredientIdNominal: d.Value(ing.ingredientId),
                                    ingredientAmountNominal: d.Value(ing.amount),
                                    ingredientUnitCodeNominal: d.Value(ing.unitCode),
                                  ),
                                );
                              }
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
                                  defaultMealCategoryId: mealCategoryId,
                                ),
                              );

                              if (entries == null) return;

                              for (final e in entries) {
                                await appDb.into(appDb.meal).insert(
                                  MealCompanion.insert(
                                    date: d.Value(e.date),
                                    mealCategoryId: d.Value(e.categoryId),

                                    ingredientId: d.Value(ingredientId),
                                    ingredientUnitCode: d.Value(e.unitCode),
                                    ingredientAmount: d.Value(e.amount),

                                    recipeId: const d.Value(null),
                                    preparationListId: const d.Value(null),
                                    recipePortionNumber: const d.Value(null),
                                    recipePortionUnit: const d.Value(null),

                                    prepared: const d.Value(false),
                                    timeConsumed: const d.Value(null),
                                  ),
                                );
                              }

                              if (!context.mounted) return;

                              final add = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: Colors.black87,
                                  title: const Text(
                                    "Zur Einkaufsliste hinzufügen?",
                                    style: TextStyle(color: Colors.white),
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

                              if (add != true) return;

                              final listId = await showDialog<int>(
                                context: context,
                                builder: (_) => _SelectTargetShoppingListDialog(),
                              );
                              if (listId == null) return;

                              final totalAmount =
                                  entries.fold<double>(0, (s, e) => s + e.amount);

                              final unitCode = entries.map((e) => e.unitCode).toSet().length == 1
                                  ? entries.first.unitCode
                                  : entries.first.unitCode;

                              await appDb.into(appDb.shoppingListIngredient).insert(
                                ShoppingListIngredientCompanion.insert(
                                  shoppingListId: listId,
                                  ingredientIdNominal: d.Value(ingredientId),
                                  ingredientAmountNominal: d.Value(totalAmount),
                                  ingredientUnitCodeNominal: d.Value(unitCode),
                                ),
                              );
                            },
                          );

                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ================================
              // ✔ TOGGLE → AUSGENOMMEN
              // ================================
              if (items.isNotEmpty)
                CategoryDayToggle(
                  day: day,
                  mealCategoryId: mealCategoryId,
                ),
            ],
          ),


           ),

        // 🔹 Category-Name (mini, oben links)
        Positioned(
          left: 18,
          top: 2, // <- etwas tiefer, nicht negativ
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            color: Colors.black12,    //darkgreen, // Hintergrund = außen, damit "Linie unterbrochen" wirkt
            child: Text(
              category.name,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white70,
                letterSpacing: 0.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

      ],
    );
        
  }
}


class _DailyImages extends StatelessWidget {
  final List<AggregatedMealEntry> items;
  final VoidCallback? onAddTap;

  const _DailyImages({
    required this.items,
    this.onAddTap,
  });


  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final unique = <String, AggregatedMealEntry>{};

    for (final e in items) {
      final key = e.recipe != null
          ? 'r_${e.recipe!.id}'
          : 'i_${e.ingredient!.id}';

      unique.putIfAbsent(key, () => e);
    }

    final displayItems = unique.values.toList();
    final maxIcons =
        ((constraints.maxWidth) / constraints.maxHeight)
            .floor()
            .clamp(0, 3);

    final size = constraints.maxHeight;       

    final children = <Widget>[
      ...displayItems.take(maxIcons).map((e) {
        final img = _resolveImage(e);
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.2),
            child: SizedBox(
              width: size,
              height: size,
              child: Image.asset(img, fit: BoxFit.cover),
            ),
          ),
        );
      }),
    ];

    children.add(
      GestureDetector(
        onTap: onAddTap,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white24,
          ),
          child: const Icon(
            Icons.add,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );

    return Row(children: children);

      },
    );
  }

  String _resolveImage(AggregatedMealEntry e) {
    final r = e.recipe?.picture;
    if (r != null && r.isNotEmpty) return r;

    final i = e.ingredient?.picture;
    if (i != null && i.isNotEmpty) return i;

    return 'assets/images/placeholder.jpg';
  }
}

// ===================================================================
// 🅰️ TOGGLE A — CategoryDayToggle
// ===================================================================
class CategoryDayToggle extends StatefulWidget {
  final DateTime day;
  final int mealCategoryId;

  const CategoryDayToggle({
    required this.day,
    required this.mealCategoryId,
    Key? key,
  }) : super(key: key);

  @override
  State<CategoryDayToggle> createState() => _CategoryDayToggleState();
}

class _CategoryDayToggleState extends State<CategoryDayToggle> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final start =
        DateTime(widget.day.year, widget.day.month, widget.day.day);
    final end = start.add(const Duration(days: 1));

    final rows = await (appDb.select(appDb.meal)
          ..where((m) =>
              m.mealCategoryId.equals(widget.mealCategoryId) &
              m.date.isBiggerOrEqualValue(start) &
              m.date.isSmallerThanValue(end)))
        .get();

    if (!mounted) return;
    setState(() {
      _checked =
          rows.isNotEmpty && rows.every((m) => m.timeConsumed != null);
    });
  }

  Future<void> _toggle() async {
    final newValue = !_checked;

    final start =
        DateTime(widget.day.year, widget.day.month, widget.day.day);
    final end = start.add(const Duration(days: 1));

    final q = appDb.update(appDb.meal)
      ..where((m) =>
          m.mealCategoryId.equals(widget.mealCategoryId) &
          m.date.isBiggerOrEqualValue(start) &
          m.date.isSmallerThanValue(end));

    if (newValue) {
      await q.write(
        MealCompanion(
          timeConsumed: d.Value(DateTime.now()),
          prepared: const d.Value(true), // ok: nur beim Setzen
        ),
      );

    } else {
      await q.write(
        const MealCompanion(
          timeConsumed: d.Value(null),
        ),
      );
    }

    if (!mounted) return;
    setState(() => _checked = newValue);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Icon(
            _checked
                ? Icons.check_circle_outline
                : Icons.circle_outlined,
            key: ValueKey(
                'cat_${widget.mealCategoryId}_${widget.day}_$_checked'),
            color: Colors.white54,
            size: 30,  // Höhe des Buttons evtl. anpassen
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


