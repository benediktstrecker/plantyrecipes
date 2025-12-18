// lib/widgets/ingredient_plan_assign_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' as d;

import '../db/app_db.dart';
import '../db/db_singleton.dart';

/// Ein Eintrag pro Tag – wird am Ende in meal gespeichert.
class IngredientDayEntry {
  DateTime date;
  int categoryId;
  double amount;
  String unitCode;

  IngredientDayEntry({
    required this.date,
    required this.categoryId,
    required this.amount,
    required this.unitCode,
  });
}

/// ===============================================================
/// INGREDIENT PLAN ASSIGN DIALOG – EXAKT wie MealPlanDialog!!!
/// ===============================================================
class IngredientPlanAssignDialog extends StatefulWidget {
  final List<DateTime> pickedDays;
  final Ingredient ingredient;
  final List<Unit> units;
  final int? defaultMealCategoryId;

  const IngredientPlanAssignDialog({
    super.key,
    required this.pickedDays,
    required this.ingredient,
    required this.units,
    required this.defaultMealCategoryId,
  });

  @override
  State<IngredientPlanAssignDialog> createState() =>
      _IngredientPlanAssignDialogState();
}

class _IngredientPlanAssignDialogState
    extends State<IngredientPlanAssignDialog> {
  late Future<List<MealCategoryData>> _catsFuture;

  // Globale Werte (oben)
  late int _mainCategoryId; // nie null
  double _globalAmount = 1;
  String _globalUnit = "g";

  final TextEditingController _amountCtrl = TextEditingController();
  final Map<DateTime, bool> _dropdownEnabled = {};

  // Lokale Entries
  late List<DateTime> _days;
  final Map<DateTime, double> _amountPerDay = {};
  final Map<DateTime, int> _categoryPerDay = {};
  final Map<DateTime, String> _unitPerDay = {};

  @override
void initState() {
  super.initState();
  init();
}

Future<void> init() async {

  await _ensureKgGExists();  // WARTEN! Keine Race Condition mehr

  _days = List.from(widget.pickedDays);

  for (final d in _days) {
    _dropdownEnabled[d] = false;
  }

  final cats = await (appDb.select(appDb.mealCategory)
      ..orderBy([(t) => d.OrderingTerm(expression: t.id)]))
  .get();

_catsFuture = Future.value(cats);

// ✅ EINMAL sauber festlegen
_mainCategoryId =
    widget.defaultMealCategoryId ??
    (cats.isNotEmpty ? cats.first.id : 1);

  _globalAmount = 1;
  _amountCtrl.text = "1";
  _globalUnit = _bestGuessUnit();

  for (final d in _days) {
    _amountPerDay[d] = _globalAmount;
    _categoryPerDay[d] = _mainCategoryId;
    _unitPerDay[d] = _globalUnit;
  }

  if (mounted) setState(() {});
}


  Future<void> _ensureKgGExists() async {
  final codes = widget.units.map((e) => e.code).toSet();

  // Alle Units aus DB
  final allUnits = await appDb.select(appDb.units).get();

  final g = allUnits.where((u) => u.code == "g").firstOrNull;
  final kg = allUnits.where((u) => u.code == "kg").firstOrNull;

  if (g != null && !codes.contains("g")) {
    widget.units.insert(0, g);
  }
  if (kg != null && !codes.contains("kg")) {
    widget.units.insert(0, kg);
  }
}





  String _bestGuessUnit() {
    // Falls ingredient_units Mengen hat, nimm die häufigste
    final freq = <String, int>{};
    for (final u in widget.units) {
      freq[u.code] = (freq[u.code] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  void _removeDay(DateTime d) {
    setState(() {
      _days.remove(d);
      _amountPerDay.remove(d);
      _categoryPerDay.remove(d);
      _unitPerDay.remove(d);
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
    final date =
        "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.";
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
          title: Text(
            "${widget.ingredient.name}",
            style: const TextStyle(color: Colors.white),
          ),

          content: SizedBox(
            width: double.maxFinite,
            child: snap.hasData
                ? ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.75,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ========================================
                          // NEUE ZEILE: Menge + Einheit
                          // ========================================
                          const Text("Menge und Einheit auswählen:",
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 6),
                          _buildAmountUnitRow(),

                          const SizedBox(height: 20),
                          
                          // ================================
                          // MAIN DROPDOWN (Wie MealDialog)
                          // ================================
                          const Text("Zeitraum auswählen:",
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 6),

                          _buildMainDropdown(cats),

                          const SizedBox(height: 10),
                          Divider(
                            color: Colors.white24,
                            thickness: 1,
                            ),
                          const SizedBox(height: 10),

                          // ========================================
                          // DAY ROWS
                          // ========================================
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

          // ================================================
          // ACTIONS
          // ================================================
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Abbrechen", style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                final result = _days
                    .map(
                      (d) => IngredientDayEntry(
                        date: d,
                        categoryId: _categoryPerDay[d] ?? _mainCategoryId,
                        amount: _amountPerDay[d] ?? _globalAmount,
                        unitCode: _unitPerDay[d] ?? _globalUnit,
                      ),
                    )
                    .toList();

                Navigator.pop(context, result);
              },
              child: const Text("Weiter", style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        );
      },
    );
  }

  // ======================================================
  // MAIN DROPDOWN (wie MealPlanAssignDialog)
  // ======================================================
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
              child: Text(c.name, style: const TextStyle(color: Colors.white)),
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

  // ======================================================
  // NEUE ZWEITE ZEILE: Menge + Einheit
  // ======================================================
  Widget _buildAmountUnitRow() {
  return Row(
    children: [
      Expanded(
        flex: 2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              // ----------- MINUS -----------
              Expanded(
                flex: 1,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: _globalAmount <= 1
                      ? const Icon(Icons.delete_forever, color: Colors.redAccent)
                      : const Icon(Icons.remove_circle_outline, color: Colors.white70),
                  onPressed: () {
                    setState(() {
                      if (_globalAmount <= 1) {
                        _globalAmount = 1;
                        _amountCtrl.text = "1";
                      } else {
                        _globalAmount--;
                        _amountCtrl.text = _globalAmount.toStringAsFixed(0);
                      }
                      for (final d in _days) {
                        _amountPerDay[d] = _globalAmount;
                      }
                    });
                  },
                ),
              ),

              // ----------- EDITIERBARES FELD (JETZT BREITER) -----------
              Expanded(
                flex: 3,   // <<< WICHTIG: Breite ×3
                child: TextField(
                  controller: _amountCtrl,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: const InputDecoration(border: InputBorder.none),
                  onChanged: (v) {
                    final parsed = double.tryParse(v) ?? 1;
                    setState(() {
                      _globalAmount = parsed.clamp(1, 99999);
                      for (final d in _days) {
                        _amountPerDay[d] = _globalAmount;
                      }
                    });
                  },
                ),
              ),

              // ----------- PLUS -----------
              Expanded(
                flex: 1,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                  onPressed: () {
                    setState(() {
                      _globalAmount++;
                      _amountCtrl.text = _globalAmount.toStringAsFixed(0);
                      for (final d in _days) {
                        _amountPerDay[d] = _globalAmount;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      const SizedBox(width: 14),

      // ----------- UNIT DROPDOWN -----------
      Expanded(
        flex: 2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white30),
            borderRadius: BorderRadius.circular(10),
            color: Colors.black,
          ),
          child: DropdownButton<String>(
            value: _globalUnit,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            dropdownColor: Colors.black,
            style: const TextStyle(color: Colors.white),
            items: [
              for (final u in widget.units)
                DropdownMenuItem(
                  value: u.code,
                  child: Text(
                    (_globalAmount <= 1
                        ? u.label
                        : (u.plural?.isNotEmpty ?? false ? u.plural! : u.label)),
                    style: const TextStyle(color: Colors.white),
                  ),
                )
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _globalUnit = v;
                for (final d in _days) {
                  _unitPerDay[d] = v;
                }
              });
            },
          ),
        ),
      ),
    ],
  );
}



  // ======================================================
  // DAY ROW – EXAKT wie MealPlanAssignDialog
  // ======================================================
    Widget _buildDayRow(DateTime day, List<MealCategoryData> cats) {
    final amount = _amountPerDay[day] ?? _globalAmount;
    final assignedCat = _categoryPerDay[day] ?? _mainCategoryId;
    final unit = _unitPerDay[day] ?? _globalUnit;


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
          
          // -------- DATUM ----------
          Text(
            _format(day),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 10),

          // -------- ROW ----------
          Row(
            children: [

              // -------- MINUS / DELETE ----------
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: amount <= 1
                    ? const Icon(Icons.delete_forever, color: Colors.redAccent)
                    : const Icon(Icons.remove_circle_outline, color: Colors.white70),
                onPressed: () {
                  if (amount <= 1) {
                    _removeDay(day);
                  } else {
                    setState(() => _amountPerDay[day] = amount - 1);
                  }
                },
              ),

              // -------- AMOUNT ----------
              Text(
                amount.toStringAsFixed(0),
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),

              // -------- PLUS ----------
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                onPressed: () {
                  setState(() => _amountPerDay[day] = amount + 1);
                },
              ),

              const SizedBox(width: 10),

              // -------- CATEGORY DROPDOWN ----------
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => _dropdownEnabled[day] = true);
                  },
                  child: AbsorbPointer(
                    absorbing: !_dropdownEnabled[day]!,
                    child: Opacity(
                      opacity: _dropdownEnabled[day]! ? 1.0 : 0.4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
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
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          style: const TextStyle(color: Colors.white),
                          items: [
                            for (final c in cats)
                              DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                          ],
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() => _categoryPerDay[day] = val);
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
