// lib/screens/recipe/recipe_detail.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:drift/drift.dart' as d;
import 'package:url_launcher/url_launcher.dart';
import 'package:planty_flutter_starter/design/layout.dart';

// navigation
import 'package:planty_flutter_starter/utils/easy_swipe_nav.dart';

// db
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

// weitere recipe-screens
import 'package:planty_flutter_starter/screens/recipe/recipe_ingredient.dart'
    as ing;
import 'package:planty_flutter_starter/screens/recipe/recipe_preparation.dart'
    as prep;
import 'package:planty_flutter_starter/screens/recipe/recipe_nutrient.dart'
    as nutr;

class RecipeDetailScreen extends StatefulWidget {
  final int recipeId;
  final String title;
  final String? imagePath;

  const RecipeDetailScreen({
    super.key,
    required this.recipeId,
    required this.title,
    this.imagePath,
  });

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen>
    with EasySwipeNav {
  int _selectedIndex = 0;

  @override
  int get currentIndex => _selectedIndex;

  void _navigateToPage(int index) {
    if (!mounted || index == _selectedIndex) return;
    if (index < 0 || index > 3) return;
    final fromRight = index > _selectedIndex;
    final target = _widgetForIndex(index);

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => target,
      transitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, __, child) {
        final begin = fromRight ? const Offset(1, 0) : const Offset(-1, 0);
        final tween = Tween(begin: begin, end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ));
    setState(() => _selectedIndex = index);
  }

  Widget _widgetForIndex(int index) {
    switch (index) {
      case 0:
        return RecipeDetailScreen(
          recipeId: widget.recipeId,
          title: widget.title,
          imagePath: widget.imagePath,
        );
      case 1:
        return ing.RecipeIngredientScreen(
          recipeId: widget.recipeId,
          title: widget.title,
          imagePath: widget.imagePath,
        );
      case 2:
        return prep.RecipePreparationScreen(
          recipeId: widget.recipeId,
          title: widget.title,
          imagePath: widget.imagePath,
        );
      case 3:
      default:
        return nutr.RecipeNutrientScreen(
          recipeId: widget.recipeId,
          title: widget.title,
          imagePath: widget.imagePath,
        );
    }
  }

  @override
  void goToIndex(int index) => _navigateToPage(index);

