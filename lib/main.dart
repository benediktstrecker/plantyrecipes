// lib/main.dart
import 'package:flutter/material.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/mobile_view.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/responsive_layout.dart';
import 'package:planty_flutter_starter/design/layout.dart';

// Import der DB und der Importfunktionen
import 'package:planty_flutter_starter/db/import_units.dart'; // <- wichtig!

Future<void> main() async {
  // Flutter Engine initialisieren (damit async in main erlaubt ist)
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Einmaliger Initialimport (idempotent, via SharedPreferences Flag)
  //    -> Importiert nur beim allerersten App-Start, danach nie wieder automatisch.
  try {
    await importInitialDataIfEmpty();
  } catch (e, st) {
    // Falls irgendwas schiefgeht, nicht den App-Start blockieren
    // (aber Fehler im Log sichtbar machen)
    // ignore: avoid_print
    print('[startup] Initial-Import Fehler: $e\n$st');
  }

  // 3) Jetzt App starten
  runApp(const PlantyApp());
}

class PlantyApp extends StatelessWidget {
  const PlantyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Planty Recipes',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: darkgreen),
      ),
      home: ResponsiveLayout(
        mobileview: MobileView(),
        tabletview: MobileView(),
        desktopview: MobileView(),
      ),
    );
  }
}
