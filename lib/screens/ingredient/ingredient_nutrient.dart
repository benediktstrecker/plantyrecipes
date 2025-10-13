import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

// DB
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

class IngredientDetailScreen extends StatelessWidget {
  final int ingredientId;
  final String? ingredientName;
  final bool embedded; // wenn true: kein eigenes Scaffold/AppBar

  const IngredientDetailScreen({
    super.key,
    required this.ingredientId,
    this.ingredientName,
    this.embedded = false,
  });

  // ------------------------------------------------------------
  // Nährwerte inkl. Kategorie & Farbe laden (ID-aufsteigend)
  // ------------------------------------------------------------
  Stream<List<_NutRow>> _watchNutrients(int ingId) {
    final link = appDb.ingredientNutrients; // IngredientNutrients
    final nut  = appDb.nutrient;            // Nutrient
    final cat  = appDb.nutrientsCategorie;  // NutrientsCategorie

    final query = appDb
        .select(link)
        .join([
          d.innerJoin(nut, nut.id.equalsExp(link.nutrientId)),
          d.leftOuterJoin(cat, cat.id.equalsExp(nut.nutrientsCategorieId)),
        ])
      ..where(link.ingredientId.equals(ingId))
      ..orderBy([
        d.OrderingTerm(expression: cat.id, mode: d.OrderingMode.asc),
        d.OrderingTerm(expression: nut.id, mode: d.OrderingMode.asc),
      ]);

    return query.watch().map((rows) {
      final list = rows.map((r) {
        final l = r.readTable(link);
        final n = r.readTable(nut);
        final c = r.readTableOrNull(cat);

        return _NutRow(
          nutrientId: n.id,
          nutrientName: n.name,
          amount: l.amount,
          unitCode: n.unitCode,
          colorHex: n.color,
          categoryId: n.nutrientsCategorieId,
          categoryName: c?.name ?? 'Weitere',
          categoryUnitCode: c?.unitCode,
          isEnergy: _isEnergy(n.name, n.unitCode, c?.name),
        );
      }).toList();

      list.sort((a, b) {
        final kc = a.categoryId.compareTo(b.categoryId);
        if (kc != 0) return kc;
        return a.nutrientId.compareTo(b.nutrientId);
      });

      return list;
    });
  }

  // Ingredient-Name streamen
  Stream<String> _watchIngredientName() {
    if (ingredientName != null && ingredientName!.trim().isNotEmpty) {
      return Stream.value(ingredientName!.trim());
    }
    final t = appDb.ingredients;
    return (appDb.select(t)..where((row) => row.id.equals(ingredientId)))
        .watchSingleOrNull()
        .map((row) => row?.name ?? 'Zutat');
  }

  // ------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------
  String _fmt(num v) {
    final s = v.toStringAsFixed(3);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  bool _isEnergy(String name, String unitCode, String? categoryName) {
    final n = name.toLowerCase();
    final u = unitCode.toLowerCase();
    final c = (categoryName ?? '').toLowerCase();

    if (c == 'energie' || c == 'energy') return true;
    if (n.contains('energie') || n.contains('brennwert') || n.contains('kalorien')) return true;
    if (u == 'kcal' || u == 'kj') return true;
    return false;
  }

  Color _parseDbColor(String? hex, {required Color fallback}) {
    if (hex == null || hex.trim().isEmpty) return fallback;
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return fallback;
    final val = int.tryParse(s, radix: 16);
    if (val == null) return fallback;
    return Color(val);
  }

  // Styles
  TextStyle get _titleStyle => const TextStyle(color: Colors.white);
  TextStyle get _headerStyle => const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      );
  TextStyle get _nutrientStyle => const TextStyle(
        color: Colors.white,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      );
  TextStyle get _nutrientSubStyle => const TextStyle(
        color: Colors.white70,
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      );

