// lib/screens/ingredient/ingredient_detail.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:drift/drift.dart' as d;

// Navigation
import 'package:planty_flutter_starter/utils/easy_swipe_nav.dart';

// DB
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

// Layout / Farben
import 'package:planty_flutter_starter/design/layout.dart';

// Andere Ingredient-Seiten
import 'package:planty_flutter_starter/screens/ingredient/ingredient_shopping.dart'
    as shop;
import 'package:planty_flutter_starter/screens/ingredient/ingredient_nutrient.dart'
    as nutr;
import 'package:planty_flutter_starter/screens/ingredient/ingredient_recipe.dart'
    as rec;

// ------------------------------------------------------------
// INGREDIENT DETAIL SCREEN
// ------------------------------------------------------------
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
  State<IngredientDetailScreen> createState() =>
      _IngredientDetailScreenState();
}

class _IngredientDetailScreenState extends State<IngredientDetailScreen>
    with EasySwipeNav {
  int _selectedIndex = 0;

  @override
  int get currentIndex => _selectedIndex;

  void _navigateToPage(int index) {
    if (!mounted || index == _selectedIndex) return;

    final toRight = index > _selectedIndex;
    final screen = _screenForIndex(index);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, anim, __, child) {
          final begin = toRight ? const Offset(1, 0) : const Offset(-1, 0);
          final tween = Tween(begin: begin, end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(position: anim.drive(tween), child: child);
        },
      ),
    );

    setState(() => _selectedIndex = index);
  }

  Widget _screenForIndex(int index) {
    switch (index) {
      case 0:
        return IngredientDetailScreen(
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
        return nutr.IngredientNutrientScreen(
          ingredientId: widget.ingredientId,
          ingredientName: widget.ingredientName,
          imagePath: widget.imagePath,
        );
      default:
        return rec.IngredientRecipeScreen(
          ingredientId: widget.ingredientId,
          ingredientName: widget.ingredientName,
          imagePath: widget.imagePath,
        );
    }
  }

  @override
  void goToIndex(int index) => _navigateToPage(index);

  // ---- Ingredient name stream ----
  Stream<String> _watchIngredientName() {
    if (widget.ingredientName != null &&
        widget.ingredientName!.trim().isNotEmpty) {
      return Stream.value(widget.ingredientName!.trim());
    }

    final t = appDb.ingredients;
    return (appDb.select(t)..where((r) => r.id.equals(widget.ingredientId)))
        .watchSingleOrNull()
        .map((r) => r?.name ?? "Zutat");
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: onSwipeStart,
      onHorizontalDragUpdate: onSwipeUpdate,
      onHorizontalDragEnd: onSwipeEnd,
      child: StreamBuilder<String>(
        stream: _watchIngredientName(),
        builder: (_, snap) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: null,
              actions: [
                _buildBookmarkButton(),
                IconButton(
                  icon: const Icon(Icons.print, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
            body: _OverviewTab(
              ingredientId: widget.ingredientId,
              imagePath: widget.imagePath,
            ),
            bottomNavigationBar: _bottomNav(),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // BOOKMARK BUTTON
  // ------------------------------------------------------------
  Widget _buildBookmarkButton() {
    return StreamBuilder<Ingredient?>(
      stream: (appDb.select(appDb.ingredients)
            ..where((i) => i.id.equals(widget.ingredientId)))
          .watchSingleOrNull(),
      builder: (_, snap) {
        final ing = snap.data;
        final isBookmarked = ing?.bookmark ?? false;

        return IconButton(
          icon: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.white,
          ),
          onPressed: () async {
            await (appDb.update(appDb.ingredients)
                  ..where((i) => i.id.equals(widget.ingredientId)))
                .write(
              IngredientsCompanion(
                bookmark: d.Value(!isBookmarked),
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // BOTTOM NAVIGATION
  // ------------------------------------------------------------
  Widget _bottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
      child: GNav(
        backgroundColor: Colors.black,
        tabBackgroundColor: const Color(0xFF0B0B0B),
        color: Colors.white70,
        activeColor: Colors.white,
        selectedIndex: _selectedIndex,
        onTabChange: _navigateToPage,
        padding: const EdgeInsets.all(16),
        gap: 8,
        tabs: const [
          GButton(icon: Icons.info_outline, text: 'Details'),
          GButton(icon: Icons.shopping_bag_outlined, text: 'Einkauf'),
          GButton(icon: Icons.stacked_bar_chart, text: 'Nährwerte'),
          GButton(icon: Icons.list_alt, text: 'Rezepte'),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// OVERVIEW TAB
// ------------------------------------------------------------
class _OverviewTab extends StatelessWidget {
  final int ingredientId;
  final String? imagePath;

  const _OverviewTab({
    required this.ingredientId,
    required this.imagePath,
  });

  Color? _parseColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) return null;
    var s = hex.replaceAll('#', '');
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final val = int.tryParse(s, radix: 16);
    if (val == null) return null;
    return Color(val);
  }

  // ---------------- SAISONALITÄT ----------------
  Stream<List<_MonthWithColor>> _watchMonthsWithSeasonality(int id) {
    final m = appDb.months;
    final link = appDb.ingredientSeasonality;
    final s = appDb.seasonality;

    final q = appDb.select(m).join([
      d.leftOuterJoin(
        link,
        link.monthsId.equalsExp(m.id) & link.ingredientsId.equals(id),
      ),
      d.leftOuterJoin(s, s.id.equalsExp(link.seasonalityId)),
    ])
      ..orderBy([d.OrderingTerm(expression: m.id)]);

    return q.watch().map((rows) {
      return rows.map((r) {
        final month = r.readTable(m);
        final season = r.readTableOrNull(s);
        return _MonthWithColor(
          id: month.id,
          name: month.name,
          color: _parseColor(season?.color),
        );
      }).toList();
    });
  }

  Stream<int> _watchSeasonalityCount(int id) {
    final link = appDb.ingredientSeasonality;
    final countExp = link.monthsId.count();
    final q = appDb.selectOnly(link)
      ..addColumns([countExp])
      ..where(link.ingredientsId.equals(id));
    return q.watchSingle().map((r) => r.read(countExp) ?? 0);
  }

  // ---------------- EINHEITEN ----------------
  Stream<List<_IngredientUnitDisplay>> _watchIngredientUnits(int id) {
    final iu = appDb.ingredientUnits;
    final u = appDb.units;

    final q = appDb.select(iu).join([
      d.innerJoin(u, u.code.equalsExp(iu.unitCode)),
    ])
      ..where(iu.ingredientId.equals(id));

    return q.watch().map((rows) {
      return rows.map((r) {
        final row = r.readTable(iu);
        final unit = r.readTable(u);
        return _IngredientUnitDisplay(
          label: unit.label,
          unitCode: row.unitCode,
          amount: row.amount,
        );
      }).toList();
    });
  }

  // ---------------- ALTERNATIVES ----------------
  Stream<List<_AltGroup>> _watchAlternatives(int id) {
    final ia = appDb.ingredientAlternatives;
    final a = appDb.alternatives;
    final ing = appDb.ingredients;

    final q = appDb.select(ia).join([
      d.innerJoin(a, a.id.equalsExp(ia.alternativesId)),
      d.innerJoin(ing, ing.id.equalsExp(ia.relatedIngredientId)),
    ])
      ..where(ia.ingredientId.equals(id))
      ..orderBy([
        d.OrderingTerm.asc(ia.alternativesId),
        d.OrderingTerm.asc(ing.name),
      ]);

    return q.watch().map((rows) {
      final out = <_AltGroup>[];

      for (final r in rows) {
        final alt = r.readTable(a);
        final ingRow = r.readTable(ing);

        final group = out.firstWhere(
          (g) => g.id == alt.id,
          orElse: () {
            final g = _AltGroup(id: alt.id, name: alt.name, items: []);
            out.add(g);
            return g;
          },
        );

        group.items.add(ingRow);
      }

      return out;
    });
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    const label = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ImageBox1x1(imagePath: imagePath),
        const SizedBox(height: 16),

        // ---------------- ACTION BUTTONS ----------------
        StreamBuilder<Ingredient?>(
          stream: (appDb.select(appDb.ingredients)
                ..where((i) => i.id.equals(ingredientId)))
              .watchSingleOrNull(),
          builder: (_, snap) {
            final ing = snap.data;
            if (ing == null) return const SizedBox.shrink();

            return StreamBuilder<List<StorageCategory>>(
              stream: appDb.select(appDb.storageCategories).watch(),
              builder: (_, catSnap) {
                final storageCats = catSnap.data ?? [];

                StorageCategory? currentCat;
                if (storageCats.isNotEmpty) {
                  currentCat = storageCats.firstWhere(
                    (c) => c.id == ing.storagecatId,
                    orElse: () => storageCats.first,
                  );
                } else {
                  currentCat = null;
                }

                return StreamBuilder<TrafficlightData?>(
                  stream: ing.trafficlightId == null
                      ? Stream<TrafficlightData?>.value(null)
                      : (appDb.select(appDb.trafficlight)
                            ..where(
                              (t) => t.id.equals(ing.trafficlightId!),
                            ))
                          .watchSingleOrNull(),
                  builder: (_, trafficSnap) {
                    final traffic = trafficSnap.data;

                    final Color? trafficColor =
                        _parseColor(traffic?.color);
                    final Color? storageColor =
                        _parseColor(currentCat?.color);

                    return Column(
                      children: [
                        Row(
                          children: [
                            // 1) Ampel
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.traffic,
                                label: "Ampel",
                                color: trafficColor ?? darkgreen,
                                onTap: () {},
                              ),
                            ),

                            // 2) Einkaufen (ohne Funktion)
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.shopping_bag,
                                label: "Einkaufen",
                                onTap: () {},
                              ),
                            ),

                            // 3) Plan
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.event,
                                label: "Plan",
                                onTap: () {},
                              ),
                            ),

                            // 4) Lagerung (Bild + Zyklus)
                            Expanded(
                              child: _ActionButton(
                                icon: null,
                                imageAsset: currentCat?.icon,
                                label: currentCat?.name ?? "Lagerung",
                                color: storageColor ?? darkgreen,
                                onTap: () async {
                                  if (storageCats.isEmpty ||
                                      currentCat == null) return;

                                  final idx = storageCats.indexWhere(
                                    (c) => c.id == currentCat!.id,
                                  );
                                  final nextIndex =
                                      (idx < 0 ? 0 : idx + 1) %
                                          storageCats.length;
                                  final next = storageCats[nextIndex];

                                  await (appDb.update(appDb.ingredients)
                                        ..where(
                                            (r) => r.id.equals(ingredientId)))
                                      .write(
                                    IngredientsCompanion(
                                      storagecatId: d.Value(next.id),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // 5) Favorit (bool)
                            Expanded(
                              child: _ActionButton(
                                icon: (ing.favorite ?? false)
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                label: "Favorit",
                                color: (ing.favorite ?? false)
                                    ? Colors.red.shade900
                                    : darkgreen,
                                onTap: () async {
                                  await (appDb
                                          .update(appDb.ingredients)
                                        ..where((r) =>
                                            r.id.equals(ingredientId)))
                                      .write(
                                    IngredientsCompanion(
                                      favorite: d.Value(
                                        !(ing.favorite ?? false),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // 6) Edit
                            Expanded(
                              child: _ActionButton(
                                icon: Icons.edit_square,
                                label: "Edit",
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),

        // ---------------- NAME ----------------
        StreamBuilder<Ingredient?>(
          stream: (appDb.select(appDb.ingredients)
                ..where((i) => i.id.equals(ingredientId)))
              .watchSingleOrNull(),
          builder: (_, snap) {
            final ing = snap.data;
            return Text(
              ing?.name ?? "",
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        const SizedBox(height: 14),

        // ---------------- SAISONALITÄT + EINHEITEN + ALTERNATIVES ----------------
        StreamBuilder<int>(
          stream: _watchSeasonalityCount(ingredientId),
          builder: (_, countSnap) {
            final widgets = <Widget>[];
            final hasSeason = (countSnap.data ?? 0) > 0;

            // SAISONALITÄT
            if (hasSeason) {
              widgets.add(const Text("Saisonalität", style: label));
              widgets.add(const SizedBox(height: 8));
              widgets.add(
                StreamBuilder<List<_MonthWithColor>>(
                  stream: _watchMonthsWithSeasonality(ingredientId),
                  builder: (_, snap) {
                    final m = snap.data ?? [];
                    if (m.length == 12) {
                      return _SeasonBarLabeledDb(months: m);
                    }
                    return const _SeasonBarSkeleton12();
                  },
                ),
              );
              widgets.add(const SizedBox(height: 16));
            }

            // EINHEITEN
            widgets.add(
              StreamBuilder<List<_IngredientUnitDisplay>>(
                stream: _watchIngredientUnits(ingredientId),
                builder: (_, snap) {
                  final data = snap.data ?? [];
                  if (data.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Einheiten", style: label),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B0B0B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1A1A1A)),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: data.map((row) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    row.label,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    "${row.amount} g/${row.unitCode}",
                                    style: const TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );

            // ALTERNATIVES
            widgets.add(
              StreamBuilder<List<_AltGroup>>(
                stream: _watchAlternatives(ingredientId),
                builder: (_, snap) {
                  final groups = snap.data ?? [];
                  if (groups.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final g in groups) ...[
                        const SizedBox(height: 16),
                        Text(g.name, style: label),
                        const SizedBox(height: 8),
                        _ImageListView(items: g.items),
                      ],
                    ],
                  );
                },
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgets,
            );
          },
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// HILFSKLASSEN
// ------------------------------------------------------------
class _IngredientUnitDisplay {
  final String label;
  final String unitCode;
  final double amount;

  _IngredientUnitDisplay({
    required this.label,
    required this.unitCode,
    required this.amount,
  });
}

class _MonthWithColor {
  final int id;
  final String name;
  final Color? color;

  _MonthWithColor({
    required this.id,
    required this.name,
    required this.color,
  });
}

class _AltGroup {
  final int id;
  final String name;
  final List<Ingredient> items;

  _AltGroup({
    required this.id,
    required this.name,
    required this.items,
  });
}

// ------------------------------------------------------------
// IMAGE LIST VIEW (Alternatives List)
// ------------------------------------------------------------
class _ImageListView extends StatelessWidget {
  final List<Ingredient> items;

  const _ImageListView({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final ing = items[i];
        final img = (ing.picture == null || ing.picture!.isEmpty)
            ? 'assets/images/placeholder.jpg'
            : ing.picture!;

        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 280),
                reverseTransitionDuration:
                    const Duration(milliseconds: 280),
                pageBuilder: (_, __, ___) => IngredientDetailScreen(
                  ingredientId: ing.id,
                  ingredientName: ing.name,
                  imagePath: img,
                ),
                transitionsBuilder: (_, animation, __, child) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ),
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: offsetAnimation,
                      child: child,
                    ),
                  );
                },
              ),
            );
          },
          splashColor: Colors.white10,
          highlightColor: Colors.white10,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 45,
                    height: 45,
                    color: Colors.black,
                    child: Image.asset(
                      img,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ing.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                (ing.bookmark == true)
                    ? const Icon(Icons.bookmark, color: Colors.white)
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------
// IMAGE BOX 1x1
// ------------------------------------------------------------
class _ImageBox1x1 extends StatelessWidget {
  final String? imagePath;
  const _ImageBox1x1({required this.imagePath});

  bool _isHttp(String p) => p.startsWith('http');
  bool _isLocal(String p) =>
      p.startsWith('/') || RegExp(r'^[a-zA-Z]:').hasMatch(p);

  @override
  Widget build(BuildContext context) {
    final p = imagePath?.trim();
    Widget img;

    if (p == null || p.isEmpty) {
      img = const ColoredBox(color: Color(0xFF0B0B0B));
    } else if (_isHttp(p)) {
      img = Image.network(p, fit: BoxFit.cover);
    } else if (!kIsWeb && _isLocal(p)) {
      img = Image.file(File(p), fit: BoxFit.cover);
    } else {
      img = Image.asset(p, fit: BoxFit.cover);
    }

    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: img,
      ),
    );
  }
}

// ------------------------------------------------------------
// ACTION BUTTON
// ------------------------------------------------------------
class _ActionButton extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? imageAsset;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    this.icon,
    this.imageAsset,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(40),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color ?? darkgreen,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: imageAsset != null
                    ? ColorFiltered(
                        colorFilter: const ColorFilter.matrix([
                          -1, 0, 0, 0, 255,
                          0, -1, 0, 0, 255,
                          0, 0, -1, 0, 255,
                          0, 0, 0, 1, 0,
                        ]),
                        child: Image.asset(
                          imageAsset!,
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Icon(icon, size: 26, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 30,
            child: Center(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                softWrap: true,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// SAISONBAR
// ------------------------------------------------------------
class _SeasonBarLabeledDb extends StatelessWidget {
  final List<_MonthWithColor> months;
  const _SeasonBarLabeledDb({super.key, required this.months});

  @override
  Widget build(BuildContext context) {
    final base = const Color(0xFF0F0F0F);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A1A1A)),
      ),
      child: Column(
        children: [
          Row(
            children: months.map((m) {
              return Expanded(
                child: Container(
                  height: 16,
                  margin: EdgeInsets.only(right: m == months.last ? 0 : 3),
                  decoration: BoxDecoration(
                    color: m.color ?? base,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(m == months.first ? 8 : 3),
                      right: Radius.circular(m == months.last ? 8 : 3),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Row(
            children: months.map((m) {
              final abbr =
                  m.name.length > 3 ? m.name.substring(0, 3) : m.name;
              return Expanded(
                child: Text(
                  abbr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SeasonBarSkeleton12 extends StatelessWidget {
  const _SeasonBarSkeleton12({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0B),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
