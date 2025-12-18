// lib/screens/meals/calendar.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planty_flutter_starter/widgets/planning_calendar.dart';
import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/screens/recipe/recipe_detail.dart';

import 'package:planty_flutter_starter/services/meal_item_picker.dart';
import 'package:planty_flutter_starter/widgets/meal_plan_assign_dialog.dart';
import 'package:planty_flutter_starter/widgets/ingredient_plan_assign_dialog.dart';

// ----------------------------------------------------
//  TOP-LEVEL Modelklassen (DÜRFEN NICHT in State liegen)
// ----------------------------------------------------
class MealWithRecipe {
  final MealData meal;
  final Recipe recipe;
  final String categoryName;

  MealWithRecipe({
    required this.meal,
    required this.recipe,
    required this.categoryName,
  });
}

class AggregatedMealEntry {
  final MealData meal;
  final Recipe recipe;
  final String categoryName;
  final String categoryColor;
    // Name der Meal Category

  AggregatedMealEntry({
    required this.meal,
    required this.recipe,
    required this.categoryName,
    required this.categoryColor,
  });
}

class AggregatedIngredientEntry {
  final MealData meal;
  final Ingredient ingredient;
  final String categoryName;
  final String categoryColor;

  AggregatedIngredientEntry({
    required this.meal,
    required this.ingredient,
    required this.categoryName,
    required this.categoryColor,
  });
}

class _CalendarBarRange {
  final DateTime start;
  final DateTime end;
  final bool isRecipe;
  final String imagePath;

  final int mealCategoryId;
  final String categoryColor;

  _CalendarBarRange({
    required this.start,
    required this.end,
    required this.isRecipe,
    required this.imagePath,
    required this.mealCategoryId,
    required this.categoryColor,
  });
}


// ----------------------------------------------------
enum CalendarView { month, week, list }
// ----------------------------------------------------



class MealsCalendarScreen extends StatefulWidget {
  const MealsCalendarScreen({super.key});

  @override
  State<MealsCalendarScreen> createState() => _MealsCalendarScreenState();
}



class _MealsCalendarScreenState extends State<MealsCalendarScreen> {
  CalendarView _view = CalendarView.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  DateTime _startOfWeek(DateTime d) =>
    d.subtract(Duration(days: d.weekday - 1));

  DateTime _endOfWeek(DateTime d) =>
      _startOfWeek(d).add(const Duration(days: 6));

  DateTime _startOfMonth(DateTime d) =>
      DateTime(d.year, d.month, 1);

  DateTime _endOfMonth(DateTime d) =>
      DateTime(d.year, d.month + 1, 0);

  int _categoryCount = 0;   

  Map<int, MealCategoryData> _mealCategories = {};




  @override
  void initState() {
    super.initState();
    _loadViewMode();
    _loadCategoryCount();
    _loadMealCategories();
  }

  Future<void> _loadCategoryCount() async {
    final cats = await appDb.select(appDb.mealCategory).get();
    setState(() {
      _categoryCount = cats.length;
    });
  }

Future<void> _loadMealCategories() async {
  final rows = await appDb.select(appDb.mealCategory).get();
  setState(() {
    _mealCategories = {
      for (final c in rows) c.id: c,
    };
  });
}