  Color get _bg => Colors.black;
  Color get _sectionBg => const Color(0xFF0B0B0B);
  Color get _fallbackColor => const Color(0xFF2A7C6F);
  Color get _legendText => Colors.white70;
  Color get _restColor => const Color(0xFFD0D0D0);

  // IDs
  static const int idEnergy = 1;
  static const int idFat = 2;
  static const int idProtein = 3;
  static const int idCarbs = 4;
  static const int idFiber = 5;
  static const int idSalt = 7;
  static const int idWater = 8;

  static const int idSatFat = 95;
  static const int idMonoFat = 104;
  static const int idPolyFat = 120;

  // kcal-Faktoren
  static const double kcalPerFat = 9.0;
  static const double kcalPerProtein = 4.0;
  static const double kcalPerCarb = 4.0;
  static const double kcalPerFiber = 2.0;

  // Betrag eines Nährstoffs in GRAMM
  double? _amountInGrams(_NutRow? r) {
    if (r == null) return null;
    final u = r.unitCode.toLowerCase();
    if (u == 'g') return r.amount;
    if (u == 'mg') return r.amount / 1000.0;
    if (u == 'µg' || u == 'ug' || u == 'mcg') return r.amount / 1e6;
    return null;
  }

  double _gramsOf(Map<int, _NutRow> byId, int id) =>
      _amountInGrams(byId[id]) ?? 0.0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: _watchIngredientName(),
      builder: (context, nameSnap) {
        final title = (nameSnap.data ?? ingredientName ?? 'Zutat');

        final body = StreamBuilder<List<_NutRow>>(
          stream: _watchNutrients(ingredientId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            final items = snap.data ?? const <_NutRow>[];
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'Keine Nährwerte gefunden.',
                  style: TextStyle(color: Colors.white70, fontSize: 14.5),
                ),
              );
            }

            final byId = {for (final n in items) n.nutrientId: n};

            // Diagramm 1: Kalorienzusammensetzung
            final double fatG   = _gramsOf(byId, idFat);
            final double protG  = _gramsOf(byId, idProtein);
            final double carbG  = _gramsOf(byId, idCarbs);
            final double fiberG = _gramsOf(byId, idFiber);

            final double kcalFat   = fatG   * kcalPerFat;
            final double kcalProt  = protG  * kcalPerProtein;
            final double kcalCarb  = carbG  * kcalPerCarb;
            final double kcalFiber = fiberG * kcalPerFiber;
            final double kcalKnown = kcalFat + kcalProt + kcalCarb + kcalFiber;

            final nEnergy = byId[idEnergy];
            late final double totalKcal;
            late final String energyTitle;
            if (nEnergy != null) {
              if (nEnergy.unitCode.toLowerCase() == 'kj') {
                totalKcal = nEnergy.amount / 4.184;
              } else {
                totalKcal = nEnergy.amount;
              }
              energyTitle = nEnergy.nutrientName;
            } else {
              totalKcal = kcalKnown;
              energyTitle = 'Energie (berechnet)';
            }
            final double kcalRest = (totalKcal - kcalKnown)
                .clamp(0.0, double.infinity)
                .toDouble();

            final Color colFat   = _parseDbColor(byId[idFat]?.colorHex,     fallback: _fallbackColor);
            final Color colProt  = _parseDbColor(byId[idProtein]?.colorHex, fallback: _fallbackColor);
            final Color colCarb  = _parseDbColor(byId[idCarbs]?.colorHex,   fallback: _fallbackColor);
            final Color colFiber = _parseDbColor(byId[idFiber]?.colorHex,   fallback: _fallbackColor);

            final kcalSegments = <_BarSeg>[
              _BarSeg('Fett', kcalFat, colFat),
              _BarSeg('Eiweiß', kcalProt, colProt),
              _BarSeg('Kohlenhydrate', kcalCarb, colCarb),
              _BarSeg('Ballaststoffe', kcalFiber, colFiber),
              _BarSeg('Rest', kcalRest, _restColor),
            ];

