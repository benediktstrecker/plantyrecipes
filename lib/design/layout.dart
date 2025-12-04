// lib/design/layout.dart
import "package:flutter/material.dart";

class Design extends StatefulWidget {
  const Design({super.key});

  @override
  State<Design> createState() => _DesignState();
}

// Screenwidths for different views:
int maxMobilewidth = 500;
int maxTabletwidth = 1100;
int maxDesktoptwidth = 1100;

//Color-Sets:
var darkgreen = Color.fromARGB(255, 17, 42, 29);
var darkdarkgreen = const Color.fromARGB(255, 11, 27, 19);
var middlegreen = Colors.green[800];
var dark = Colors.black12;

//Schriften
var middlewhite = TextStyle(color: Colors.white, fontWeight: FontWeight.bold);

//Zeiten
var Slidetime = const Duration(milliseconds: 500);

class _DesignState extends State<Design> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
