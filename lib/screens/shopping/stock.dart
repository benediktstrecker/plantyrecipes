import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

import 'package:planty_flutter_starter/screens/ingredient/ingredient_detail.dart';


class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late Future<List<_StockWithMeta>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadStock();
  }

  Future<List<_StockWithMeta>> _loadStock() async {
    final s = appDb.stock;
    final ing = appDb.ingredients;
    final sto = appDb.storage;
    final u = appDb.units;

    final q = (appDb.select(s)).join([
      d.leftOuterJoin(ing, ing.id.equalsExp(s.ingredientId)),
      d.leftOuterJoin(sto, sto.id.equalsExp(s.storageId)),
      d.leftOuterJoin(u, u.code.equalsExp(s.unitCode)),
    ]);

    final rows = await q.get();

    return rows.map((r) {
      final stock = r.readTable(s);
      final ingredient = r.readTableOrNull(ing);
      final storage = r.readTableOrNull(sto);
      final unit = r.readTableOrNull(u);

      return _StockWithMeta(
  id: stock.id,
  ingredientId: ingredient?.id ?? 0,
  ingredientName: ingredient?.name ?? "Unbekannt",
  ingredientPicture: ingredient?.picture,
  storageId: storage?.id,
  storageName: storage?.name ?? "Unbekannt",
  storageIcon: storage?.icon,
  amount: stock.amount,
  unitLabel: unit?.label ?? stock.unitCode,
  dateEntry: stock.dateEntry,
);

    }).toList();
  }

  // Gruppiert nach STORAGE NAME
  Map<String, List<_StockWithMeta>> _groupByStorage(
    List<_StockWithMeta> items,
  ) {
    final map = <String, List<_StockWithMeta>>{};

    for (final item in items) {
      map.putIfAbsent(item.storageName, () => []);
      map[item.storageName]!.add(item);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          "Lager",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: FutureBuilder<List<_StockWithMeta>>(
        future: _future,
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          final data = snap.data!;
          if (data.isEmpty) {
            return const Center(
              child: Text(
                "Keine Lagerdaten vorhanden.",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final grouped = _groupByStorage(data);

          // -------------------------
          // Sortierte Sektionen (nach storage.id)
          // -------------------------
          final sortedEntries = grouped.entries.toList()
            ..sort((a, b) {
              final aId = a.value.first.storageId ?? 9999;
              final bId = b.value.first.storageId ?? 9999;
              return aId.compareTo(bId);
            });

          return ListView(
            padding: const EdgeInsets.all(16),
            children: sortedEntries.map((entry) {
              final title = entry.key;
              final items = entry.value;

              final storageIcon = items.first.storageIcon;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION HEADER MIT ICON
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6, top: 16),
                    child: Row(
                      children: [
                        if (storageIcon != null && storageIcon.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Image.asset(
                              storageIcon,
                              width: 22,
                              height: 22,
                              color: Colors.white,
                            ),
                          ),

                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SECTION BLOCK
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: items
                          .map((item) => _StockTile(item: item))
                          .toList(),
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MODEL FOR UI
// -----------------------------------------------------------------------------
class _StockWithMeta {
  final int id;
  final int ingredientId;

  final String ingredientName;
  final String? ingredientPicture;

  final int? storageId;
  final String storageName;
  final String? storageIcon;

  final double? amount;
  final String? unitLabel;
  final DateTime? dateEntry;

  _StockWithMeta({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.ingredientPicture,
    required this.storageId,
    required this.storageName,
    required this.storageIcon,
    required this.amount,
    required this.unitLabel,
    required this.dateEntry,
  });
}


// -----------------------------------------------------------------------------
// TILE – optisch wie IngredientTile
// -----------------------------------------------------------------------------
class _StockTile extends StatelessWidget {
  final _StockWithMeta item;

  const _StockTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final img = (item.ingredientPicture == null ||
            item.ingredientPicture!.isEmpty)
        ? 'assets/images/placeholder.jpg'
        : item.ingredientPicture!;

    final d = item.dateEntry;
    final dateString = d != null
        ? "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}"
        : "–";

    return InkWell(
      onTap: () {
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => IngredientDetailScreen(
      ingredientId: item.ingredientId,
      ingredientName: item.ingredientName,
      imagePath: item.ingredientPicture ?? 'assets/images/placeholder.jpg',
    ),
    transitionsBuilder: (_, animation, __, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  ));
},

      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                img,
                width: 45,
                height: 45,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.ingredientName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Eingelagert: $dateString",
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              "${item.amount?.toStringAsFixed(item.amount != null && item.amount! % 1 == 0 ? 0 : 1) ?? '-'} ${item.unitLabel ?? ''}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