  // ============================================================
  // Lade alle Meals für einen Tag → gruppiert nach Kategorie
  // UND pro Rezept aggregiert (also nur 1 Anzeige)
  // ============================================================
  Future<Map<int, List<dynamic>>> _loadMealsForDate(DateTime day) async {
  final start = DateTime(day.year, day.month, day.day);
  final end = start.add(const Duration(days: 1));

  final m = appDb.meal;
  final r = appDb.recipes;
  final ing = appDb.ingredients;
  final c = appDb.mealCategory;

  final rows = await (appDb.select(m)
        ..where((t) => t.date.isBiggerOrEqualValue(start))
        ..where((t) => t.date.isSmallerThanValue(end)))
      .join([
        d.leftOuterJoin(r, r.id.equalsExp(m.recipeId)),
        d.leftOuterJoin(ing, ing.id.equalsExp(m.ingredientId)),
        d.leftOuterJoin(c, c.id.equalsExp(m.mealCategoryId)),
      ])
      .get();

  // ----------------------------------------------
  // 1) Rezepte → zuerst Gruppieren nach recipeId!
  // ----------------------------------------------
  final recipeGroups = <int, List<dynamic>>{};
  final ingredientEntries = <dynamic>[];

  for (final row in rows) {
    final meal = row.readTable(m);
    final recipe = row.readTableOrNull(r);
    final ingredient = row.readTableOrNull(ing);
    final catRow = row.readTableOrNull(c);
    final categoryName = catRow?.name ?? "-";
    final categoryColor = catRow?.color ?? '#ffffff';
    final categoryId = meal.mealCategoryId ?? 0;

    if (recipe != null) {
      // Rezept gruppieren nach recipeId
      recipeGroups.putIfAbsent(recipe.id, () => []).add(
        AggregatedMealEntry(
          meal: meal,
          recipe: recipe,
          categoryName: categoryName,
          categoryColor: categoryColor,
        ),
      );
    } else if (ingredient != null) {
      // Zutaten nie gruppieren
      ingredientEntries.add(
        AggregatedIngredientEntry(
          meal: meal,
          ingredient: ingredient,
          categoryName: categoryName,
          categoryColor: categoryColor,
        ),
      );
    }
  }

  // ----------------------------------------------
  // 2) Für jedes Rezept nur EIN AggregatedMealEntry
  // ----------------------------------------------
  final finalMap = <int, List<dynamic>>{};

  // Zuerst Rezepte einsortieren
  recipeGroups.forEach((recipeId, list) {
    final first = list.first as AggregatedMealEntry;
    final cat = first.meal.mealCategoryId ?? 0;

    finalMap.putIfAbsent(cat, () => []);
    finalMap[cat]!.add(first);
  });

  // Jetzt Ingredients einsortieren
  for (final entry in ingredientEntries) {
    final ingEntry = entry as AggregatedIngredientEntry;
    final cat = ingEntry.meal.mealCategoryId ?? 0;

    finalMap.putIfAbsent(cat, () => []);
    finalMap[cat]!.add(ingEntry);
  }

  // ---------------------------------------------------------
// 3) Sortierung: ZUERST Rezepte (AggregatedMealEntry),
// dann Ingredients (AggregatedIngredientEntry)
// ---------------------------------------------------------
finalMap.forEach((cat, list) {
  list.sort((a, b) {
    final aIsRecipe = a is AggregatedMealEntry;
    final bIsRecipe = b is AggregatedMealEntry;

    if (aIsRecipe && !bIsRecipe) return -1; // Rezepte zuerst
    if (!aIsRecipe && bIsRecipe) return 1;  // Zutaten danach

    return 0; // untereinander Reihenfolge beibehalten
  });
});


  return finalMap;
}

// ============================================================
// Farbe aus Hex-String parsen  
// ============================================================

Color _parseCategoryColor(String hex) {
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xff')));
  } catch (_) {
    return Colors.white24;
  }
}






