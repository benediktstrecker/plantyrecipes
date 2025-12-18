// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:flutter/scheduler.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/recipes.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/responsive_layout.dart';
import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/design/splash_screen.dart';
import 'package:planty_flutter_starter/db/import_units.dart';

// ---------------------------------------------------------------------------
// HINZUGEFÜGT: RouteObserver für RouteAware
// ---------------------------------------------------------------------------
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  painting.imageCache.maximumSizeBytes = 512 * 1024 * 1024;
  painting.imageCache.maximumSize = 200;
  timeDilation = 1.0;

  runApp(const PlantyApp());
}

class PlantyApp extends StatefulWidget {
  const PlantyApp({super.key});

  @override
  State<PlantyApp> createState() => _PlantyAppState();
}

class _PlantyAppState extends State<PlantyApp> {
  late final Future<bool> _dbReady;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _dbReady = _initDatabase();
  }

  Future<bool> _initDatabase() async {
    try {
      await importInitialDataIfEmpty();
      debugPrint('[startup] DB bereit');
      return true;
    } catch (e, st) {
      debugPrint('[startup] Fehler: $e\n$st');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Planty Recipes',

      // -----------------------------------------------------------------------
      // HINZUGEFÜGT: RouteObserver aktivieren
      // -----------------------------------------------------------------------
      navigatorObservers: [routeObserver],

      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF112A1D),
        colorScheme: ColorScheme.fromSeed(seedColor: darkgreen),
      ),

      home: FutureBuilder<bool>(
        future: _dbReady,
        builder: (context, snapshot) {
          if (!snapshot.hasData || _showSplash) {
            return SplashScreen(
              onComplete: () => setState(() => _showSplash = false),
            );
          }
          return ResponsiveLayout(
            mobileview: Recipes(),
            tabletview: Recipes(),
            desktopview: Recipes(),
          );
        },
      ),
    );
  }
}
