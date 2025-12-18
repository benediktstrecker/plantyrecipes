// lib/design/drawer.dart
import 'package:flutter/material.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/recipes.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/ingredients.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/shopping.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/nutrition.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/meals.dart';

import 'package:planty_flutter_starter/db/app_db.dart' as dbt;
import 'package:planty_flutter_starter/db/db_singleton.dart' as db;
import 'package:planty_flutter_starter/screens/user/user.dart';


// DB-/Admin-Screens
import 'package:planty_flutter_starter/screens/data_manager/month_manager_screen.dart';
import 'package:planty_flutter_starter/screens/data_manager/unit_manager_screen.dart';
import 'package:planty_flutter_starter/screens/data_manager/countries_manager_screen.dart';
import 'package:planty_flutter_starter/screens/data_manager/nutrient_categorie_manager_screen.dart';
import 'package:planty_flutter_starter/screens/data_manager/nutrient_manager_screen.dart';
import 'package:planty_flutter_starter/screens/data_manager/ingredient_category_manager_screen.dart';
import 'package:planty_flutter_starter/screens/data_manager/seasonality_manager_screen.dart';
import 'package:planty_flutter_starter/screens/data_manager/recipe_category_manager_screen.dart'; 
import 'package:planty_flutter_starter/screens/data_manager/tag_categorie_manager_screen.dart';
import 'package:planty_flutter_starter/screens/data_manager/tag_manager_screen.dart';
import 'package:planty_flutter_starter/screens/data_manager/trafficlight_manager_screen.dart'; 
import 'package:planty_flutter_starter/screens/data_manager/shopshelf_manager_screen.dart'; 
import 'package:planty_flutter_starter/screens/data_manager/storage_category_manager_screen.dart';
import 'package:planty_flutter_starter/screens/data_manager/markets_manager_screen.dart';
import 'package:planty_flutter_starter/screens/data_manager/producers_manager_screen.dart';





class AppDrawer extends StatelessWidget {
  final int currentIndex;
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
              /*const DrawerHeader(
                decoration: BoxDecoration(color: Colors.black),
                child: Text('Menü',
                    style: TextStyle(fontSize: 20, color: Colors.white)),
              ),*/

              //const SizedBox(height: 8),
              _UserSelectorRow(),
              const SizedBox(height: 8),


              // Hauptnavigation
              ListTile(
                leading: const Icon(Icons.eco),
                title: const Text('Zutaten'),
                selected: currentIndex == 0,
                selectedTileColor: Colors.white10,
                onTap: () => _go(context, const Ingredients()),
              ),

              ListTile(
                leading: const Icon(Icons.shopping_bag),
                title: const Text('Einkauf'),
                selected: currentIndex == 1,
                selectedTileColor: Colors.white10,
                onTap: () => _go(context, const Shopping()),
              ),

              ListTile(
                leading: const Icon(Icons.list_alt),
                title: const Text('Rezepte'),
                selected: currentIndex == 2,
                selectedTileColor: Colors.white10,
                onTap: () => _go(context, const Recipes()),
              ),

              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Planung'),
                selected: currentIndex == 3,
                selectedTileColor: Colors.white10,
                onTap: () => _go(context, const Meals()),
              ),

              ListTile(
                leading: const Icon(Icons.stacked_bar_chart),
                title: const Text('Nährwerte'),
                selected: currentIndex == 4,
                selectedTileColor: Colors.white10,
                onTap: () => _go(context, const Nutrition()),
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
                      icon: Icons.restaurant_menu, // ✅ NEU
                      label: 'Rezept-Kategorien verwalten', // ✅ NEU
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const RecipeCategoryManagerScreen(),
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
                      icon: Icons.severe_cold,
                      label: 'Saisonalität verwalten',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                const SeasonalityManagerScreen(),
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
                      icon: Icons.flag_rounded,
                      label: 'Länder verwalten',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) => const CountriesManagerScreen(),
                            transitionDuration: const Duration(milliseconds: 220),
                            reverseTransitionDuration: const Duration(milliseconds: 220),
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
                    _DbTile(
  icon: Icons.style, // ✅ Tag-Kategorien
  label: 'Tag-Kategorien verwalten',
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const TagCategorieManagerScreen(),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  },
),
_DbTile(
  icon: Icons.edit_attributes, // ✅ Tags
  label: 'Tags verwalten',
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const TagManagerScreen(),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  },
),
_DbTile(
  icon: Icons.traffic_outlined, // ✅ Trafficlight
  label: 'Trafficlight verwalten',
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const TrafficlightManagerScreen(),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  },
),
_DbTile(
  icon: Icons.shelves, // ✅ Shopshelf
  label: 'Shopshelf verwalten',
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ShopshelfManagerScreen(),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  },
),
_DbTile(
  icon: Icons.inventory_2_outlined, // ✅ Storage Categories
  label: 'Storage Categories verwalten',
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const StorageCategoryManagerScreen(),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  },
),
_DbTile(
  icon: Icons.storefront_outlined, // ✅ Markets
  label: 'Markets verwalten',
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MarketsManagerScreen(),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
  },
),
_DbTile(
  icon: Icons.factory_outlined, // ✅ Producers
  label: 'Producers verwalten',
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ProducersManagerScreen(),
        transitionDuration: const Duration(milliseconds: 220),
        reverseTransitionDuration: const Duration(milliseconds: 220),
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

class _UserSelectorRow extends StatelessWidget {
  const _UserSelectorRow();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dbt.UserData>>(
      future: db.appDb.select(db.appDb.user).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final users = snapshot.data!;

        return SizedBox(
          height: 110,
          child: LayoutBuilder(
            builder: (context, c) {
              final itemWidth = c.maxWidth / 2;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: users.length,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemBuilder: (context, i) {
                  final u = users[i];

                  return SizedBox(
                    width: users.length == 1 ? c.maxWidth : itemWidth,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, __, ___) =>
                                UserEditScreen(userId: u.id),
                            transitionDuration:
                                const Duration(milliseconds: 220),
                            reverseTransitionDuration:
                                const Duration(milliseconds: 220),
                            transitionsBuilder: (_, a, __, child) =>
                                FadeTransition(opacity: a, child: child),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white24,
                            backgroundImage:
                                (u.picture != null && u.picture!.isNotEmpty)
                                    ? AssetImage(u.picture!)
                                    : null,
                            child: (u.picture == null || u.picture!.isEmpty)
                                ? const Icon(Icons.person,
                                    color: Colors.white54, size: 32)
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            u.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
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
        );
      },
    );
  }
}

