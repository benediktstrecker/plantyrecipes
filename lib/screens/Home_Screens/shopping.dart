// lib/screens/Home_Screens/shopping.dart
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/utils/easy_swipe_nav.dart';
import 'package:planty_flutter_starter/main.dart' show routeObserver;
import 'package:planty_flutter_starter/design/drawer.dart';
import 'package:planty_flutter_starter/utils/number_formatter.dart';

// DB
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

// Screens
import 'package:planty_flutter_starter/screens/Home_Screens/recipes.dart'
    as screen_rec;
import 'package:planty_flutter_starter/screens/Home_Screens/ingredients.dart'
    as screen_ing;
import 'package:planty_flutter_starter/screens/Home_Screens/nutrition.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/meals.dart';

// Produktliste
import 'package:planty_flutter_starter/screens/shopping/products_list_screen.dart';

// Shopping
import 'package:planty_flutter_starter/screens/shopping/shopping_list_overview.dart';
import 'package:planty_flutter_starter/screens/shopping/shopping_list_history.dart';

import 'package:planty_flutter_starter/screens/shopping/stock.dart';

import 'package:planty_flutter_starter/widgets/create_shopping_list_flow.dart';


Color _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return Colors.white;

  String h = hex.replaceAll('#', '');

  // 6-stellig = RGB → Alpha hinzufügen
  if (h.length == 6) {
    h = 'FF$h';
  }

  // 8-stellig = AARRGGBB → NICHT ändern

  // Jetzt immer als 0xAARRGGBB interpretieren
  return Color(int.parse('0x$h'));
}



class Shopping extends StatefulWidget {
  const Shopping({super.key});

  @override
  State<Shopping> createState() => _ShoppingState();
}

class _ShoppingState extends State<Shopping> 
    with EasySwipeNav, RouteAware {

  int _selectedIndex = 1; // 1 = Einkauf
  int _pageIndex = 0;

  List<ShoppingListData> _shoppingLists = [];
  int? _selectedListId;
  bool _loading = true;

  @override
  int get currentIndex => _selectedIndex;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  // WICHTIG: RouteAware → wenn wir von Overview zurückkommen, neu laden!
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    // Diese Seite wurde erneut sichtbar → Listen aktualisieren
    _loadLists();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // NUR NICHT erledigte Listen laden
  // ---------------------------------------------------------------------------
  Future<void> _loadLists() async {
    final sl = appDb.shoppingList;

    final lists = await (appDb.select(sl)
          ..where((tbl) => tbl.done.equals(false)))
        .get();

    lists.sort((a, b) {
  final aDate = a.dateCreated ?? DateTime(1970);
  final bDate = b.dateCreated ?? DateTime(1970);
  return bDate.compareTo(aDate);
});


    setState(() {
      _shoppingLists = lists;
      _selectedListId = lists.isNotEmpty ? lists.first.id : null;
      _loading = false;
    });
  }

  Stream<List<ShoppingListData>> _watchRecentOpenLists() {
  final sl = appDb.shoppingList;

  final q = appDb.select(sl)
    ..where((t) => t.done.equals(false))
    ..orderBy([
      (t) => d.OrderingTerm(expression: t.dateCreated, mode: d.OrderingMode.desc)
    ])
    ..limit(3);

  return q.watch();
}


  // ===============================================================
// FLOW: Neue Einkaufsliste erstellen (wie in ShoppingListOverview)
// ===============================================================
Future<int?> _createShoppingListFlow() async {
  // --------------------------------------
  // Schritt 1: Datum auswählen
  // --------------------------------------
  DateTime selectedDate = DateTime.now();

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
                child: const Text(
                  "Abbrechen",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, selectedDate),
                child: const Text(
                  "Weiter",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  if (pickedDate == null) return null;
  final DateTime date = pickedDate;

  // --------------------------------------
  // Schritt 2: Markt auswählen
  // --------------------------------------
  final markets = await (appDb.select(appDb.markets)
        ..orderBy([(m) => d.OrderingTerm(expression: m.id)]))
      .get();

  if (markets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Keine Märkte vorhanden.")),
    );
    return null;
  }

  Market? defaultMarket;
  final fav = markets.where((m) => m.favorite == true).toList()
    ..sort((a, b) => a.id.compareTo(b.id));

  defaultMarket = fav.isNotEmpty ? fav.first : markets.first;

  final chosenMarket = await showDialog<Market>(
    context: Navigator.of(context, rootNavigator: true).context,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
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
                            m.picture ?? "assets/images/shop/placeholder.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
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

  final Market market = chosenMarket ?? defaultMarket;

  // --------------------------------------
  // Schritt 3: Neue Liste erstellen
  // --------------------------------------
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
          marketId: d.Value(market.id),
          dateShopping: d.Value(date),
        ),
      );

  return newId;
}

  

  // Navigation zwischen offenen Listen
  void _nextList() {
    if (_shoppingLists.isEmpty) return;
    final i = _shoppingLists.indexWhere((l) => l.id == _selectedListId);
    final ni = (i + 1) % _shoppingLists.length;
    setState(() {
      _selectedListId = _shoppingLists[ni].id;
      _pageIndex = 0;
    });
  }

  void _prevList() {
    if (_shoppingLists.isEmpty) return;
    final i = _shoppingLists.indexWhere((l) => l.id == _selectedListId);
    final ni = (i - 1 + _shoppingLists.length) % _shoppingLists.length;
    setState(() {
      _selectedListId = _shoppingLists[ni].id;
      _pageIndex = 0;
    });
  }

  Future<List<ShoppingListData>> _loadRecentLists() async {
  final sl = appDb.shoppingList;

  final lists = await (appDb.select(sl)
        ..orderBy([
          (t) => d.OrderingTerm(expression: t.dateCreated, mode: d.OrderingMode.desc)
        ])
        ..limit(3))
      .get();

  return lists;
}

Future<List<ShoppingListData>> _loadRecentOpenLists() async {
  final sl = appDb.shoppingList;

  final lists = await (appDb.select(sl)
        ..where((t) => t.done.equals(false))
        ..orderBy([
          (t) => d.OrderingTerm(expression: t.dateCreated, mode: d.OrderingMode.desc)
        ])
        ..limit(3))
      .get();

  return lists;
}

Future<Market?> _loadMarketForList(int? marketId) async {
  if (marketId == null) return null;
  final q = appDb.select(appDb.markets)..where((m) => m.id.equals(marketId));
  return q.getSingleOrNull();
}

