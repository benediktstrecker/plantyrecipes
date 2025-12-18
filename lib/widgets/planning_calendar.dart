// lib/widgets/planning_calendar.dart
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

import 'package:planty_flutter_starter/screens/meals/meal_detail.dart';

import 'package:planty_flutter_starter/services/meal_item_picker.dart';

import 'package:planty_flutter_starter/widgets/ingredient_plan_assign_dialog.dart';
import 'package:planty_flutter_starter/widgets/meal_plan_assign_dialog.dart';

Color _parseHexColor(String? hex) {
  if (hex == null) return Colors.grey;
  String c = hex.replaceAll('#', '');
  if (c.length == 6) c = 'FF$c';
  return Color(int.parse(c, radix: 16));
}

class BarSegment {
  final int startCol; // 0..6
  final int endCol;   // 0..6
  const BarSegment({required this.startCol, required this.endCol});
}

class CategoryWeekBar {
  final int mealCategoryId;
  final int categoryRow;
  final Color color;

  /// ✅ NEU: mehrere Balken-Segmente pro Kategorie (z.B. Di-Do + Fr-So)
  final List<BarSegment> segments;

  final Map<int, List<BarVisual>> visualsPerDay;

  CategoryWeekBar({
    required this.mealCategoryId,
    required this.categoryRow,
    required this.color,
    required this.segments,
    required this.visualsPerDay,
  });
}



class BarVisual {
  final String? imagePath; // null = +Kreis
  final int overflowCount;
  final bool isRecipe; // wichtig: Rezeptbild nur am Start-Tag anzeigen

  const BarVisual.image(this.imagePath, {required this.isRecipe})
      : overflowCount = 0;

  const BarVisual.overflow(this.overflowCount)
      : imagePath = null,
        isRecipe = false;
}



class PlanningCalendar extends StatefulWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  /// true = nur die Woche anzeigen, in der selectedDay liegt
  final bool showOnlyWeek;

  /// Monat, der angezeigt werden soll (DateTime(year, month, 1))
  final DateTime? focusedMonth;

  /// Liefert category-basierte Wochenbalken (fixe Reihen)
  final Future<List<CategoryWeekBar>> Function(DateTime weekStart)?
    categoryWeekBars;

  final int categoryCount; 

  final Map<int, MealCategoryData> mealCategories;

  final Future<Map<int, List<dynamic>>> Function(DateTime day)?
    dayMealsByCategory;

  /// Debug: zeigt Platzhalter-Balken, falls keine Daten geliefert werden
  final bool debugBars;



  const PlanningCalendar({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    required this.categoryCount,
    required this.mealCategories, // 👈 NEU
    this.showOnlyWeek = false,
    this.focusedMonth,
    this.categoryWeekBars,
    this.dayMealsByCategory,
    this.debugBars = false,
  });





  @override
  State<PlanningCalendar> createState() => _PlanningCalendarState();
}

class _PlanningCalendarState extends State<PlanningCalendar> {
  late DateTime _focusedMonth;