Future<List<_CalendarBarRange>> _buildRangesForPeriod(
  DateTime start,
  DateTime end,
) async {
  final Map<String, List<DateTime>> occurrences = {};
  final Map<String, dynamic> meta = {};

  for (DateTime d = start;
      !d.isAfter(end);
      d = d.add(const Duration(days: 1))) {

    final map = await _loadMealsForDate(d);

    final sorted = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (final entry in sorted) {
      for (final item in entry.value) {
        final isRecipe = item is AggregatedMealEntry;

        // ❗ Ingredients NICHT als Range behandeln
        if (!isRecipe) {
          continue;
        }

        final key = 'r_${item.recipe.id}';


        occurrences.putIfAbsent(key, () => []).add(d);
        meta[key] = item;
      }
    }
  }

  final ranges = <_CalendarBarRange>[];

  occurrences.forEach((_, days) {
    days.sort();

    DateTime segStart = days.first;
    DateTime segEnd = days.first;

    for (int i = 1; i <= days.length; i++) {
      if (i < days.length &&
          days[i].difference(days[i - 1]).inDays == 1) {
        segEnd = days[i];
      } else {
        final item = meta[_];
        final isRecipe = item is AggregatedMealEntry;

        final img = isRecipe
            ? (item.recipe.picture?.isNotEmpty == true
                ? item.recipe.picture!
                : 'assets/images/placeholder.jpg')
            : (item.ingredient.picture?.isNotEmpty == true
                ? item.ingredient.picture!
                : 'assets/images/placeholder.jpg');

        ranges.add(
          _CalendarBarRange(
            start: segStart,
            end: segEnd,
            isRecipe: isRecipe,
            imagePath: img,
            mealCategoryId: item.meal.mealCategoryId ?? 0,
            categoryColor: item.categoryColor,
          ),
        );

        if (i < days.length) {
          segStart = days[i];
          segEnd = days[i];
        }
      }
    }
  });

  return ranges;
}


Future<List<CategoryWeekBar>> buildCategoryWeekBars(
  DateTime weekStart,
) async {
  final weekEnd = weekStart.add(const Duration(days: 6));

  final categories =
    (await appDb.select(appDb.mealCategory).get())
      ..sort((a, b) => a.id.compareTo(b.id));

  final Map<int, int> categoryRowIndex = {
    for (int i = 0; i < categories.length; i++)
      categories[i].id: i,
  };

  // 🔹 Rezept-Zeiträume (NUR Rezepte!)
  final ranges = await _buildRangesForPeriod(weekStart, weekEnd);

  // 🔹 Meals pro Tag (für Ingredient-Icons)
  final Map<DateTime, Map<int, List<dynamic>>> mealsPerDay = {};
  for (int i = 0; i < 7; i++) {
    final d = weekStart.add(Duration(days: i));
    mealsPerDay[d] = await _loadMealsForDate(d);
  }

  final result = <CategoryWeekBar>[];

  // ============================================================
  // PRO KATEGORIE
  // ============================================================
  for (final cat in categories) {
    // 🔹 ALLE Rezept-Ranges dieser Kategorie
    final recipeRanges = ranges
        .where((r) => r.isRecipe && r.categoryColor == cat.color)
        .toList();

    // ========================================================
    // FALL 1: KEIN REZEPT → NUR INGREDIENT-ICONS, KEIN BALKEN
    // ========================================================
    if (recipeRanges.isEmpty) {
      final visualsPerDay = <int, List<BarVisual>>{};

      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));
        final dayMeals = mealsPerDay[day]?[cat.id] ?? [];

        final visuals = <BarVisual>[];

        for (final item in dayMeals) {
          if (item is AggregatedIngredientEntry) {
            visuals.add(
              BarVisual.image(
                item.ingredient.picture?.isNotEmpty == true
                    ? item.ingredient.picture!
                    : 'assets/images/placeholder.jpg',
                isRecipe: false,
              ),
            );
          }
        }

        if (visuals.length > 2) {
          final hidden = visuals.length - 1;
          visuals
            ..removeRange(1, visuals.length)
            ..add(BarVisual.overflow(hidden));
        }

        if (visuals.isNotEmpty) {
          visualsPerDay[i] = visuals;
        }
      }

      if (visualsPerDay.isNotEmpty) {
        result.add(
          CategoryWeekBar(
            mealCategoryId: cat.id,
            categoryRow: categoryRowIndex[cat.id]!,
            color: Colors.transparent,
            segments: const [], // ✅ keine Balken
            visualsPerDay: visualsPerDay,
          ),
        );
      }

      continue;
    }

    // ============================================================
    // FALL 2: EINE KATEGORIE = EIN BAR, MIT MEHREREN SEGMENTEN
    // ============================================================
    final visualsPerDay = <int, List<BarVisual>>{};

    // Alle Rezept-Segmente dieser Kategorie
    for (final r in recipeRanges) {
      for (int i = 0; i < 7; i++) {
        final day = weekStart.add(Duration(days: i));

        // Rezeptbild nur am Starttag des Segments
        if (DateUtils.isSameDay(day, r.start)) {
          visualsPerDay.putIfAbsent(i, () => []);
          visualsPerDay[i]!.add(
            BarVisual.image(
              r.imagePath,
              isRecipe: true,
            ),
          );
        }
      }
    }

    // Ingredients ergänzen (täglich)
    for (int i = 0; i < 7; i++) {
      final day = weekStart.add(Duration(days: i));
      final dayMeals = mealsPerDay[day]?[cat.id] ?? [];

      for (final item in dayMeals) {
        if (item is AggregatedIngredientEntry) {
          visualsPerDay.putIfAbsent(i, () => []);
          visualsPerDay[i]!.add(
            BarVisual.image(
              item.ingredient.picture?.isNotEmpty == true
                  ? item.ingredient.picture!
                  : 'assets/images/placeholder.jpg',
              isRecipe: false,
            ),
          );
        }
      }

      // Overflow > 2
      if (visualsPerDay[i] != null && visualsPerDay[i]!.length > 2) {
        final hidden = visualsPerDay[i]!.length - 1;
        visualsPerDay[i]!
          ..removeRange(1, visualsPerDay[i]!.length)
          ..add(BarVisual.overflow(hidden));
      }
    }

    // 👉 EIN EINZIGER CategoryWeekBar
    // ✅ Segmente: jedes recipeRange ist ein eigenes Segment
    final segments = recipeRanges
        .map((r) => BarSegment(
              startCol: r.start.weekday - 1,
              endCol: r.end.weekday - 1,
            ))
        .toList()
      ..sort((a, b) => a.startCol.compareTo(b.startCol));

    result.add(
      CategoryWeekBar(
        mealCategoryId: cat.id,
        categoryRow: categoryRowIndex[cat.id]!,
        color: _parseCategoryColor(cat.color),
        segments: segments,            // ✅ HIER ist der Fix
        visualsPerDay: visualsPerDay,
      ),
    );


  }
  return result;
}