            // Diagramm 2: Massenzusammensetzung
            final double saltG  = _gramsOf(byId, idSalt);
            final double waterG = _gramsOf(byId, idWater);
            final double knownMass = fatG + protG + carbG + fiberG + waterG + saltG;
            final double restMass = (100.0 - knownMass)
                .clamp(0.0, 100.0)
                .toDouble();

            final Color colSalt  = _parseDbColor(byId[idSalt]?.colorHex,   fallback: _fallbackColor);
            final Color colWater = _parseDbColor(byId[idWater]?.colorHex,  fallback: _fallbackColor);

            final massSegments = <_BarSeg>[
              _BarSeg('Fett', fatG, colFat),
              _BarSeg('Eiweiß', protG, colProt),
              _BarSeg('Kohlenhydrate', carbG, colCarb),
              _BarSeg('Ballaststoffe', fiberG, colFiber),
              _BarSeg('Wasser', waterG, colWater),
              _BarSeg('Salz', saltG, colSalt),
              _BarSeg('Rest', restMass, _restColor),
            ];

            // Diagramm 3: Fettsäuren-Zusammensetzung
            final double satG  = _gramsOf(byId, idSatFat);
            final double monoG = _gramsOf(byId, idMonoFat);
            final double polyG = _gramsOf(byId, idPolyFat);
            final double knownFatty = satG + monoG + polyG;

            final double restFatty = (fatG - knownFatty)
                .clamp(0.0, double.infinity)
                .toDouble();

            final Color colSat  = _parseDbColor(byId[idSatFat]?.colorHex,  fallback: _fallbackColor);
            final Color colMono = _parseDbColor(byId[idMonoFat]?.colorHex, fallback: _fallbackColor);
            final Color colPoly = _parseDbColor(byId[idPolyFat]?.colorHex, fallback: _fallbackColor);

            final fattySegments = <_BarSeg>[
              _BarSeg('gesättigt', satG, colSat),
              _BarSeg('einfach ungesättigt', monoG, colMono),
              _BarSeg('mehrfach ungesättigt', polyG, colPoly),
              _BarSeg('Rest', restFatty, _restColor),
            ];

            // Kategorien
            final Map<int, _CatBucket> buckets = {};
            for (final n in items) {
              if (n.isEnergy) continue;
              final b = buckets.putIfAbsent(
                n.categoryId,
                () => _CatBucket(categoryId: n.categoryId, categoryName: n.categoryName, items: []),
              );
              b.items.add(n);
            }
            final bucketList = buckets.values.toList()
              ..sort((a, b) => a.categoryId.compareTo(b.categoryId));
            for (final b in bucketList) {
              b.items.sort((a, b2) => a.nutrientId.compareTo(b2.nutrientId));
            }