  Stream<Recipe?> _watchRecipe() {
    final t = appDb.recipes;
    return (appDb.select(t)..where((r) => r.id.equals(widget.recipeId)))
        .watchSingleOrNull();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: onSwipeStart,
      onHorizontalDragUpdate: onSwipeUpdate,
      onHorizontalDragEnd: onSwipeEnd,
      child: StreamBuilder<Recipe?>(
        stream: _watchRecipe(),
        builder: (context, snap) {
          final recipe = snap.data;
          final resolvedTitle = recipe?.name ?? widget.title;
          final imagePath = recipe?.picture ?? widget.imagePath;

          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: null, // kein Texttitel
              actions: [
                // --- Bookmark ---
                StreamBuilder<Recipe?>(
                  stream: (appDb.select(appDb.recipes)
                        ..where((r) => r.id.equals(widget.recipeId)))
                      .watchSingleOrNull(),
                  builder: (context, snap) {
                    final recipe = snap.data;
                    final isBookmarked = (recipe?.bookmark ?? 0) == 1;

                    return IconButton(
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        final newVal = isBookmarked ? 0 : 1;
                        await (appDb.update(appDb.recipes)
                              ..where((r) => r.id.equals(widget.recipeId)))
                            .write(
                          RecipesCompanion(bookmark: d.Value(newVal)),
                        );
                      },
                    );
                  },
                ),

                // --- Print ---
                IconButton(
                  icon: const Icon(Icons.print, color: Colors.white),
                  onPressed: () {
                    // TODO: Funktion ergänzen
                  },
                ),

                // --- More / Menü ---
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {
                    // TODO: Funktion ergänzen
                  },
                ),
              ],
            ),
            body: _OverviewTab(
              recipe: recipe,
              imagePath: imagePath,
              recipeId: widget.recipeId,
              title: resolvedTitle,
            ),
            bottomNavigationBar: Container(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
              child: GNav(
                backgroundColor: Colors.black,
                tabBackgroundColor: const Color(0xFF0B0B0B),
                color: Colors.white70,
                activeColor: Colors.white,
                padding: const EdgeInsets.all(16),
                gap: 8,
                selectedIndex: _selectedIndex,
                onTabChange: _navigateToPage,
                tabs: const [
                  GButton(icon: Icons.info_outline, text: 'Details'),
                  GButton(icon: Icons.eco, text: 'Zutaten'),
                  GButton(icon: Icons.local_dining, text: 'Zubereitung'),
                  GButton(icon: Icons.stacked_bar_chart, text: 'Nährwerte'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------- OVERVIEW TAB ----------------------
class _OverviewTab extends StatefulWidget {
  final Recipe? recipe;
  final String? imagePath;

  // NEU: für Navigation/Weitergabe
  final int recipeId;
  final String title;

  const _OverviewTab({
    required this.recipe,
    required this.imagePath,
    required this.recipeId,
    required this.title,
  });

  @override
  State<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends State<_OverviewTab> {
  Stream<RecipeCategory?> _watchRecipeCategory(int recipeId) {
    final r = appDb.recipes;
    final c = appDb.recipeCategories;

    final query = (appDb.select(r)..where((t) => t.id.equals(recipeId)))
        .join([d.innerJoin(c, c.id.equalsExp(r.recipeCategory))]);

    return query.watchSingleOrNull().map((row) => row?.readTable(c));
  }

  Stream<List<Tag>> _watchRecipeTags(int recipeId) {
    final rt = appDb.recipeTags;
    final t = appDb.tags;

    final tagIdsQ = appDb.selectOnly(rt)
      ..addColumns([rt.tagId])
      ..where(rt.recipeId.equals(recipeId));

    final q = appDb.select(t)..where((x) => x.id.isInQuery(tagIdsQ));
    return q.watch();
  }

  Stream<List<_MonthWithColor>> _watchRecipeSeasonality(int recipeId) {
    final m = appDb.months;
    final s = appDb.seasonality;
    final link = appDb.ingredientSeasonality;
    final ri = appDb.recipeIngredients;

    final riSub = appDb.selectOnly(ri)
      ..addColumns([ri.ingredientId])
      ..where(ri.recipeId.equals(recipeId));

    final q = appDb.select(m).join([
      d.leftOuterJoin(
        link,
        link.monthsId.equalsExp(m.id) & link.ingredientsId.isInQuery(riSub),
      ),
      d.leftOuterJoin(s, s.id.equalsExp(link.seasonalityId)),
    ])
      ..orderBy([d.OrderingTerm(expression: m.id)]);

    return q.watch().map((rows) {
      final byMonth = <int, int>{};
      final colorByMonth = <int, String?>{};
      for (final r in rows) {
        final month = r.readTable(m);
        final season = r.readTableOrNull(s);
        final id = month.id;
        final val = season?.id ?? 0;
        if (!byMonth.containsKey(id) || val > (byMonth[id] ?? 0)) {
          byMonth[id] = val;
          colorByMonth[id] = season?.color;
        }
      }
      return List.generate(12, (i) {
        final mid = i + 1;
        final hex = colorByMonth[mid];
        return _MonthWithColor(
          id: mid,
          name: _monthNames[i],
          color: _parseDbColor(hex),
        );
      });
    });
  }

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mär',
    'Apr',
    'Mai',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Okt',
    'Nov',
    'Dez'
  ];

  static Color? _parseDbColor(String? hex) {
    if (hex == null) return null;
    var s = hex.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    final v = int.tryParse(s, radix: 16);
    return v != null ? Color(v) : null;
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final recipeId = widget.recipeId;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---------- Bild + Kategorie ----------
        Stack(
          children: [
            _ImageBox1x1(imagePath: widget.imagePath),
            /*Positioned(
              top: 10,
              left: 10,
              child: StreamBuilder<RecipeCategory?>(
                stream: _watchRecipeCategory(recipeId),
                builder: (context, catSnap) {
                  final cat = catSnap.data;
                  if (cat == null) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      cat.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),
            ),
            // --- Bookmark oben rechts ---
Positioned(
  top: 12,
  right: 12,
  child: StreamBuilder<Recipe?>(
    stream: (appDb.select(appDb.recipes)
          ..where((r) => r.id.equals(recipeId)))
        .watchSingleOrNull(),
    builder: (context, snap) {
      final recipe = snap.data;
      final isBookmarked = (recipe?.bookmark ?? 0) == 1;

      return GestureDetector(
        onTap: () async {
          final newVal = isBookmarked ? 0 : 1;
          await (appDb.update(appDb.recipes)
                ..where((r) => r.id.equals(recipeId)))
              .write(RecipesCompanion(bookmark: d.Value(newVal)));
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isBookmarked
                ? const Color(0xFF2C2C2C)
                : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    },
  ),
),*/
          ],
        ),

        const SizedBox(height: 12),

        // ---------- Action Buttons ----------
        StreamBuilder(
          stream: (appDb.select(appDb.recipes)
                ..where((r) => r.id.equals(recipeId)))
              .join([
            d.leftOuterJoin(
              appDb.units,
              appDb.units.code.equalsExp(appDb.recipes.portionUnit),
            ),
          ]).watchSingleOrNull(),
          builder: (context, snap) {
            final row = snap.data;
            final recipe = row?.readTable(appDb.recipes);
            final unit = row?.readTableOrNull(appDb.units);
            if (recipe == null) return const SizedBox.shrink();

            final portionNumber = recipe.portionNumber ?? 0;
            final unitLabel = unit?.label ?? recipe.portionUnit ?? '';
            final unitPlural = unit?.plural ?? unitLabel;

            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // --- Portionen Button ---
                    Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: darkgreen,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$portionNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          portionNumber <= 1 ? unitLabel : unitPlural,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),

                    // --- EINKAUFEN Button ---
                    _ActionButton(
  icon: Icons.shopping_bag,
  label: 'Einkaufen',
  onTap: () {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ing.RecipeIngredientScreen(
          recipeId: widget.recipeId,
          title: widget.title,
          imagePath: widget.imagePath,
          autoSelectNonStorageCat1: true,   // ← WICHTIG!
        ),
      ),
    );
  },
),


                    // --- PLAN Button (vor Kochen) ---
                    _ActionButton(
                      icon: Icons.event,
                      label: 'Plan',
                      onTap: () {},
                    ),

                    // --- KOCHEN Button: nur Zähler, kein Datum ---
                    GestureDetector(
                      onTap: () async {
                        final newVal = (recipe.cookCounter ?? 0) + 1;
                        final nowIso = DateTime.now().toIso8601String();
                        await (appDb.update(appDb.recipes)
                              ..where((r) => r.id.equals(recipeId)))
                            .write(
                          RecipesCompanion(
                            cookCounter: d.Value(newVal),
                            lastCooked: d.Value(nowIso),
                          ),
                        );
                      },
                      onLongPress: () async {
                        await (appDb.update(appDb.recipes)
                              ..where((r) => r.id.equals(recipeId)))
                            .write(
                          const RecipesCompanion(cookCounter: d.Value(0)),
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: darkgreen,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${recipe.cookCounter ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Mal gekocht',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    // --- FAVORIT Button ---
                    _ActionButton(
                      icon: (recipe.favorite ?? 0) == 1
                          ? Icons.favorite
                          : Icons.favorite_border,
                      label: 'Favorit',
                      color: (recipe.favorite ?? 0) == 1
                          ? Colors.red.shade900
                          : darkgreen,
                      onTap: () async {
                        final newVal =
                            (recipe.favorite ?? 0) == 1 ? 0 : 1;
                        await (appDb.update(appDb.recipes)
                              ..where((r) => r.id.equals(recipeId)))
                            .write(
                          RecipesCompanion(favorite: d.Value(newVal)),
                        );
                      },
                    ),

                    // --- EDIT Button ---
                    _ActionButton(
                      icon: Icons.edit_square,
                      label: 'Edit',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),

        // ---------- Rezeptname ----------
        Text(
          recipe?.name ?? '',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 14),

        // ---------- Beschreibung ----------
        StreamBuilder<Recipe?>(
          stream: (appDb.select(appDb.recipes)
                ..where((r) => r.id.equals(recipeId)))
              .watchSingleOrNull(),
          builder: (context, snap) {
            final desc = snap.data?.description?.trim() ?? '';
            if (desc.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                desc,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            );
          },
        ),

        // ---------- Tags (mit Kategorie zuerst, gleiche Größe wie andere) ----------
        StreamBuilder<RecipeCategory?>(
          stream: ((appDb.select(appDb.recipeCategories)
                ..where(
                  (c) => c.id.equalsExp(appDb.recipes.recipeCategory),
                ))
              .join([
                d.innerJoin(
                  appDb.recipes,
                  appDb.recipes.recipeCategory
                          .equalsExp(appDb.recipeCategories.id) &
                      appDb.recipes.id.equals(recipeId),
                ),
              ])
              .watchSingleOrNull()
              .map((row) => row?.readTable(appDb.recipeCategories))),
          builder: (context, catSnap) {
            final cat = catSnap.data;

            return StreamBuilder<List<Tag>>(
              stream: _watchRecipeTags(recipeId),
              builder: (context, snap) {
                final tags = (snap.data ?? [])
                  ..sort((a, b) =>
                      a.tagCategorieId.compareTo(b.tagCategorieId));

                final children = <Widget>[];

                // Kategorie zuerst
                if (cat != null) {
                  children.add(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        image: cat.image != null && cat.image!.isNotEmpty
                            ? DecorationImage(
                                image: AssetImage(cat.image!),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.35),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                        color: const Color(0xFF2C2C2C),
                      ),
                      child: Text(
                        cat.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }

                // Alle Tags danach
                children.addAll(tags.map(
                  (t) => _TagPill(
                    label: t.name,
                    image: t.image,
                    hexColor: t.color,
                  ),
                ));

                if (children.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: children,
                  ),
                );
              },
            );
          },
        ),

        // ---------- Trenner zwischen Tags und Saisonalität ----------
        const SizedBox(height: 18),
        Divider(
          color: Colors.white24,
          thickness: 0.6,
          height: 0,
        ),
        const SizedBox(height: 18),

        // ------ Saisonalität ---------
        const SizedBox(height: 16),
        const Text(
          'Saisonalität',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<_MonthWithColor>>(
          stream: _watchRecipeSeasonality(recipeId),
          builder: (context, snap) {
            final list = snap.data ?? [];
            if (list.length == 12) {
              return _SeasonBarLabeledDb(months: list);
            }
            return const _SeasonBarSkeleton12();
          },
        ),

        // ---------- Zuletzt gekocht ----------
        const SizedBox(height: 16),
        const Text(
          'Zuletzt gekocht',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<Recipe?>(
          stream: (appDb.select(appDb.recipes)
                ..where((r) => r.id.equals(recipeId)))
              .watchSingleOrNull(),
          builder: (context, snap) {
            final recipe = snap.data;
            final lastCooked = recipe?.lastCooked;

            String displayText;
            if (lastCooked == null || lastCooked.isEmpty) {
              displayText = 'Noch nie gekocht';
            } else {
              try {
                final dt = DateTime.parse(lastCooked);
                displayText =
                    '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}   ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
              } catch (_) {
                displayText = lastCooked;
              }
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0B0B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A1A1A)),
              ),
              child: Text(
                displayText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                ),
                textAlign: TextAlign.left,
              ),
            );
          },
        ),

        // ---------- Tipps ----------
        StreamBuilder<Recipe?>(
          stream: (appDb.select(appDb.recipes)
                ..where((r) => r.id.equals(recipeId)))
              .watchSingleOrNull(),
          builder: (context, snap) {
            final recipe = snap.data;
            final tip = recipe?.tip?.trim() ?? '';

            if (tip.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Tipps',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B0B0B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1A1A1A)),
                  ),
                  child: Text(
                    tip,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            );
          },
        ),

        // ---------- Inspiriert von ----------
        const SizedBox(height: 16),
        const Text(
          'Inspiriert von',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<Recipe?>(
          stream: (appDb.select(appDb.recipes)
                ..where((r) => r.id.equals(recipeId)))
              .watchSingleOrNull(),
          builder: (context, snap) {
            final recipe = snap.data;
            final inspired = recipe?.inspiredBy?.trim() ?? '';

            if (inspired.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0B0B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1A1A1A)),
                ),
                child: const Text(
                  'Eigenkreation',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.left,
                ),
              );
            }

            final uri = Uri.tryParse(inspired);
            final isValidUrl =
                uri != null && uri.hasScheme && uri.host.isNotEmpty;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 10, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0B0B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1A1A1A)),
              ),
              child: isValidUrl
                  ? InkWell(
                      onTap: () async {
                        try {
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            debugPrint('Kann URL nicht starten: $uri');
                          }
                        } catch (e) {
                          debugPrint(
                              'Fehler beim Öffnen der URL: $e');
                        }
                      },
                      child: Text(
                        inspired,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : Text(
                      inspired,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                      textAlign: TextAlign.left,
                    ),
            );
          },
        ),
      ],
    );
  }
}