int? _latestListIdFrom(List<ShoppingListData> lists) {
  if (lists.isEmpty) return null;
  lists.sort((a, b) {
    final aDate = a.dateCreated ?? DateTime(1970);
    final bDate = b.dateCreated ?? DateTime(1970);
    return bDate.compareTo(aDate);
  });
  return lists.first.id;
}

Future<int> _countItemsInList(int listId) async {
  final sli = appDb.shoppingListIngredient;
  final rows = await (appDb.select(sli)
        ..where((t) => t.shoppingListId.equals(listId)))
      .get();
  return rows.length;
}

// Statistik-Methoden

Future<double> sumForMonth(int year, int month) async {
  final sl = appDb.shoppingList;
  final sli = appDb.shoppingListIngredient;

  final start = DateTime(year, month, 1);
  final end = DateTime(year, month + 1, 1);

  // Alle LISTEN des Monats (nach Abschluss)
  final lists = await (appDb.select(sl)
        ..where((t) =>
            t.done.equals(true) &
            t.dateShopping.isNotNull() &
            t.dateShopping.isBiggerOrEqualValue(start) &
            t.dateShopping.isSmallerThanValue(end)))
      .get();

  if (lists.isEmpty) return 0;

  final listIds = lists.map((e) => e.id).toList();

  final rows = await (appDb.select(sli)
        ..where((t) => t.shoppingListId.isIn(listIds)))
      .get();

  return rows.fold<double>(
      0.0, (sum, r) => sum + (r.priceActual ?? 0.0));
}

Future<Map<String, double>> loadRegionalityShare() async {
  final sli = appDb.shoppingListIngredient;
  final c = appDb.countries;

  final rows = await (appDb.select(sli)
        ..where((t) =>
            t.bought.equals(true) &         // nur gekaufte
            t.countryId.isNotNull()))       // nur gültige Länder
      .join([
        d.innerJoin(c, c.id.equalsExp(sli.countryId)),
      ])
      .get();

  double de = 0;
  double eu = 0;
  double rest = 0;

  for (final row in rows) {
    final s = row.readTable(sli);
    final country = row.readTable(c);

    final price = s.priceActual ?? 0.0;

    if (s.countryId == 33) {
      de += price;
    } else if ((country.continent ?? "").toLowerCase() == "europa") {
      eu += price;
    } else {
      rest += price;
    }
  }

  final total = de + eu + rest;
  if (total == 0) return {"DE": 0, "EU": 0, "REST": 0};

  return {
    "DE": de / total,
    "EU": eu / total,
    "REST": rest / total,
  };
}




Future<Map<String, double>> loadSeasonalityShare() async {
  final sli = appDb.shoppingListIngredient;
  final sl = appDb.shoppingList;
  final ingSeas = appDb.ingredientSeasonality;

  // ---------------------------------------------------------
  // 1) Alle SLI holen, die gekauft wurden (bought = true)
  // ---------------------------------------------------------
  final sliRows = await (appDb.select(sli)
        ..where((t) => t.bought.equals(true)))
      .get();

  if (sliRows.isEmpty) return {};

  // ---------------------------------------------------------
  // 2) Alle ShoppingLists holen, um später das Datum zuzuordnen
  // ---------------------------------------------------------
  final lists = await (appDb.select(sl).get());

  // ---------------------------------------------------------
  // 3) Zähler für Seasonality-Kategorien
  // Keys sind später Strings ("1", "2", "3", "4", ...)
  // ---------------------------------------------------------
  final Map<int, int> counter = {};

  // ---------------------------------------------------------
  // 4) Für jeden SLI das Seasonality-Label bestimmen
  // ---------------------------------------------------------
  for (final row in sliRows) {
    final ingredientId = row.ingredientIdActual;
    if (ingredientId == null) continue;

    // ----- Liste finden (Null-safe!) -----
    final matching = lists.where((l) => l.id == row.shoppingListId);
    if (matching.isEmpty) continue;

    final list = matching.first;
    final date = list.dateShopping ?? list.lastEdited;
    if (date == null) continue;

    final month = date.month;

    // ----- Seasonality lookup -----
    final entry = await (appDb.select(ingSeas)
          ..where((t) =>
              t.ingredientsId.equals(ingredientId) &
              t.monthsId.equals(month)))
        .getSingleOrNull();

    if (entry == null) continue;

    counter[entry.seasonalityId] =
        (counter[entry.seasonalityId] ?? 0) + 1;
  }

  if (counter.isEmpty) return {};

  // ---------------------------------------------------------
  // 5) Relative Anteile berechnen (0.0 – 1.0)
  // ---------------------------------------------------------
  final total = counter.values.fold<int>(0, (a, b) => a + b);

  return counter.map((key, value) {
    return MapEntry(key.toString(), value / total);
  });
}


Future<Map<String, Color>> loadSeasonalityColors() async {
  final rows = await appDb.select(appDb.seasonality).get();

  final Map<String, Color> out = {};

  for (final s in rows) {
    out[s.id.toString()] = _parseColor(s.color);
  }

  return out;
}






Future<Map<String, double>> loadAutarkyShare() async {
  // später implementieren
  return {"self": 0, "other": 0};
}

Future<Map<String, dynamic>> _loadStatisticsData() async {
  final now = DateTime.now();

  final currMonth = now.month;
  final currYear = now.year;

  final prevMonth = currMonth == 1 ? 12 : currMonth - 1;
  final prevYear = currMonth == 1 ? currYear - 1 : currYear;

  final currValue = await sumForMonth(currYear, currMonth);
  final prevValue = await sumForMonth(prevYear, prevMonth);

  final regionality = await loadRegionalityShare();
  final seasonality = await loadSeasonalityShare(); // placeholder
  final autarky = await loadAutarkyShare();         // placeholder

  return {
    "currLabel": "${currMonth.toString().padLeft(2, '0')}/$currYear",
    "prevLabel": "${prevMonth.toString().padLeft(2, '0')}/$prevYear",
    "currValue": currValue,
    "prevValue": prevValue,
    "maxValue": (currValue > prevValue) ? currValue : prevValue,

    "regionality": regionality,
    "seasonality": seasonality,
    "autarky": autarky,
  };
}

