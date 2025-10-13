// lib/screens/recipe_list_screen.dart
import 'package:flutter/material.dart';
import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/design/drawer.dart'; // AppDrawer
import 'package:planty_flutter_starter/screens/Home_Screens/mobile_view.dart'
    show categories;

class Recipe {
  final String title;
  final String category;
  final String image;
  final double pricePerPortion;

  const Recipe({
    required this.title,
    required this.category,
    required this.image,
    this.pricePerPortion = 0,
  });
}

const List<Recipe> allRecipes = [
  Recipe(
    title: 'Dinkel-Porridge',
    category: 'Vollkorn-Basis',
    image: 'assets/images/placeholder.jpg',
    pricePerPortion: 1.2,
  ),
  Recipe(
    title: 'Penne Arrabbiata',
    category: 'Pasta',
    image: 'assets/images/placeholder.jpg',
    pricePerPortion: 2.5,
  ),
  Recipe(
    title: 'Kürbis-Curry-Suppe',
    category: 'Eintöpfe & Suppen',
    image: 'assets/images/placeholder.jpg',
    pricePerPortion: 1.9,
  ),
  Recipe(
    title: 'Ofengemüse',
    category: 'Beilagen',
    image: 'assets/images/placeholder.jpg',
    pricePerPortion: 1.1,
  ),
  Recipe(
    title: 'Buddha Bowl',
    category: 'Bowls',
    image: 'assets/images/placeholder.jpg',
    pricePerPortion: 3.2,
  ),
  Recipe(
    title: 'Grüner Salat',
    category: 'Salate',
    image: 'assets/images/placeholder.jpg',
    pricePerPortion: 1.0,
  ),
  Recipe(
    title: 'Hummus',
    category: 'Saucen & Dipps',
    image: 'assets/images/placeholder.jpg',
    pricePerPortion: 0.8,
  ),
  Recipe(
    title: 'Energie-Riegel',
    category: 'Snacks',
    image: 'assets/images/placeholder.jpg',
    pricePerPortion: 0.9,
  ),
  Recipe(
    title: 'Pilz-Risotto',
    category: 'Specials',
    image: 'assets/images/placeholder.jpg',
    pricePerPortion: 2.8,
  ),
];

class RecipeListScreen extends StatefulWidget {
  final String? category; // ← darf null sein (für „Alle Rezepte“)
  const RecipeListScreen({super.key, this.category});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen>
    with SingleTickerProviderStateMixin {
  // Zoom-Handling
  double _currentScale = 1.0;
  int _columns = 3; // Start: 3 Spalten
  double _lastScale = 1.0;

  // Animation Shelf
  late final AnimationController _shelfCtrl;
  double _dragStartValue = 0.0;
  bool _panLockedToHorizontal = false;
  bool _panDirectionChosen = false;
  Offset _panStart = Offset.zero;

  final ScrollController _scrollCtrl = ScrollController();

  bool get _shelfOpen => _shelfCtrl.value >= 0.999;
  void _openShelf() => _shelfCtrl.fling(velocity: 2.0);
  void _closeShelf() => _shelfCtrl.fling(velocity: -2.0);
  void _toggleShelf() => _shelfOpen ? _closeShelf() : _openShelf();

  @override
  void initState() {
    super.initState();
    _shelfCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 0.0,
    );
  }