Future<void> _onAddForDay(BuildContext context, DateTime day) async {
  // KEINE mealCategoryId übergeben!
  final picked = await MealItemPicker.pick(
    context: context,
    day: day,
    mealCategoryId: null, // 🔴 WICHTIG
  );

  if (picked == null) return;

  final pickedDays = <DateTime>[day];

  await picked.when(
    // ======================================================
    // 🟩 REZEPT
    // ======================================================
    recipe: (recipeId) async {
      final result = await showDialog<MealPlanAssignmentResult>(
        context: context,
        builder: (_) => MealPlanAssignDialog(
          selectedDays: pickedDays,
          recipeId: recipeId,
          recipePortionNumber: 1,
        ),
      );

      if (result == null) return;

      // ⬇️ IDENTISCH zu PlanningCalendar / Meals.dart
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

      for (final entry in result.entries) {
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

      final unitCodes = iuRows.map((e) => e.unitCode).toSet();
      final allUnits = await appDb.select(appDb.units).get();

      final units = [
        for (final u in allUnits)
          if (unitCodes.contains(u.code)) u,
      ];

      final result = await showDialog<List<IngredientDayEntry>>(
        context: context,
        barrierDismissible: false,
        builder: (_) => IngredientPlanAssignDialog(
          pickedDays: pickedDays,
          ingredient: ingredient,
          units: units,
          defaultMealCategoryId: null, // 🔴 KEINE Vorauswahl
        ),
      );

      if (result == null) return;

      for (final e in result) {
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
    },
  );

  if (!mounted) return;
  setState(() {}); // 🔄 List neu laden
}






  // ----------------------------------------------------
  // VIEW MODE persistieren
  // ----------------------------------------------------
  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('calendar_view') ?? 'month';
    setState(() {
      _view = CalendarView.values.firstWhere(
        (v) => v.toString().split('.').last == name,
        orElse: () => CalendarView.month,
      );
    });
  }

  Future<void> _saveViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('calendar_view', _view.toString().split('.').last);
  }

  void _toggleView() {
    setState(() {
      if (_view == CalendarView.month) {
        _view = CalendarView.week;
      } else if (_view == CalendarView.week) {
        _view = CalendarView.list;
      } else {
        _view = CalendarView.month;
      }
    });
    _saveViewMode();
  }

  IconData _iconForView() {
    switch (_view) {
      case CalendarView.month: return Icons.calendar_month;
      case CalendarView.week:  return Icons.calendar_view_week;
      case CalendarView.list:  return Icons.calendar_view_day;
    }
  }

  // ----------------------------------------------------
  // SWIPE Navigation
  // ----------------------------------------------------
  void _onSwipeLeft() {
    setState(() {
      if (_view == CalendarView.month) {
        final nextMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
        _focusedDay = nextMonth;

        final day = _selectedDay.day;
        final daysInMonth = DateUtils.getDaysInMonth(nextMonth.year, nextMonth.month);
        final safeDay = day.clamp(1, daysInMonth);

        _selectedDay = DateTime(nextMonth.year, nextMonth.month, safeDay);
      } else {
        _focusedDay = _focusedDay.add(const Duration(days: 7));
        _selectedDay = _focusedDay;
      }
    });
  }

  void _onSwipeRight() {
    setState(() {
      if (_view == CalendarView.month) {
        final prevMonth = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
        _focusedDay = prevMonth;

        final day = _selectedDay.day;
        final daysInMonth = DateUtils.getDaysInMonth(prevMonth.year, prevMonth.month);
        final safeDay = day.clamp(1, daysInMonth);

        _selectedDay = DateTime(prevMonth.year, prevMonth.month, safeDay);
      } else {
        _focusedDay = _focusedDay.subtract(const Duration(days: 7));
        _selectedDay = _focusedDay;
      }
    });
  }

  void _onSwipeUp() {
    setState(() {
      if (_view == CalendarView.month) {
        _view = CalendarView.week;
      } else if (_view == CalendarView.week) {
        _view = CalendarView.list;
      }
    });
    _saveViewMode();
  }

  void _onSwipeDown() {
    setState(() {
      if (_view == CalendarView.list) {
        _view = CalendarView.week;
      } else if (_view == CalendarView.week) {
        _view = CalendarView.month;
      }
    });
    _saveViewMode();
  }

  // ----------------------------------------------------
  // BUILD
  // ----------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -150) _onSwipeLeft();
        if (v > 150) _onSwipeRight();
      },
      onVerticalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -150) _onSwipeUp();
        if (v > 150) _onSwipeDown();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Kalender', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: Icon(_iconForView(), color: Colors.white),
              onPressed: _toggleView,
            ),
          ],
        ),
        body: _buildView(),
      ),
    );
  }

  Widget _buildView() {
    switch (_view) {
      case CalendarView.month:
        return _buildMonthCalendar(showOnlyWeek: false);
      case CalendarView.week:
        return _buildMonthCalendar(showOnlyWeek: true);
      case CalendarView.list:
        return _buildListView();
    }
  }

  Widget _buildMonthCalendar({required bool showOnlyWeek}) {
    final monthAnchor = DateTime(_focusedDay.year, _focusedDay.month, 1);

    // Warten bis Kategorien geladen sind
    if (_categoryCount == 0) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: PlanningCalendar(
        selectedDay: _selectedDay,
        onDaySelected: (d) {
          setState(() {
            _selectedDay = d;
            _focusedDay = d;
          });
        },
        categoryCount: _categoryCount, // ✅ DAS ist der Fix
        mealCategories: _mealCategories, // 👈 Map<int, MealCategoryData>
        showOnlyWeek: showOnlyWeek,
        focusedMonth: monthAnchor,
        categoryWeekBars: buildCategoryWeekBars,
        dayMealsByCategory: _loadMealsForDate,
      ),
    );
  }

  // ----------------------------------------------------
  // LIST VIEW MIT REZEPTEN
  // ----------------------------------------------------
  Widget _buildListView() {
    final monday = _focusedDay.subtract(Duration(days: _focusedDay.weekday - 1));
    final days = List.generate(7, (i) => monday.add(Duration(days: i)));

    const names = [
      'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag',
      'Freitag', 'Samstag', 'Sonntag'
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 7,
      itemBuilder: (_, i) {
        final day = days[i];
        final isToday = DateUtils.isSameDay(day, DateTime.now());

        return FutureBuilder<Map<int, List<dynamic>>>(
          future: _loadMealsForDate(day),
          builder: (_, snap) {
            final map = snap.data ?? {};
            final sortedEntries = map.entries.toList()
              ..sort((a, b) => a.key.compareTo(b.key));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================
                // SCHMALER DIVIDER ZWISCHEN DEN TAGEN
                // (nicht vor dem ersten Tag)
                // ============================================
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        height: 1,
                        width: MediaQuery.of(context).size.width * 1,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // ============================================
                // DATUMS-HEADER + PLUS
                // ============================================
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            names[i],
                            style: TextStyle(
                              color: isToday ? Colors.greenAccent : Colors.white,
                              fontSize: 20,
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${day.day}.${day.month}.${day.year}',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),

                    // ➕ PLUS
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () => _onAddForDay(context, day),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ============================================
                // KEINE EINTRÄGE
                // ============================================
                if (map.isEmpty)
                  const Text(
                    "Keine Einträge",
                    style: TextStyle(color: Colors.white38),
                  ),

                // ============================================
                // KATEGORIEN + ITEMS
                // ============================================
                for (final entry in sortedEntries) ...[
                  const SizedBox(height: 12),
                  Text(
                    entry.value.first.categoryName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _MealsOfCategoryList(items: entry.value),
                ],

                const SizedBox(height: 5),
              ],
            );

          },
        );
      },
    );
  }
}