Future<Map<int, double>> sumForMonthByMarket(int year, int month) async {
  final sl = appDb.shoppingList;
  final sli = appDb.shoppingListIngredient;

  final start = DateTime(year, month, 1);
  final end = DateTime(year, month + 1, 1);

  // Listen des Monats (done + dateShopping im Zeitraum)
  final lists = await (appDb.select(sl)
        ..where((t) =>
            t.done.equals(true) &
            t.dateShopping.isNotNull() &
            t.dateShopping.isBiggerOrEqualValue(start) &
            t.dateShopping.isSmallerThanValue(end)))
      .get();

  if (lists.isEmpty) return {};

  final listIds = lists.map((e) => e.id).toList();

  // Alle SLI der Listen holen
  final rows = await (appDb.select(sli)
        ..where((t) => t.shoppingListId.isIn(listIds)))
      .get();

  final Map<int, double> result = {};

  // Summe nach market_id gruppieren
  for (final row in rows) {
    final list = lists.firstWhere((e) => e.id == row.shoppingListId);
    final marketId = list.marketId;

    if (marketId == null) continue;

    final price = row.priceActual ?? 0.0;
    result[marketId] = (result[marketId] ?? 0.0) + price;
  }

  return result;
}

Widget _buildRegionalityDonut() {
  return FutureBuilder<Map<String, double>>(
    future: loadRegionalityShare(),
    builder: (context, snap) {
      final share = snap.data ?? {"DE": 0, "EU": 0, "REST": 0};

      if (share == null || share.isEmpty) {
        return const DonutWithLegend(
          title: "Regionalität",
          values: [1.0],
          colors: [Colors.white24],
          labels: [],
          percentIndices: [0],
        );
      }

      return DonutWithLegend(
        title: "Regionalität",
        values: [share["DE"]!, share["EU"]!, share["REST"]!],
        colors: [
          const Color(0xFF245225),
          const Color(0xFFFFF59D),
          const Color(0xFFFFCCBC),
        ],
        labels: [],
        percentIndices: const [0],
      );

    },
  );
}

Widget _buildSeasonalityDonut() {
  return FutureBuilder<Map<String, double>>(
    future: loadSeasonalityShare(),
    builder: (context, snap) {
      final share = snap.data;
      if (share == null || share.isEmpty) {
        return const DonutWithLegend(
          title: "Saisonalität",
          values: [1.0],
          colors: [Colors.white24],
          labels: [],
          percentIndices: [0],
        );
      }

      return FutureBuilder<Map<String, Color>>(
        future: loadSeasonalityColors(),
        builder: (context, colSnap) {
          final colorMap = colSnap.data ?? {};

          final keys = share.keys.toList()..sort((a, b) {
            final ia = int.tryParse(a) ?? 9999;
            final ib = int.tryParse(b) ?? 9999;
            return ia.compareTo(ib);
          });

          final values = keys.map((k) => share[k] ?? 0.0).toList();
          final colors =
              keys.map((k) => colorMap[k] ?? Colors.white).toList();

          final percentIndices = <int>[];
          for (int i = 0; i < keys.length; i++) {
            final id = int.tryParse(keys[i]) ?? 9999;
            if (id <= 3) percentIndices.add(i);
          }
          if (percentIndices.isEmpty) {
            for (int i = 0; i < keys.length; i++) {
              percentIndices.add(i);
            }
          }

          return DonutWithLegend(
            title: "Saisonalität",
            values: values,
            colors: colors,
            labels: const [],
            percentIndices: percentIndices,
          );
        },
      );
    },
  );
}

Widget _buildAutarkyDonut() {
  return const DonutWithLegend(
    title: "Autarkie",
    values: [1.0],
    colors: [Colors.white],
    labels: [],
    percentIndices: [0],
  );
}

 // ---------------------------------------------------------------------------
  // Lager-Kram
  // ---------------------------------------------------------------------------


// HELFER: Einheit in Gramm / ml umrechnen

Future<double> _convertToBaseUnit(int ingredientId, double amount, String? unitCode) async {
  if (amount == 0 || unitCode == null || unitCode.isEmpty) return amount;

  // Units lookup
  final u = await (appDb.select(appDb.units)
        ..where((t) => t.code.equals(unitCode)))
      .getSingleOrNull();

  if (u != null && (u.categorie == "Masse" || u.categorie == "Volumen")) {
    return amount * (u.baseFactor ?? 1.0); // g oder ml
  }

  // IngredientUnit fallback
  final iu = await (appDb.select(appDb.ingredientUnits)
        ..where((t) => t.ingredientId.equals(ingredientId))
        ..where((t) => t.unitCode.equals(unitCode)))
      .getSingleOrNull();

  if (iu != null) return amount * iu.amount;

  return amount;
}


// ---------------------------------------------------------------------------
// LADEN ALLER STOCK-INFORMATIONEN (Resthaltbarkeit + Bestand)
// ---------------------------------------------------------------------------
Future<Map<String, List<_IngredientStockInfo>>> _loadStockAlerts() async {
  final s = appDb.stock;
  final ing = appDb.ingredients;

  final stockRows = await (appDb.select(s)).get();
  if (stockRows.isEmpty) {
    return {"lowShelfLife": [], "needsRefill": []};
  }

  // --------------------------------------
  // A) Gruppierung nach ingredientId
  // --------------------------------------
  final Map<int, List<StockData>> perIng = {};
  for (final row in stockRows) {
    perIng.putIfAbsent(row.ingredientId, () => []);
    perIng[row.ingredientId]!.add(row);
  }

  // OUTPUT-Model
  final List<_IngredientStockInfo> lowShelfLife = [];
  final List<_IngredientStockInfo> needsRefill = [];

  // --------------------------------------
  // PRO INGREDIENT ALLE WERTE AGGREGIEREN
  // --------------------------------------
  for (final entry in perIng.entries) {
    final ingredientId = entry.key;
    final rows = entry.value;

    final ingRow = await (appDb.select(ing)
          ..where((t) => t.id.equals(ingredientId)))
        .getSingleOrNull();
    if (ingRow == null) continue;

    // -----------------------------
    // 1) Resthaltbarkeit bestimmen
    // -----------------------------
    // minimaler daysLeft = gültig für A1
    int? bestDaysLeft;
    DateTime now = DateTime.now();

    for (final r in rows) {
      if (r.dateEntry == null) continue;

      // IngredientStorage lookup
      final isRow = await (appDb.select(appDb.ingredientStorage)
            ..where((t) => t.ingredientId.equals(ingredientId))
            ..limit(1))
          .getSingleOrNull();

      if (isRow == null) continue;

      int maxDays;
      switch ((isRow.unitCode ?? "").toLowerCase()) {
        case "day":
        case "d":
        case "t":
        case "tage":
          maxDays = isRow.amount.floor();
          break;
        case "month":
        case "m":
          maxDays = (isRow.amount * 30).floor();
          break;
        case "year":
        case "y":
        case "jahr":
        case "j":
          maxDays = (isRow.amount * 365).floor();
          break;
        default:
          maxDays = isRow.amount.floor();
      }

      final diff = now.difference(r.dateEntry!).inDays;
      final remaining = maxDays - diff;

      if (bestDaysLeft == null || remaining < bestDaysLeft!) {
        bestDaysLeft = remaining;
      }
    }

    // -----------------------------
    // 2) Bestand berechnen (nur sign = 0)
    // -----------------------------
    double totalBase = 0;
    double totalBaseWithoutSign = 0;
    int positiveCount = 0;

    for (final r in rows) {
      if (r.amount == null) continue;

      final base = await _convertToBaseUnit(ingredientId, r.amount!, r.unitCode);

      if (r.sign == "0" || r.sign == null || r.sign == "+") {
        totalBase += base;
        totalBaseWithoutSign += base;
        positiveCount++;
      } else {
        totalBase -= base;
      }
    }

    double avg = positiveCount == 0 ? 0 : totalBaseWithoutSign / positiveCount;

    // -----------------------------
    // 3) Eintrag erzeugen
    // -----------------------------
    final info = _IngredientStockInfo(
      ingredientId: ingredientId,
      name: ingRow.name,
      picture: ingRow.picture,
      daysLeft: bestDaysLeft,
      totalBaseAmount: totalBase,
      averageBaseAmount: avg,
      storageCatId: ingRow.storagecatId,
    );

    // A) geringe Haltbarkeit
    if (bestDaysLeft != null) {
      lowShelfLife.add(info);
    }

    // B) Aufzufüllen
    if (ingRow.storagecatId == 1 && avg > 0 && totalBase < avg * 0.1) {
      needsRefill.add(info);
    }
  }

  // Sortieren + kürzen
  lowShelfLife.sort((a, b) => (a.daysLeft ?? 9999).compareTo(b.daysLeft ?? 9999));
  needsRefill.sort((a, b) => (a.totalBaseAmount).compareTo(b.totalBaseAmount));

  return {
    "lowShelfLife": lowShelfLife.take(5).toList(),
    "needsRefill": needsRefill.take(5).toList(),
  };
}

