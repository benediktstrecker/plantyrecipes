import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/utils/easy_swipe_nav.dart';
import 'package:planty_flutter_starter/design/drawer.dart';

// Zielseiten
import 'package:planty_flutter_starter/screens/Home_Screens/ingredients.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/shopping.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/nutrition.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/settings.dart';
import 'package:planty_flutter_starter/screens/recipe/recipe_list_screen.dart';

// NEU: Import-Helper für CSV-Imports
import 'package:planty_flutter_starter/db/import_units.dart';

// Kategorien (Startseite)
final List<Map<String, String>> categories = [
  {"title": "Vollkorn-Basis", "image": "assets/images/Vollkorn-Basis.jpg"},
  {"title": "Pasta", "image": "assets/images/Pasta.jpg"},
  {"title": "Eintöpfe & Suppen", "image": "assets/images/Eintoepfe.jpg"},
  {"title": "Specials", "image": "assets/images/Specials.jpg"},
  {"title": "Beilagen", "image": "assets/images/Beilagen.jpg"},
  {"title": "Salate", "image": "assets/images/Salate.jpg"},
  {"title": "Bowls", "image": "assets/images/Bowls.jpg"},
  {"title": "Saucen & Dipps", "image": "assets/images/Saucen.jpg"},
  {"title": "Snacks", "image": "assets/images/Snacks.jpg"},
  // ✅ Neue Kachel ganz unten:
  {"title": "Alle Rezepte", "image": "assets/images/all_recipes.jpg"},
];

class MobileView extends StatefulWidget {
  const MobileView({super.key});

  @override
  State<MobileView> createState() => _MobileViewState();
}

class _MobileViewState extends State<MobileView> with EasySwipeNav {
  int _selectedIndex = 0; // 0 = Rezepte
  static const Duration _slideDuration = Duration(milliseconds: 280);

  bool _bootstrapDone = false;

  // Für programmatic Drawer-Open
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Swipe-Tracking
  double _dragStartX = 0;
  double _dragStartY = 0;
  bool _drawerGesture = false;

  // Schwellwerte für Gesten
  static const double _horizontalOpenThreshold = 30; // Pixel nach rechts
  static const double _verticalTolerance = 24; // Verhindert "diagonal"

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
        return const MobileView();
      case 1:
        return const Ingredients();
      case 2:
        return const Shopping();
      case 3:
        return const Nutrition();
      case 4:
      default:
        return const Settings();
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
      // WICHTIG: Wir erlauben Drawer-Open bei *jedem* links→rechts-Swipe,
      // und lassen rechts→links weiterhin an EasySwipeNav (Ingredients) gehen.
      onHorizontalDragStart: (details) {
        _dragStartX = details.globalPosition.dx;
        _dragStartY = details.globalPosition.dy;
        _drawerGesture = false;

        // Für EasySwipeNav immer starten (damit ← weiterhin funktioniert)
        onSwipeStart(details);
      },
      onHorizontalDragUpdate: (details) {
        final dx = details.globalPosition.dx - _dragStartX;
        final dy = (details.globalPosition.dy - _dragStartY).abs();

        // Wenn die Bewegung weitgehend horizontal ist und deutlich nach rechts geht:
        if (!_drawerGesture && dy < _verticalTolerance && dx > _horizontalOpenThreshold) {
          _drawerGesture = true;

          final state = _scaffoldKey.currentState;
          if (state != null && !state.isDrawerOpen) {
            state.openDrawer();
          }
          // Drawer hat Priorität — NICHT an EasySwipeNav weiterreichen
          return;
        }

        // Für rechts→links (dx < 0) oder wenn Drawer nicht aktiv ist:
        if (!_drawerGesture) {
          onSwipeUpdate(details);
        }
      },
      onHorizontalDragEnd: (details) {
        if (!_drawerGesture) {
          onSwipeEnd(details); // für den Ingredients-Linkswisch
        }
        // Drawer-Geste beendet: nichts weiter tun
      },
      child: Scaffold(
        key: _scaffoldKey,
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
        ),
        drawer: const AppDrawer(currentIndex: 0),

        // ACHTUNG: Nicht "drawerEdgeDragWidth" auf volle Breite setzen,
        // da das nur Edge-Drags verbreitert. Wir nutzen unsere eigene Geste.

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
              GButton(icon: Icons.list_alt, text: 'Rezepte'),
              GButton(icon: Icons.eco, text: 'Zutaten'),
              GButton(icon: Icons.shopping_bag, text: 'Einkauf'),
              GButton(icon: Icons.incomplete_circle_rounded, text: 'Nährwerte'),
              GButton(icon: Icons.settings, text: 'Einstellungen'),
            ],
          ),
        ),

        body: const _HomeGrid(),
      ),
    );
  }
}

/// Ausgelagerter Body (unverändert)
class _HomeGrid extends StatelessWidget {
  const _HomeGrid();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const cross = 2;
            // 10 Kacheln = 5 Reihen bei 2 Spalten
            final rows = ((categories.length + cross - 1) / cross).floor();

            const spacingV = 12.0;
            const spacingH = 12.0;
            const epsilon = 1.0; // winzige Sicherheitsmarge

            // Nach Padding/ SafeArea ist das hier die *echte* verfügbare Höhe
            final availableH = constraints.maxHeight;

            // Exakte Kachelhöhe so, dass 5 Reihen + Abstände perfekt reinpassen
            final itemH = (availableH - spacingV * (rows - 1)) / rows - epsilon;

            return GridView.builder(
              itemCount: categories.length,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(), // alles sichtbar, kein Scroll
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cross,
                crossAxisSpacing: spacingH,
                mainAxisSpacing: spacingV,
                mainAxisExtent: itemH, // <- der Schlüssel
              ),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final title = cat['title']!;
                final imagePath = cat['image'];

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => RecipeListScreen(
                          category: title == 'Alle Rezepte' ? null : title,
                        ),
                        transitionDuration: const Duration(milliseconds: 280),
                        reverseTransitionDuration: const Duration(milliseconds: 280),
                        transitionsBuilder: (_, a, __, child) =>
                            FadeTransition(opacity: a, child: child),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        if ((imagePath ?? '').isNotEmpty)
                          Positioned.fill(
                            child: Image.asset(imagePath!, fit: BoxFit.cover),
                          )
                        else
                          const Positioned.fill(child: ColoredBox(color: Colors.black26)),
                        Positioned(
                          left: 0, right: 0, bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            color: Colors.black.withOpacity(0.5),
                            child: Text(
                              title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}
