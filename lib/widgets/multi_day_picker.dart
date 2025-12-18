//lib/widgets/multi_day_picker.dart
import 'package:flutter/material.dart';

/// ============================================================
/// MultiDayPicker – stellt 3 verschiedene Mehrfach-Datumsauswahl-Dialoge bereit
/// ============================================================
class MultiDayPicker {
  // ------------------------------------------------------------
  // 1) BASIC MULTI DATE PICKER (CalendarDatePicker)
  // ------------------------------------------------------------
  static Future<List<DateTime>?> showBasic({
    required BuildContext context,
    required int portionLimit,
  }) async {
    DateTime selectedDate = DateTime.now();
    List<DateTime> selectedDates = [];

    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    void toggle(DateTime d, void Function(void Function()) setStateDialog) {
      if (!selectedDates.any((x) => isSameDay(x, d))) {
        if (selectedDates.length >= portionLimit) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Nur so viele Tage auswählbar wie Portionen!"),
            ),
          );
          return;
        }
        selectedDates.add(d);
      } else {
        selectedDates.removeWhere((x) => isSameDay(x, d));
      }
      setStateDialog(() {});
    }

    return showDialog<List<DateTime>>(
      context: Navigator.of(context, rootNavigator: true).context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (ctx, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.black87,
            title: const Text("Datum wählen",
                style: TextStyle(color: Colors.white, fontSize: 20)),
            content: SizedBox(
              width: double.maxFinite,
              child: Theme(
                data: Theme.of(ctx).copyWith(
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
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  currentDate: DateTime.now(),
                  onDateChanged: (d) => toggle(d, setStateDialog),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Abbrechen",
                    style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, selectedDates),
                child: const Text("Weiter",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  // ------------------------------------------------------------
  // 2) SIMPLE MULTI DAY PICKER (Grid mit Drag-Range)
  // ------------------------------------------------------------
  static Future<List<DateTime>?> showGrid(
    BuildContext context, {
    int? portionLimit,
  }) {
    DateTime month = DateTime(DateTime.now().year, DateTime.now().month, 1);
    List<DateTime> selected = [];
    DateTime? dragStart;

    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    List<DateTime> daysInMonth(DateTime m) {
      final first = DateTime(m.year, m.month, 1);
      final last = DateTime(m.year, m.month + 1, 0);
      return List.generate(last.day, (i) => DateTime(m.year, m.month, i + 1));
    }

    return showDialog<List<DateTime>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          final days = daysInMonth(month);

          return AlertDialog(
            backgroundColor: Colors.black,
            title: const Text("Tage auswählen",
                style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Month header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.chevron_left, color: Colors.white),
                        onPressed: () => setState(() {
                          month = DateTime(month.year, month.month - 1, 1);
                        }),
                      ),
                      Text("${month.year} – ${month.month}",
                          style: const TextStyle(color: Colors.white)),
                      IconButton(
                        icon: const Icon(Icons.chevron_right,
                            color: Colors.white),
                        onPressed: () => setState(() {
                          month = DateTime(month.year, month.month + 1, 1);
                        }),
                      ),
                    ],
                  ),

                  // Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: days.length,
                    itemBuilder: (context, i) {
                      final d = days[i];
                      final selectedNow =
                          selected.any((x) => isSameDay(x, d));

                      return GestureDetector(
                        onTapDown: (_) {
                          dragStart = d;
                          setState(() {
                            if (selectedNow) {
                              selected.removeWhere((x) => isSameDay(x, d));
                            } else {
                              if (portionLimit != null &&
                                  selected.length >= portionLimit) return;
                              selected.add(d);
                            }
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: selectedNow
                                ? Colors.green.shade800
                                : Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selectedNow
                                  ? Colors.greenAccent
                                  : Colors.white24,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "${d.day}",
                            style: TextStyle(
                              color: selectedNow
                                  ? Colors.white
                                  : Colors.white70,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Abbrechen",
                    style: TextStyle(color: Colors.white)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, selected),
                child: const Text("Weiter",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  // ------------------------------------------------------------
  // 3) MEAL-PLAN MULTI DAY DIALOG (mit Limit + Drag Range + Month Grid)
  // ------------------------------------------------------------
  static Future<List<DateTime>?> showMealPlan(
    BuildContext context, {
    required int portionLimit,
  }) async {
    final now = DateTime.now();
    final firstAllowed = now.subtract(const Duration(days: 365));
    final lastAllowed = now.add(const Duration(days: 365));

    DateTime visibleMonth = DateTime(now.year, now.month);
    List<DateTime> selectedDates = [];
    DateTime? dragStart;

    bool isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    List<DateTime> buildRange(DateTime a, DateTime b) {
      final start = a.isBefore(b) ? a : b;
      final end = a.isBefore(b) ? b : a;
      return List.generate(
        end.difference(start).inDays + 1,
        (i) => DateTime(start.year, start.month, start.day + i),
      );
    }

    List<DateTime?> buildMonthCells(DateTime month) {
      final firstOfMonth = DateTime(month.year, month.month, 1);
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      final startOffset = firstOfMonth.weekday - 1;

      final cells = List<DateTime?>.filled(42, null);
      for (int day = 1; day <= daysInMonth; day++) {
        final index = startOffset + (day - 1);
        if (index >= 0 && index < 42) {
          cells[index] = DateTime(month.year, month.month, day);
        }
      }
      return cells;
    }

    return showDialog<List<DateTime>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(builder: (ctx, setState) {
          final cells = buildMonthCells(visibleMonth);

          const weekdayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

          Widget buildGrid() {
            return LayoutBuilder(
              builder: (gridCtx, constraints) {
                final width = constraints.maxWidth;
                const rows = 6;
                final cellWidth = width / 7;
                final cellHeight = constraints.maxHeight / rows;

                int? hitTestIndex(Offset pos) {
                  if (pos.dx < 0 || pos.dy < 0) return null;
                  final col = (pos.dx ~/ cellWidth);
                  final row = (pos.dy ~/ cellHeight);
                  if (col < 0 || col > 6 || row < 0 || row > 5) return null;
                  final idx = row * 7 + col;
                  if (idx < 0 || idx >= cells.length) return null;
                  return idx;
                }

                // DRAG handling
                void handleDrag(Offset localPos) {
                  final idx = hitTestIndex(localPos);
                  if (idx == null) return;

                  final day = cells[idx];
                  if (day == null) return;
                  if (day.isBefore(firstAllowed) || day.isAfter(lastAllowed)) return;

                  if (dragStart == null) {
                    dragStart = day;
                  }

                  final range = buildRange(dragStart!, day);

                  if (range.length <= portionLimit) {
                    selectedDates = range;
                    setState(() {});
                  }
                }

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,

                  // --- DRAG RANGE ---
                  onPanStart: (details) => handleDrag(details.localPosition),
                  onPanUpdate: (details) => handleDrag(details.localPosition),
                  onPanEnd: (_) => dragStart = null,

                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                    ),
                    itemCount: cells.length,
                    itemBuilder: (cellCtx, index) {
                      final day = cells[index];
                      if (day == null) return const SizedBox.shrink();

                      final disabled =
                          day.isBefore(firstAllowed) || day.isAfter(lastAllowed);

                      final selectedNow =
                          selectedDates.any((d) => isSameDay(d, day));
                      final isToday = isSameDay(day, now);

                      Color textColor;
                      if (disabled) {
                        textColor = Colors.white24;
                      } else if (selectedNow) {
                        textColor = Colors.white;
                      } else if (isToday) {
                        textColor = Colors.greenAccent;
                      } else {
                        textColor = Colors.white70;
                      }

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,

                        // --- EINZELTAP ---
                        onTap: disabled
                            ? null
                            : () {
                                if (selectedNow) {
                                  selectedDates.removeWhere((d) => isSameDay(d, day));
                                } else {
                                  if (selectedDates.length >= portionLimit) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "Nicht mehr Tage als Portionen auswählbar."),
                                      ),
                                    );
                                    return;
                                  }
                                  selectedDates.add(day);
                                }
                                setState(() {});
                              },

                        child: Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selectedNow ? Colors.green : Colors.transparent,
                              border: isToday && !selectedNow
                                  ? Border.all(color: Colors.greenAccent, width: 1.2)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "${day.day}",
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: selectedNow
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }




          return AlertDialog(
            backgroundColor: Colors.black87,
            title: const Text(
              "Tage wählen",
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Monat-Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left,
                            color: Colors.white),
                        onPressed: () => setState(() {
                          visibleMonth = DateTime(
                              visibleMonth.year, visibleMonth.month - 1);
                        }),
                      ),
                      Text(
                        '${visibleMonth.year}-${visibleMonth.month.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right,
                            color: Colors.white),
                        onPressed: () => setState(() {
                          visibleMonth = DateTime(
                              visibleMonth.year, visibleMonth.month + 1);
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: weekdayLabels
                        .map(
                          (w) => Expanded(
                            child: Center(
                              child:
                                  Text(w, style: const TextStyle(color: Colors.white54)),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 6 * 40,
                    child: buildGrid(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text(
                  "Abbrechen",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, selectedDates),
                child: const Text(
                  "Weiter",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        });
      },
    );
  }
}
