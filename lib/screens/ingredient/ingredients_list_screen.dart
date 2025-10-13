// lib/screens/ingredient/ingredients_list_screen.dart
import 'package:flutter/material.dart';
import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/design/drawer.dart'; // AppDrawer

// DB
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:drift/drift.dart' as d;

// Detail-Screen importieren
import 'package:planty_flutter_starter/screens/ingredient/ingredient_detail.dart';

class IngredientsListScreen extends StatefulWidget {
  final String category; // Titel der Kategorie (z. B. "Gemüse")

  const IngredientsListScreen({super.key, required this.category});

  @override
  State<IngredientsListScreen> createState() => _IngredientsListScreenState();
}

class _IngredientsListScreenState extends State<IngredientsListScreen>
    with SingleTickerProviderStateMixin {
  // Shelf-Animation
  late final AnimationController _shelfCtrl; // 0 = zu, 1 = offen

  double _dragStartValue = 0.0;

  // Swipe-Lock
  bool _panLockedToHorizontal = false;
  bool _panDirectionChosen = false;
  Offset _panStart = Offset.zero;

  static const double _lockSlop = 6.0;
  static const _animDur = Duration(milliseconds: 220);
  static const Slidetime = Duration(milliseconds: 220);

  // Scroll rechts
  final ScrollController _listCtrl = ScrollController();

  bool get _shelfOpen => _shelfCtrl.value >= 0.999;

  void _openShelf() => _shelfCtrl.fling(velocity: 2.0);
  void _closeShelf() => _shelfCtrl.fling(velocity: -2.0);
  void _toggleShelf() => _shelfOpen ? _closeShelf() : _openShelf();

  @override
  void initState() {
    super.initState();
    _shelfCtrl = AnimationController(
      vsync: this,
      duration: _animDur,
      value: 0.0,
    );
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    _shelfCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Shelf-Breite
    final size = MediaQuery.of(context).size;
    final double shelfMaxWidth =
        (size.width * 0.28).clamp(80.0, size.width * 0.6);

    // 1) Kategorien streamen
    final categoriesStream = (appDb.select(appDb.ingredientCategories)
          ..orderBy([(t) => d.OrderingTerm.asc(t.id)]))
        .watch();

    // 2) Alle Zutaten streamen (für Liste + Counts)
    final ingredientsStream = (appDb.select(appDb.ingredients)
          ..orderBy([(t) => d.OrderingTerm.asc(t.name)]))
        .watch();

    return StreamBuilder<List<IngredientCategory>>(
      stream: categoriesStream,
      builder: (context, catSnap) {
        if (catSnap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: darkgreen,
            body: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final categories = catSnap.data ?? const <IngredientCategory>[];

        // Aktuelle Kategorie anhand des Titels bestimmen
        final currentCat = categories.firstWhere(
          (c) => c.title == widget.category,
          orElse: () => IngredientCategory(
            id: -1,
            title: widget.category,
            image: null,
          ),
        );

        final catImage = (currentCat.image == null || currentCat.image!.isEmpty)
            ? 'assets/images/placeholder.jpg'
            : currentCat.image!;

        return StreamBuilder<List<Ingredient>>(
          stream: ingredientsStream,
          builder: (context, ingSnap) {
            final loading2 = ingSnap.connectionState == ConnectionState.waiting;
            final allIngredients = ingSnap.data ?? const <Ingredient>[];

            // Counts je Kategorie berechnen (Titel → Count)
            final Map<int, int> countByCatId = {};
            for (final ing in allIngredients) {
              countByCatId.update(ing.ingredientCategoryId, (v) => v + 1,
                  ifAbsent: () => 1);
            }
            final Map<String, int> countsByCategory = {
              for (final c in categories) c.title: (countByCatId[c.id] ?? 0),
            };

            // Zutaten der aktuellen Kategorie
            final currentCategoryId = currentCat.id;
            final items = (currentCategoryId > 0)
                ? allIngredients
                    .where((ing) => ing.ingredientCategoryId == currentCategoryId)
                    .toList()
                : const <Ingredient>[];

            return Scaffold(
              backgroundColor: Colors.black,
              drawer: const AppDrawer(currentIndex: 1),

              // AppBar
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leadingWidth: 100,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Zurück',
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Builder(
                      builder: (ctx) => IconButton(
                        tooltip: 'Menü',
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                  ],
                ),
                title: Text(
                  widget.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip:
                        _shelfOpen ? 'Kategorien schließen' : 'Kategorien öffnen',
                    onPressed: _toggleShelf,
                    icon: const Icon(Icons.view_sidebar, color: Colors.white),
                  ),
                ],
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(catImage),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.35),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                ),
              ),

              // Body: Row(Shelf + Liste)
              body: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) {
                  _panStart = d.localPosition;
                  _panDirectionChosen = false;
                  _panLockedToHorizontal = false;
                  _dragStartValue = _shelfCtrl.value;
                },
                onPanUpdate: (d) {
                  if (!_panDirectionChosen) {
                    final dx = (d.localPosition.dx - _panStart.dx).abs();
                    final dy = (d.localPosition.dy - _panStart.dy).abs();
                    if (dx > dy + _lockSlop) {
                      _panDirectionChosen = true;
                      _panLockedToHorizontal = true;
                    } else if (dy > dx + _lockSlop) {
                      _panDirectionChosen = true;
                      _panLockedToHorizontal = false;
                    } else {
                      return;
                    }
                  }
                  if (_panLockedToHorizontal) {
                    final next = (_dragStartValue +
                            (d.localPosition.dx - _panStart.dx) / shelfMaxWidth)
                        .clamp(0.0, 1.0);
                    _shelfCtrl.value = next;
                  }
                },
                onPanEnd: (d) {
                  if (!_panLockedToHorizontal) return;
                  final vx = d.velocity.pixelsPerSecond.dx;
                  const vThresh = 350.0;
                  if (vx > vThresh) {
                    _openShelf();
                  } else if (vx < -vThresh) {
                    _closeShelf();
                  } else {
                    (_shelfCtrl.value >= 0.5) ? _openShelf() : _closeShelf();
                  }
                },
                child: Row(
                  children: [
                    // --- Shelf ---
                    AnimatedBuilder(
                      animation: _shelfCtrl,
                      builder: (_, __) {
                        final w = shelfMaxWidth * _shelfCtrl.value;
                        return SizedBox(
                          width: w,
                          child: (w > 1)
                              ? Material(
                                  color: Colors.black,
                                  elevation: 6,
                                  child: SafeArea(
                                    child: _IngredientShelf(
                                      categories: categories,
                                      countsByCategory: countsByCategory,
                                      onTapCategory: (catTitle) {
                                        Navigator.of(context).pushReplacement(
                                          PageRouteBuilder(
                                            pageBuilder: (_, __, ___) =>
                                                IngredientsListScreen(
                                              category: catTitle,
                                            ),
                                            transitionDuration: Slidetime,
                                            reverseTransitionDuration:
                                                Slidetime,
                                            transitionsBuilder:
                                                (_, a, __, child) =>
                                                    FadeTransition(
                                              opacity: a,
                                              child: child,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        );
                      },
                    ),

                    // --- Zutatenliste ---
                    Expanded(
                      child: loading2
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : (items.isEmpty
                              ? const _EmptyState(
                                  onImportHint:
                                      'CSV importieren: assets/data/ingredient.csv',
                                )
                              : ListView.separated(
                                  controller: _listCtrl,
                                  padding: const EdgeInsets.fromLTRB(
                                      12, 12, 12, 24),
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (_, i) {
                                    final ing = items[i];
                                    final img = (ing.picture == null ||
                                            ing.picture!.isEmpty)
                                        ? 'assets/images/placeholder.jpg'
                                        : ing.picture!;
                                    return InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          PageRouteBuilder(
                                            pageBuilder: (_, __, ___) =>
                                                IngredientDetailScreen(
                                              ingredientId: ing.id,
                                              ingredientName: ing.name,
                                              imagePath: img, // << Pfad durchreichen
                                            ),
                                            transitionDuration: Slidetime,
                                            reverseTransitionDuration:
                                                Slidetime,
                                            transitionsBuilder: (_,
                                                    animation, __, child) =>
                                                FadeTransition(
                                              opacity: animation,
                                              child: child,
                                            ),
                                          ),
                                        );
                                      },
                                      splashColor: Colors.white10,
                                      highlightColor: Colors.white10,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.15),
                                            width: 1,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Container(
                                                width: 56,
                                                height: 56,
                                                color: Colors.black,
                                                child: Image.asset(
                                                  img,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (_, __, ___) =>
                                                          const SizedBox
                                                              .shrink(),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                ing.name,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            const Icon(Icons.chevron_right,
                                                color: Colors.white54),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// --- Shelf: Kategorien aus der DB untereinander ---
class _IngredientShelf extends StatelessWidget {
  final List<IngredientCategory> categories;
  final Map<String, int> countsByCategory;
  final void Function(String catTitle) onTapCategory;

  const _IngredientShelf({
    required this.categories,
    required this.countsByCategory,
    required this.onTapCategory,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalHeight = constraints.maxHeight;
        final int itemCount = categories.length.clamp(1, 999);
        final double itemHeight =
            (itemCount > 0) ? totalHeight / itemCount : totalHeight;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final cat in categories)
              SizedBox(
                height: itemHeight,
                child: _IngredientShelfTile(
                  title: cat.title,
                  image: cat.image ?? 'assets/images/placeholder.jpg',
                  count: countsByCategory[cat.title] ?? 0,
                  onTap: () => onTapCategory(cat.title),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _IngredientShelfTile extends StatelessWidget {
  final String title;
  final String image;
  final int count;
  final VoidCallback onTap;

  const _IngredientShelfTile({
    required this.title,
    required this.image,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white10,
      highlightColor: Colors.white10,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: AssetImage(image),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.35),
              BlendMode.darken,
            ),
          ),
        ),
        padding: const EdgeInsets.all(10),
        alignment: Alignment.bottomLeft,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "$title\n",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              TextSpan(
                text: "$count Zutaten",
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String onImportHint;

  const _EmptyState({required this.onImportHint});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant, size: 48, color: Colors.white70),
            const SizedBox(height: 12),
            const Text('Noch keine Zutaten vorhanden.',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(onImportHint,
                style: const TextStyle(color: Colors.white54, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}
