// lib/screens/ingredient/ingredient_nutrient.dart
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:drift/drift.dart' as d;
import 'package:planty_flutter_starter/utils/easy_swipe_nav.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

import 'package:planty_flutter_starter/screens/ingredient/ingredient_detail.dart' as det;
import 'package:planty_flutter_starter/screens/ingredient/ingredient_shopping.dart' as shop;
import 'package:planty_flutter_starter/screens/ingredient/ingredient_recipe.dart' as rec;

class IngredientNutrientScreen extends StatefulWidget {
  final int ingredientId;
  final String? ingredientName;
  final String? imagePath;

  const IngredientNutrientScreen({
    super.key,
    required this.ingredientId,
    this.ingredientName,
    this.imagePath,
  });

  @override
  State<IngredientNutrientScreen> createState() => _IngredientNutrientScreenState();
}

class _IngredientNutrientScreenState extends State<IngredientNutrientScreen>
    with EasySwipeNav {
  int _selectedIndex = 2;

  @override
  int get currentIndex => _selectedIndex;

  void _navigateToPage(int index) {
    if (!mounted || index == _selectedIndex) return;
    final fromRight = index > _selectedIndex;
    final next = _widgetForIndex(index);

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => next,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) {
        final begin = fromRight ? const Offset(1, 0) : const Offset(-1, 0);
        final tween =
            Tween(begin: begin, end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ));
  }

  @override
  void goToIndex(int index) => _navigateToPage(index);

  Widget _widgetForIndex(int index) {
    switch (index) {
      case 0:
        return det.IngredientDetailScreen(
          ingredientId: widget.ingredientId,
          ingredientName: widget.ingredientName,
          imagePath: widget.imagePath,
        );
      case 1:
        return shop.IngredientShoppingScreen(
          ingredientId: widget.ingredientId,
          ingredientName: widget.ingredientName,
          imagePath: widget.imagePath,
        );
      case 2:
        return IngredientNutrientScreen(
          ingredientId: widget.ingredientId,
          ingredientName: widget.ingredientName,
          imagePath: widget.imagePath,
        );
      case 3:
      default:
        return rec.IngredientRecipeScreen(
          ingredientId: widget.ingredientId,
          ingredientName: widget.ingredientName,
          imagePath: widget.imagePath,
        );
    }
  }

  // ---------------- Daten / Logik ----------------

  Stream<List<_NutRow>> _watchNutrients(int ingId) {
    final link = appDb.ingredientNutrients;
    final nut = appDb.nutrient;
    final cat = appDb.nutrientsCategorie;

    final query = appDb.select(link).join([
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

  Stream<String> _watchIngredientName() {
    if (widget.ingredientName != null && widget.ingredientName!.trim().isNotEmpty) {
      return Stream.value(widget.ingredientName!.trim());
    }
    final t = appDb.ingredients;
    return (appDb.select(t)..where((row) => row.id.equals(widget.ingredientId)))
        .watchSingleOrNull()
        .map((row) => row?.name ?? 'Zutat');
  }

  // ---------------- Helper ----------------

  String _fmt(num v) => v.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');
  String _fmtPct(num v) => v.toStringAsFixed(v % 1 == 0 ? 0 : 1).replaceFirst(RegExp(r'\.?0+$'), '');
  static bool _isEnergy(String name, String unitCode, String? categoryName) {
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

  // ---------------- Styles ----------------

  TextStyle get _titleStyle => const TextStyle(color: Colors.white);
  TextStyle get _headerStyle =>
      const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700);
  TextStyle get _nutrientStyle =>
      const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600);
  TextStyle get _nutrientSubStyle =>
      const TextStyle(color: Colors.white70, fontSize: 13.5, fontWeight: FontWeight.w500);

  Color get _bg => Colors.black;
  Color get _sectionBg => const Color(0xFF0B0B0B);
  Color get _fallbackColor => const Color(0xFF2A7C6F);
  Color get _legendText => Colors.white70;
  Color get _restColor => const Color(0xFFD0D0D0);

  static const double _nameCol = 160;
  static const double _valueCol = 120;

  static const int idEnergy = 1;
  static const int idFat = 2;
  static const int idProtein = 3;
  static const int idCarbs = 4;
  static const int idFiber = 5;
  static const int idSugar = 6;
  static const int idSalt = 7;
  static const int idWater = 8;
  static const int idSatFat = 95;
  static const int idMonoFat = 104;
  static const int idPolyFat = 120;
  static const List<int> carbComponentIds = [42, 46, 50, 51, 55];

  static const double kcalPerFat = 9.0;
  static const double kcalPerProtein = 4.0;
  static const double kcalPerCarb = 4.0;
  static const double kcalPerFiber = 2.0;

  // WHO/FAO/UNU 2007 Referenz (>3 Jahre), mg/g Protein
  static const Map<String, double> _refEAA_mgPerG = {
    'Histidin': 16,
    'Isoleucin': 30,
    'Leucin': 61,
    'Lysin': 48,
    'Methionin+Cystein': 23,
    'Phenylalanin+Tyrosin': 41,
    'Threonin': 25,
    'Tryptophan': 6.6,
    'Valin': 40,
  };

  // ---------------- Build ----------------

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<List<_NutRow>>(
      stream: _watchNutrients(widget.ingredientId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        final items = snap.data ?? const <_NutRow>[];
        if (items.isEmpty) {
          return const Center(
            child: Text('Keine Nährwerte gefunden.',
                style: TextStyle(color: Colors.white70, fontSize: 14.5)),
          );
        }

        final byId = {for (final n in items) n.nutrientId: n};
        double g(int id) => _amountInGrams(byId[id]) ?? 0.0;

        // Energie (kcal) – 4 Segmente
        final kcalFat = g(idFat) * kcalPerFat;
        final kcalProt = g(idProtein) * kcalPerProtein;
        final kcalCarb = g(idCarbs) * kcalPerCarb;
        final kcalFiber = g(idFiber) * kcalPerFiber;
        final kcalKnown = kcalFat + kcalProt + kcalCarb + kcalFiber;

        final nEnergy = byId[idEnergy];
        final totalKcal = nEnergy != null
            ? (nEnergy.unitCode.toLowerCase() == 'kj' ? nEnergy.amount / 4.184 : nEnergy.amount)
            : kcalKnown;
        final kcalRest = (totalKcal - kcalKnown).clamp(0.0, double.infinity);

        // Farben
        final colFat = _parseDbColor(byId[idFat]?.colorHex, fallback: _fallbackColor);
        final colProt = _parseDbColor(byId[idProtein]?.colorHex, fallback: _fallbackColor);
        final colCarb = _parseDbColor(byId[idCarbs]?.colorHex, fallback: _fallbackColor);
        final colFiber = _parseDbColor(byId[idFiber]?.colorHex, fallback: _fallbackColor);
        final colSugar = _parseDbColor(byId[idSugar]?.colorHex, fallback: _fallbackColor);
        final colSalt = _parseDbColor(byId[idSalt]?.colorHex, fallback: _fallbackColor);
        final colWater = _parseDbColor(byId[idWater]?.colorHex, fallback: _fallbackColor);
        final colSat = _parseDbColor(byId[idSatFat]?.colorHex, fallback: _fallbackColor);
        final colMono = _parseDbColor(byId[idMonoFat]?.colorHex, fallback: _fallbackColor);
        final colPoly = _parseDbColor(byId[idPolyFat]?.colorHex, fallback: _fallbackColor);

        // Segmente
        final energySegments = <_BarSeg>[
          _BarSeg('Fett', kcalFat, colFat),
          _BarSeg('Eiweiß', kcalProt, colProt),
          _BarSeg('Kohlenhydrate', kcalCarb, colCarb),
          _BarSeg('Ballaststoffe', kcalFiber, colFiber),
          _BarSeg('Rest', kcalRest, _restColor),
        ];

        // Makro-Mengen (7+Rest)
        final knownMass = g(idFat) + g(idProtein) + g(idCarbs) + g(idFiber) + g(idSugar) + g(idWater) + g(idSalt);
        final restMass = (100.0 - knownMass).clamp(0.0, 100.0);
        final macroSegments = <_BarSeg>[
          _BarSeg('Fett', g(idFat), colFat),
          _BarSeg('Eiweiß', g(idProtein), colProt),
          _BarSeg('Kohlenhydrate', g(idCarbs), colCarb),
          _BarSeg('Ballaststoffe', g(idFiber), colFiber),
          _BarSeg('Zucker', g(idSugar), colSugar),
          _BarSeg('Wasser', g(idWater), colWater),
          _BarSeg('Salz', g(idSalt), colSalt),
          _BarSeg('Rest', restMass, _restColor),
        ];

        // Fettsäuren
        final satG = g(idSatFat);
        final monoG = g(idMonoFat);
        final polyG = g(idPolyFat);
        final restFatty = (g(idFat) - (satG + monoG + polyG)).clamp(0.0, double.infinity);
        final fattySegments = <_BarSeg>[
          _BarSeg('gesättigt', satG, colSat),
          _BarSeg('einfach unges.', monoG, colMono),
          _BarSeg('mehrfach unges.', polyG, colPoly),
          _BarSeg('Rest', restFatty, _restColor),
        ];

        // KH-Komponenten
        final carbCompSegments = <_BarSeg>[];
        double knownCarbComp = 0.0;
        for (final id in carbComponentIds) {
          final row = byId[id];
          final val = g(id);
          knownCarbComp += val;
          carbCompSegments.add(_BarSeg(row?.nutrientName ?? 'ID $id', val,
              _parseDbColor(row?.colorHex, fallback: _fallbackColor)));
        }
        final restCarb = (g(idCarbs) - knownCarbComp).clamp(0.0, double.infinity);
        carbCompSegments.add(_BarSeg('Rest', restCarb, _restColor));

        // Buckets
        final Map<int, _CatBucket> buckets = {};
        for (final n in items) {
          if (n.isEnergy) continue;
          buckets.putIfAbsent(
            n.categoryId,
            () => _CatBucket(categoryId: n.categoryId, categoryName: n.categoryName, items: []),
          ).items.add(n);
        }
        final bucketList = buckets.values.toList()
          ..sort((a, b) => a.categoryId.compareTo(b.categoryId));
        for (final b in bucketList) {
          b.items.sort((a, b2) => a.nutrientId.compareTo(b2.nutrientId));
        }
        final macroIndex = bucketList.indexWhere((b) {
          final n = b.categoryName.toLowerCase();
          return n.contains('makronährstoffe') || n.contains('makronaehrstoffe');
        });
        final fattyIndex =
            bucketList.indexWhere((b) => b.categoryName.toLowerCase().contains('fettsäuren'));
        final carbsIndex =
            bucketList.indexWhere((b) => b.categoryName.toLowerCase().contains('kohlenhydrate'));
        final aminoIndex =
            bucketList.indexWhere((b) => b.categoryName.toLowerCase().contains('amino'));

        // EAA-Prozente
        final eaaPercents = _buildEaaPercents(items, g(idProtein));
        final double eaaBarWidth =
            (MediaQuery.of(context).size.width * 0.15).clamp(90.0, 150.0).toDouble();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            // Energie (mit Prozent-Legende)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(color: _sectionBg, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Energie', style: TextStyle(color: Colors.white, fontSize: 16.5)),
                      ),
                      Text('${_fmt(totalKcal)} kcal', style: _nutrientSubStyle),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _StackedBar100(
                    segments: energySegments,
                    legendTextStyle: TextStyle(color: _legendText),
                    showLegendPercents: true, // Prozentwerte anzeigen
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Kategorien
            ...List.generate(bucketList.length, (i) {
              final bucket = bucketList[i];
              final isMacro = i == macroIndex;
              final isFatty = i == fattyIndex;
              final isCarbs = i == carbsIndex;
              final isAmino = i == aminoIndex;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: _sectionBg, borderRadius: BorderRadius.circular(12)),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    collapsedIconColor: Colors.white70,
                    iconColor: Colors.white70,
                    initiallyExpanded: isMacro,
                    title: Text(bucket.categoryName, style: _headerStyle),
                    childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                    children: [
                      if (isMacro)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                          child: _StackedBar100(
                            segments: macroSegments,
                            legendTextStyle: const TextStyle(color: Colors.transparent), // keine Textlegende
                            showLegendPercents: false,
                          ),
                        ),
                      if (isFatty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                          child: _StackedBar100(
                            segments: fattySegments,
                            legendTextStyle: TextStyle(color: _legendText),
                            showLegendPercents: true, // Prozent in Legende
                          ),
                        ),
                      if (isCarbs)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                          child: _StackedBar100(
                            segments: carbCompSegments,
                            legendTextStyle: TextStyle(color: _legendText),
                            showLegendPercents: true,
                          ),
                        ),

                      // Essentielle Aminosäuren mit Balken
                      if (isAmino) ..._buildAminoRows(bucket.items, eaaPercents, barWidth: eaaBarWidth),

                      if (!isAmino)
                        ...bucket.items.map((n) {
                          Color? dot;
                          if (isMacro &&
                              (n.nutrientId == idFat ||
                                  n.nutrientId == idProtein ||
                                  n.nutrientId == idCarbs ||
                                  n.nutrientId == idFiber ||
                                  n.nutrientId == idSugar ||
                                  n.nutrientId == idSalt ||
                                  n.nutrientId == idWater)) {
                            dot = _parseDbColor(n.colorHex, fallback: _fallbackColor);
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            child: _PlainRow(
                              name: n.nutrientName,
                              value: '${_fmt(n.amount)} ${n.unitCode}',
                              textStyle: _nutrientStyle,
                              subStyle: _nutrientSubStyle,
                              leadingDotColor: dot,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );

    // Vollseite
    return GestureDetector(
      onHorizontalDragStart: onSwipeStart,
      onHorizontalDragUpdate: onSwipeUpdate,
      onHorizontalDragEnd: onSwipeEnd,
      child: StreamBuilder<String>(
        stream: _watchIngredientName(),
        builder: (context, nameSnap) {
          final title = (nameSnap.data ?? widget.ingredientName ?? 'Zutat');
          return Scaffold(
            backgroundColor: _bg,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(title, style: _titleStyle),
            ),
            body: content,
            bottomNavigationBar: Container(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
              child: GNav(
                backgroundColor: _bg,
                tabBackgroundColor: const Color(0xFF0B0B0B),
                color: Colors.white70,
                activeColor: Colors.white,
                padding: const EdgeInsets.all(16),
                gap: 8,
                selectedIndex: _selectedIndex,
                onTabChange: _navigateToPage,
                tabs: const [
                  GButton(icon: Icons.info_outline, text: 'Details'),
                  GButton(icon: Icons.shopping_bag_outlined, text: 'Einkauf'),
                  GButton(icon: Icons.stacked_bar_chart, text: 'Nährwerte'),
                  GButton(icon: Icons.list_alt, text: 'Rezepte'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------- Aminosäuren-Berechnung ----------

  Map<String, double?> _buildEaaPercents(List<_NutRow> items, double proteinGper100g) {
    final p = proteinGper100g;
    if (p <= 0) {
      return {
        'Histidin': null,
        'Isoleucin': null,
        'Leucin': null,
        'Lysin': null,
        'Methionin': null,
        'Cystein': null,
        'Phenylalanin': null,
        'Tyrosin': null,
        'Threonin': null,
        'Tryptophan': null,
        'Valin': null,
      };
    }

    double? mgOf(String name) {
      final row = items.firstWhere(
        (e) => e.nutrientName.toLowerCase() == name.toLowerCase(),
        orElse: () => _NutRow.empty(),
      );
      if (row.nutrientName.isEmpty) return null;
      final u = row.unitCode.toLowerCase();
      if (u == 'mg') return row.amount;
      if (u == 'g') return row.amount * 1000.0;
      if (u == 'µg' || u == 'ug' || u == 'mcg') return row.amount / 1000.0;
      return null;
    }

    // mg/100g
    final histidin = mgOf('Histidin') ?? 0;
    final isoleucin = mgOf('Isoleucin') ?? 0;
    final leucin = mgOf('Leucin') ?? 0;
    final lysin = mgOf('Lysin') ?? 0;
    final methionin = mgOf('Methionin') ?? 0;
    final cystein = mgOf('Cystein') ?? mgOf('Cystin') ?? 0;
    final phenylalanin = mgOf('Phenylalanin') ?? 0;
    final tyrosin = mgOf('Tyrosin') ?? 0;
    final threonin = mgOf('Threonin') ?? 0;
    final tryptophan = mgOf('Tryptophan') ?? 0;
    final valin = mgOf('Valin') ?? 0;

    double mgPerG(double mgPer100g) => mgPer100g / p;
    final ref = _refEAA_mgPerG;

    final map = <String, double?>{};
    map['Histidin'] = mgPerG(histidin) / ref['Histidin']! * 100.0;
    map['Isoleucin'] = mgPerG(isoleucin) / ref['Isoleucin']! * 100.0;
    map['Leucin'] = mgPerG(leucin) / ref['Leucin']! * 100.0;
    map['Lysin'] = mgPerG(lysin) / ref['Lysin']! * 100.0;
    map['Threonin'] = mgPerG(threonin) / ref['Threonin']! * 100.0;
    map['Tryptophan'] = mgPerG(tryptophan) / ref['Tryptophan']! * 100.0;
    map['Valin'] = mgPerG(valin) / ref['Valin']! * 100.0;

    // Paare als gemeinsamer Balken (Mittel)
    final saaPct = mgPerG(methionin + cystein) / ref['Methionin+Cystein']! * 100.0;
    map['Methionin'] = saaPct; // mittlerer Balken
    map['Cystein'] = double.nan; // Platzhalterzeile

    final aaaPct = mgPerG(phenylalanin + tyrosin) / ref['Phenylalanin+Tyrosin']! * 100.0;
    map['Phenylalanin'] = aaaPct; // mittlerer Balken
    map['Tyrosin'] = double.nan;

    return map;
  }

  // ---------- Aminosäuren-UI ----------

  List<Widget> _buildAminoRows(
    List<_NutRow> items,
    Map<String, double?> pct, {
    required double barWidth,
  }) {
    final names = items.map((e) => e.nutrientName).toList();

    final out = <Widget>[];
    int i = 0;
    while (i < names.length) {
      final nm = names[i];

      // Methionin + Cystein (Mittelbalken)
      if (nm.toLowerCase() == 'methionin' &&
          i + 1 < names.length &&
          names[i + 1].toLowerCase() == 'cystein') {
        out.add(_AminoPairRows(
          topName: names[i],
          bottomName: names[i + 1],
          topValue: items[i].amount,
          bottomValue: items[i + 1].amount,
          unitTop: items[i].unitCode,
          unitBottom: items[i + 1].unitCode,
          percentCenter: pct['Methionin'] ?? 0,
          nameStyle: _nutrientStyle,
          valueStyle: _nutrientSubStyle,
          nameCol: _nameCol,
          valueCol: _valueCol,
          barWidth: barWidth,
        ));
        i += 2;
        continue;
      }

      // Phenylalanin + Tyrosin (Mittelbalken)
      if (nm.toLowerCase() == 'phenylalanin' &&
          i + 1 < names.length &&
          names[i + 1].toLowerCase() == 'tyrosin') {
        out.add(_AminoPairRows(
          topName: names[i],
          bottomName: names[i + 1],
          topValue: items[i].amount,
          bottomValue: items[i + 1].amount,
          unitTop: items[i].unitCode,
          unitBottom: items[i + 1].unitCode,
          percentCenter: pct['Phenylalanin'] ?? 0,
          nameStyle: _nutrientStyle,
          valueStyle: _nutrientSubStyle,
          nameCol: _nameCol,
          valueCol: _valueCol,
          barWidth: barWidth,
        ));
        i += 2;
        continue;
      }

      // Einzelne EAA mit linksbündigem Balken (wenn vorhanden)
      final p = pct[nm] ?? double.nan;
      Widget? mid;
      if (p.isFinite) {
        mid = SizedBox(
          width: barWidth,
          child: _PercentBar(
            percent: p,
            maxPercent: 300,
            height: 12,
            squaredRightFill: true,
          ),
        );
      }

      out.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: _ListRowFixedCols(
          name: nm,
          value: '${_fmt(items[i].amount)} ${items[i].unitCode}',
          middle: mid,
          nameStyle: _nutrientStyle,
          valueStyle: _nutrientSubStyle,
          nameCol: _nameCol,
          valueCol: _valueCol,
          middleWidth: barWidth, // Platz reservieren, damit Werte immer rechtsbündig stehen
        ),
      ));
      i += 1;
    }

    return out;
  }

  // Umrechnungen
  double? _amountInGrams(_NutRow? r) {
    if (r == null) return null;
    final u = r.unitCode.toLowerCase();
    if (u == 'g') return r.amount;
    if (u == 'mg') return r.amount / 1000.0;
    if (u == 'µg' || u == 'ug' || u == 'mcg') return r.amount / 1e6;
    return null;
  }
}

// ---------------- Widgets ----------------

class _ListRowFixedCols extends StatelessWidget {
  final String name;
  final String value;
  final Widget? middle;
  final TextStyle nameStyle;
  final TextStyle valueStyle;
  final double nameCol;
  final double valueCol;
  final double middleWidth;

  const _ListRowFixedCols({
    super.key,
    required this.name,
    required this.value,
    required this.middle,
    required this.nameStyle,
    required this.valueStyle,
    required this.nameCol,
    required this.valueCol,
    this.middleWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: nameCol, child: Text(name, style: nameStyle)),
        const SizedBox(width: 8),
        if (middle != null) middle! else if (middleWidth > 0) SizedBox(width: middleWidth),
        if (middle != null || middleWidth > 0) const SizedBox(width: 8),
        Expanded(
  child: Align(
    alignment: Alignment.centerRight,
    child: Text(value, style: valueStyle),
  ),
),

      ],
    );
  }
}

class _AminoPairRows extends StatelessWidget {
  final String topName;
  final String bottomName;
  final double topValue;
  final double bottomValue;
  final String unitTop;
  final String unitBottom;
  final double percentCenter; // gemeinsamer Prozentwert
  final TextStyle nameStyle;
  final TextStyle valueStyle;
  final double nameCol;
  final double valueCol;
  final double barWidth;

  const _AminoPairRows({
    super.key,
    required this.topName,
    required this.bottomName,
    required this.topValue,
    required this.bottomValue,
    required this.unitTop,
    required this.unitBottom,
    required this.percentCenter,
    required this.nameStyle,
    required this.valueStyle,
    required this.nameCol,
    required this.valueCol,
    required this.barWidth,
  });

  @override
  Widget build(BuildContext context) {
    const rowH = 28.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Column(
            children: [
              SizedBox(
                height: rowH,
                child: Row(
                  children: [
                    SizedBox(width: nameCol, child: Text(topName, style: nameStyle)),
                    const SizedBox(width: 8),
                    SizedBox(width: barWidth),
                    const SizedBox(width: 8),
                    Expanded(
  child: Align(
    alignment: Alignment.centerRight,
    child: Text('${_fmt(topValue)} $unitTop', style: valueStyle),
  ),
),
                  ],
                ),
              ),
              SizedBox(
                height: rowH,
                child: Row(
                  children: [
                    SizedBox(width: nameCol, child: Text(bottomName, style: nameStyle)),
                    const SizedBox(width: 8),
                    SizedBox(width: barWidth),
                    const SizedBox(width: 8),
                    Expanded(
  child: Align(
    alignment: Alignment.centerRight,
    child: Text('${_fmt(topValue)} $unitTop', style: valueStyle),
  ),
),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            left: nameCol + 8,
            child: SizedBox(
              width: barWidth,
              height: rowH,
              child: _PercentBar(
                percent: percentCenter,
                maxPercent: 300,
                height: 12,
                squaredRightFill: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(num v) {
    final s = v.toStringAsFixed(3);
    return s.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
class _PlainRow extends StatelessWidget {
  final String name;
  final String value;
  final TextStyle textStyle;
  final TextStyle subStyle;
  final Color? leadingDotColor;

  const _PlainRow({
    required this.name,
    required this.value,
    required this.textStyle,
    required this.subStyle,
    this.leadingDotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (leadingDotColor != null) ...[
          _LegendDot(color: leadingDotColor!),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(name, style: textStyle.copyWith(fontWeight: FontWeight.w600))),
        Text(value, style: subStyle),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  const _LegendDot({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
  }
}

class _StackedBar100 extends StatelessWidget {
  final List<_BarSeg> segments;
  final double height;
  final double radius;
  final TextStyle? legendTextStyle;
  final bool showLegendPercents;

  const _StackedBar100({
    super.key,
    required this.segments,
    this.height = 16,
    this.radius = 8,
    this.legendTextStyle,
    this.showLegendPercents = false,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = segments.where((s) => s.value > 0 && s.value.isFinite).toList();
    final total = filtered.fold<double>(0.0, (s, e) => s + e.value);
    if (total <= 0.0) return const SizedBox.shrink();

    String fmtPct(double v) {
      final p = (v / total) * 100.0;
      return p % 1 == 0 ? '${p.toStringAsFixed(0)}%' : '${p.toStringAsFixed(0)}%';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Row(
            children: filtered.map((s) {
              final flex = ((s.value / total) * 1000).round().clamp(1, 1000);
              return Expanded(flex: flex, child: Container(height: height, color: s.color));
            }).toList(),
          ),
        ),
        if (legendTextStyle != null && legendTextStyle!.color != Colors.transparent) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: filtered.map((s) {
              final label = showLegendPercents ? '${s.label} ${fmtPct(s.value)}' : s.label;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendDot(color: s.color),
                  const SizedBox(width: 6),
                  Text(label, style: legendTextStyle),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _PercentBar extends StatelessWidget {
  final double percent;      // 0..∞
  final double maxPercent;   // z. B. 300
  final double height;
  final bool squaredRightFill;

  const _PercentBar({
    super.key,
    required this.percent,
    required this.maxPercent,
    required this.height,
    this.squaredRightFill = false,
  });

  @override
  Widget build(BuildContext context) {
    final cl = Theme.of(context).colorScheme;
    final capped = percent.clamp(0, maxPercent);
    final fraction = (capped / maxPercent).clamp(0, 1.0);
    final isGood = percent >= 100.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fullW = constraints.maxWidth;
        final barW = fullW * fraction;
        final mark100 = (100 / maxPercent) * fullW;

        return Stack(
          children: [
            Container(
              height: height,
              decoration: BoxDecoration(
                color: cl.surfaceVariant.withOpacity(0.35),
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
            Positioned(
              left: mark100 - 0.5,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: cl.onSurface.withOpacity(0.45)),
            ),
            Container(
              width: barW,
              height: height,
              decoration: BoxDecoration(
                color: isGood ? Colors.green : Colors.red,
                borderRadius: squaredRightFill
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(9999),
                        bottomLeft: Radius.circular(9999),
                      )
                    : BorderRadius.circular(height / 2),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BarSeg {
  final String label;
  final double value;
  final Color color;
  _BarSeg(this.label, this.value, this.color);
}

// ---------------- Datenmodelle ----------------

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
