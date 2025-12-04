// lib/utils/easy_swipe_nav.dart
import 'package:flutter/material.dart';

mixin EasySwipeNav<T extends StatefulWidget> on State<T> {
  /// Setze hier pro Screen den aktuellen Tab-Index (0..4)
  int get currentIndex;

  /// So navigierst du wirklich (z.B. deine _navigateToPage)
  void goToIndex(int index);

  // Tuning (gern nach Geschmack anpassen)
  static const double kVelocityThresh = 180; // früher 300
  static const double kDistanceThresh = 60; // Wischweg in px

  double _accDx = 0.0;

  void onSwipeStart(DragStartDetails d) {
    _accDx = 0.0;
  }

  void onSwipeUpdate(DragUpdateDetails d) {
    _accDx += d.delta.dx; // >0 rechts, <0 links
  }

  void onSwipeEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0.0;

    // 1) Velocity-Trigger (fühlt sich „flutschig“ an)
    if (v <= -kVelocityThresh && currentIndex < 4) {
      goToIndex(currentIndex + 1); // links → nächster Tab
      return;
    }
    if (v >= kVelocityThresh && currentIndex > 0) {
      goToIndex(currentIndex - 1); // rechts → vorheriger Tab
      return;
    }

    // 2) Distanz-Trigger (Fallback, wenn Finger langsam wischt)
    if (_accDx <= -kDistanceThresh && currentIndex < 4) {
      goToIndex(currentIndex + 1);
      return;
    }
    if (_accDx >= kDistanceThresh && currentIndex > 0) {
      goToIndex(currentIndex - 1);
      return;
    }

    // Sonst: nichts tun
  }
}
