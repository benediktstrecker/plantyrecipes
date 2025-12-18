import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

import 'package:planty_flutter_starter/screens/ingredient/ingredient_detail.dart';


String formatDaysLeft(int days) {
  // POSITIV → Noch ...
  if (days > 0) {
    if (days < 30) {
      final d = days.floor();
      final unit = (d == 1) ? "Tag" : "Tage";
      return "Noch $d $unit";
    } else if (days < 365) {
      final m = (days / 30).floor();
      final unit = (m == 1) ? "Monat" : "Monate";
      return "Noch $m $unit";
    } else {
      final y = (days / 365).floor();
      final unit = (y == 1) ? "Jahr" : "Jahre";
      return "Noch $y $unit";
    }
  }

  // NEGATIV oder 0 → abge­laufen
  final absDays = days.abs();
  if (absDays < 30) {
    final d = absDays.floor();
    final unit = (d == 1) ? "Tag" : "Tage";
    return "Seit $d $unit abgelaufen";
  } else if (absDays < 365) {
    final m = (absDays / 30).floor();
    final unit = (m == 1) ? "Monat" : "Monate";
    return "Seit $m $unit abgelaufen";
  } else {
    final y = (absDays / 365).floor();
    final unit = (y == 1) ? "Jahr" : "Jahre";
    return "Seit $y $unit abgelaufen";
  }
}



// -----------------------------------------------------------------------------
// MODEL BASE FOR RAW STOCK JOIN
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
  final String? unitCode;
  final DateTime? dateEntry;
  final String? sign;

  _StockWithMeta({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.ingredientPicture,
    required this.storageId,
    required this.storageName,
    required this.storageIcon,
    required this.amount,
    required this.unitCode,
    required this.dateEntry,
    required this.sign,
  });
}


// -----------------------------------------------------------------------------
// MODEL: AGGREGATED RESULT PER INGREDIENT + STORAGE
// -----------------------------------------------------------------------------
class _AggregatedStock {
  final int ingredientId;
  final String ingredientName;
  final String? ingredientPicture;

  final int? storageId;
  final String storageName;
  final String? storageIcon;

  final double amount;
  final String unitLabel;

  final int? daysLeft;        // NEU

  _AggregatedStock({
    required this.ingredientId,
    required this.ingredientName,
    required this.ingredientPicture,
    required this.storageId,
    required this.storageName,
    required this.storageIcon,
    required this.amount,
    required this.unitLabel,
    required this.daysLeft,
  });
}