// ---------- ActionButton ----------
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ---------- Hilfsklassen ----------
class _MonthWithColor {
  final int id;
  final String name;
  final Color? color;
  _MonthWithColor({required this.id, required this.name, required this.color});
}

class _TagPill extends StatelessWidget {
  final String label;
  final String? image;
  final String? hexColor;
  const _TagPill({required this.label, this.image, this.hexColor});

  @override
  Widget build(BuildContext context) {
    final bg = _OverviewTabState._parseDbColor(hexColor) ??
        const Color(0xFF2C2C2C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (image != null && image!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Image.asset(image!, width: 16, height: 16),
            ),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ---------- Bildbox ----------
class _ImageBox1x1 extends StatelessWidget {
  final String? imagePath;
  const _ImageBox1x1({required this.imagePath});

  bool _isHttp(String p) => p.startsWith('http');
  bool _isLocal(String p) =>
      p.startsWith('/') || RegExp(r'^[a-zA-Z]:').hasMatch(p);

  String? _normalize(String? p) {
    if (p == null || p.trim().isEmpty) return null;
    return p.trim();
  }

  @override
  Widget build(BuildContext context) {
    final norm = _normalize(imagePath);
    Widget img;
    if (norm == null) {
      img = const ColoredBox(color: Color(0xFF0B0B0B));
    } else if (_isHttp(norm)) {
      img =
          Image.network(norm, fit: BoxFit.cover, width: double.infinity);
    } else if (!kIsWeb && _isLocal(norm)) {
      img =
          Image.file(File(norm), fit: BoxFit.cover, width: double.infinity);
    } else {
      img =
          Image.asset(norm, fit: BoxFit.cover, width: double.infinity);
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

// ---------- Saisonbar ----------
class _SeasonBarLabeledDb extends StatelessWidget {
  final List<_MonthWithColor> months;
  const _SeasonBarLabeledDb({super.key, required this.months});

  @override
  Widget build(BuildContext context) {
    final base = const Color(0xFF0F0F0F);
    final border = const Color(0xFF1A1A1A);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            children: months.map((m) {
              return Expanded(
                child: Container(
                  height: 16,
                  margin: EdgeInsets.only(
                      right: m == months.last ? 0 : 3),
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
              return Expanded(
                child: Text(
                  m.name,
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