Widget _buildRecipeTile(BuildContext context, AggregatedMealEntry e) {
  final meal = e.meal;
  final r = e.recipe;

  final img = (r.picture == null || r.picture!.isEmpty)
      ? 'assets/images/placeholder.jpg'
      : r.picture!;

  final unprepared = (meal.prepared == null || meal.prepared == false);

  // Rahmenfarbe wie jetzt
  Color borderColor = Colors.white.withOpacity(0.15);
  final date = meal.date;
  if (date != null) {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final mealDay = DateTime(date.year, date.month, date.day);

    if (mealDay == today && unprepared) {
      borderColor = Colors.yellowAccent.withOpacity(0.45);
    } else if (mealDay.isBefore(today) && unprepared) {
      borderColor = Colors.redAccent.withOpacity(0.45);
    }
  }

  return Container(
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor, width: 1.5),
    ),
    child: Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.of(context).push(PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 280),
                pageBuilder: (_, __, ___) => RecipeDetailScreen(
                  recipeId: r.id,
                  title: r.name,
                  imagePath: img,
                ),
                transitionsBuilder: (_, animation, __, child) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ));
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  );
                },
              ));
            },
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(img, width: 45, height: 45, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16)),
                        const SizedBox(height: 2),
                        FutureBuilder<Unit?>(
                          future: () async {
                            final code = meal.recipePortionUnit;
                            if (code == null || code.isEmpty) return null;

                            return (appDb.select(appDb.units)
                                  ..where((u) => u.code.equals(code)))
                                .getSingleOrNull();
                          }(),
                          builder: (_, snap) {
                            final unit = snap.data;
                            final amount = meal.recipePortionNumber ?? 1;

                            final singular = unit?.label ?? meal.recipePortionUnit ?? "";
                            final plural   = unit?.plural ?? singular;

                            final unitText = (amount <= 1) ? singular : plural;

                            return Text(
                              '${amount.toInt()} $unitText',
                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        FutureBuilder<List<int>>(
          future: () async {
            final m = appDb.meal;

            final date = meal.date!;
            final start = DateTime(date.year, date.month, date.day);
            final end = start.add(const Duration(days: 1));

            final rows = await (appDb.select(m)
                  ..where((t) =>
                      t.recipeId.equals(meal.recipeId!) &
                      t.mealCategoryId.equals(meal.mealCategoryId!) &
                      t.date.isBiggerOrEqualValue(start) &
                      t.date.isSmallerThanValue(end)))
                .get();

            return rows.map((r) => r.id).toList();
          }(),
          builder: (_, snap) {
            if (!snap.hasData || snap.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            return MealGroupToggle(
              mealIds: snap.data!,
            );
          },
        ),

      ],
    ),
  );
}

