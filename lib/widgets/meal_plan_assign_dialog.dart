//lib/widgets/meal_plan_assign_dialog.dart
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

import '../db/app_db.dart';
import '../db/db_singleton.dart';

class MealPlanAssignDialog extends StatefulWidget {
  final List<DateTime> selectedDays;
  final int recipeId;
  final int recipePortionNumber;

  const MealPlanAssignDialog({
    super.key,
    required this.selectedDays,
    required this.recipeId,
    required this.recipePortionNumber,
  });

  @override
  State<MealPlanAssignDialog> createState() => _MealPlanAssignDialogState();
}

class _MealPlanAssignDialogState extends State<MealPlanAssignDialog> {
  late Future<List<MealCategoryData>> _catsFuture;

  int? _mainCategoryId;

  final Map<DateTime, int> _portionsPerDay = {};
  final Map<DateTime, int> _categoryPerDay = {};
  final Map<DateTime, bool> _dropdownEnabled = {};

  late List<DateTime> _days;

  @override
  void initState() {
    super.initState();

    // lokale Kopie — diese können wir verändern
    _days = List.from(widget.selectedDays);

    _catsFuture = (appDb.select(appDb.mealCategory)
          ..orderBy([(t) => d.OrderingTerm(expression: t.id)]))
        .get();

    for (final day in _days) {
      _portionsPerDay[day] =
          widget.recipePortionNumber ~/ widget.selectedDays.length;

      if (_portionsPerDay[day] == 0) _portionsPerDay[day] = 1;

      _dropdownEnabled[day] = false;
    }

    _initPreferredCategory();
  }

  Future<void> _initPreferredCategory() async {
    final recipe = await (appDb.select(appDb.recipes)
          ..where((r) => r.id.equals(widget.recipeId)))
        .getSingleOrNull();

    if (recipe == null) {
      setState(() => _mainCategoryId = 1);
      return;
    }

    final sameMeals = await (appDb.select(appDb.meal)
          ..where((m) => m.recipeId.equals(widget.recipeId)))
        .get();

    if (sameMeals.isNotEmpty) {
      final freq = <int, int>{};
      for (final m in sameMeals) {
        if (m.mealCategoryId != null) {
          freq[m.mealCategoryId!] = (freq[m.mealCategoryId!] ?? 0) + 1;
        }
      }

      if (freq.isNotEmpty) {
        final sorted = freq.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        setState(() => _mainCategoryId = sorted.first.key);
        return;
      }
    }

    // Kategorie fallback: gleiche Rezept-Kategorie
    if (recipe.recipeCategory != null) {
      final other = await (appDb.select(appDb.meal)
            ..where((m) => m.recipeId.isInQuery(
                  appDb.selectOnly(appDb.recipes)
                    ..addColumns([appDb.recipes.id])
                    ..where(appDb.recipes.recipeCategory.equals(recipe.recipeCategory)),
                )))
          .get();

      final freq2 = <int, int>{};
      for (final m in other) {
        if (m.mealCategoryId != null) {
          freq2[m.mealCategoryId!] = (freq2[m.mealCategoryId!] ?? 0) + 1;
        }
      }

      if (freq2.isNotEmpty) {
        final sorted2 = freq2.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        setState(() => _mainCategoryId = sorted2.first.key);
        return;
      }
    }

    setState(() => _mainCategoryId = 1);
  }

  // =============================================
  // Tag entfernen
  // =============================================
  void _removeDay(DateTime day) {
    setState(() {
      _days.remove(day);
      _portionsPerDay.remove(day);
      _categoryPerDay.remove(day);
      _dropdownEnabled.remove(day);
    });
  }

