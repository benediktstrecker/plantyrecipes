// lib/utils/number_formatter.dart
import 'package:fraction/fraction.dart';

class NumberFormatter {
  /// Formatiert eine Zahl mit individuellen Rundungsregeln.
  static String formatCustom(double value) {
    double absVal = value.abs();
    double rounded;

    if (absVal < 1) {
      // bis viertel
      rounded = (value * 4).round() / 4;
      return _toMixed(Fraction.fromDouble(rounded));
    } else if (absVal < 5) {
      // bis Viertel
      rounded = (value * 2).round() / 2;
      return _toMixed(Fraction.fromDouble(rounded));
    } else if (absVal < 100) {
      // bis halbe
      rounded = (value * 1).round() / 1;
      return _toMixed(Fraction.fromDouble(rounded));
    } else {
      // über 100 auf 5er-Schritte runden
      int roundedInt = (5 * (value / 5).round());
      return roundedInt.toString();
    }
  }

  /// Gibt einen gemischten Bruch als String aus, z. B. 2 3/4 statt 11/4.
  static String _toMixed(Fraction f) {
    if (f.numerator.abs() < f.denominator) return f.toString();
    final whole = f.numerator ~/ f.denominator;
    final remainder = (f.numerator.abs() % f.denominator);
    return remainder == 0
        ? '$whole'
        : '$whole ${Fraction(remainder, f.denominator)}';
  }
}