Widget _buildIngredientTile(BuildContext context, AggregatedIngredientEntry e) {
  final meal = e.meal;
  final ing = e.ingredient;

  final img = (ing.picture == null || ing.picture!.isEmpty)
      ? 'assets/images/placeholder.jpg'
      : ing.picture!;


  Color borderColor = Colors.white.withOpacity(0.15);

  final amount = meal.ingredientAmount ?? 0;
  final unit = meal.ingredientUnitCode ?? "";

  return Container(
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: borderColor, width: 1.5),
    ),
    child: Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(img, width: 45, height: 45, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ing.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16)),
                      const SizedBox(height: 2),
                      FutureBuilder<Unit?>(
                        future: () async {
                          if (unit.isEmpty) return null;

                          return (appDb.select(appDb.units)
                                ..where((u) => u.code.equals(unit)))
                              .getSingleOrNull();
                        }(),
                        builder: (_, snapUnit) {
                          final u = snapUnit.data;

                          final singular = u?.label ?? unit;
                          final plural = u?.plural ?? singular;

                          final unitText = (amount <= 1) ? singular : plural;

                          return Text(
                            '${amount.toInt()} $unitText',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        MealGroupToggle(
          mealIds: [meal.id],
        ),
      ],
    ),
  );
}





// ------------------------------------------------------------
// WIDGET für die Rezept-Liste innerhalb einer Kategorie
// ------------------------------------------------------------
class _MealsOfCategoryList extends StatelessWidget {
  final List<dynamic> items;


