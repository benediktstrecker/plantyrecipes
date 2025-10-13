// lib/screens/ingredient/ingredient_detail.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:planty_flutter_starter/screens/ingredient/ingredient_nutrient.dart' as nutr;

class IngredientDetailScreen extends StatefulWidget {
  final int ingredientId;
  final String? ingredientName;
  final String? imagePath;

  const IngredientDetailScreen({
    super.key,
    required this.ingredientId,
    this.ingredientName,
    this.imagePath,
  });

  @override
  State<IngredientDetailScreen> createState() => _IngredientDetailScreenState();
}

class _IngredientDetailScreenState extends State<IngredientDetailScreen> {
  int _index = 0;

  Stream<String> _watchIngredientName() {
    if (widget.ingredientName != null && widget.ingredientName!.trim().isNotEmpty) {
      return Stream.value(widget.ingredientName!.trim());
    }
    final t = appDb.ingredients;
    return (appDb.select(t)..where((r) => r.id.equals(widget.ingredientId)))
        .watchSingleOrNull()
        .map((row) => row?.name ?? 'Zutat');
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OverviewTab(ingredientId: widget.ingredientId, imagePath: widget.imagePath),
      _ShoppingTab(ingredientId: widget.ingredientId),
      nutr.IngredientDetailScreen(
        ingredientId: widget.ingredientId,
        ingredientName: widget.ingredientName,
        embedded: true,
      ),
      _RecipesTab(ingredientId: widget.ingredientId),
    ];

    return StreamBuilder<String>(
      stream: _watchIngredientName(),
      builder: (context, snap) {
        final title = snap.data ?? widget.ingredientName ?? 'Zutat';
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(title, style: const TextStyle(color: Colors.white)),
          ),
          body: IndexedStack(index: _index, children: pages),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
            child: GNav(
              backgroundColor: Colors.black,
              tabBackgroundColor: const Color(0xFF0B0B0B),
              color: Colors.white70,
              activeColor: Colors.white,
              padding: const EdgeInsets.all(16),
              gap: 8,
              selectedIndex: _index,
              onTabChange: (i) => setState(() => _index = i),
              tabs: const [
                GButton(icon: Icons.info_outline, text: 'Details'),
                GButton(icon: Icons.shopping_bag_outlined, text: 'Einkauf'),
                GButton(icon: Icons.health_and_safety_outlined, text: 'Nährwerte'),
                GButton(icon: Icons.list_alt, text: 'Rezepte'),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---- Tabs ----

class _OverviewTab extends StatelessWidget {
  final int ingredientId;
  final String? imagePath;
  const _OverviewTab({required this.ingredientId, required this.imagePath});

  // Monate + Seasonality-Farbe je Monat für diese Zutat
  Stream<List<_MonthWithColor>> _watchMonthsWithSeasonality(int ingId) {
    final m = appDb.months;
    final link = appDb.ingredientSeasonality;
    final s = appDb.seasonality;

    final q = appDb
        .select(m)
        .join([
          d.leftOuterJoin(
            link,
            link.monthsId.equalsExp(m.id) & link.ingredientsId.equals(ingId),
          ),
          d.leftOuterJoin(
            s,
            s.id.equalsExp(link.seasonalityId),
          ),
        ])
      ..orderBy([d.OrderingTerm(expression: m.id, mode: d.OrderingMode.asc)]);

    return q.watch().map((rows) {
      return rows.map((r) {
        final month = r.readTable(m);
        final season = r.readTableOrNull(s);
        return _MonthWithColor(
          id: month.id,
          name: month.name,
          color: _parseDbColor(season?.color),
        );
      }).toList();
    });
  }

  // Gibt >0 zurück, wenn es Einträge in ingredient_seasonality für diese Zutat gibt
  Stream<int> _watchSeasonalityCount(int ingId) {
    final link = appDb.ingredientSeasonality;
    final countExp = link.monthsId.count();
    final q = appDb.selectOnly(link)
      ..addColumns([countExp])
      ..where(link.ingredientsId.equals(ingId));
    return q.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Color? _parseDbColor(String? hex) {
    if (hex == null) return null;
    var s = hex.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final v = int.tryParse(s, radix: 16);
    if (v == null) return null;
    return Color(v);
  }

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(color: Colors.white, fontWeight: FontWeight.w600);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ImageBox1x1(imagePath: imagePath),
        const SizedBox(height: 16),

        // Saisonalität nur anzeigen, wenn ingredient_seasonality Daten vorhanden
        StreamBuilder<int>(
          stream: _watchSeasonalityCount(ingredientId),
          builder: (context, countSnap) {
            final hasData = (countSnap.data ?? 0) > 0;
            if (!hasData) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saisonalität', style: label),
                const SizedBox(height: 8),
                StreamBuilder<List<_MonthWithColor>>(
                  stream: _watchMonthsWithSeasonality(ingredientId),
                  builder: (context, snap) {
                    final list = snap.data ?? const <_MonthWithColor>[];
                    if (list.length == 12) {
                      final sorted = [...list]..sort((a, b) => a.id.compareTo(b.id));
                      return _SeasonBarLabeledDb(months: sorted);
                    }
                    return const _SeasonBarSkeleton12();
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ShoppingTab extends StatelessWidget {
  final int ingredientId;
  const _ShoppingTab({required this.ingredientId});
  @override
  Widget build(BuildContext context) {
    const label = TextStyle(color: Colors.white, fontWeight: FontWeight.w600);
    const sub = TextStyle(color: Colors.white70);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(title: Text('Herkunft', style: label), subtitle: Text('', style: sub)),
        Divider(color: Colors.white12),
        ListTile(title: Text('Lagerung', style: label), subtitle: Text('', style: sub)),
        Divider(color: Colors.white12),
        ListTile(title: Text('Alternativen', style: label), subtitle: Text('', style: sub)),
        Divider(color: Colors.white12),
        ListTile(title: Text('Tipps', style: label), subtitle: Text('', style: sub)),
      ],
    );
  }
}

class _RecipesTab extends StatelessWidget {
  final int ingredientId;
  const _RecipesTab({required this.ingredientId});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Rezepte folgen', style: TextStyle(color: Colors.white)));
  }
}

// ---- Bild-Widget 1:1, volle Breite, Pfad-Normalisierung ----

class _ImageBox1x1 extends StatelessWidget {
  final String? imagePath;
  const _ImageBox1x1({required this.imagePath});

  bool _isHttp(String p) => p.startsWith('http://') || p.startsWith('https://');
  bool _isLocalFile(String p) =>
      p.startsWith('/') || RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(p);

  String? _normalize(String? p) {
    if (p == null) return null;
    var s = p.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('/')) s = s.substring(1);
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final size = constraints.maxWidth;
        final norm = _normalize(imagePath);

        Widget child;
        if (norm == null) {
          child = const ColoredBox(color: Color(0xFF0B0B0B));
        } else if (_isHttp(norm)) {
          child = Image.network(
            norm,
            fit: BoxFit.cover,
            loadingBuilder: (_, w, progress) =>
                progress == null ? w : const ColoredBox(color: Color(0xFF0B0B0B)),
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF0B0B0B)),
          );
        } else if (!kIsWeb && _isLocalFile(norm)) {
          child = Image.file(
            File(norm),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF0B0B0B)),
          );
        } else {
          child = Image.asset(
            norm,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF0B0B0B)),
          );
        }

        return SizedBox(
          width: double.infinity,
          height: size, // 1:1
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
        );
      },
    );
  }
}