  String _format(DateTime d) {
    const weekday = [
      "",
      "Montag",
      "Dienstag",
      "Mittwoch",
      "Donnerstag",
      "Freitag",
      "Samstag",
      "Sonntag",
    ];

    final w = weekday[d.weekday];
    final date = "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.";

    return "$w, $date";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MealCategoryData>>(
      future: _catsFuture,
      builder: (ctx, snap) {
        final cats = snap.data ?? [];

        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text(
            "Mahlzeiten zuteilen",
            style: TextStyle(color: Colors.white),
          ),

          content: SizedBox(
            width: double.maxFinite,
            child: snap.hasData
                ? ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Zeitraum auswählen:",
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 6),

                          _buildMainDropdown(cats),
                          const SizedBox(height: 20),

                          ..._days.map((d) => _buildDayRow(d, cats)),
                        ],
                      ),
                    ),
                  )
                : const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Abbrechen",
                  style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                final result = <_AssignedMealEntry>[];

                for (final day in _days) {
                  final p = _portionsPerDay[day] ?? 0;
                  if (p == 0) continue;

                  final c = _categoryPerDay[day] ?? _mainCategoryId ?? 1;

                  result.add(_AssignedMealEntry(
                    date: day,
                    portions: p,
                    categoryId: c,
                  ));
                }

                Navigator.pop(
                  context,
                  MealPlanAssignmentResult(
                    result.map((e) => MealPlanDayEntry(
                      date: e.date,
                      categoryId: e.categoryId,
                      portions: e.portions,
                    )).toList(),
                  ),
                );
              },
              child: const Text("Weiter",
                  style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        );
      },
    );
  }

  // =============================================
  // MAIN DROPDOWN
  // =============================================
  Widget _buildMainDropdown(List<MealCategoryData> cats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(6),
        color: Colors.black,
      ),
      child: DropdownButton<int>(
        value: _mainCategoryId,
        isExpanded: true,
        dropdownColor: Colors.black,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        style: const TextStyle(color: Colors.white),
        items: [
          for (final c in cats)
            DropdownMenuItem(
              value: c.id,
              child:
                  Text(c.name, style: const TextStyle(color: Colors.white)),
            ),
        ],
        onChanged: (val) {
          if (val == null) return;

          setState(() {
            _mainCategoryId = val;
            for (final d in _days) {
              _categoryPerDay[d] = val;
            }
          });
        },
      ),
    );
  }

  // =============================================
  // DAY ROW
  // =============================================
  Widget _buildDayRow(DateTime day, List<MealCategoryData> cats) {
    final p = _portionsPerDay[day]!;
    final assignedCat = _categoryPerDay[day] ?? _mainCategoryId ?? 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black54,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER (Datum) =====
          Text(
            _format(day),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              // Minus / Delete
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: p == 1
                    ? const Icon(Icons.delete_forever,
                        color: Colors.redAccent)
                    : const Icon(Icons.remove_circle_outline,
                        color: Colors.white70),
                onPressed: () {
                  if (p == 1) {
                    _removeDay(day); // <<< DER WICHTIGE FIX
                  } else {
                    setState(() => _portionsPerDay[day] = p - 1);
                  }
                },
              ),

              Text(
                "$p",
                style:
                    const TextStyle(color: Colors.white, fontSize: 18),
              ),

              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.add_circle_outline,
                    color: Colors.white70),
                onPressed: () {
                  setState(() => _portionsPerDay[day] = p + 1);
                },
              ),

              const SizedBox(width: 10),

              // Dropdown
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _dropdownEnabled[day] = true),
                  child: AbsorbPointer(
                    absorbing: !_dropdownEnabled[day]!,
                    child: Opacity(
                      opacity: _dropdownEnabled[day]! ? 1.0 : 0.4,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white30),
                          borderRadius: BorderRadius.circular(6),
                          color: Colors.black,
                        ),
                        child: DropdownButton<int>(
                          value: assignedCat,
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: Colors.black,
                          icon: const Icon(Icons.arrow_drop_down,
                              color: Colors.white),
                          style:
                              const TextStyle(color: Colors.white),
                          items: [
                            for (final c in cats)
                              DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white),
                                ),
                              ),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setState(
                                () => _categoryPerDay[day] = val);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignedMealEntry {
  final DateTime date;
  final int portions;
  final int categoryId;

  _AssignedMealEntry({
    required this.date,
    required this.portions,
    required this.categoryId,
  });
}


// --------------------------------------------------------------
// Ergebnis-Modell für den Plan-Dialog (MealPlanAssignDialog)
// --------------------------------------------------------------

class MealPlanAssignmentResult {
  final List<MealPlanDayEntry> entries;

  MealPlanAssignmentResult(this.entries);
}

class MealPlanDayEntry {
  final DateTime date;
  final int categoryId;
  final int portions;

  MealPlanDayEntry({
    required this.date,
    required this.categoryId,
    required this.portions,
  });
}
