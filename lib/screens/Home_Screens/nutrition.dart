// lib/screens/Home_Screens/nutrition.dart
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/utils/easy_swipe_nav.dart';
import 'package:planty_flutter_starter/design/drawer.dart';

// Zielseiten importieren
import 'package:planty_flutter_starter/screens/Home_Screens/recipes.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/ingredients.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/shopping.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/meals.dart';

class Nutrition extends StatefulWidget {
  const Nutrition({super.key});

  @override
  State<Nutrition> createState() => _NutritionState();
}

class _NutritionState extends State<Nutrition> with EasySwipeNav {
  int _selectedIndex = 4; // 4 = Nährwerte
  static const Duration _slideDuration = Duration(milliseconds: 280);

  @override
  int get currentIndex => _selectedIndex;

  Widget _widgetForIndex(int index) {
  switch (index) {
    case 0:
      return const Ingredients();       // Zutaten
    case 1:
      return const Shopping();          // Einkauf
    case 2:
      return const Recipes();           // Rezepte (Startseite)
    case 3:
      return const Meals();          // Mahlzeiten
    case 4:
    default:
      return const Nutrition();         // Nährwerte
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
          return SlideTransition(
              position: animation.drive(tween), child: child);
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
      onHorizontalDragStart: onSwipeStart,
      onHorizontalDragUpdate: onSwipeUpdate,
      onHorizontalDragEnd: onSwipeEnd,
      child: Scaffold(
        backgroundColor: darkgreen,
        appBar: AppBar(
          title: const Text(
            "Planty Nutrition",
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: darkgreen,
        ),

        // Einfacher Drawer (ohne DB)
        drawer: const AppDrawer(currentIndex: 4),
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
              GButton(icon: Icons.eco, text: 'Zutaten'),            // index 0
              GButton(icon: Icons.storefront, text: 'Einkauf'),   // index 1
              GButton(icon: Icons.list_alt, text: 'Rezepte'),       // index 2
              GButton(icon: Icons.calendar_month, text: 'Mahlzeiten'), // index 3
              GButton(icon: Icons.stacked_bar_chart, text: 'Nährwerte'), // index 4
            ],
          ),
        ),

        body: const Center(
          child: Text(
            "Nährwerte – Coming Soon",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