            final macroIndex = bucketList.indexWhere((b) {
              final n = b.categoryName.toLowerCase();
              return n == 'makronährstoffe' || n == 'makronaehrstoffe';
            });
            final fattyIndex = bucketList.indexWhere((b) =>
                b.categoryName.toLowerCase().contains('fettsäuren') ||
                b.categoryName.toLowerCase().contains('fettsaeuren'));

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                if (totalKcal > 0.0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: _sectionBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(energyTitle, style: _nutrientStyle.copyWith(fontSize: 16.5))),
                            Text('${_fmt(totalKcal)} kcal', style: _nutrientStyle.copyWith(color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _StackedBar100(segments: kcalSegments, legendTextStyle: TextStyle(color: _legendText)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                ...List<Widget>.generate(bucketList.length, (i) {
                  final bucket = bucketList[i];
                  final isMacro = i == macroIndex;
                  final isFatty = i == fattyIndex;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _sectionBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isMacro
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bucket.categoryName, style: _headerStyle),
                                const SizedBox(height: 8),
                                ...bucket.items.map((n) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: _PlainRow(
                                        name: n.nutrientName,
                                        value: '${_fmt(n.amount)} ${n.unitCode}',
                                        textStyle: _nutrientStyle,
                                        subStyle: _nutrientSubStyle,
                                      ),
                                    )),
                                const SizedBox(height: 12),
                                _StackedBar100(segments: massSegments, legendTextStyle: TextStyle(color: _legendText)),
                              ],
                            ),
                          )
                        : Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                              listTileTheme: const ListTileThemeData(
                                dense: true,
                                visualDensity: VisualDensity(vertical: -2, horizontal: 0),
                              ),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              collapsedIconColor: Colors.white70,
                              iconColor: Colors.white70,
                              title: Text(bucket.categoryName, style: _headerStyle),
                              childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                              children: [
                                if (isFatty) ...[
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                                    child: _StackedBar100(
                                      segments: fattySegments,
                                      legendTextStyle: TextStyle(color: _legendText),
                                    ),
                                  ),
                                ],
                                ...bucket.items.map((n) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                                    child: _PlainRow(
                                      name: n.nutrientName,
                                      value: '${_fmt(n.amount)} ${n.unitCode}',
                                      textStyle: _nutrientStyle,
                                      subStyle: _nutrientSubStyle,
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                  );
                }),
              ],
            );
          },
        );

        if (embedded) {
          return Container(color: _bg, child: body);
        }

        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(title, style: _titleStyle),
          ),
          body: body,
        );
      },
    );
  }
}

// ---------------------------
// UI Widgets
// ---------------------------
class _PlainRow extends StatelessWidget {
  final String name;
  final String value;
  final TextStyle textStyle;
  final TextStyle subStyle;

  const _PlainRow({
    required this.name,
    required this.value,
    required this.textStyle,
    required this.subStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(name, style: textStyle.copyWith(fontWeight: FontWeight.w600))),
        Text(value, style: subStyle),
      ],
    );
  }
}

// 100%-Stacked-Bar + Legende
class _StackedBar100 extends StatelessWidget {
  final List<_BarSeg> segments;
  final double height;
  final double radius;
  final TextStyle? legendTextStyle;

  const _StackedBar100({
    super.key,
    required this.segments,
    this.height = 16,
    this.radius = 8,
    this.legendTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = segments.where((s) => s.value > 0 && s.value.isFinite).toList();
    final double total = filtered.fold<double>(0.0, (s, e) => s + e.value);
    if (total <= 0.0) {
      return Text('Keine Daten für Diagramm', style: legendTextStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Row(
            children: filtered.map((s) {
              final int flex = ((s.value / total) * 1000).round().clamp(1, 1000);
              return Expanded(
                flex: flex,
                child: Container(height: height, color: s.color),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: filtered.map((s) {
            final double pct = (s.value / total) * 100.0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: s.color, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text('${s.label} (${pct.toStringAsFixed(0)}%)', style: legendTextStyle),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _BarSeg {
  final String label;
  final double value;
  final Color color;
  _BarSeg(this.label, this.value, this.color);
}

// ---------------------------
// Datenmodelle
// ---------------------------
class _NutRow {
  final int nutrientId;
  final String nutrientName;
  final double amount;
  final String unitCode;
  final String? colorHex;

  final int categoryId;
  final String categoryName;
  final String? categoryUnitCode;

  final bool isEnergy;

  _NutRow({
    required this.nutrientId,
    required this.nutrientName,
    required this.amount,
    required this.unitCode,
    required this.colorHex,
    required this.categoryId,
    required this.categoryName,
    required this.categoryUnitCode,
    required this.isEnergy,
  });

  factory _NutRow.empty() => _NutRow(
        nutrientId: -1,
        nutrientName: '',
        amount: 0,
        unitCode: '',
        colorHex: null,
        categoryId: -1,
        categoryName: '',
        categoryUnitCode: null,
        isEnergy: false,
      );
}

class _CatBucket {
  final int categoryId;
  final String categoryName;
  final List<_NutRow> items;

  _CatBucket({
    required this.categoryId,
    required this.categoryName,
    required this.items,
  });
}
