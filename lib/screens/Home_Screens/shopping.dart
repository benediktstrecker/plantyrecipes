// lib/screens/shopping.dart
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/utils/easy_swipe_nav.dart';
import 'package:planty_flutter_starter/design/drawer.dart';

// Zielseiten importieren
import 'package:planty_flutter_starter/screens/Home_Screens/mobile_view.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/ingredients.dart';

import 'package:planty_flutter_starter/screens/Home_Screens/nutrition.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/settings.dart';

class Shopping extends StatefulWidget {
  const Shopping({super.key});

  @override
  State<Shopping> createState() => _ShoppingState();
}

class _ShoppingState extends State<Shopping> with EasySwipeNav {
  int _selectedIndex = 2; // 2 = Einkauf
  static const Duration _slideDuration = Duration(milliseconds: 280);

  @override
  int get currentIndex => _selectedIndex;

  Widget _widgetForIndex(int index) {
    switch (index) {
      case 0: return MobileView();
case 1: return Ingredients();

      case 2:
        return Shopping();
      case 3:
        return Nutrition();
      case 4:
      default:
        return Settings();
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
            "Planty Recipes",
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: darkgreen,
        ),

        // Einfacher Drawer (keine DB, kein AppDrawer)
        drawer: const AppDrawer(currentIndex: 0),
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

        body: const Center(
          child: Text(
            "Einkaufsliste – Coming Soon",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