  const _MealsOfCategoryList({required this.items});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final e = items[i];

        if (e is AggregatedMealEntry) {
          return _buildRecipeTile(context, e);
        } else if (e is AggregatedIngredientEntry) {
          return _buildIngredientTile(context, e);
        }

        return const SizedBox.shrink();
      },
    );
  }
}

// ==============================================
// 🅱️ TOGGLE B — MealGroupToggle
// ==============================================

class MealGroupToggle extends StatefulWidget {
  final List<int> mealIds;

  const MealGroupToggle({
    required this.mealIds,
    Key? key,
  }) : super(key: key);

  @override
  State<MealGroupToggle> createState() => _MealGroupToggleState();
}

class _MealGroupToggleState extends State<MealGroupToggle> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await (appDb.select(appDb.meal)
          ..where((m) => m.id.isIn(widget.mealIds)))
        .get();

    if (!mounted) return;
    setState(() {
      _checked =
          rows.isNotEmpty && rows.every((m) => m.timeConsumed != null);
    });
  }

  Future<void> _toggle() async {
    final newValue = !_checked;

    final q = appDb.update(appDb.meal)
      ..where((m) => m.id.isIn(widget.mealIds));

    if (newValue) {
      await q.write(
        MealCompanion(
          timeConsumed: d.Value(DateTime.now()),
          prepared: const d.Value(true),
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
        padding: const EdgeInsets.all(12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Icon(
            _checked
                ? Icons.check_circle_outline
                : Icons.circle_outlined,
            key: ValueKey(
                'mealgrp_${widget.mealIds.join("_")}_$_checked'),
            color: Colors.white54,
            size: 26,
          ),
        ),
      ),
    );
  }
}
