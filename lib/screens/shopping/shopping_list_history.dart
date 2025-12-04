// lib/screens/shopping/shopping_list_history.dart
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';


// -----------------------------------------------------------------------------
// Helper: Rundung für IngredientMarket-Mengen (aus overview übernommen)
// -----------------------------------------------------------------------------
double _effectiveIngredientMarketAmount(
  double summedAmount,
  String? unitCodeRaw,
) {
  final unitCode = unitCodeRaw?.trim().toLowerCase() ?? '';

  // g => niemals runden
  // alles andere => CEIL
  return (unitCode.isNotEmpty && unitCode != "g")
      ? summedAmount.ceilToDouble()
      : summedAmount;
}



// -----------------------------------------------------------------------------
// SCREEN
// -----------------------------------------------------------------------------
class ShoppingListHistoryScreen extends StatefulWidget {
  const ShoppingListHistoryScreen({super.key});

  @override
  State<ShoppingListHistoryScreen> createState() =>
      _ShoppingListHistoryScreenState();
}

class _ShoppingListHistoryScreenState
    extends State<ShoppingListHistoryScreen> {

  // ---------------------------------------------------------------------------
  // Lade alle erledigten Listen + Produktanzahl + Market
  // ---------------------------------------------------------------------------
  Future<List<_ShoppingListWithCount>> _loadHistory() async {
    final sl = appDb.shoppingList;
    final sli = appDb.shoppingListIngredient;
    final markets = appDb.markets;

    final query = (appDb.select(sl)
          ..where((tbl) => tbl.done.equals(true))
          ..orderBy([(tbl) => d.OrderingTerm.desc(tbl.dateCreated)]))
        .join([
      d.leftOuterJoin(sli, sli.shoppingListId.equalsExp(sl.id)),
      d.leftOuterJoin(markets, markets.id.equalsExp(sl.marketId)),
    ])
          ..addColumns([sli.id.count()])
          ..groupBy([sl.id]);

    final rows = await query.get();

    return rows.map((r) {
      final list = r.readTable(sl);
      final count = r.read(sli.id.count()) ?? 0;
      final market = r.readTableOrNull(markets);
      return _ShoppingListWithCount(list: list, count: count, market: market);
    }).toList();
  }


  // ---------------------------------------------------------------------------
  // Restore: wieder aktiv + bought=0 + alle ACTUAL-Felder löschen
  // ---------------------------------------------------------------------------
  Future<void> _restoreShoppingList(int shoppingListId) async {
    final db = appDb;
    final sli = db.shoppingListIngredient;
    final sl  = db.shoppingList;

    // alle Items zurücksetzen
    await (db.update(sli)
          ..where((t) => t.shoppingListId.equals(shoppingListId)))
        .write(
      const ShoppingListIngredientCompanion(
        bought: d.Value(false),
        ingredientIdActual: d.Value(null),
        ingredientAmountActual: d.Value(null),
        ingredientUnitCodeActual: d.Value(null),
        productIdActual: d.Value(null),
        productAmountActual: d.Value(null),
        ingredientMarketIdActual: d.Value(null),
        ingredientMarketAmountActual: d.Value(null),
      ),
    );

    // Liste wieder aktiv
    await (db.update(sl)..where((t) => t.id.equals(shoppingListId))).write(
      ShoppingListCompanion(
        done: d.Value(false),
        lastEdited: d.Value(DateTime.now()),
      ),
    );
  }


  // ---------------------------------------------------------------------------
  // Delete ganze Liste + Items
  // ---------------------------------------------------------------------------
  Future<void> _deleteList(ShoppingListData list) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        title: const Text(
          "Wirklich löschen?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Diese Einkaufsliste wird dauerhaft gelöscht.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Abbrechen",
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Löschen",
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // zuerst Items löschen
    await (appDb.delete(appDb.shoppingListIngredient)
          ..where((t) => t.shoppingListId.equals(list.id)))
        .go();

    // dann Liste löschen
    await appDb.delete(appDb.shoppingList).delete(list);
  }


  // ---------------------------------------------------------------------------
  // Hex → Color
  // ---------------------------------------------------------------------------
  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;

    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = "FF$h";

    try {
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return null;
    }
  }


  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          "Historie",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: FutureBuilder<List<_ShoppingListWithCount>>(
        future: _loadHistory(),
        builder: (context, snapshot) {
          final lists = snapshot.data ?? [];

          if (lists.isEmpty) {
            return const Center(
              child: Text(
                "Keine erledigten Listen",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final item = lists[index];

              return _HistoryListTile(
                list: item.list,
                productCount: item.count,
                market: item.market,
                onRestore: (l) async {
                  await _restoreShoppingList(l.id);
                  setState(() {});
                },
                onDelete: (l) async {
                  await _deleteList(l);
                  setState(() {});
                },
              );
            },
          );
        },
      ),
    );
  }
}


// -----------------------------------------------------------------------------
// DATA HOLDER
// -----------------------------------------------------------------------------
class _ShoppingListWithCount {
  final ShoppingListData list;
  final int count;
  final Market? market;
  _ShoppingListWithCount({
    required this.list,
    required this.count,
    required this.market,
  });
}



// -----------------------------------------------------------------------------
// TILE – identisch zu Overview, nur mit anderem Menü
// -----------------------------------------------------------------------------
class _HistoryListTile extends StatelessWidget {
  final ShoppingListData list;
  final int productCount;
  final Market? market;
  final Future<void> Function(ShoppingListData) onRestore;
  final Future<void> Function(ShoppingListData) onDelete;

  const _HistoryListTile({
    required this.list,
    required this.productCount,
    required this.market,
    required this.onRestore,
    required this.onDelete,
  });

  Color _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF0B0B0B);

    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = "FF$h";

    return Color(int.tryParse(h, radix: 16) ?? 0xFF0B0B0B);
  }


  // ---------------------------------------------------------------------------
// Gesamtpreis: Summe aller price_actual für bought == true
// ---------------------------------------------------------------------------
Future<double> _calculateTotalPrice() async {
  final sli = appDb.shoppingListIngredient;

  // Alle gekauften Items dieser Liste laden
  final items = await (appDb.select(sli)
        ..where((t) =>
            t.shoppingListId.equals(list.id) &
            t.bought.equals(true)))
      .get();

  double total = 0.0;

  for (final row in items) {
    if (row.priceActual != null) {
      total += row.priceActual!;
    }
  }

  return total;
}



  @override
  Widget build(BuildContext context) {
    final pText = productCount == 1 ? "Produkt" : "Produkte";
    final bgColor = _parseHexColor(market?.color);
    final picture = market?.picture ?? "assets/images/shop/placeholder.png";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  picture,
                  width: 38,
                  height: 38,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Name + Produktzahl
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  list.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$productCount $pText",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Preis
          FutureBuilder<double>(
            future: _calculateTotalPrice(),
            builder: (context, snapshot) {
              final total = snapshot.data ?? 0.0;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  "${total.toStringAsFixed(2)} €",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),

          // Menü
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            color: const Color(0xFF1A1A1A),
            elevation: 6,
            onSelected: (v) {
              if (v == "restore") onRestore(list);
              if (v == "delete") onDelete(list);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "restore",
                child: Text("Auf zu erledigen ändern",
                    style: TextStyle(color: Colors.white)),
              ),
              PopupMenuItem(
                value: "delete",
                child: Text("Löschen",
                    style: TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