// ---- Saisonalität mit Farben aus DB je Monat ----

class _MonthWithColor {
  final int id;       // 1..12
  final String name;  // "Januar" ...
  final Color? color; // null => inaktiv
  _MonthWithColor({required this.id, required this.name, required this.color});
}

class _SeasonBarLabeledDb extends StatelessWidget {
  final List<_MonthWithColor> months; // genau 12 Einträge, id 1..12
  final double height;
  final double gap;

  const _SeasonBarLabeledDb({
    super.key,
    required this.months,
    this.height = 16,
    this.gap = 3,
  });

  String _abbr(String name) {
    if (name.length <= 3) return name;
    return name.substring(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    final base = const Color(0xFF0F0F0F);
    final frame = const Color(0xFF0B0B0B);
    final border = const Color(0xFF1A1A1A);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: frame,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(months.length, (i) {
              final m = months[i];
              final col = m.color ?? base;
              return Expanded(
                child: Container(
                  height: height,
                  margin: EdgeInsets.only(right: i == months.length - 1 ? 0 : gap),
                  decoration: BoxDecoration(
                    color: col,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(i == 0 ? 8 : 3),
                      right: Radius.circular(i == months.length - 1 ? 8 : 3),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(months.length, (i) {
              final m = months[i];
              return Expanded(
                child: Text(
                  _abbr(m.name),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                  overflow: TextOverflow.visible,
                  maxLines: 1,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// Fallback, falls DB leer/nicht 12 Einträge
class _SeasonBarSkeleton12 extends StatelessWidget {
  const _SeasonBarSkeleton12({super.key});

  @override
  Widget build(BuildContext context) {
    final frame = const Color(0xFF0B0B0B);
    final base = const Color(0xFF0F0F0F);
    final border = const Color(0xFF1A1A1A);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: frame,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        children: List.generate(12, (i) {
          return Expanded(
            child: Container(
              height: 16,
              margin: EdgeInsets.only(right: i == 11 ? 0 : 3),
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(i == 0 ? 8 : 3),
                  right: Radius.circular(i == 11 ? 8 : 3),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