Widget _buildStockItemRow(_IngredientStockInfo info) {
  final img = info.picture?.isNotEmpty == true
      ? info.picture!
      : 'assets/images/placeholder.jpg';

  return Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          img,
          width: 26,
          height: 26,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          info.name,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}










  // ---------------------------------------------------------------------------
  // Zutaten-Stream
  // ---------------------------------------------------------------------------
  Stream<List<_ShoppingIngredientDisplay>> _watchIngredients(int id) {
    final sli = appDb.shoppingListIngredient;
    final ing = appDb.ingredients;
    final u = appDb.units;

    final q = (appDb.select(sli)
          ..where((t) => t.shoppingListId.equals(id)))
        .join([
      d.leftOuterJoin(ing, ing.id.equalsExp(sli.ingredientIdNominal)),
      d.leftOuterJoin(u, u.code.equalsExp(sli.ingredientUnitCodeNominal)),
    ]);

    return q.watch().map((rows) {
      return rows.map((row) {
        final s = row.readTable(sli);
        final ir = row.readTableOrNull(ing);
        final ur = row.readTableOrNull(u);

        return _ShoppingIngredientDisplay(
          id: s.id,
          shoppingListId: s.shoppingListId,
          recipeId: s.recipeId,
          recipePortionNumberId: s.recipePortionNumberId,
          ingredientId: s.ingredientIdNominal,
          amount: s.ingredientAmountNominal,
          unitCode: s.ingredientUnitCodeNominal,
          unitLabel: ur?.label,
          ingredientName: ir?.name ?? 'Unbekannt',
          basket: s.basket,
        );
      }).toList();
    });
  }

  Future<void> _toggleBasket(_ShoppingIngredientDisplay i) async {
    final sli = appDb.shoppingListIngredient;

    await (appDb.update(sli)..where((t) => t.id.equals(i.id))).write(
      ShoppingListIngredientCompanion(basket: d.Value(!i.basket)),
    );
  }

  // Zutatenanzeige-Text
  String _buildDisplayText(_ShoppingIngredientDisplay i) {
    final amount = i.amount ?? 0;
    final formattedAmount = NumberFormatter.formatCustom(amount);

    if (i.unitCode == 'Stk') {
      return '$formattedAmount ${i.ingredientName}';
    }

    const symbolUnits = {'g', 'kg', 't', 'L', 'ml', 'EL', 'TL'};
    final useCodeAsLabel = i.unitCode != null && symbolUnits.contains(i.unitCode);

    final u = useCodeAsLabel
        ? i.unitCode
        : (amount <= 1 ? (i.unitLabel ?? i.unitCode) : (i.unitLabel ?? i.unitCode));

    return '$formattedAmount ${u ?? ''} ${i.ingredientName}';
  }

  // Zeile einer einzelnen Zutat
  Widget _buildItemRow(_ShoppingIngredientDisplay item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => _toggleBasket(item),
            child: Icon(
              item.basket ? Icons.check_box : Icons.check_box_outline_blank,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _buildDisplayText(item),
              style: TextStyle(
                color: item.basket ? Colors.white60 : Colors.white,
                fontSize: 16,
                decoration: item.basket
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Liste erledigt / nicht erledigt setzen
  Future<void> _toggleListDone(bool v) async {
    final current =
        _shoppingLists.firstWhere((l) => l.id == _selectedListId);

    await (appDb.update(appDb.shoppingList)
          ..where((t) => t.id.equals(current.id)))
        .write(ShoppingListCompanion(done: d.Value(v)));

    await _loadLists();
  }

  // Navigation Tabs (unten)
  Widget _widgetForIndex(int index) {
    switch (index) {
      case 0:
        return const screen_ing.Ingredients();   // Zutaten
      case 1:
        return const Shopping();                 // Einkauf
      case 2:
        return const screen_rec.Recipes();       // Rezepte (Startseite)
      case 3:
        return const Meals();                 // Mahlzeiten
      case 4:
      default:
        return const Shopping();                // Nährwerte
    }
  }

  void _navigateToPage(int index) {
    if (index == _selectedIndex) return;

    final fromRight = index > _selectedIndex;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _widgetForIndex(index),
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween(
              begin: Offset(fromRight ? 1 : -1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );

    setState(() => _selectedIndex = index);
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  @override
  void goToIndex(int index) => _navigateToPage(index);


  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool noLists = !_loading && _shoppingLists.isEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: onSwipeStart,
      onHorizontalDragUpdate: onSwipeUpdate,
      onHorizontalDragEnd: onSwipeEnd,

      onVerticalDragEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond.dy;
        if (velocity < -300) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const ProductsListScreen(category: 'Alle Produkte'),
            ),
          );
        }
      },

      child: Scaffold(
        backgroundColor: darkgreen,
        appBar: AppBar(
          backgroundColor: darkgreen,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Planty Shopping",
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        drawer: const AppDrawer(currentIndex: 1),

        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
          child: GNav(
            backgroundColor: darkgreen,
            tabBackgroundColor: darkdarkgreen,
            color: Colors.white70,
            activeColor: Colors.white,
            padding: const EdgeInsets.all(16),
            gap: 8,
            selectedIndex: _selectedIndex,
            onTabChange: _navigateToPage,
            tabs: const [
              GButton(icon: Icons.eco, text: 'Zutaten'),           // index 0
              GButton(icon: Icons.storefront, text: 'Einkauf'),  // index 1
              GButton(icon: Icons.list_alt, text: 'Rezepte'),      // index 2
              GButton(icon: Icons.calendar_month, text: 'Mahlzeiten'),// index 3
              GButton(icon: Icons.stacked_bar_chart, text: 'Nährwerte'), // index 4
            ],

          ),
        ),

        // ---------------------------------------------------------------------
        // BODY
        // ---------------------------------------------------------------------
        body: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraint) {
            final double blockHeight = constraint.maxHeight / 3;

            return Column(
              children: [
                // -------------------------------------------------------------------
                // BLOCK 1 – Einkaufslisten
                // -------------------------------------------------------------------
                Container(
                  height: blockHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.transparent,
                  ),
                  child: Column(
                    children: [

                      // ✔ KLICKBARE GRÜNE HEADER-LEISTE (wie Lager + Statistik)
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ShoppingListOverviewScreen(),
                            ),
                          );
                        },
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: darkdarkgreen,
                            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: const Text(
                            "Einkaufslisten",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // ✔ INHALTSBEREICH (unverändert)
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final itemHeight = constraints.maxHeight / 3;   // ✔ genau 3 Items 

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(16),
                                ),
                              ),
                              child: StreamBuilder<List<ShoppingListData>>(
                                stream: _watchRecentOpenLists(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(color: Colors.white),
                                    );
                                  }

                                  final lists = snapshot.data!;
                                  
                                  // Höhe eines Listenelements
                                    final double itemHeight = constraints.maxHeight / 3;

                                    // sichtbare Listen
                                    final visibleLists = lists.take(3).toList();
                                    final int count = visibleLists.length;

                                    // Builder für ein echtes Listenelement
                                    Widget buildListItem(ShoppingListData list) {
                                      return FutureBuilder<Market?>(
                                        future: _loadMarketForList(list.marketId),
                                        builder: (context, marketSnap) {
                                          final mk = marketSnap.data;

                                          return FutureBuilder<int>(
                                            future: _countItemsInList(list.id),
                                            builder: (context, countSnap) {
                                              final itemCount = countSnap.data ?? 0;

                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedListId = list.id;
                                                  });

                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) => ShoppingListOverviewScreen(
                                                        initialListId: list.id,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: SizedBox(
                                                  height: itemHeight,
                                                  child: ShoppingListTile(
                                                    shoppingListId: list.id,
                                                    name: list.name,
                                                    productCount: itemCount,
                                                    marketImagePath: mk?.picture ?? "",
                                                    backgroundColor:
                                                        _parseHexColor(mk?.color) ?? Colors.black,
                                                    onLogoTap: () {
                                                      setState(() => _selectedListId = list.id);
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              const ShoppingListOverviewScreen(),
                                                        ),
                                                      );
                                                    },
                                                    onMenuSelected: (_) {},
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      );
                                    }

                                  // ------------------------------------------------------------------
                                  // BUTTON 1 – Neue Liste erstellen
                                  // ------------------------------------------------------------------
                                  Widget buildCreateButton() {
                                    return SizedBox(
                                      height: itemHeight,
                                      child: InkWell(
                                        onTap: () async {
                                          final newListId = await CreateShoppingListFlow.start(context);

                                          if (newListId != null) {
                                            await _loadLists();      // Listen neu laden
                                            setState(() {});         // UI aktualisieren

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ShoppingListOverviewScreen(initialListId: newListId),
                                              ),
                                            );
                                          }
                                        },
                                        child: Row(
                                          children: const [
                                            SizedBox(width: 12),
                                            Icon(Icons.add, color: Colors.white),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                "Neue Liste erstellen",
                                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                                maxLines: 2,
                                                softWrap: true,
                                                overflow: TextOverflow.visible,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  // ------------------------------------------------------------------
                                  // BUTTON 2 – Historie
                                  // ------------------------------------------------------------------
                                  Widget buildHistoryButton() {
                                    return SizedBox(
                                      height: itemHeight,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => const ShoppingListHistoryScreen(),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          children: const [
                                            SizedBox(width: 12),
                                            Icon(Icons.history, color: Colors.white),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                "Historie",
                                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                                maxLines: 2,
                                                softWrap: true,
                                                overflow: TextOverflow.visible,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  // ------------------------------------------------------------------
                                  // LAYOUT LOGIK
                                  // ------------------------------------------------------------------

                                  List<Widget> children = [];

                                  // 3 LISTEN → drei Elemente, KEINE Buttons
                                  if (count == 3) {
                                    for (final list in visibleLists) {
                                      children.add(buildListItem(list));
                                    }
                                  }

                                  // 2 LISTEN → zwei Elemente + Buttons NEBENEINANDER
                                  else if (count == 2) {
                                    children.add(buildListItem(visibleLists[0]));
                                    children.add(buildListItem(visibleLists[1]));

                                    children.add(
                                      SizedBox(
                                        height: itemHeight,
                                        child: Row(
                                          children: [
                                            Expanded(child: buildCreateButton()),
                                            Expanded(child: buildHistoryButton()),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  // 1 LISTE → eine Liste + beide Buttons untereinander
                                  else if (count == 1) {
                                    children.add(buildListItem(visibleLists[0]));
                                    children.add(buildCreateButton());
                                    children.add(buildHistoryButton());
                                  }

                                  // 0 LISTEN → nur Buttons
                                  else {
                                    children.add(buildCreateButton());
                                    children.add(buildHistoryButton());
                                  }


                                  return Column(children: children);

                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),


                const SizedBox(height: 12),

                // -------------------------------------------------------------------
                // BLOCK 2 – Lager (wie bisher)
                // -------------------------------------------------------------------
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const StockScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.transparent,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: darkdarkgreen,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                            ),
                            child: const Text(
                              "Lager",
                              style: TextStyle(
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
                              child: FutureBuilder<Map<String, List<_IngredientStockInfo>>>(
                                future: _loadStockAlerts(),
                                builder: (context, snap) {
                                  if (!snap.hasData) {
                                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                                  }

                                  final low = snap.data!["lowShelfLife"]!;
                                  final refill = snap.data!["needsRefill"]!;

                                  Widget buildItem(_IngredientStockInfo info) {
                                    final img = info.picture?.isNotEmpty == true
                                        ? info.picture!
                                        : 'assets/images/placeholder.jpg';

                                    return Row(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.asset(
                                            img,
                                            width: 28,
                                            height: 28,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            info.name,
                                            style: const TextStyle(color: Colors.white, fontSize: 12),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    );
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        // ------------------------------------------------------
                                        // LINKER BLOCK — geringe Haltbarkeit
                                        // ------------------------------------------------------
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Geringe Haltbarkeit",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),

                                              // 5 Zeilen, sauber verteilt
                                              Expanded(
                                                child: Column(
                                                  children: List.generate(3, (i) {
                                                    final item = i < low.length ? low[i] : null;

                                                    return Expanded(
                                                      child: Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: item == null
                                                            ? const SizedBox.shrink()
                                                            : _buildStockItemRow(item),
                                                      ),
                                                    );
                                                  }),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        //const SizedBox(width: 10),
                                        VerticalDivider(
                                          color: Colors.white24,
                                          thickness: 1,
                                          width: 10,
                                        ),
                                        //const SizedBox(width: 10),

                                        // ------------------------------------------------------
                                        // RECHTER BLOCK — Aufzufüllen
                                        // ------------------------------------------------------
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                "Aufzufüllen",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),

                                              Expanded(
                                                child: Column(
                                                  children: List.generate(3, (i) {
                                                    final item = i < refill.length ? refill[i] : null;

                                                    return Expanded(
                                                      child: Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: item == null
                                                            ? const SizedBox.shrink()
                                                            : _buildStockItemRow(item),
                                                      ),
                                                    );
                                                  }),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                  // ============================================================
                  // BLOCK 3 — STATISTIK
                  // ============================================================
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        // später eigener Statistikscreen
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.transparent,
                        ),
                        child: Column(
                          children: [

                            // HEADER
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                              decoration: BoxDecoration(
                                color: darkdarkgreen,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              child: const Text(
                                "Statistik",
                                style: TextStyle(
                                  color: Colors.white, 
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // INHALT
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                                ),
                                child: FutureBuilder<Map<String, dynamic>>(
                                  future: () async {
                                    final now = DateTime.now();
                                    final m = now.month;
                                    final y = now.year;

                                    final prevM = m == 1 ? 12 : m - 1;
                                    final prevY = m == 1 ? y - 1 : y;

                                    // Monatsdaten nach Market
                                    final currMarkets = await sumForMonthByMarket(y, m);
                                    final prevMarkets = await sumForMonthByMarket(prevY, prevM);

                                    // Market-Farben laden
                                    final marketRows = await appDb.select(appDb.markets).get();
                                    final Map<int, Color> marketColors = {
                                      for (final mk in marketRows)
                                        mk.id: _parseHexColor(mk.color) ?? Colors.white,
                                    };

                                    return {
                                      "currLabel": "${m.toString().padLeft(2, '0')}/$y",
                                      "prevLabel": "${prevM.toString().padLeft(2, '0')}/$prevY",
                                      "currMarkets": currMarkets,
                                      "prevMarkets": prevMarkets,
                                      "marketColors": marketColors,
                                    };
                                  }(),
                                  builder: (context, snap) {
                                    if (!snap.hasData) {
                                      return const Center(
                                        child: CircularProgressIndicator(color: Colors.white),
                                      );
                                    }

                                    final d = snap.data!;
                                    final currLabel = d["currLabel"];
                                    final prevLabel = d["prevLabel"];
                                    final currMarkets = Map<int, double>.from(d["currMarkets"]);
                                    final prevMarkets = Map<int, double>.from(d["prevMarkets"]);
                                    final marketColors =
                                        Map<int, Color>.from(d["marketColors"]);

                                    return LayoutBuilder(
                                      builder: (context, c) {
                                        return Column(
                                          children: [
                                            // -------- Vorheriger Monat --------
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(0, 4, 0, 2),  
                                              child: MonthBarWithMarkets(
                                                label: prevLabel,
                                                marketValues: prevMarkets,
                                                marketColors: marketColors,
                                                maxValue: 500,
                                              ),
                                            ),


                                            // -------- Aktueller Monat --------
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                                              child: MonthBarWithMarkets(
                                                label: currLabel,
                                                marketValues: currMarkets,
                                                marketColors: marketColors,
                                                maxValue: 500,
                                              ),
                                            ),

                                            // ---------- Abstand ----------
                                            //const SizedBox(height: 6),
                                            Divider(
                                              color: Colors.white24,
                                              thickness: 1,
                                            ),
                                            const SizedBox(height: 6),

                                            // ======================================================
                                            // DONUTS — AUTOMATISCH SKALIEREND
                                            // ======================================================
                                            Expanded(
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: Align(
                                                      alignment: Alignment.center,
                                                      child: _buildRegionalityDonut(),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Align(
                                                      alignment: Alignment.center,
                                                      child: _buildSeasonalityDonut(),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Align(
                                                      alignment: Alignment.center,
                                                      child: _buildAutarkyDonut(),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );

                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
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

  // ---------------------------------------------------------------------------
  // Offene Listen (Zutatenliste)
  // ---------------------------------------------------------------------------
  Widget _buildOpenListContent() {
    if (_shoppingLists.isEmpty) return const SizedBox.shrink();

    final currentList =
        _shoppingLists.firstWhere((l) => l.id == _selectedListId);

    return Expanded(
      child: Column(
        children: [
          // Unterer Header
          Container(
            color: darkdarkgreen,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    currentList.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: _prevList,
                  icon: const Icon(Icons.arrow_left, color: Colors.white),
                ),
                IconButton(
                  onPressed: _nextList,
                  icon: const Icon(Icons.arrow_right, color: Colors.white),
                ),

                FutureBuilder<Market?>(
                  future: () async {
                    if (currentList.marketId == null) return null;
                    final q = appDb.select(appDb.markets)
                      ..where((m) => m.id.equals(currentList.marketId!));
                    return q.getSingleOrNull();
                  }(),
                  builder: (context, snap) {
                    final mk = snap.data;
                    if (mk == null) {
                      return const SizedBox(width: 32, height: 32);
                    }

                    return Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _parseHexColor(mk.color) ??
                            const Color(0xFF0B0B0B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            mk.picture ?? "",
                            width: 26,
                            height: 26,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Trenner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              height: 1.2,
              width: double.infinity,
              color: Colors.white24,
            ),
          ),

          // Zutatenliste
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: darkdarkgreen,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child:
                  StreamBuilder<List<_ShoppingIngredientDisplay>>(
                      stream: _watchIngredients(currentList.id),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white),
                          );
                        }

                        final items = snap.data!;
                        if (items.isEmpty) {
                          return const Center(
                            child: Text(
                              "Keine Zutaten vorhanden.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, size) {
                            const double arrowsReservedHeight = 40;
                            final double available =
                                size.maxHeight -
                                    arrowsReservedHeight;

                            final double rowHeight =
                                available / 10;

                            const int itemsPerPage = 10;
                            final int totalPages =
                                (items.length / itemsPerPage)
                                    .ceil();

                            if (_pageIndex >= totalPages) {
                              _pageIndex = totalPages - 1;
                            }

                            final int start =
                                _pageIndex * itemsPerPage;
                            final int end = (start +
                                    itemsPerPage)
                                .clamp(0, items.length);
                            final visibleItems =
                                items.sublist(start, end);

                            return Column(
                              children: [
                                for (int i = 0; i < 10; i++)
                                  SizedBox(
                                    height: rowHeight,
                                    child: i <
                                            visibleItems
                                                .length
                                        ? _buildItemRow(
                                            visibleItems[i],
                                          )
                                        : const SizedBox
                                            .shrink(),
                                  ),
                                SizedBox(
                                  height:
                                      arrowsReservedHeight,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .end,
                                    children: [
                                      if (_pageIndex > 0)
                                        IconButton(
                                          padding:
                                              EdgeInsets
                                                  .zero,
                                          iconSize: 22,
                                          onPressed: () {
                                            setState(() {
                                              _pageIndex--;
                                            });
                                          },
                                          icon:
                                              const Icon(
                                            Icons
                                                .keyboard_arrow_up,
                                            color: Colors
                                                .white,
                                          ),
                                        ),
                                      if (_pageIndex <
                                          totalPages - 1)
                                        IconButton(
                                          padding:
                                              EdgeInsets
                                                  .zero,
                                          iconSize: 22,
                                          onPressed: () {
                                            setState(() {
                                              _pageIndex++;
                                            });
                                          },
                                          icon:
                                              const Icon(
                                            Icons
                                                .keyboard_arrow_down,
                                            color: Colors
                                                .white,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }),
            ),
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// MODEL
// ---------------------------------------------------------------------------
class _ShoppingIngredientDisplay {
  final int id;
  final int shoppingListId;
  final int? recipeId;
  final int? recipePortionNumberId;
  final int? ingredientId;
  final double? amount;
  final String? unitCode;
  final String? unitLabel;
  final String ingredientName;
  bool basket;

  _ShoppingIngredientDisplay({
    required this.id,
    required this.shoppingListId,
    required this.recipeId,
    required this.recipePortionNumberId,
    required this.ingredientId,
    required this.amount,
    required this.unitCode,
    required this.unitLabel,
    required this.ingredientName,
    required this.basket,
  });
}

class ShoppingListTile extends StatelessWidget {
  final int shoppingListId;
  final String name;
  final int productCount;
  final String marketImagePath;
  final Color backgroundColor;
  final VoidCallback onLogoTap;
  final ValueChanged<String> onMenuSelected;

  const ShoppingListTile({
    super.key,
    required this.shoppingListId,
    required this.name,
    required this.productCount,
    required this.marketImagePath,
    required this.backgroundColor,
    required this.onLogoTap,
    required this.onMenuSelected,
  });

  // --- UNAVAILABLE ITEMS ---
  Future<int> _countUnavailableItems() async {
    final sli = appDb.shoppingListIngredient;

    final rows = await (appDb.select(sli)
          ..where((t) => t.shoppingListId.equals(shoppingListId)))
        .get();

    int count = 0;
    for (final row in rows) {
      final hasNominal =
          row.productIdNominal != null ||
          row.ingredientMarketIdNominal != null;

      if (!hasNominal) count++;
    }

    return count;
  }

  double _effectiveIngredientMarketAmount(double summedAmount, String? unitCodeRaw) {
  final unitCode = unitCodeRaw?.trim().toLowerCase() ?? '';

  // Wenn Einheit leer ODER "g" => nicht runden
  final shouldRound = unitCode.isNotEmpty && unitCode != 'g';

  return shouldRound ? summedAmount.ceilToDouble() : summedAmount;
}


  // --- TOTAL PRICE ---
  Future<double> _calculateTotalPrice() async {
    final sli = appDb.shoppingListIngredient;
    final sl = appDb.shoppingList;
    final pm = appDb.productMarkets;
    final im = appDb.ingredientMarket;

    final listRow = await (appDb.select(sl)
          ..where((t) => t.id.equals(shoppingListId)))
        .getSingleOrNull();

    if (listRow == null || listRow.marketId == null) return 0.0;
    final marketId = listRow.marketId!;

    final items = await (appDb.select(sli)
          ..where((t) => t.shoppingListId.equals(shoppingListId)))
        .get();

    double total = 0.0;

    final Map<int, double> productSums = {};
    final Map<int, double> ingredientMarketSums = {};

    for (final row in items) {
      if (row.productIdNominal != null &&
          row.productAmountNominal != null) {
        productSums[row.productIdNominal!] =
            (productSums[row.productIdNominal!] ?? 0) +
                row.productAmountNominal!;
      }

      if (row.ingredientMarketIdNominal != null &&
          row.ingredientMarketAmountNominal != null) {
        ingredientMarketSums[row.ingredientMarketIdNominal!] =
            (ingredientMarketSums[row.ingredientMarketIdNominal!] ?? 0) +
                row.ingredientMarketAmountNominal!;
      }
    }

    // Produkte
    for (final entry in productSums.entries) {
      final pid = entry.key;
      final sumRounded = entry.value.ceil();

      final priceRow = await (appDb.select(pm)
            ..where((t) =>
                t.productsId.equals(pid) &
                t.marketId.equals(marketId)))
          .getSingleOrNull();

      if (priceRow?.price != null) {
        total += sumRounded * priceRow!.price!;
      }
    }

    // IngredientMarket
    for (final entry in ingredientMarketSums.entries) {
      final imId = entry.key;
      final summed = entry.value;

      final imRow = await (appDb.select(im)
            ..where((t) => t.id.equals(imId)))
          .getSingleOrNull();

      if (imRow == null || imRow.price == null) continue;

      final effectiveAmount =
          _effectiveIngredientMarketAmount(summed, imRow.unitCode);

      total += effectiveAmount * imRow.price!;
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    final pText = productCount == 1 ? "Eintrag" : "Einträge";

    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        // kein fester Hintergrund mehr
        child: Row(
          children: [
            GestureDetector(
              onTap: onLogoTap,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    marketImagePath,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Text stretch
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FutureBuilder<int>(
                    future: _countUnavailableItems(),
                    builder: (context, snap) {
                      final unavailable = snap.data ?? 0;
                      final suffix =
                          unavailable > 0 ? " ($unavailable nicht verfügbar)" : "";
                      return Text(
                        "$productCount Einträge$suffix",
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // price
            FutureBuilder<double>(
              future: _calculateTotalPrice(),
              builder: (context, snapshot) {
                final total = snapshot.data ?? 0.0;
                return Text(
                  "${total.toStringAsFixed(2)} €",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

  }
}
  // ================================================================
  // REGIONDATA – Datenmodell für Regionalität
  // ================================================================
  class _RegionData {
    final double dePercent;
    final double euPercent;
    final double otherPercent;

    const _RegionData({
      required this.dePercent,
      required this.euPercent,
      required this.otherPercent,
    });

    factory _RegionData.empty() =>
        const _RegionData(dePercent: 0, euPercent: 0, otherPercent: 0);
  }

  // ================================================================
  // REGIONALE ANTEILE LADEN
  // ================================================================
  Future<_RegionData> _loadRegionStats() async {
    final sli = appDb.shoppingListIngredient;
    final c = appDb.countries;

    final rows = await (appDb.select(sli)
          ..where((t) => t.priceActual.isNotNull()))
        .join([
      d.leftOuterJoin(c, c.id.equalsExp(sli.countryId)),
    ]).get();

    double de = 0;
    double eu = 0;
    double rest = 0;

    for (final row in rows) {
      final s = row.readTable(sli);
      final country = row.readTableOrNull(c);
      final price = s.priceActual ?? 0.0;

      if (s.countryId == 33) {
        de += price;
      } else if ((country?.continent ?? "") == "Europa") {
        eu += price;
      } else {
        rest += price;
      }
    }

    final total = de + eu + rest;

    if (total == 0) {
      return _RegionData.empty();
    }

    return _RegionData(
      dePercent: de / total,
      euPercent: eu / total,
      otherPercent: rest / total,
    );
  }

  // ================================================================
  // DONUTPAINTER – Ringdiagramm
  // ================================================================
  class DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final String centerText;

  DonutPainter({
    required this.values,
    required this.colors,
    required this.centerText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0.0, (a, b) => a + b);
    if (total == 0) return;

    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.22;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double start = -90;

    for (int i = 0; i < values.length; i++) {
      final sweep = 360 * (values[i] / total);
      paint.color = colors[i];

      canvas.drawArc(
        rect,
        _degToRad(start),
        _degToRad(sweep),
        false,
        paint,
      );
      start += sweep;
    }

    // Mitteltext
    final tp = TextPainter(
      text: TextSpan(
        text: centerText,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final center = Offset(size.width / 2, size.height / 2);
    final offset = center - Offset(tp.width / 2, tp.height / 2);
    tp.paint(canvas, offset);
  }

  double _degToRad(double deg) => deg * 3.1415926535 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


// ================================================================
  // DONUT WITH LEGEND – Ringdiagramm mit Legende
  // ================================================================

class DonutWithLegend extends StatelessWidget {
  final String title;
  final List<double> values;
  final List<Color> colors;
  final List<String> labels;
  final List<int> percentIndices;

  const DonutWithLegend({
    super.key,
    required this.title,
    required this.values,
    required this.colors,
    required this.labels,
    required this.percentIndices,
  });

  @override
  Widget build(BuildContext context) {
    // Prozentberechnung
    final double selectedSum = percentIndices
        .where((i) => i >= 0 && i < values.length)
        .fold(0.0, (sum, i) => sum + values[i]);

    final percent = (selectedSum * 100).toStringAsFixed(0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,  // Titel & Diagramm mittig
      children: [
        
        // ------------ Donut + Legende (nebeneinander) ------------
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CustomPaint(
                painter: DonutPainter(
                  values: values,
                  colors: colors,
                  centerText: "$percent%",
                ),
              ),
            ),

            // const SizedBox(width: 10),

            // Legende
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < labels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(width: 10, height: 10, color: colors[i]),
                        const SizedBox(width: 6),
                        Text(
                          labels[i],
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  )
              ],
            ),
          ],
        ),

        // ------------ Abstand zwischen Ring und Titel ------------
        const SizedBox(height: spacing),

        // ------------ Titel unter dem Donut, mittig ------------
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}



  // ================================================================
  // MONTHBAR – Balken pro Monat
  // ================================================================
  class MonthBarWithMarkets extends StatelessWidget {
  final String label;
  final Map<int, double> marketValues;
  final Map<int, Color> marketColors;
  final double maxValue;

  const MonthBarWithMarkets({
    super.key,
    required this.label,
    required this.marketValues,
    required this.marketColors,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final total = marketValues.values.fold(0.0, (a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: LayoutBuilder(
        builder: (context, c) {
          final double barWidth = c.maxWidth * 0.6; // 60% für Balken
          final double textWidth = c.maxWidth - barWidth - 8; // links + spacing

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ---- TEXT LINKS ----
              SizedBox(
                width: textWidth,
                child: Text(
                  "$label: ${total.toStringAsFixed(2)} €",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.fade,
                  softWrap: false,
                ),
              ),

              const SizedBox(width: 8),

              // ---- BALKEN RECHTS ----
              SizedBox(
                width: barWidth,
                height: 16,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _buildBar(barWidth),
                ),
              ),
            ],
          );
        },
      ),

    );
  }

  Widget _buildBar(double fullWidth) {
    const double max = 500.0;

    return Container(
      color: Colors.white12,
      child: Row(
        children: marketValues.entries.map((e) {
          final segmentRatio = (e.value / max).clamp(0.0, 1.0);
          final segmentWidth = fullWidth * segmentRatio;

          return Container(
            width: segmentWidth,
            color: marketColors[e.key] ?? Colors.white,
          );
        }).toList(),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// MODEL
// ---------------------------------------------------------------------------
class _IngredientStockInfo {
  final int ingredientId;
  final String name;
  final String? picture;
  final int? daysLeft;
  final double totalBaseAmount;
  final double averageBaseAmount;
  final int? storageCatId;

  _IngredientStockInfo({
    required this.ingredientId,
    required this.name,
    required this.picture,
    required this.daysLeft,
    required this.totalBaseAmount,
    required this.averageBaseAmount,
    required this.storageCatId,
  });
}





