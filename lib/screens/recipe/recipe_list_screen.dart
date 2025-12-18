// lib/screens/recipe/recipe_list_screen.dart
import 'package:flutter/material.dart';
import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/design/drawer.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:drift/drift.dart' as d;
import 'package:planty_flutter_starter/screens/recipe/recipe_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planty_flutter_starter/services/meal_item_picker.dart';


class RecipeListScreen extends StatefulWidget {
  final String? category;
  final ListPickMode pickMode;
  final DateTime? mealDay;
  final int? mealCategoryId;

  const RecipeListScreen({
    super.key,
    this.category,
    this.pickMode = ListPickMode.none,
    this.mealDay,
    this.mealCategoryId,
  });

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shelfCtrl;
  double _dragStartValue = 0.0;
  bool _panLockedToHorizontal = false;
  bool _panDirectionChosen = false;
  Offset _panStart = Offset.zero;

  static const double _lockSlop = 6.0;
  static const _animDur = Duration(milliseconds: 220);
  static const Slidetime = Duration(milliseconds: 220);

  int _viewMode = 3; // 1=textlist, 2=image list, 3=grid2, 4=grid3, 5=grid5
  int _sortMode = 1; // 1=ID, 2=Name, 3=Time (TODO), 4=TimesCooked (TODO)

  bool get _shelfOpen => _shelfCtrl.value >= 0.999;
  void _openShelf() => _shelfCtrl.fling(velocity: 2.0);
  void _closeShelf() => _shelfCtrl.fling(velocity: -2.0);
  void _toggleShelf() => _shelfOpen ? _closeShelf() : _openShelf();

