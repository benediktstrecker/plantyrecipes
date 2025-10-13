// lib/screens/ingredients.dart
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/utils/easy_swipe_nav.dart';
import 'package:planty_flutter_starter/design/drawer.dart';

// Zielseiten importieren
import 'package:planty_flutter_starter/screens/Home_Screens/mobile_view.dart';
import 'package:planty_flutter_starter/screens/ingredient/ingredients_list_screen.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/shopping.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/nutrition.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/settings.dart';

// DB
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

// Importer
import 'package:planty_flutter_starter/db/import_units.dart';

import 'package:drift/drift.dart' as d;

class Ingredients extends StatefulWidget {
  const Ingredients({super.key});

  @override
  State<Ingredients> createState() => _IngredientsState();
}

class _IngredientsState extends State<Ingredients> with EasySwipeNav {
  int _selectedIndex = 1; // 1 = Zutaten
  static const Duration _slideDuration = Duration(milliseconds: 280);

  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    _seedIfEmpty();
  }

  Future<void> _seedIfEmpty() async {
    try {
      final count = await (appDb.selectOnly(appDb.ingredientCategories)
            ..addColumns([appDb.ingredientCategories.id.count()]))
          .map((row) => row.read(appDb.ingredientCategories.id.count()) ?? 0)
          .getSingle();

      if (count == 0) {
        setState(() => _seeding = true);
        final affected = await importIngredientCategoriesFromCsv();
        setState(() => _seeding = false);
        if (mounted && affected > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Kategorien importiert: $affected Einträge.')),
          );
        }
      }
    } catch (e) {
      setState(() => _seeding = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Initial-Import: $e')),
      );
    }
  }

  @override
  int get currentIndex => _selectedIndex;

  Widget _widgetForIndex(int index) {
    switch (index) {
      case 0:
        return const MobileView(); // Rezepte
      case 1:
        return const Ingredients(); // Zutaten
      case 2:
        return const Shopping(); // Einkauf
      case 3:
        return const Nutrition(); // Nährwerte
      case 4:
      default:
        return const Settings(); // Einstellungen
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
    return GestureDetector(
      // EasySwipeNav (rechts→links etc.)
      onHorizontalDragStart: onSwipeStart,
      onHorizontalDragUpdate: onSwipeUpdate,
      onHorizontalDragEnd: onSwipeEnd,
      child: Scaffold(
        backgroundColor: darkgreen,
        appBar: AppBar(
          title: const Text(
            "Planty Ingredients",
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: darkgreen,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (_seeding)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
        drawer: const AppDrawer(currentIndex: 1),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
          child: GNav(
            backgroundColor: darkgreen,
            tabBackgroundColor: darkdarkgreen,
            padding: const EdgeInsets.all(16),
            gap: 8,
            selectedIndex: _selectedIndex.clamp(0, 4),
            onTabChange: _navigateToPage,
            tabs: const [
              GButton(icon: Icons.list_alt, text: 'Rezepte'),
              GButton(icon: Icons.eco, text: 'Zutaten'),
              GButton(icon: Icons.shopping_bag, text: 'Einkauf'),
              GButton(icon: Icons.incomplete_circle_rounded, text: 'Nährwerte'),
              GButton(icon: Icons.settings, text: 'Einstellungen'),
            ],
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<List<IngredientCategory>>(
            stream: (appDb.select(appDb.ingredientCategories)
                  ..orderBy([(t) => d.OrderingTerm.asc(t.id)]))
                .watch(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }

              final categories =
                  snap.data ?? const <IngredientCategory>[];

              if (categories.isEmpty) {
                return const Center(
                  child: Text(
                    'Keine Kategorien gefunden.\nBitte CSV importieren oder im DB-Bereich anlegen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              // 🔽 Dynamische, nicht-scrollende Grid-Berechnung (wie in mobile_view.dart)
              return LayoutBuilder(
                builder: (context, constraints) {
                  const cross = 2; // Spalten
                  final rows = ((categories.length + cross - 1) ~/ cross);

                  const spacingV = 12.0;
                  const spacingH = 12.0;
                  const epsilon = 1.0;

                  final availableH = constraints.maxHeight;
                  final itemH =
                      (availableH - spacingV * (rows - 1)) / rows - epsilon;

                  return GridView.builder(
                    itemCount: categories.length,
                    padding: EdgeInsets.zero,
                    physics:
                        const NeverScrollableScrollPhysics(), // alles sichtbar, kein Scrollen
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      crossAxisSpacing: spacingH,
                      mainAxisSpacing: spacingV,
                      mainAxisExtent: itemH, // 👈 Schlüssel für die dynamische Höhe
                    ),
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final title = category.title;
                      final imagePath = category.image; // nullable

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) =>
                                  IngredientsListScreen(category: title),
                              transitionDuration: _slideDuration,
                              reverseTransitionDuration: _slideDuration,
                              transitionsBuilder: (_, animation, __, child) =>
                                  FadeTransition(opacity: animation, child: child),
                            ),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias, // Rundungen durchsetzen
                          child: Stack(
                            children: [
                              // Hintergrundbild oder Fallback-Farbe
                              if (imagePath != null && imagePath.isNotEmpty)
                                Positioned.fill(
                                  child: Image.asset(
                                    imagePath,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                const Positioned.fill(
                                  child: ColoredBox(color: Colors.black26),
                                ),

                              // Unterer, durchgehender Balken (Text)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 8,
                                  ),
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
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
