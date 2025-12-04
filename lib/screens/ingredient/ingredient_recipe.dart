// lib/screens/ingredient/ingredient_recipe.dart
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:planty_flutter_starter/utils/easy_swipe_nav.dart';

// andere Ingredient-Screens
import 'package:planty_flutter_starter/screens/ingredient/ingredient_detail.dart'
    as det;
import 'package:planty_flutter_starter/screens/ingredient/ingredient_shopping.dart'
    as shop;
import 'package:planty_flutter_starter/screens/ingredient/ingredient_nutrient.dart'
    as nutr;

// DB
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:drift/drift.dart' as drift;

// Rezeptdetail
import 'package:planty_flutter_starter/screens/recipe/recipe_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IngredientRecipeScreen extends StatefulWidget {
  final int ingredientId;
  final String? ingredientName;
  final String? imagePath;

  const IngredientRecipeScreen({
    super.key,
    required this.ingredientId,
    this.ingredientName,
    this.imagePath,
  });

  @override
  State<IngredientRecipeScreen> createState() => _IngredientRecipeScreenState();
}

class _IngredientRecipeScreenState extends State<IngredientRecipeScreen>
    with EasySwipeNav {
  int _selectedIndex = 3;
  int _viewMode = 3; // 1=textlist, 2=image list, 3=grid2, 4=grid3, 5=grid5
  int _sortMode = 1; // 1=ID, 2=Name, 3=Time (TODO), 4=TimesCooked (TODO)

  @override
  int get currentIndex => _selectedIndex;

  // -------------------------------
  // Navigation
  // -------------------------------
  void _navigateToPage(int index) {
    if (!mounted || index == _selectedIndex) return;
    if (index < 0 || index > 3) return;

    final fromRight = index > _selectedIndex;
    final next = _widgetForIndex(index);

    Navigator.of(context).pushReplacement(PageRouteBuilder(
      pageBuilder: (_, __, ___) => next,
      transitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder: (_, animation, __, child) {
        final begin = fromRight ? const Offset(1, 0) : const Offset(-1, 0);
        final tween = Tween(begin: begin, end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ));
  }

  @override
  void goToIndex(int index) {
    if (index < 0 || index > 3) return;
    _navigateToPage(index);
  }

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
        return nutr.IngredientNutrientScreen(
          ingredientId: widget.ingredientId,
          ingredientName: widget.ingredientName,
          imagePath: widget.imagePath,
        );
      case 3:
      default:
        return IngredientRecipeScreen(
          ingredientId: widget.ingredientId,
          ingredientName: widget.ingredientName,
          imagePath: widget.imagePath,
        );
    }
  }

  // -------------------------------
  // Sortierung & Ansicht speichern
  // -------------------------------
  Future<void> _saveSortMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ingredient_recipe_sort_mode', mode);
  }

  Future<int> _loadSortMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('ingredient_recipe_sort_mode') ?? 1;
  }

  Future<void> _saveViewMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ingredient_recipe_view_mode', mode);
  }

  Future<int> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('ingredient_recipe_view_mode') ?? 3;
  }

  void _toggleSortMode() {
    setState(() {
      _sortMode = (_sortMode % 4) + 1;
    });
    _saveSortMode(_sortMode);
  }

  void _toggleViewMode() {
    setState(() {
      _viewMode = (_viewMode % 5) + 1;
    });
    _saveViewMode(_viewMode);
  }

  IconData get _sortIcon {
    switch (_sortMode) {
      case 1:
        return Icons.onetwothree;
      case 2:
        return Icons.sort_by_alpha;
      case 3:
        return Icons.timer; // TODO: Zeit (später)
      case 4:
        return Icons.leaderboard; // TODO: Häufigkeit gekocht
      default:
        return Icons.sort;
    }
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

  @override
  void initState() {
    super.initState();
    _loadSortMode().then((m) => setState(() => _sortMode = m));
    _loadViewMode().then((m) => setState(() => _viewMode = m));
  }

  // -------------------------------
  // Build
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    final title = widget.ingredientName ?? 'Rezepte';
    final ingredientId = widget.ingredientId;

    final recipeStream = (appDb.select(appDb.recipeIngredients)
          ..where((ri) => ri.ingredientId.equals(ingredientId)))
        .join([
          drift.innerJoin(
            appDb.recipes,
            appDb.recipes.id.equalsExp(appDb.recipeIngredients.recipeId),
          ),
        ]).watch();

    return GestureDetector(
      onHorizontalDragStart: onSwipeStart,
      onHorizontalDragUpdate: onSwipeUpdate,
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! > 0 && _selectedIndex > 0) {
          goToIndex(_selectedIndex - 1);
        } else if (details.primaryVelocity! < 0 && _selectedIndex < 3) {
          goToIndex(_selectedIndex + 1);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(title, style: const TextStyle(color: Colors.white)),
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
          ],
        ),
        body: StreamBuilder<List<drift.TypedResult>>(
          stream: recipeStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final data = snapshot.data ?? [];
            final recipes = data
                .map((row) => row.readTable(appDb.recipes))
                .whereType<Recipe>()
                .toList();
            final recipeIngredients =
                data.map((row) => row.readTable(appDb.recipeIngredients)).toList();

            if (recipes.isEmpty) {
              return const Center(
                child: Text(
                  'noch in keinem Rezept vorhanden',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              );
            }

            // ---- Statistiken ----
            final totalCount = recipes.length;
            double totalAmount = 0;
            String? unit;
            for (final ri in recipeIngredients) {
              totalAmount += ri.amount;
              unit ??= ri.unitCode;
            }

            // ---- Sortierung ----
            switch (_sortMode) {
              case 1:
                recipes.sort((a, b) => a.id.compareTo(b.id));
                break;
              case 2:
                recipes.sort((a, b) =>
                    a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                break;
              case 3:
                // TODO: Zeit-Sortierung
                break;
              case 4:
                // TODO: Häufigkeit gekocht
                break;
            }

            return Column(
              children: [
                // Info-Kasten (wie Einheiten-Box)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0B0B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF1A1A1A)),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Verwendet in',
                                  style: TextStyle(color: Colors.white70)),
                              Text('$totalCount Rezepten',
                                  style:
                                      const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Gesamtmenge',
                                  style: TextStyle(color: Colors.white70)),
                              Text(
                                  '${totalAmount.toStringAsFixed(1)} ${unit ?? ''}',
                                  style:
                                      const TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Inhalt je nach ViewMode
                Expanded(
                  child: _SmoothContent(items: recipes, viewMode: _viewMode),
                ),
              ],
            );
          },
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
              GButton(icon: Icons.shopping_bag_outlined, text: 'Einkauf'),
              GButton(icon: Icons.stacked_bar_chart, text: 'Nährwerte'),
              GButton(icon: Icons.list_alt, text: 'Rezepte'),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------
// SmoothContent & Ansichten wie in RecipeListScreen
// ----------------------------------------------------------
class _SmoothContent extends StatelessWidget {
  final List<Recipe> items;
  final int viewMode;
  const _SmoothContent({required this.items, required this.viewMode});

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
            1 => _TextListView(items: items),
            2 => _ImageListView(items: items),
            3 => _GridViewRecipes(items: items, columns: 2),
            4 => _GridViewRecipes(items: items, columns: 3),
            5 => _GridViewRecipes(items: items, columns: 5),
            _ => _GridViewRecipes(items: items, columns: 2),
          },
        ),
      ),
    );
  }
}