  static const List<String> weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  static const double _kwWidth = 36.0;


  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(widget.selectedDay.year, widget.selectedDay.month, 1);
  }

  @override
  void didUpdateWidget(covariant PlanningCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Falls von außen ein anderer Monat vorgegeben wird
    if (widget.focusedMonth != null) {
      final m = widget.focusedMonth!;
      if (m.year != _focusedMonth.year || m.month != _focusedMonth.month) {
        _focusedMonth = DateTime(m.year, m.month, 1);
      }
    }

  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + offset, 1);
    });
  }

  /// ISO-Kalenderwoche (Montag als Wochenanfang)
  int isoWeekNumber(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final firstThursday = DateTime(date.year, 1, 4);
    final firstMonday =
        firstThursday.subtract(Duration(days: firstThursday.weekday - 1));
    final diff = monday.difference(firstMonday);
    return (diff.inDays / 7).floor() + 1;
  }

  @override
  Widget build(BuildContext context) {
    // Monat berechnen
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);

    final int daysInMonth = lastDayOfMonth.day;

    // Offset: Montag = 0, Sonntag = 6
    final int leadingEmpty = (firstDayOfMonth.weekday + 6) % 7;

    // Alle Zellen: vorangestellte Null-Zellen + Tage + trailing Nulls
    final List<DateTime?> paddedDays = [];

    // Leading nulls
    for (int i = 0; i < leadingEmpty; i++) {
      paddedDays.add(null);
    }

    // Tage des Monats
    for (int d = 1; d <= daysInMonth; d++) {
      paddedDays.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }

    // Trailing nulls für volle Wochen
    final int remainder = paddedDays.length % 7;
    if (remainder != 0) {
      final int missing = 7 - remainder;
      for (int i = 0; i < missing; i++) {
        paddedDays.add(null);
      }
    }

    final int rows = paddedDays.length ~/ 7;

    // Index der Woche, in der der selectedDay liegt
    int weekIndexOf(DateTime day) {
      for (int i = 0; i < paddedDays.length; i++) {
        final d = paddedDays[i];
        if (d != null && DateUtils.isSameDay(d, day)) {
          return i ~/ 7;
        }
      }
      return 0;
    }

    final int selectedWeekIndex = weekIndexOf(widget.selectedDay);

    return Column(
      children: [
        // -------------------------------------------------------------
        // HEADER: Monat-Navigation
        // -------------------------------------------------------------
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              color: Colors.white,
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _changeMonth(-1),
            ),
            Text(
              '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              color: Colors.white,
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _changeMonth(1),
            ),
          ],
        ),

        // -------------------------------------------------------------
        // Wochentags-Header + KW
        // -------------------------------------------------------------
        Row(
          children: [
            for (final w in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              ),
            const SizedBox(
              width: _kwWidth,
              child: Center(
                child: Text(
                  'KW',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // =============================================================
        // GRID / WEEK LAYOUT (EIN Height-Kontext)
        // =============================================================
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final totalHeight = constraints.maxHeight;
              final rowHeight = totalHeight / rows;

              // -----------------------------
              // MONATSANSICHT
              // -----------------------------
              if (!widget.showOnlyWeek) {
                return Stack(
                  children: [
                    Positioned.fill(child: Container(color: Colors.black)),
                    for (int rowIndex = 0; rowIndex < rows; rowIndex++)
                      _buildWeekRow(
                        rowIndex: rowIndex,
                        rowHeight: rowHeight,
                        paddedDays: paddedDays,
                        selectedWeekIndex: selectedWeekIndex,
                      ),
                  ],
                );
              }

              // -----------------------------
              // WOCHENANSICHT (EIN FLOW)
              // -----------------------------
              return Column(
                children: [
                  // 🟩 WOCHE – gleiche Höhe wie im Monat
                  SizedBox(
                    height: rowHeight,
                    child: Stack(
                      children: [
                        Positioned.fill(child: Container(color: Colors.black)),
                        _buildWeekRow(
                          rowIndex: selectedWeekIndex,
                          rowHeight: rowHeight,
                          paddedDays: paddedDays,
                          selectedWeekIndex: selectedWeekIndex,
                        ),
                      ],
                    ),
                  ),

                  // 🟦 TAGESANSICHT – Resthöhe
                  Expanded(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: _buildDayDetailArea(),
                    ),
                  ),
                ],
              );


            },
          ),
        ),

      ],
    );

  }

  Widget _buildWeekRow({
    required int rowIndex,
    required double rowHeight,
    required List<DateTime?> paddedDays,
    required int selectedWeekIndex,
  }) {
    final rowItems = paddedDays.skip(rowIndex * 7).take(7).toList();

    final List<DateTime> nonNullDays =
        rowItems.whereType<DateTime>().toList();

    final DateTime? weekStart =
        nonNullDays.isNotEmpty ? nonNullDays.first : null;


    final DateTime? kwDay =
        rowItems.firstWhere((d) => d != null, orElse: () => null);
    final String kw = kwDay == null ? '' : isoWeekNumber(kwDay).toString();

    // Sichtbarkeit der Woche
    final bool visibleRow =
        !widget.showOnlyWeek || rowIndex == selectedWeekIndex;

    // Position: in Monatsansicht alle untereinander,
    // in Wochenansicht slidet die selektierte Woche nach oben.
    final double top = widget.showOnlyWeek
        ? (rowIndex == selectedWeekIndex ? 0.0 : rowIndex * rowHeight)
        : rowIndex * rowHeight;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 320), // ⬅️ WICHTIG
      curve: Curves.easeInOutCubic,                 // ⬅️ WICHTIG
      left: 0,
      right: 0,
      top: widget.showOnlyWeek
          ? (rowIndex == selectedWeekIndex ? 0.0 : rowIndex * rowHeight)
          : rowIndex * rowHeight,
      height: rowHeight,
      child: Opacity(
        opacity: visibleRow ? 1.0 : 0.0,
        child: Stack(
          children: [
            // -----------------------------
            // 1) Tageszellen
            // -----------------------------
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      for (final day in rowItems)
                        Expanded(child: _buildDayCell(day)),
                    ],
                  ),
                ),
                SizedBox(
                  width: _kwWidth,
                  child: Center(
                    child: Text(
                      kw,
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),


            // -----------------------------
            // 2) CATEGORY-WEEK-BALKEN
            // -----------------------------
            if (widget.categoryWeekBars != null && weekStart != null)
              _buildWeekBars(
                weekStart: weekStart,
                rowHeight: rowHeight,
              ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const names = [
      '',
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    return names[m];
  }

  Widget _buildDayCell(DateTime? day) {
    if (day == null) {
      return Container();
    }

    final bool isToday = DateUtils.isSameDay(day, DateTime.now());
    final bool isSelected = DateUtils.isSameDay(day, widget.selectedDay);

    return GestureDetector(
      onTap: () => widget.onDaySelected(day),
      child: Container(
        //margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Container(
                decoration: isToday
                    ? BoxDecoration(
                        //shape: BoxShape.circle,
                        //border: Border.all(color: Colors.white, width: 1.4),
                      )
                    : null,
                padding: const EdgeInsets.all(6),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    color: isToday ? Colors.greenAccent : Colors.white,
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),

            // Platz für Meal-Balken
            const Spacer(),
       ],
        ),
      ),
    );
  }


