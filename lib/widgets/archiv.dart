// lib/widgets/planning_calendar.dart
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';



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

  final Future<Map<int, List<dynamic>>> Function(DateTime day)?
    dayMealsByCategory;



  const PlanningCalendar({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    required this.categoryCount, 
    this.showOnlyWeek = false,
    this.focusedMonth,
    this.categoryWeekBars,
    this.dayMealsByCategory, // 👈 NEU
  });




  @override
  State<PlanningCalendar> createState() => _PlanningCalendarState();
}

class _PlanningCalendarState extends State<PlanningCalendar>
    with SingleTickerProviderStateMixin {
  late DateTime _focusedMonth;

  static const List<String> weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  static const double _kwWidth = 36.0;

  late final AnimationController _weekSlideCtrl;
  late final Animation<Offset> _weekSlideAnim;



  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(widget.selectedDay.year, widget.selectedDay.month, 1);

    _weekSlideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520), // ⬅️ ruhiger
    );

    final curved = CurvedAnimation(
      parent: _weekSlideCtrl,
      curve: Curves.easeInOutCubic, // ⬅️ symmetrisch!
    );

    _weekSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.30), // ⬅️ kurzer Weg = kein Nachziehen
      end: Offset.zero,
    ).animate(curved);



    if (widget.showOnlyWeek) {
      _weekSlideCtrl.forward();
    }
    
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

    if (oldWidget.showOnlyWeek != widget.showOnlyWeek) {
      if (widget.showOnlyWeek) {
        _weekSlideCtrl.forward(from: 0);
      } else {
        _weekSlideCtrl.reverse();
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
                  // 🟩 WOCHE
                  SizedBox(
                    height: rowHeight,
                    child: SlideTransition(
                      position: _weekSlideAnim,
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
                  ),

                  // 🟦 TAG – HÄNGT AM SELBEN CONTROLLER
                  Expanded(
                    child: FadeTransition(
                      opacity: _weekSlideCtrl, // 👈 SELBE TIMELINE
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
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      left: 0,
      right: 0,
      top: top,
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

      // Wichtig: auch wenn bars leer sind, behalten wir die feste Höhe/Struktur
      // -> dann wird einfach nichts gezeichnet
      final categoryCount = (widget.categoryCount <= 0) ? 1 : widget.categoryCount;

      return LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth =
            (constraints.maxWidth - _kwWidth) / 7;

          // ✅ FIX: reserviere oben Platz für die Tageszahl-Zeile
          const double dayNumberArea = 36.0; // ggf. 34..42 je nach deinem Look
          final double barAreaHeight = (rowHeight - dayNumberArea).clamp(0.0, rowHeight);

          final double categoryRowHeight =
              categoryCount == 0 ? 0 : (barAreaHeight / categoryCount);

          if (categoryRowHeight <= 0) return const SizedBox.shrink();

          return Stack(
            children: [
              for (final bar in bars)
                _buildCategoryRow(
                  bar,
                  bar.categoryRow,
                  categoryRowHeight,
                  cellWidth,
                  topOffset: dayNumberArea, // ✅ NEU
                ),
            ],
          );
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
            final rowHeight =
                constraints.maxHeight / widget.categoryCount;

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 1️⃣ kcal Kreis
          GestureDetector(
            onTap: () {},
            child: Container(
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
          ),

          const SizedBox(width: 10),

          // 2️⃣ Meal Bilder
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxIcons =
                      (constraints.maxWidth / 48).floor().clamp(0, 4);

                  return Row(
                    children: items.take(maxIcons).map((e) {
                      final img = e.runtimeType.toString() == 'AggregatedMealEntry'
                          ? e.recipe.picture
                          : e.ingredient.picture;

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
                    }).toList(),
                  );
                },
              ),
            ),
          ),


          // 3️⃣ Prepared Toggle (Platzhalter)
          if (items.isNotEmpty)
          _MealPreparedToggle(
            mealId: (items.first as dynamic).meal.id,
            initialValue:
                ((items.first as dynamic).meal.prepared ?? false),
          ),
        ],
      ),
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


class _MealPreparedToggle extends StatefulWidget {
  final int mealId;
  final bool initialValue;

  const _MealPreparedToggle({
    required this.mealId,
    required this.initialValue,
    Key? key,
  }) : super(key: key);

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

    if (newValue == false) {
      await (appDb.update(appDb.meal)
            ..where((m) => m.id.equals(widget.mealId)))
          .write(
        const MealCompanion(
          prepared: d.Value(false),
          timeConsumed: d.Value(null),
        ),
      );
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

    setState(() {
      _prepared = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Icon(
            _prepared
                ? Icons.check_circle_outline
                : Icons.circle_outlined,
            key: ValueKey("prep_${widget.mealId}_$_prepared"),
            color: Colors.white54,
            size: 26,
          ),
        ),
      ),
    );
  }
}



/*Widget _buildDayDetailArea() {
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
            final rowHeight =
                constraints.maxHeight / widget.categoryCount;

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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 1️⃣ kcal Kreis
          GestureDetector(
            onTap: () {},
            child: Container(
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
          ),

          const SizedBox(width: 10),

          // 2️⃣ Meal Bilder
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxIcons =
                      (constraints.maxWidth / 48).floor().clamp(0, 4);

                  return Row(
                    children: items.take(maxIcons).map((e) {
                      final img = e.runtimeType.toString() == 'AggregatedMealEntry'
                          ? e.recipe.picture
                          : e.ingredient.picture;

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
                    }).toList(),
                  );
                },
              ),
            ),
          ),


          // 3️⃣ Prepared Toggle (Platzhalter)
          if (items.isNotEmpty)
          _MealPreparedToggle(
            mealId: (items.first as dynamic).meal.id,
            initialValue:
                ((items.first as dynamic).meal.prepared ?? false),
          ),
        ],
      ),
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


class _MealPreparedToggle extends StatefulWidget {
  final int mealId;
  final bool initialValue;

  const _MealPreparedToggle({
    required this.mealId,
    required this.initialValue,
    Key? key,
  }) : super(key: key);

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

    if (newValue == false) {
      await (appDb.update(appDb.meal)
            ..where((m) => m.id.equals(widget.mealId)))
          .write(
        const MealCompanion(
          prepared: d.Value(false),
          timeConsumed: d.Value(null),
        ),
      );
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

    setState(() {
      _prepared = newValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _toggle,
      child: Container(
        padding: const EdgeInsets.all(12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Icon(
            _prepared
                ? Icons.check_circle_outline
                : Icons.circle_outlined,
            key: ValueKey("prep_${widget.mealId}_$_prepared"),
            color: Colors.white54,
            size: 26,
          ),
        ),
      ),
    );
  }
}
*/
// Ende der PlanningCalendar-Klasse
