/*import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';

// WICHTIG: AggregatedMealEntry kommt aus meals.dart
import 'package:planty_flutter_starter/screens/Home_Screens/meals.dart';

// ===================================================================
// MEAL DAY VIEW
// ===================================================================
class MealDayView extends StatelessWidget {
  final DateTime day;
  final int categoryCount;
  final Future<Map<int, List<AggregatedMealEntry>>> Function(DateTime day)
      dayMealsByCategory;

  const MealDayView({
    super.key,
    required this.day,
    required this.categoryCount,
    required this.dayMealsByCategory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // -------------------------------------------------------------
        // HEADER: Datum
        // -------------------------------------------------------------
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Text(
            _formatDay(day),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // -------------------------------------------------------------
        // KATEGORIEN
        // -------------------------------------------------------------
        Expanded(
          child: _buildCategoryBoxes(),
        ),
      ],
    );
  }

  // =================================================================
  // KATEGORIE-BLÖCKE
  // =================================================================
  Widget _buildCategoryBoxes() {
    return FutureBuilder<Map<int, List<AggregatedMealEntry>>>(
      future: dayMealsByCategory(day),
      builder: (context, snap) {
        final data = snap.data ?? const <int, List<AggregatedMealEntry>>{};

        return LayoutBuilder(
          builder: (context, constraints) {
            final double rowHeight =
              categoryCount > 0 ? constraints.maxHeight / categoryCount : 0.0;


            return Column(
              children: List.generate(categoryCount, (index) {
                final catId = index + 1;
                final items = data[catId] ?? const <AggregatedMealEntry>[];

                return SizedBox(
                  height: rowHeight,
                  child: _DayCategoryRow(items: items),
                );
              }),
            );
          },
        );
      },
    );
  }

  // =================================================================
  // DATUM FORMAT
  // =================================================================
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

// ===================================================================
// EINZELNE KATEGORIE-ZEILE
// ===================================================================
class _DayCategoryRow extends StatelessWidget {
  final List<AggregatedMealEntry> items;

  const _DayCategoryRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // -----------------------------------------------------------
          // kcal Kreis (Platzhalter)
          // -----------------------------------------------------------
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white24,
            ),
            alignment: Alignment.center,
            child: const Text(
              '—',
              style: TextStyle(color: Colors.white),
            ),
          ),

          const SizedBox(width: 10),

          // -----------------------------------------------------------
          // Meal / Recipe / Ingredient Bilder
          // -----------------------------------------------------------
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxIcons =
                    ((constraints.maxWidth - 12) / 48).floor().clamp(0, 4);

                return Row(
                  children: items.take(maxIcons).map((entry) {
                    final img = _resolveImage(entry);

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          img,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          // -----------------------------------------------------------
          // Prepared Toggle (rechts)
          // -----------------------------------------------------------
          if (items.isNotEmpty)
            _MealPreparedToggle(
              mealId: items.first.meal.id,
              initialValue: items.first.meal.prepared ?? false,
            ),
        ],
      ),
    );
  }

  // =================================================================
  // BILD-AUFLÖSUNG (ROBUST)
  // =================================================================
  String _resolveImage(AggregatedMealEntry e) {
    final r = e.recipe?.picture;
    if (r != null && r.isNotEmpty) return r;

    final i = e.ingredient?.picture;
    if (i != null && i.isNotEmpty) return i;

    return 'assets/images/placeholder.jpg';
  }
}

// ===================================================================
// PREPARED TOGGLE (1:1, STABIL)
// ===================================================================
class _MealPreparedToggle extends StatefulWidget {
  final int mealId;
  final bool initialValue;

  const _MealPreparedToggle({
    required this.mealId,
    required this.initialValue,
  });

  @override
  State<_MealPreparedToggle> createState() => _MealPreparedToggleState();
}

class _MealPreparedToggleState extends State<_MealPreparedToggle> {
  late bool _prepared;

  @override
  void initState() {
    super.initState();
    _prepared = widget.initialValue;
  }

  Future<void> _toggle() async {
    final newValue = !_prepared;

    if (!newValue) {
      await (appDb.update(appDb.meal)
            ..where((m) => m.id.equals(widget.mealId)))
          .write(const MealCompanion(
        prepared: d.Value(false),
        timeConsumed: d.Value(null),
      ));
    } else {
      await (appDb.update(appDb.meal)
            ..where((m) => m.id.equals(widget.mealId)))
          .write(
        MealCompanion(
          prepared: const d.Value(true),
          timeConsumed: d.Value(DateTime.now()),
        ),
      );
    }

    if (mounted) {
      setState(() => _prepared = newValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _toggle,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Icon(
            _prepared
                ? Icons.check_circle_outline
                : Icons.circle_outlined,
            key: ValueKey(_prepared),
            color: Colors.white54,
            size: 26,
          ),
        ),
      ),
    );
  }
}
*/