Widget _buildWeekBars({
  required DateTime weekStart,
  required double rowHeight,
}) {
  return FutureBuilder<List<CategoryWeekBar>>(
    future: widget.categoryWeekBars!(weekStart),
    builder: (context, snap) {
      final bars = snap.data ?? [];
      // Debug-Ausgabe zur Kontrolle der gelieferten Balken
      // (nur wenn Connection fertig ist)
      if (snap.connectionState == ConnectionState.done) {
        for (final b in bars) {
        }
      }

      // Wichtig: auch wenn bars leer sind, behalten wir die feste Höhe/Struktur
      // -> dann wird einfach nichts gezeichnet
      final categoryCount = (widget.categoryCount <= 0) ? 1 : widget.categoryCount;

      return LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth =
            (constraints.maxWidth - _kwWidth) / 7;

          // Reserviere oben Platz für die Tageszahl-Zeile, aber
          // begrenze die Reservierung proportional zur tatsächlichen
          // Zeilenhöhe, damit die eigentliche Balkenfläche nicht
          // auf 0 zusammenschrumpft (-> keine Anzeige).
          const double desiredDayNumberArea = 36.0;
          // Maximal die Hälfte der Zeilenhöhe für die Tageszahl-Box verwenden
          final double topPadding = desiredDayNumberArea.clamp(0.0, rowHeight * 0.5);
          final double barAreaHeight = (rowHeight - topPadding).clamp(0.0, rowHeight);

          final double categoryRowHeight =
              categoryCount == 0 ? 0 : (barAreaHeight / categoryCount);

          if (categoryRowHeight <= 0) return const SizedBox.shrink();

          // Wenn keine Balken geliefert wurden und Debug aktiv ist,
          // zeichne Platzhalter, um Layout-Probleme auszuschließen.
          final List<Widget> children = [];
          if (bars.isEmpty && widget.debugBars) {
            final placeholder = CategoryWeekBar(
              mealCategoryId: 0,
              categoryRow: 0,
              color: Colors.orangeAccent,
              segments: const [BarSegment(startCol: 1, endCol: 3)],
              visualsPerDay: const {},
            );
            children.add(
              _buildCategoryRow(
                placeholder,
                placeholder.categoryRow,
                categoryRowHeight,
                cellWidth,
                topOffset: topPadding,
              ),
            );
          }

          for (final bar in bars) {
            children.add(
              _buildCategoryRow(
                bar,
                bar.categoryRow,
                categoryRowHeight,
                cellWidth,
                topOffset: topPadding,
              ),
            );
          }

          return Stack(children: children);
        },
      );
    },
  );
}