  @override
  void dispose() {
    _shelfCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? selectedCategory = widget.category;

    // Bild für AppBar-Hintergrund
    final categoryImage = (selectedCategory != null)
        ? (categories.firstWhere(
              (cat) => cat['title'] == selectedCategory,
              orElse: () => {'image': 'assets/images/placeholder.jpg'},
            )['image'] ??
            'assets/images/placeholder.jpg')
        : 'assets/images/all_recipes.jpg';

    // Liste filtern (alle vs. nach Kategorie)
    final recipes = (selectedCategory == null)
        ? allRecipes
        : allRecipes
            .where((r) =>
                r.category.toLowerCase() == selectedCategory.toLowerCase())
            .toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    // Zähler je Kategorie für das Shelf
    final Map<String, int> countsByCategory = {
      for (final c in categories.map((c) => c['title']!))
        c: allRecipes.where((r) => r.category == c).length,
    };

    // Platzhalter für schönes Scrolling/Zoomen
    const int extraPlaceholders = 100;
    final int totalTiles = recipes.length + extraPlaceholders;

    // Maße für Shelf-Breite
    final size = MediaQuery.of(context).size;
    const double horizontalPadding = 12 * 2;
    const double spacing = 6;
    final double availableWidthForGrid =
        size.width - horizontalPadding - (spacing * (_columns - 1));
    final double oneColumnWidth =
        (_columns > 0) ? (availableWidthForGrid / _columns) : 0;
    final double shelfWidth = oneColumnWidth.clamp(80.0, size.width * 0.8);

    final double tileScale = 1.0 - 0.06 * _shelfCtrl.value;

    return Scaffold(
      backgroundColor: darkgreen,
      drawer: const AppDrawer(currentIndex: 0),
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
          selectedCategory ?? 'Alle Rezepte',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _shelfOpen ? 'Kategorien schließen' : 'Kategorien öffnen',
            onPressed: _toggleShelf,
            icon: const Icon(Icons.view_sidebar, color: Colors.white),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(categoryImage),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.35),
                BlendMode.darken,
              ),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (details) {
          _lastScale = 1.0;
          _panStart = details.focalPoint;
          _panDirectionChosen = false;
          _panLockedToHorizontal = false;
          _dragStartValue = _shelfCtrl.value;
        },
        onScaleUpdate: (details) {
          final dx = details.focalPoint.dx - _panStart.dx;
          final dy = details.focalPoint.dy - _panStart.dy;

          if (!_panDirectionChosen) {
            if (dx.abs() > dy.abs() + 6) {
              _panDirectionChosen = true;
              _panLockedToHorizontal = true;
            } else if (dy.abs() > dx.abs() + 6) {
              _panDirectionChosen = true;
              _panLockedToHorizontal = false;
            }
          }

          if (_panLockedToHorizontal) {
            final next = (_dragStartValue + dx / shelfWidth).clamp(0.0, 1.0);
            _shelfCtrl.value = next;
          } else {
            final newScale =
                (_currentScale * details.scale / _lastScale).clamp(0.7, 2.0);
            _lastScale = details.scale;
            setState(() {
              _currentScale = newScale;
              _columns = (3 / _currentScale).clamp(2, 6).round();
            });
          }
        },
        onScaleEnd: (details) {
          if (_panLockedToHorizontal) {
            final vx = details.velocity.pixelsPerSecond.dx;
            const vThresh = 350.0;
            if (vx > vThresh) {
              _openShelf();
            } else if (vx < -vThresh) {
              _closeShelf();
            } else {
              (_shelfCtrl.value >= 0.5) ? _openShelf() : _closeShelf();
            }
          }
        },
        onDoubleTap: () {
          setState(() {
            _columns = 3;
            _currentScale = 1.0;
          });
        },
        child: Row(
          children: [
            // Shelf
            AnimatedBuilder(
              animation: _shelfCtrl,
              builder: (_, __) {
                final w = shelfWidth * _shelfCtrl.value;
                return SizedBox(
                  width: w,
                  child: (w > 1)
                      ? Material(
                          color: const Color(0xFF0F3A2E),
                          elevation: 6,
                          child: SafeArea(
                            child: _CategoryShelf(
                              countsByCategory: countsByCategory,
                              onTapCategory: (catTitle) {
                                Navigator.of(context).pushReplacement(
                                  PageRouteBuilder(
                                    pageBuilder: (_, __, ___) =>
                                        RecipeListScreen(category: catTitle),
                                    transitionDuration:
                                        const Duration(milliseconds: 280),
                                    reverseTransitionDuration:
                                        const Duration(milliseconds: 280),
                                    transitionsBuilder: (_, a, __, child) =>
                                        FadeTransition(
                                            opacity: a, child: child),
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

            // Grid
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: GridView.builder(
                  key: ValueKey<int>(_columns),
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _columns,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: spacing,
                    childAspectRatio: 1,
                  ),
                  itemCount: totalTiles,
                  itemBuilder: (_, i) {
                    final bool isPlaceholder = i >= recipes.length;
                    final title = isPlaceholder ? "" : recipes[i].title;
                    return AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: tileScale,
                      child: _RecipeTile(
                        title: title,
                        onTap: () {
                          if (!isPlaceholder) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Ausgewählt: $title')),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _RecipeTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white10,
      highlightColor: Colors.white10,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(10),
        alignment: Alignment.bottomLeft,
        child: (title.isEmpty)
            ? const SizedBox.shrink()
            : Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _CategoryShelf extends StatelessWidget {
  final Map<String, int> countsByCategory;
  final void Function(String catTitle) onTapCategory;

  const _CategoryShelf({
    required this.countsByCategory,
    required this.onTapCategory,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalHeight = constraints.maxHeight;
        final int itemCount = categories.length;
        final double itemHeight = totalHeight / itemCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < itemCount; i++)
              SizedBox(
                height: itemHeight,
                child: _CategoryShelfTile(
                  title: categories[i]['title']!,
                  image: categories[i]['image']!,
                  count: countsByCategory[categories[i]['title']!] ?? 0,
                  onTap: () => onTapCategory(categories[i]['title']!),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryShelfTile extends StatelessWidget {
  final String title;
  final String image;
  final int count;
  final VoidCallback onTap;

  const _CategoryShelfTile({
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
                text: "$count Rezepte",
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