class _TextListView extends StatelessWidget {
  final List<Recipe> items;
  const _TextListView({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          Divider(color: Colors.white.withOpacity(0.15)),
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
          trailing:
              const Icon(Icons.chevron_right, color: Colors.white54),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(
                recipeId: r.id,
                title: r.name,
                imagePath: r.picture ?? 'assets/images/placeholder.jpg',
              ),
            ));
          },
        );
      },
    );
  }
}

class _ImageListView extends StatelessWidget {
  final List<Recipe> items;
  const _ImageListView({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = items[i];
        final img = (r.picture == null || r.picture!.isEmpty)
            ? 'assets/images/placeholder.jpg'
            : r.picture!;
        return InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(
                recipeId: r.id,
                title: r.name,
                imagePath: r.picture ?? 'assets/images/placeholder.jpg',
              ),
            ));
          },
          splashColor: Colors.white10,
          highlightColor: Colors.white10,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.white.withOpacity(0.15), width: 1),
            ),
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(img,
                      width: 45, height: 45, fit: BoxFit.cover),
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
                const Icon(Icons.chevron_right, color: Colors.white54),
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
  const _GridViewRecipes({required this.items, required this.columns});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
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
          // Nur Bild, keine Beschriftung
          return InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(
                  recipeId: r.id,
                  title: r.name,
                  imagePath: r.picture ?? 'assets/images/placeholder.jpg',
                ),
              ));
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(img, fit: BoxFit.cover),
            ),
          );
        }

        // Standard-Grid mit Name + dunklem Balken
        return InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RecipeDetailScreen(
                recipeId: r.id,
                title: r.name,
                imagePath: r.picture ?? 'assets/images/placeholder.jpg',
              ),
            ));
          },
          splashColor: Colors.white10,
          highlightColor: Colors.white10,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(image: AssetImage(img), fit: BoxFit.cover),
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