Widget _buildCategoryRow(
  CategoryWeekBar bar,
  int row,
  double rowHeight,
  double cellWidth, {
  required double topOffset, // ✅ NEU
}) {
  if (rowHeight <= 0) return const SizedBox.shrink();

  final top = topOffset + row * rowHeight; // ✅ FIX: Offset + feste Reihe


  return Positioned(
    top: top,
    left: 0,
    right: _kwWidth,
    height: rowHeight,
    child: Stack(
      children: [
        // --------------------------------------------------
        // 1) Balken-Segmente (pro Rezept-Zeitraum ein Segment)
        // --------------------------------------------------
        for (final seg in bar.segments)
          Positioned(
            left: seg.startCol * cellWidth,
            width: (seg.endCol - seg.startCol + 1) * cellWidth,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: bar.color.withOpacity(0.85),
                borderRadius: BorderRadius.circular(rowHeight / 2),
              ),
            ),
          ),


        // --------------------------------------------------
        // 2) Tages-Pills (nur wenn KEIN Rezept-Segment existiert)
        // --------------------------------------------------
        if (bar.segments.isEmpty)
          for (final dayIndex in bar.visualsPerDay.keys)
            Positioned(
              left: dayIndex * cellWidth,
              width: cellWidth,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: cellWidth * 0.9,
                  height: rowHeight,
                  decoration: BoxDecoration(
                    color: bar.color.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(rowHeight / 2),
                  ),
                ),
              ),
            ),

        // --------------------------------------------------
        // 3) Bilder / +n
        // --------------------------------------------------
        for (final entry in bar.visualsPerDay.entries)
          Positioned(
            left: entry.key * cellWidth,
            top: 0,
            bottom: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: entry.value.map((v) {
                if (v.imagePath != null) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(rowHeight / 2),
                    child: Image.asset(
                      v.imagePath!,
                      width: rowHeight,
                      height: rowHeight,
                      fit: BoxFit.cover,
                    ),
                  );
                }

                // +n Kreis
                return Container(
                  width: rowHeight,
                  height: rowHeight,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Text(
                    '+${v.overflowCount}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),

            ),
          ),
      ],
    ),
  );
}

  Widget _buildDayDetailArea() {
    return GestureDetector(
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -120) _changeSelectedDay(1);
        if (v > 120) _changeSelectedDay(-1);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            child: Text(
              _formatSelectedDay(widget.selectedDay),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _buildDayCategoryBoxes(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCategoryBoxes() {
    if (widget.dayMealsByCategory == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<int, List<dynamic>>>(
      future: widget.dayMealsByCategory!(widget.selectedDay),
      builder: (context, snap) {
        final data = snap.data ?? {};

        return LayoutBuilder(
          builder: (context, constraints) {
            final effectiveCount =
                widget.categoryCount < 5 ? 5 : widget.categoryCount;  

            final rowHeight =
                constraints.maxHeight / effectiveCount;

            // War vorher so, stehen lassen falls es Probleme gibt
            //final rowHeight =
              //constraints.maxHeight / widget.categoryCount;


            return Column(
              children: List.generate(widget.categoryCount, (row) {
                final catId = row + 1;
                final items = data[catId] ?? [];

                return SizedBox(
                  height: rowHeight,
                  child: _buildDayCategoryRow(
                    categoryId: catId,
                    items: items,
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }

  Widget _buildDayCategoryRow({
  required int categoryId,
  required List<dynamic> items,
}) {
  return Stack(
    children: [
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 8), // Platz für Label oben
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white24,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ================= LEFT → NAVIGATION =================
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
                        day: widget.selectedDay,
                        category: widget.mealCategories[categoryId]!,
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
                          begin: 0.8, // verhindert weißes Einblitzen
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // kcal
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Text(
                        'kcal',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // IMAGES + PLUS = EINE REIHE
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth.isFinite
                            ? constraints.maxWidth
                            : MediaQuery.of(context).size.width;

                        final maxIcons =
                            (availableWidth / 48).floor().clamp(0, 3);

                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...items.take(maxIcons).map((e) {
                              final img =
                                  e.runtimeType.toString() == 'AggregatedMealEntry'
                                      ? e.recipe?.picture
                                      : e.ingredient?.picture;

                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    img ?? 'assets/images/placeholder.jpg',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            }),

                            // ➕ PLUS DIREKT DANACH
                            GestureDetector(
                              onTap: () async {
                                final picked = await MealItemPicker.pick(
                                  context: context,
                                  day: widget.selectedDay,
                                  mealCategoryId: categoryId,
                                );

                                if (picked == null) return;

                                final pickedDays = <DateTime>[widget.selectedDay];

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

                                    // ===== Zutaten des Rezepts laden =====
                                    final recipe = await (appDb.select(appDb.recipes)
                                          ..where((r) => r.id.equals(recipeId)))
                                        .getSingleOrNull();
                                    if (recipe == null) return;

                                    final ingRows = await (appDb.select(appDb.recipeIngredients)
                                          ..where((t) => t.recipeId.equals(recipe.id)))
                                        .get();

                                    final basePortions = recipe.portionNumber ?? 1;
                                    final portionUnit = recipe.portionUnit;

                                    // ===== PreparationList anlegen =====
                                    final prepId = await appDb.into(appDb.preparationList).insert(
                                      PreparationListCompanion.insert(
                                        recipeId: recipe.id,
                                        recipePortionNumberBase: d.Value(basePortions),
                                        recipePortionNumberLeft: d.Value(basePortions),
                                        timePrepared: const d.Value(null),
                                      ),
                                    );

                                    // ===== Meals erzeugen =====
                                    for (final entry in result.entries) {
                                      final day = entry.date;
                                      final categoryId = entry.categoryId;
                                      final plannedPortions = entry.portions;

                                      for (final ing in ingRows) {
                                        final recipeAmount = ing.amount ?? 0;
                                        final scaledAmount =
                                            (plannedPortions / basePortions) * recipeAmount;

                                        await appDb.into(appDb.meal).insert(
                                          MealCompanion.insert(
                                            date: d.Value(day),
                                            mealCategoryId: d.Value(categoryId),

                                            recipeId: d.Value(recipe.id),
                                            recipePortionNumber: d.Value(plannedPortions),
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

                                    // ======================================================
                                    // 6) Zutaten zur Einkaufsliste hinzufügen?
                                    // ======================================================
                                    if (!context.mounted) return;

                                    final addToShopping = await showDialog<bool>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: Colors.black87,
                                        title: const Text(
                                          "Zutaten hinzufügen?",
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

                                    if (addToShopping != true) return;

                                    // ======================================================
                                    // 7) Einkaufsliste auswählen
                                    // ======================================================
                                    final targetShoppingListId = await showDialog<int>(
                                      context: context,
                                      builder: (_) => _SelectTargetShoppingListDialog(),
                                    );

                                    if (targetShoppingListId == null) return;

                                    // ======================================================
                                    // 8) Zutaten einfügen
                                    // ======================================================
                                    for (final ing in ingRows) {
                                      await appDb.into(appDb.shoppingListIngredient).insert(
                                        ShoppingListIngredientCompanion.insert(
                                          shoppingListId: targetShoppingListId,
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
                                    final ingredient =
                                        await (appDb.select(appDb.ingredients)
                                              ..where((i) => i.id.equals(ingredientId)))
                                            .getSingle();

                                    // ---------------------------------------------
                                    // Units vorfiltern: nur ingredient_units
                                    // ---------------------------------------------
                                    final iuRows = await (appDb.select(appDb.ingredientUnits)
                                          ..where((u) => u.ingredientId.equals(ingredientId)))
                                        .get();

                                    final iuCodes = iuRows.map((e) => e.unitCode).toSet();

                                    // alle Units laden
                                    final allUnits = await appDb.select(appDb.units).get();

                                    // nur passende Units fürs Ingredient
                                    final units = <Unit>[
                                      for (final u in allUnits)
                                        if (iuCodes.contains(u.code)) u,
                                    ];

                                    final result = await showDialog<List<IngredientDayEntry>>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => IngredientPlanAssignDialog(
                                        pickedDays: pickedDays,
                                        ingredient: ingredient,
                                        units: units,
                                        defaultMealCategoryId: categoryId,
                                      ),
                                    );

                                    if (result == null) return;

                                    // 👉 INSERT meal (Zutat)


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

                                    // ======================================================
                                    // 7) Zur Einkaufsliste hinzufügen?
                                    // ======================================================
                                    if (!context.mounted) return;

                                    final addToShopping = await showDialog<bool>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: Colors.black87,
                                        title: const Text(
                                          "Zur Einkaufsliste hinzufügen?",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        content: const Text(
                                          "Soll diese geplante Zutat zur Einkaufsliste hinzugefügt werden?",
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

                                    if (addToShopping != true) return;

                                    // ======================================================
                                    // 8) Einkaufsliste auswählen
                                    // ======================================================
                                    final targetShoppingListId = await showDialog<int>(
                                      context: context,
                                      builder: (_) => _SelectTargetShoppingListDialog(),
                                    );

                                    if (targetShoppingListId == null) return;

                                    // ======================================================
                                    // 9) Gesamtmenge berechnen & einfügen
                                    // ======================================================
                                    final totalAmount = result.fold<double>(
                                      0,
                                      (sum, e) => sum + e.amount,
                                    );

                                    final unitCodes = result.map((e) => e.unitCode).toSet();
                                    final unitCode =
                                        unitCodes.length == 1 ? unitCodes.first : result.first.unitCode;

                                    await appDb.into(appDb.shoppingListIngredient).insert(
                                      ShoppingListIngredientCompanion.insert(
                                        shoppingListId: targetShoppingListId,
                                        ingredientIdNominal: d.Value(ingredientId),
                                        ingredientAmountNominal: d.Value(totalAmount),
                                        ingredientUnitCodeNominal: d.Value(unitCode),
                                      ),
                                    );

                                  },
                                );
                              },

                              

                              



                              child: Container(
                                width: 40,
                                height: 40,
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
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ================= TOGGLE (RECHTS) =================
            if (items.isNotEmpty)
              CategoryDayToggle(
                day: widget.selectedDay,
                mealCategoryId: categoryId,
              ),
          ],
        )
      ),

      // 🔹 Meal-Category-Name im Rahmen (oben links, Linie unterbrochen)
      Positioned(
        left: 18,
        top: 2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          color: Colors.black, // Hintergrund des Kalenders
          child: Text(
            widget.mealCategories[categoryId]?.name ?? '',
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


  void _changeSelectedDay(int delta) {
    final newDay = widget.selectedDay.add(Duration(days: delta));
    widget.onDaySelected(newDay);
  }

  String _formatSelectedDay(DateTime d) {
    const names = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag'
    ];
    return '${names[d.weekday - 1]}, ${d.day}.${d.month}.${d.year}';
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
                'cat_${widget.mealCategoryId}_${widget.day}_$_checked'),
            color: Colors.white54,
            size: 26,
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
