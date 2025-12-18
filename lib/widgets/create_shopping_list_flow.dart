// lib/widgets/create_shopping_list_flow.dart
//-------------------------------------------------------
// ZENTRALER FLOW zum Erstellen einer neuen Einkaufsliste
// Aufrufbar aus jedem Screen:
//    final newListId = await CreateShoppingListFlow.start(context);
//-------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';

class CreateShoppingListFlow {
  //-------------------------------------------------------
  // ÖFFENTLICHE STATISCHE FUNKTION
  // Die du überall in der App nutzen kannst!
  //-------------------------------------------------------
  static Future<int?> start(BuildContext context) async {
    final date = await _stepSelectDate(context);
    if (date == null) return null;

    final market = await _stepSelectMarket(context);
    if (market == null) return null;

    final id = await _stepCreateList(date, market.id);
    return id;
  }

  //-------------------------------------------------------
  // SCHRITT 1: Datum wählen
  //-------------------------------------------------------
  static Future<DateTime?> _stepSelectDate(BuildContext context) async {
    DateTime selectedDate = DateTime.now();

    return showDialog<DateTime>(
      context: context,
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
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 365),
                    ),
                    lastDate: DateTime.now().add(
                      const Duration(days: 365),
                    ),
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
                  child: const Text("Weiter",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  //-------------------------------------------------------
  // SCHRITT 2: Markt auswählen
  //-------------------------------------------------------
  static Future<Market?> _stepSelectMarket(BuildContext context) async {
    final markets = await (appDb.select(appDb.markets)
          ..orderBy([(m) => d.OrderingTerm(expression: m.id)]))
        .get();

    if (markets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Keine Märkte vorhanden.")),
      );
      return null;
    }

    // Lieblingsmarkt → sonst erster
    Market? defaultMarket;
    final fav = markets.where((m) => m.favorite == true).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    defaultMarket = fav.isNotEmpty ? fav.first : markets.first;

    return showDialog<Market>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text(
            "Markt wählen",
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: markets.length,
              itemBuilder: (context, index) {
                final m = markets[index];
                return GestureDetector(
                  onTap: () => Navigator.pop(ctx, m),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        // Market Bild
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: _parseHexColor(m.color),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              m.picture ??
                                  "assets/images/shop/placeholder.png",
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Name
                        Expanded(
                          child: Text(
                            m.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  //-------------------------------------------------------
  // SCHRITT 3: Liste erstellen
  //-------------------------------------------------------
  static Future<int> _stepCreateList(DateTime date, int marketId) async {
    const weekdayNames = [
      "",
      "Montag",
      "Dienstag",
      "Mittwoch",
      "Donnerstag",
      "Freitag",
      "Samstag",
      "Sonntag",
    ];

    final name =
        "${weekdayNames[date.weekday]}, ${date.day.toString().padLeft(2, '0')}."
        "${date.month.toString().padLeft(2, '0')}.";

    final newId = await appDb.into(appDb.shoppingList).insert(
          ShoppingListCompanion.insert(
            name: name,
            dateCreated: d.Value(DateTime.now()),
            lastEdited: d.Value(DateTime.now()),
            marketId: d.Value(marketId),
            dateShopping: d.Value(date),
          ),
        );

    return newId;
  }

  //-------------------------------------------------------
  // Hilfsfunktion Farbumwandlung
  //-------------------------------------------------------
  static Color _parseHexColor(String? hex) {
    if (hex == null) return Colors.grey;
    String clean = hex.replaceAll("#", "");
    if (clean.length == 6) clean = "FF$clean";
    final intVal = int.tryParse(clean, radix: 16);
    return intVal != null ? Color(intVal) : Colors.grey;
  }
}
