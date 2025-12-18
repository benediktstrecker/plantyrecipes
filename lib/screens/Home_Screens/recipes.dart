// lib/screens/Home_Screens/recipes.dart
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/utils/easy_swipe_nav.dart';
import 'package:planty_flutter_starter/design/drawer.dart';

// DB
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart' as db;

// Import-Helfer
import 'package:planty_flutter_starter/db/import_units.dart';

// Zielseiten
import 'package:planty_flutter_starter/screens/Home_Screens/ingredients.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/shopping.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/nutrition.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/meals.dart';
import 'package:planty_flutter_starter/screens/recipe/recipe_list_screen.dart';

class Recipes extends StatefulWidget {
  const Recipes({super.key});

  @override
  State<Recipes> createState() => _RecipesState();
}

class _RecipesState extends State<Recipes> with EasySwipeNav {
  int _selectedIndex = 2; // 2 = Rezepte
  static const Duration _slideDuration = Duration(milliseconds: 280);
  bool _bootstrapDone = false;

  // Schwellwerte
  static const double _horizontalOpenThreshold = 30;
  static const double _verticalTolerance = 24;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await importInitialDataIfEmpty();
    } catch (e) {
      debugPrint("Fehler beim Initialimport: $e");
    } finally {
      if (mounted) setState(() => _bootstrapDone = true);
    }
  }

  @override
  int get currentIndex => _selectedIndex;

  Widget _widgetForIndex(int index) {
  switch (index) {
    case 0:
      return const Ingredients();
    case 1:
      return const Shopping();
    case 2:
      return const Recipes();   // Startseite in der Mitte
    case 3:
      return const Meals();
    case 4:
    default:
      return const Nutrition();
  }
}


  void _slideToIndex(int index, {required bool fromRight}) {
    if (!mounted || index < 0 || index > 4) return;
    final target = _widgetForIndex(index);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => target,
        transitionDuration: _slideDuration,
        reverseTransitionDuration: _slideDuration,
        transitionsBuilder: (_, animation, __, child) {
          final begin =
              fromRight ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0);
          final tween = Tween(begin: begin, end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
    setState(() => _selectedIndex = index);
  }

  void _navigateToPage(int index) {
    if (!mounted || index == _selectedIndex || index < 0 || index > 4) return;
    final fromRight = index > _selectedIndex;
    _slideToIndex(index, fromRight: fromRight);
  }

  @override
  void goToIndex(int index) =>
      _slideToIndex(index, fromRight: index > _selectedIndex);

  @override
  Widget build(BuildContext context) {
    if (!_bootstrapDone) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onHorizontalDragStart: onSwipeStart,
      onHorizontalDragUpdate: onSwipeUpdate,
      onHorizontalDragEnd: onSwipeEnd,
      child: Scaffold(
        backgroundColor: darkgreen,
        appBar: AppBar(
          title: const Text(
            "Planty Recipes",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: darkgreen,
          iconTheme: const IconThemeData(color: Colors.white), // 👈 HINZUFÜGEN
        ),
        drawer: const AppDrawer(currentIndex: 2),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: GNav(
            backgroundColor: darkgreen,
            tabBackgroundColor: darkdarkgreen,
            padding: const EdgeInsets.all(16),
            gap: 8,
            selectedIndex: _selectedIndex.clamp(0, 4),
            onTabChange: _navigateToPage,
            tabs: const [
              GButton(icon: Icons.eco, text: 'Zutaten'),              // 0
              GButton(icon: Icons.storefront, text: 'Einkauf'),     // 1
              GButton(icon: Icons.list_alt, text: 'Rezepte'),         // 2
              GButton(icon: Icons.calendar_month, text: 'Mahlzeiten'),   // 3
              GButton(icon: Icons.stacked_bar_chart, text: 'Nährwerte'), // 4
            ],

          ),
        ),
        body: const _HomeGrid(),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// 🔹 GRID: Rezeptkategorien aus DB + 10. Kachel „Alle Rezepte“
// ----------------------------------------------------------------------
// ----------------------------------------------------------------------
// 🔹 GRID: Rezeptkategorien aus DB
// 🔹 Wischbewegung nach oben öffnet "Alle Rezepte"
// ----------------------------------------------------------------------
class _HomeGrid extends StatelessWidget {
  const _HomeGrid();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<List<db.RecipeCategory>>(
          stream: (appDb.select(appDb.recipeCategories)
                ..orderBy([(t) => d.OrderingTerm.asc(t.id)]))
              .watch(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            // 🔧 Fix: Liste immer modifizierbar halten
            final categories = List.of(snap.data ?? const <db.RecipeCategory>[]);

            // Layout-Berechnung
            const cross = 2;
            const spacingV = 12.0;
            const spacingH = 12.0;
            const epsilon = 1.0;

            double dragStartY = 0;
            const double swipeThreshold = 80; // minimale Wischhöhe

            return LayoutBuilder(
              builder: (context, constraints) {
                final rows = ((categories.length + cross - 1) ~/ cross);
final availableH = constraints.maxHeight;

// sichere Berechnung
double itemH = (availableH - spacingV * (rows - 1)) / rows - epsilon;
if (itemH.isNaN || itemH.isInfinite || itemH < 0) {
  itemH = 100; // Fallback-Höhe
}


                return GestureDetector(
                  // 🔹 Nach-oben-Wisch öffnet "Alle Rezepte"
                  onVerticalDragStart: (details) {
                    dragStartY = details.globalPosition.dy;
                  },
                  onVerticalDragEnd: (details) {
                    final endYVelocity = details.velocity.pixelsPerSecond.dy;
                    if (dragStartY > 0 && endYVelocity < -swipeThreshold) {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) =>
                              const RecipeListScreen(category: null),
                          transitionDuration:
                              const Duration(milliseconds: 280),
                          reverseTransitionDuration:
                              const Duration(milliseconds: 280),
                          transitionsBuilder: (_, animation, __, child) {
                            final offsetAnimation = Tween<Offset>(
                                    begin: const Offset(0, 0.08),
                                    end: Offset.zero)
                                .animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic));
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                  position: offsetAnimation, child: child),
                            );
                          },
                        ),
                      );
                    }
                  },

                  child: GridView.builder(
                    itemCount: categories.length,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      crossAxisSpacing: spacingH,
                      mainAxisSpacing: spacingV,
                      mainAxisExtent: itemH,
                    ),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final title = cat.title;
                      final imagePath = cat.image ?? '';

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  RecipeListScreen(category: title),
                              transitionDuration:
                                  const Duration(milliseconds: 280),
                              reverseTransitionDuration:
                                  const Duration(milliseconds: 280),
                              transitionsBuilder: (_, animation, __, child) {
                                final offsetAnimation = Tween<Offset>(
                                        begin: const Offset(0, 0.05),
                                        end: Offset.zero)
                                    .animate(CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic));
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                      position: offsetAnimation, child: child),
                                );
                              },
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              if (imagePath.isNotEmpty)
                                Positioned.fill(
                                  child:
                                      Image.asset(imagePath, fit: BoxFit.cover),
                                )
                              else
                                const Positioned.fill(
                                    child: ColoredBox(color: Colors.black26)),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8, horizontal: 8),
                                  color: Colors.black.withOpacity(0.5),
                                  child: Text(
                                    title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
