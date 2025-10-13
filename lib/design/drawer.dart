import 'package:flutter/material.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/mobile_view.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/ingredients.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/shopping.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/nutrition.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/settings.dart';

// DB-/Admin-Screens
import 'package:planty_flutter_starter/screens/data_manager/month_manager_screen.dart';
import 'package:planty_flutter_starter/screens/data_manager/unit_manager_screen.dart';
import 'package:planty_flutter_starter/screens/data_manager/nutrient_categorie_manager_screen.dart';
import 'package:planty_flutter_starter/screens/data_manager/nutrient_manager_screen.dart';
import 'package:planty_flutter_starter/screens/data_manager/ingredient_category_manager_screen.dart'; // <- NEU
import 'package:planty_flutter_starter/screens/data_manager/ingredient_property_manager_screen.dart'; // <- NEU
import 'package:planty_flutter_starter/screens/data_manager/seasonality_manager_screen.dart';

class AppDrawer extends StatelessWidget {
  final int currentIndex; // 0..4 um den aktiven Tab zu markieren
  const AppDrawer({super.key, this.currentIndex = 0});

  void _go(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const divider = Divider(color: Colors.white24, height: 1);

    return Drawer(
      child: Container(
        color: Colors.black,
        child: ListTileTheme(
          iconColor: Colors.white,
          textColor: Colors.white,
          child: ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: Colors.black),
                child: Text('Menu',
                    style: TextStyle(fontSize: 20, color: Colors.white)),
              ),

              // Hauptnavigation
              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('Rezepte'),
                selected: currentIndex == 0,
                selectedTileColor: Colors.white10,
                onTap: () => _go(context, const MobileView()),
              ),
              ListTile(
                leading: const Icon(Icons.eco),
                title: const Text('Zutaten'),
                selected: currentIndex == 1,
                selectedTileColor: Colors.white10,
                onTap: () => _go(context, const Ingredients()),
              ),
              ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: const Text('Einkauf'),
                selected: currentIndex == 2,
                selectedTileColor: Colors.white10,
                onTap: () => _go(context, const Shopping()),
              ),
              ListTile(
                leading: const Icon(Icons.incomplete_circle_rounded),
                title: const Text('Nährwerte'),
                selected: currentIndex == 3,
                selectedTileColor: Colors.white10,
                onTap: () => _go(context, const Nutrition()),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Einstellungen'),
                selected: currentIndex == 4,
                selectedTileColor: Colors.white10,
                onTap: () => _go(context, const Settings()),
              ),

              divider,
              divider,

              // Datenbank-Abschnitt
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  expansionTileTheme: const ExpansionTileThemeData(
                    collapsedIconColor: Colors.white70,
                    iconColor: Colors.white,
                    textColor: Colors.white,
                    collapsedTextColor: Colors.white,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  title: const Text(
                    'Datenbank',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .3,
                    ),
                  ),
                  leading:
                      const Icon(Icons.storage_rounded, color: Colors.white),
                  childrenPadding:
                      const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                  children: [
                    _DbTile(
                      icon: Icons.category_outlined,
                      label: 'Zutaten-Kategorien verwalten',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const IngredientCategoryManagerScreen(),
                            transitionDuration:
                                const Duration(milliseconds: 220),
                            reverseTransitionDuration:
                                const Duration(milliseconds: 220),
                            transitionsBuilder: (_, a, __, child) =>
                                FadeTransition(opacity: a, child: child),
                          ),
                        );
                      },
                    ),
                    _DbTile(
                      icon: Icons.tune, // <- NEU
                      label: 'Zutaten-Eigenschaften verwalten', // <- NEU
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const IngredientPropertyManagerScreen(),
                            transitionDuration:
                                const Duration(milliseconds: 220),
                            reverseTransitionDuration:
                                const Duration(milliseconds: 220),
                            transitionsBuilder: (_, a, __, child) =>
                                FadeTransition(opacity: a, child: child),
                          ),
                        );
                      },
                    ),
                    _DbTile(
                      icon: Icons.calendar_month,
                      label: 'Monate verwalten',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const MonthManagerScreen(),
                            transitionDuration:
                                const Duration(milliseconds: 220),
                            reverseTransitionDuration:
                                const Duration(milliseconds: 220),
                            transitionsBuilder: (_, a, __, child) =>
                                FadeTransition(opacity: a, child: child),
                          ),
                        );
                      },
                    ),
                    _DbTile(
                      icon: Icons.severe_cold, // oder Icons.grass / Icons.park
                      label: 'Saisonalität verwalten', // <- NEU (Seasonality)
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                SeasonalityManagerScreen(),
                            transitionDuration:
                                const Duration(milliseconds: 220),
                            reverseTransitionDuration:
                                const Duration(milliseconds: 220),
                            transitionsBuilder: (_, a, __, child) =>
                                FadeTransition(opacity: a, child: child),
                          ),
                        );
                      },
                    ),
                    _DbTile(
                      icon: Icons.straighten,
                      label: 'Einheiten verwalten',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const UnitManagerScreen(),
                            transitionDuration:
                                const Duration(milliseconds: 220),
                            reverseTransitionDuration:
                                const Duration(milliseconds: 220),
                            transitionsBuilder: (_, a, __, child) =>
                                FadeTransition(opacity: a, child: child),
                          ),
                        );
                      },
                    ),
                    _DbTile(
                      icon: Icons.category,
                      label: 'Nährstoff-Kategorien',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const NutrientCategorieManagerScreen(),
                            transitionDuration:
                                const Duration(milliseconds: 220),
                            reverseTransitionDuration:
                                const Duration(milliseconds: 220),
                            transitionsBuilder: (_, a, __, child) =>
                                FadeTransition(opacity: a, child: child),
                          ),
                        );
                      },
                    ),
                    _DbTile(
                      icon: Icons.local_fire_department,
                      label: 'Nährstoffe verwalten',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const NutrientManagerScreen(),
                            transitionDuration:
                                const Duration(milliseconds: 220),
                            reverseTransitionDuration:
                                const Duration(milliseconds: 220),
                            transitionsBuilder: (_, a, __, child) =>
                                FadeTransition(opacity: a, child: child),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DbTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DbTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      hoverColor: Colors.white10,
      selectedTileColor: Colors.white10,
      onTap: onTap,
    );
  }
}