  // --- Persistenz ---
  Future<void> _saveViewMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('recipe_view_mode', mode);
  }

  Future<int> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('recipe_view_mode') ?? 3;
  }

  Future<void> _saveSortMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('recipe_sort_mode', mode);
  }

  Future<int> _loadSortMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('recipe_sort_mode') ?? 1;
  }

  void _toggleViewMode() {
    setState(() {
      _viewMode = (_viewMode % 5) + 1;
    });
    _saveViewMode(_viewMode);
  }

  void _toggleSortMode() {
    setState(() {
      _sortMode = (_sortMode % 4) + 1;
    });
    _saveSortMode(_sortMode);
  }

  IconData get _viewIcon {
  switch (_viewMode) {
    case 1:
      return Icons.view_headline;
    case 2:
      return Icons.list;
    case 3:
      return Icons.window_outlined;
    case 4:
      return Icons.grid_on; // 3-Spalten-Icon
    case 5:
      return Icons.view_compact_outlined;
    default:
      return Icons.list;
  }
}

  IconData get _sortIcon {
    switch (_sortMode) {
      case 1:
        return Icons.onetwothree;
      case 2:
        return Icons.sort_by_alpha;
      case 3:
        return Icons.timer; // TODO: Später Sortierung nach Rezeptzeit
      case 4:
        return Icons.leaderboard; // TODO: Später Sortierung nach Häufigkeit gekocht
      default:
        return Icons.sort;
    }
  }

  @override
  void initState() {
    super.initState();
    _shelfCtrl =
        AnimationController(vsync: this, duration: _animDur, value: 0.0);
    _loadViewMode().then((m) => setState(() => _viewMode = m));
    _loadSortMode().then((m) => setState(() => _sortMode = m));
  }

  @override
  void dispose() {
    _shelfCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double shelfMaxWidth =
        (size.width * 0.28).clamp(80.0, size.width * 0.6);

    final categoriesStream = (appDb.select(appDb.recipeCategories)
          ..orderBy([(t) => d.OrderingTerm.asc(t.id)]))
        .watch();
    final recipesStream = appDb.select(appDb.recipes).watch();

    return StreamBuilder<List<RecipeCategory>>(
      stream: categoriesStream,
      builder: (context, catSnap) {
        if (catSnap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final categories = catSnap.data ?? const <RecipeCategory>[];
        final currentCat = (widget.category == null)
            ? RecipeCategory(
                id: -1,
                title: 'Alle Rezepte',
                image: 'assets/images/all_recipes.jpg')
            : categories.firstWhere(
                (c) => c.title == widget.category,
                orElse: () =>
                    RecipeCategory(id: -1, title: widget.category!, image: null),
              );

        final catImage = (currentCat.image == null || currentCat.image!.isEmpty)
            ? 'assets/images/placeholder.jpg'
            : currentCat.image!;

        return StreamBuilder<List<Recipe>>(
          stream: recipesStream,
          builder: (context, recSnap) {
            final loading2 = recSnap.connectionState == ConnectionState.waiting;
final allRecipes = List.of(recSnap.data ?? const <Recipe>[]); // ← Fix: kopierbar

final currentCategoryId = currentCat.id;
List<Recipe> items;
if (currentCategoryId > 0) {
  items = allRecipes
      .where((r) => r.recipeCategory == currentCategoryId)
      .toList();
} else {
  items = List.of(allRecipes);
}

// Sicherheit vor Sortierung
items = List.of(items);


            // --- Sortierlogik ---
            switch (_sortMode) {
              case 1: // ID (default)
                items.sort((a, b) => a.id.compareTo(b.id));
                break;
              case 2: // Name
                items.sort((a, b) =>
                    a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                break;
              case 3: // TODO: Zeit (noch nicht in DB)
                // Hier später: items.sort((a, b) => a.time.compareTo(b.time));
                break;
              case 4: // TODO: Häufigkeit gekocht (noch nicht in DB)
                // Hier später: items.sort((a, b) => b.timesCooked.compareTo(a.timesCooked));
                break;
            }

            // --- Kategorie-Zählung für Sidebar ---
            final Map<int, int> countByCatId = {};
            for (final r in allRecipes) {
              countByCatId.update(r.recipeCategory, (v) => v + 1,
                  ifAbsent: () => 1);
            }
            final Map<String, int> countsByCategory = {
              for (final c in categories) c.title: (countByCatId[c.id] ?? 0),
            };

            return Scaffold(
              backgroundColor: Colors.black,
              drawer: const AppDrawer(currentIndex: 0),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leadingWidth: 48,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Zurück',
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    /*Builder(
                      builder: (ctx) => IconButton(
                        tooltip: 'Menü',
                        icon:
                            const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),*/
                  ],
                ),
                title: GestureDetector(
  onTap: _toggleShelf,
  child: Text(
    currentCat.title,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
  ),
),
                actions: [
                  IconButton(
                    tooltip: 'Sortierung ändern',
                    onPressed: _toggleSortMode,
                    icon: Icon(_sortIcon, color: Colors.white),
                  ),
                  IconButton(
                    tooltip: 'Ansicht wechseln',
                    onPressed: _toggleViewMode,
                    icon: Icon(_viewIcon, color: Colors.white),
                  ),
                  /*IconButton(
                    tooltip: _shelfOpen
                        ? 'Kategorien schließen'
                        : 'Kategorien öffnen',
                    onPressed: _toggleShelf,
                    icon: const Icon(Icons.view_sidebar,
                        color: Colors.white),
                  ),*/
                ],
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(catImage),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.35),
                          BlendMode.darken),
                    ),
                  ),
                ),
              ),
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
                            (d.localPosition.dx - _panStart.dx) /
                                shelfMaxWidth)
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
                    (_shelfCtrl.value >= 0.5)
                        ? _openShelf()
                        : _closeShelf();
                  }
                },
                child: Row(
                  children: [
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
                                    child: _RecipeShelf(
                                      categories: categories,
                                      countsByCategory: countsByCategory,
                                      onTapCategory: (catTitle) {
                                        Navigator.of(context)
                                            .pushReplacement(
                                          PageRouteBuilder(
                                            pageBuilder: (_, __, ___) =>
                                                RecipeListScreen(
                                                    category: catTitle),
                                            transitionDuration:
                                                Slidetime,
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
                    Expanded(
                      child: AnimatedSwitcher(
                        duration:
                            const Duration(milliseconds: 600),
                        switchInCurve: Curves.easeInOutCubic,
                        switchOutCurve: Curves.easeInOutCubic,
                        transitionBuilder:
                            (child, animation) {
                          final offsetAnimation = Tween<Offset>(
                            begin: const Offset(0.10, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOutCubic,
                          ));
                          return SlideTransition(
                            position: offsetAnimation,
                            child: FadeTransition(
                                opacity: animation,
                                child: child),
                          );
                        },
                        child: loading2
                            ? Container(
                                key: const ValueKey('loading'),
                                color: Colors.black,
                              )
                            : (items.isEmpty
                                ? const _EmptyState(
                                    onImportHint:
                                        'CSV importieren: assets/data/recipes.csv',
                                  )
                                : _SmoothContent(
                                items: items,
                                viewMode: _viewMode,
                                pickMode: widget.pickMode,
                              )
                            ),
                      ),
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


// ----------------------------------------------------------
// Sanfter Wechsel zwischen Ansichten
// ----------------------------------------------------------
class _SmoothContent extends StatelessWidget {
  final List<Recipe> items;
  final int viewMode;
  final ListPickMode pickMode;

  const _SmoothContent({
    required this.items,
    required this.viewMode,
    required this.pickMode,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 750),
        switchInCurve: Curves.easeInOutCubic,
        switchOutCurve: Curves.easeInOutCubic,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.center,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        transitionBuilder: (child, animation) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(0.08, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          ));
          final fadeAnimation =
              CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic);
          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(opacity: fadeAnimation, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(viewMode),
          child: switch (viewMode) {
            1 => _TextListView(
                  items: items,
                  pickMode: pickMode,
                ),
            2 => _ImageListView(
                  items: items,
                  pickMode: pickMode,
                ),
            3 => _GridViewRecipes(
                  items: items,
                  columns: 2,
                  pickMode: pickMode,
                ),
            4 => _GridViewRecipes(
                  items: items,
                  columns: 3,
                  pickMode: pickMode,
                ),
            5 => _GridViewRecipes(
                  items: items,
                  columns: 5,
                  pickMode: pickMode,
                ),
            _ => _GridViewRecipes( // ✅ Pflicht für int
                  items: items,
                  columns: 2,
                  pickMode: pickMode,
                ),
          },
        ),
      ),
    );
  }
}
// ----------------------------------------------------------
// Ansichten
// ----------------------------------------------------------

class _TextListView extends StatelessWidget {
  final List<Recipe> items;
  final ListPickMode pickMode;

  const _TextListView({
    required this.items,
    required this.pickMode,
  });


  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      addRepaintBoundaries: false,
      addAutomaticKeepAlives: false,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(
        color: Colors.white.withOpacity(0.15),
        height: 4,    // statt ~16
        thickness: 0.5,
        ),
      itemBuilder: (_, i) {
        final r = items[i];
        return ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          title: Text(
            r.name,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16),
          ),
          trailing: (r.bookmark == 1)
            ? const Icon(Icons.bookmark, color: Colors.white)
            : const SizedBox.shrink(),
          onTap: () {
            if (pickMode == ListPickMode.mealSelect) {
              Navigator.of(context).pop(
                SelectedMealItem.recipe(r.id),
              );
              return;
            }

            Navigator.of(context).push(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 280),
                reverseTransitionDuration: const Duration(milliseconds: 280),
                pageBuilder: (_, __, ___) => RecipeDetailScreen(
                  recipeId: r.id,
                  title: r.name,
                  imagePath: r.picture ?? 'assets/images/placeholder.jpg',
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
        );
      },
    );
  }
}

class _ImageListView extends StatelessWidget {
  final List<Recipe> items;
  final ListPickMode pickMode;

  const _ImageListView({
    required this.items,
    required this.pickMode,
  });


  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      addRepaintBoundaries: false,
      addAutomaticKeepAlives: false,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final r = items[i];
        final img = (r.picture == null || r.picture!.isEmpty)
            ? 'assets/images/placeholder.jpg'
            : r.picture!;
        return InkWell(
          onTap: () {
            if (pickMode == ListPickMode.mealSelect) {
              Navigator.of(context).pop(
                SelectedMealItem.recipe(r.id),
              );
              return;
            }

            Navigator.of(context).push(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 280),
                reverseTransitionDuration: const Duration(milliseconds: 280),
                pageBuilder: (_, __, ___) => RecipeDetailScreen(
                  recipeId: r.id,
                  title: r.name,
                  imagePath: r.picture ?? 'assets/images/placeholder.jpg',
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

          splashColor: Colors.white10,
          highlightColor: Colors.white10,
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
                  child: Container(
                    width: 45,
                    height: 45,
                    color: Colors.black,
                    child: Image.asset(img,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(r.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                ),
                (r.bookmark == 1)
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

class _GridViewRecipes extends StatelessWidget {
  final List<Recipe> items;
  final int columns;
  final ListPickMode pickMode;
  const _GridViewRecipes({required this.items, required this.columns, required this.pickMode});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      addRepaintBoundaries: false,
      addAutomaticKeepAlives: false,
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final r = items[i];
        final img = (r.picture == null || r.picture!.isEmpty)
            ? 'assets/images/placeholder.jpg'
            : r.picture!;

        if (columns >= 5) {
          return InkWell(
            onTap: () {
              if (pickMode == ListPickMode.mealSelect) {
                Navigator.of(context).pop(
                  SelectedMealItem.recipe(r.id),
                );
                return;
              }

              Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 280),
                  reverseTransitionDuration: const Duration(milliseconds: 280),
                  pageBuilder: (_, __, ___) => RecipeDetailScreen(
                    recipeId: r.id,
                    title: r.name,
                    imagePath: r.picture ?? 'assets/images/placeholder.jpg',
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

            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(img, fit: BoxFit.cover),
            ),
          );
        }

        return InkWell(
          onTap: () {
            if (pickMode == ListPickMode.mealSelect) {
              Navigator.of(context).pop(
                SelectedMealItem.recipe(r.id),
              );
              return;
            }

            Navigator.of(context).push(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 280),
                reverseTransitionDuration: const Duration(milliseconds: 280),
                pageBuilder: (_, __, ___) => RecipeDetailScreen(
                  recipeId: r.id,
                  title: r.name,
                  imagePath: r.picture ?? 'assets/images/placeholder.jpg',
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

          splashColor: Colors.white10,
          highlightColor: Colors.white10,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                  image: AssetImage(img), fit: BoxFit.cover),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black.withOpacity(0.45),
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(
                r.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: columns == 2 ? 16 : 12,//Schriftgröße Text im Grid
                    height: 1.1),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------
// Kategorie-Shelf + EmptyState
// ----------------------------------------------------------

class _RecipeShelf extends StatelessWidget {
  final List<RecipeCategory> categories;
  final Map<String, int> countsByCategory;
  final void Function(String catTitle) onTapCategory;
  const _RecipeShelf({
    required this.categories,
    required this.countsByCategory,
    required this.onTapCategory,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
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
              child: _RecipeShelfTile(
                title: cat.title,
                image: cat.image ?? 'assets/images/placeholder.jpg',
                count: countsByCategory[cat.title] ?? 0,
                onTap: () => onTapCategory(cat.title),
              ),
            ),
        ],
      );
    });
  }
}

class _RecipeShelfTile extends StatelessWidget {
  final String title;
  final String image;
  final int count;
  final VoidCallback onTap;
  const _RecipeShelfTile({
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
                Colors.black.withOpacity(0.35), BlendMode.darken),
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
                    fontSize: 13),
              ),
              TextSpan(
                text: "$count Rezepte",
                style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                    fontSize: 11.5),
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
            const Icon(Icons.restaurant_menu,
                size: 48, color: Colors.white70),
            const SizedBox(height: 12),
            const Text('Noch keine Rezepte vorhanden.',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(onImportHint,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}
