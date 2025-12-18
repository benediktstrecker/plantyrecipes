// lib/screens/meals/meal_stock.dart
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/design/drawer.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

import 'package:planty_flutter_starter/screens/recipe/recipe_detail.dart';

/// ============================================================
/// MealStockScreen
/// ============================================================
/// Datenquelle: preparation_list
/// - Zuzubereiten: time_prepared IS NULL
/// - Vorrat: recipe_portion_number_left > 0
class MealStockScreen extends StatefulWidget {
  const MealStockScreen({super.key});

  @override
  State<MealStockScreen> createState() => _MealStockScreenState();
}

class _MealStockScreenState extends State<MealStockScreen> {
  /// ------------------------------------------------------------
  /// preparation_list JOIN recipes
  /// ------------------------------------------------------------
  Stream<List<_PrepRecipeRow>> _watchPrepRecipes() {
    final pl = appDb.preparationList;
    final r = appDb.recipes;

    final q = (appDb.select(pl)
          ..orderBy([
            (t) => d.OrderingTerm.desc(t.timePrepared),
          ]))
        .join([
      d.innerJoin(r, r.id.equalsExp(pl.recipeId)),
    ]);

    return q.watch().map((rows) {
      return rows.map((row) {
        return _PrepRecipeRow(
          prep: row.readTable(pl),
          recipe: row.readTable(r),
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<_PrepRecipeRow>>(
      stream: _watchPrepRecipes(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final rows = snap.data!;

        // -------------------------------
        // Zuzubereiten
        // -------------------------------
        final zuzubereiten = rows
            .where((e) => e.prep.timePrepared == null)
            .toList();

        final vorrat = rows
            .where((e) =>
                (e.prep.recipePortionNumberLeft ?? 0) > 0 &&
                e.prep.timePrepared != null)
            .toList();



        return Scaffold(
          backgroundColor: Colors.black,
          drawer: const AppDrawer(currentIndex: 3),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text(
              'Meal Stock',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image:
                      const AssetImage('assets/images/header_meals.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.35),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _Section(title: 'Zuzubereiten', emptyText: 'Keine Rezepte offen.', items: zuzubereiten),
              _Section(title: 'Vorrat', emptyText: 'Kein Vorrat vorhanden.', items: vorrat),
            ],
          ),
        );
      },
    );
  }
}

/// ============================================================
/// Abschnitt
/// ============================================================
class _Section extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<_PrepRecipeRow> items;

  const _Section({
    required this.title,
    required this.emptyText,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Text(
                emptyText,
                style: const TextStyle(color: Colors.white54),
              ),
            )
          else
            _ImageListView(items: items),
        ],
      ),
    );
  }
}


/// ============================================================
/// ImageListView – exakt wie vorgegeben
/// ============================================================
class _ImageListView extends StatelessWidget {
  final List<_PrepRecipeRow> items;
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
        final row = items[i];
        final r = row.recipe;
        final prepId = row.prep.id;
        final img = (r.picture == null || r.picture!.isEmpty)
            ? 'assets/images/placeholder.jpg'
            : r.picture!;
        return InkWell(
          onTap: () {
            Navigator.of(context).push(PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 280),
              pageBuilder: (_, __, ___) => RecipeDetailScreen(
                recipeId: r.id,
                title: r.name,
                imagePath: img,
              ),
              transitionsBuilder: (_, animation, __, child) {
                final offset = Tween<Offset>(
                        begin: const Offset(0, 0.05),
                        end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic));
                return FadeTransition(
                  opacity: animation,
                  child:
                      SlideTransition(position: offset, child: child),
                );
              },
            ));
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withOpacity(0.15), width: 1),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 45,
                    height: 45,
                    child: Image.asset(img, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    r.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (r.bookmark == 1)
                      const Icon(Icons.bookmark, color: Colors.white),
                    PreparationToggle(
                      preparationListId: prepId, // siehe unten
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ============================================================
/// Join-Hilfsklasse
/// ============================================================
class _PrepRecipeRow {
  final PreparationListData prep;
  final Recipe recipe;

  const _PrepRecipeRow({
    required this.prep,
    required this.recipe,
  });
}

/// ============================================================
/// Vorbereitungs-Checkbox
/// ============================================================

class PreparationToggle extends StatefulWidget {
  final int preparationListId;

  const PreparationToggle({
    super.key,
    required this.preparationListId,
  });

  @override
  State<PreparationToggle> createState() => _PreparationToggleState();
}

class _PreparationToggleState extends State<PreparationToggle> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final row = await (appDb.select(appDb.preparationList)
          ..where((p) => p.id.equals(widget.preparationListId)))
        .getSingleOrNull();

    if (!mounted) return;
    setState(() {
      _checked = row?.timePrepared != null;
    });
  }

  Future<void> _toggle() async {
    final newValue = !_checked;

    final q = appDb.update(appDb.preparationList)
      ..where((p) => p.id.equals(widget.preparationListId));

    await q.write(
      PreparationListCompanion(
        timePrepared:
            newValue ? d.Value(DateTime.now()) : const d.Value(null),
      ),
    );

    if (!mounted) return;
    setState(() => _checked = newValue);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.translucent,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Icon(
            _checked
                ? Icons.check_circle_outline
                : Icons.circle_outlined,
            key: ValueKey(
                'prep_${widget.preparationListId}_$_checked'),
            color: Colors.white54,
            size: 26,
          ),
        ),
      ),
    );
  }
}