// -----------------------------------------------------------------------------
// SCREEN
// -----------------------------------------------------------------------------
class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  late Future<List<_AggregatedStock>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadStock();
  }

  // ---------------------------------------------------------------------------
  // MAIN LOADER: join → group per ingredient+storage → aggregate amounts/units
  // ---------------------------------------------------------------------------
  Future<List<_AggregatedStock>> _loadStock() async {
    final s = appDb.stock;
    final ing = appDb.ingredients;
    final sto = appDb.storage;
    final u = appDb.units;
    final iu = appDb.ingredientUnits;

    final q = (appDb.select(s)).join([
      d.leftOuterJoin(ing, ing.id.equalsExp(s.ingredientId)),
      d.leftOuterJoin(sto, sto.id.equalsExp(s.storageId)),
      d.leftOuterJoin(u, u.code.equalsExp(s.unitCode)),
    ]);

    final rows = await q.get();

    // RAW LIST
    final List<_StockWithMeta> raw = rows.map((r) {
      final stock = r.readTable(s);
      final ingredient = r.readTableOrNull(ing);
      final storage = r.readTableOrNull(sto);

      return _StockWithMeta(
        id: stock.id,
        ingredientId: stock.ingredientId,
        ingredientName: ingredient?.name ?? "Unbekannt",
        ingredientPicture: ingredient?.picture,
        storageId: storage?.id,
        storageName: storage?.name ?? "Unbekannt",
        storageIcon: storage?.icon,
        amount: stock.amount,
        unitCode: stock.unitCode,
        dateEntry: stock.dateEntry,
        sign: stock.sign,
      );
    }).toList();

    // -------------------------------------------------------------------------
    // GROUP BY (ingredientId, storageId)
    // -------------------------------------------------------------------------
    final Map<String, List<_StockWithMeta>> grouped = {};
    for (final x in raw) {
      final key = "${x.ingredientId}_${x.storageId}";
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(x);
    }

    final out = <_AggregatedStock>[];

    // -------------------------------------------------------------------------
    // AGGREGATION PER GROUP
    // -------------------------------------------------------------------------
    for (final entry in grouped.entries) {
      final items = entry.value;

      final ingredientId = items.first.ingredientId;
      final ingredientName = items.first.ingredientName;
      final ingredientPic = items.first.ingredientPicture;
      final storageId = items.first.storageId;
      final storageName = items.first.storageName;
      final storageIcon = items.first.storageIcon;

      // -------- 1) SUM SIGNED AMOUNT --------
      double signedSum = 0;

      for (final i in items) {
        if (i.amount == null) continue;
        final sign = (i.sign == '-' ? -1.0 : 1.0);
        signedSum += sign * i.amount!;
      }

      if (signedSum == 0) {
        continue; // ingredient hat netto 0 im storage → nicht anzeigen
      }

      // -------- 2) UNIT AGGREGATION --------
      final allCodes = items
          .map((e) => e.unitCode ?? "")
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      String finalUnit = "";
      double finalValue = signedSum;

      // --- helper: unit info
      Future<(String? category, double factor)> unitInfo(String code) async {
        final q = await (appDb.select(u)
              ..where((t) => t.code.equals(code)))
            .getSingleOrNull();
        if (q == null) return (null, 1.0);
        return (q.categorie, q.baseFactor ?? 1.0);
      }

      // --- helper: ingredient-specific factor to grams
      Future<double?> ingFactor(String code) async {
        final q = await (appDb.select(iu)
              ..where((t) => t.ingredientId.equals(ingredientId))
              ..where((t) => t.unitCode.equals(code)))
            .getSingleOrNull();
        return q?.amount; // always grams
      }

      // -------- CASE A: all same unit --------
      if (allCodes.length == 1) {
        finalUnit = allCodes.first;
        finalValue = signedSum;
      } else {
        // categories
        final categories = <String?>{};
        final factors = <String, double>{};

        for (final code in allCodes) {
          final info = await unitInfo(code);
          categories.add(info.$1);
          factors[code] = info.$2;
        }

        // -------- CASE B: one category & mass/volume --------
        if (categories.length == 1 &&
            (categories.first == "Masse" || categories.first == "Volumen")) {
          double baseSum = 0;

          for (final i in items) {
            if (i.amount == null) continue;
            final sign = (i.sign == '-' ? -1.0 : 1.0);
            final code = i.unitCode ?? "";
            final bf = factors[code] ?? 1.0;
            baseSum += sign * i.amount! * bf;
          }

          if (categories.first == "Masse") {
            if (baseSum.abs() >= 1000) {
              finalUnit = "kg";
              finalValue = baseSum / 1000;
            } else {
              finalUnit = "g";
              finalValue = baseSum;
            }
          } else {
            if (baseSum.abs() >= 1000) {
              finalUnit = "L";
              finalValue = baseSum / 1000;
            } else {
              finalUnit = "ml";
              finalValue = baseSum;
            }
          }
        } else {
          // -------- CASE C: mixed categories → convert everything to grams
          double gSum = 0;

          for (final i in items) {
            if (i.amount == null) continue;

            final sign = (i.sign == '-' ? -1.0 : 1.0);
            final code = i.unitCode ?? "";

            final info = await unitInfo(code);
            if (info.$1 == "Masse") {
              gSum += sign * i.amount! * info.$2; // factor → grams
            } else {
              final f = await ingFactor(code);
              if (f != null) {
                gSum += sign * i.amount! * f;
              }
            }
          }

          if (gSum.abs() >= 1000) {
            finalUnit = "kg";
            finalValue = gSum / 1000;
          } else {
            finalUnit = "g";
            finalValue = gSum;
          }
        }
      }

      // ===================================================================
      // 3) RESTLICHE LAGERDAUER (IngredientStorage)
      // ===================================================================
      IngredientStorageData? isRow;

      if (storageId != null) {
        isRow = await (appDb.select(appDb.ingredientStorage)
              ..where((t) => t.ingredientId.equals(ingredientId))
              ..where((t) => t.storageId.equals(storageId!)))
            .getSingleOrNull();
      } else {
        isRow = null;
      }


      int? daysLeft;

      if (isRow != null) {
        // maximale Lagerdauer in Tagen berechnen
        final maxAmount = isRow.amount;
        final maxUnit = isRow.unitCode;

        // Unit-Lookup → basefactor für Zeit gibt es nicht,
        // deshalb direkt feste Regeln:
        // Einheit muss eine ZEITEINHEIT sein: "d", "day", "tage", "month", "year" usw.
        // Wir definieren Standards:
        int maxDays = 0;

        switch (maxUnit.toLowerCase()) {
          case "d":
          case "day":
          case "tage":
          case "t":
            maxDays = maxAmount.floor();
            break;

          case "month":
          case "mon":
          case "m":
            maxDays = (maxAmount * 30).floor();
            break;

          case "y":
          case "year":
          case "jahr":
          case "j":
            maxDays = (maxAmount * 365).floor();
            break;

          default:
            // unbekannt → wir interpretieren als Tage
            maxDays = maxAmount.floor();
            break;
        }

        // vergangene Tage seit erstem (!) Einlagerungsdatum
        final firstDate = items
            .map((i) => i.dateEntry)
            .whereType<DateTime>()
            .fold<DateTime?>(null, (old, d) => old == null || d.isBefore(old) ? d : old);

        if (firstDate != null) {
          final diff = DateTime.now().difference(firstDate).inDays;
          final rem = maxDays - diff;
          daysLeft = rem < 0 ? 0 : rem;
        }
      }


      out.add(
        _AggregatedStock(
          ingredientId: ingredientId,
          ingredientName: ingredientName,
          ingredientPicture: ingredientPic,
          storageId: storageId,
          storageName: storageName,
          storageIcon: storageIcon,
          amount: finalValue,
          unitLabel: finalUnit,
          daysLeft: daysLeft,
        ),
      );

    }

    return out;
  }

  // ---------------------------------------------------------------------------
  // group aggregated items per storage
  // ---------------------------------------------------------------------------
  Map<String, List<_AggregatedStock>> _groupByStorage(
      List<_AggregatedStock> items) {
    final map = <String, List<_AggregatedStock>>{};
    for (final item in items) {
      map.putIfAbsent(item.storageName, () => []);
      map[item.storageName]!.add(item);
    }
    return map;
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
          "Lager",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: FutureBuilder<List<_AggregatedStock>>(
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
                  // HEADER
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

                  // LIST
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
// TILE
// -----------------------------------------------------------------------------
class _StockTile extends StatelessWidget {
  final _AggregatedStock item;

  const _StockTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final img = (item.ingredientPicture == null ||
            item.ingredientPicture!.isEmpty)
        ? 'assets/images/placeholder.jpg'
        : item.ingredientPicture!;

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
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
          ),
        );
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
            // PICTURE
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

            // TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
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

                  // Zweite Zeile: Haltbarkeit + Farbcodierung
                  Builder(
                    builder: (_) {
                      final days = item.daysLeft ?? 0;

                      // NEGATIV → abgelaufen
                      if (days <= 0) {
                        final absDays = days.abs();

                        // Einheit
                        String textUnit;
                        if (absDays < 30) {
                          textUnit = "${absDays.floor()} Tage";
                        } else if (absDays < 365) {
                          final m = (absDays / 30).floor();
                          textUnit = "$m Monate";
                        } else {
                          final y = (absDays / 365).floor();
                          textUnit = "$y Jahre";
                        }

                        return Text(
                          "Seit ${textUnit}n abgelaufen",
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        );

                      }

                      // POSITIV → noch haltbar
                      // Farbcodierung: <10% gelb
                      final isRow = item.daysLeft;
                      int? maxDays;  // wir legen unten dynamisch fest

                      final threshold = days * 0.1;

                      final color = (days < threshold)
                          ? Colors.yellowAccent
                          : Colors.white60;

                      return Text(
                        formatDaysLeft(days),
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),


            // AMOUNT
            Text(
              "${item.amount.toStringAsFixed(item.amount % 1 == 0 ? 0 : 1)} ${item.unitLabel}",
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
