import 'package:planty_flutter_starter/db/app_db.dart';

/// Produkt-Umrechnung nach deiner 4-Fälle-Systematik.
/// --------------------------------------------------------
///
/// Fall 1: size_unit_code == ingredient_unit_code_nominal
///     → result = A_sli / sizeNumber
///
/// Fall 2: yield_unit_code == ingredient_unit_code_nominal
///     → result = A_sli / yield_amount
///
/// Fall 3: beide Einheiten = Masse
///     → beide via baseFactor
///       c = A_sli * bfSli
///       b = yieldAmount * bfYield
///       result = c / b
///
/// Fall 4: exakt eine Einheit = Masse
///     → Masse   = baseFactor
///     → Nicht-Masse = IngredientUnits
///
/// Fall 5: keine Einheit = Masse
///     → beide via IngredientUnits
///
class UnitConversionService {
  final AppDb db;

  UnitConversionService(this.db);

  Future<double?> calculateProductAmountNominal({
    required int ingredientIdNominal,
    required double ingredientAmountNominal,
    required String ingredientUnitCodeNominal,
    required Product product,
  }) async {
    print("=== UnitConversionService ===");
    print("INPUT ingredientId=$ingredientIdNominal, amount=$ingredientAmountNominal, unit=$ingredientUnitCodeNominal");
    print("PRODUCT id=${product.id}, ingredientId=${product.ingredientId}, sizeUnit=${product.sizeUnitCode}, sizeNumber=${product.sizeNumber}, yieldUnit=${product.yieldUnitCode}, yieldAmount=${product.yieldAmount}");

    if (ingredientAmountNominal <= 0) {
      print("ABBRUCH: ingredientAmountNominal <= 0");
      return null;
    }

    final A_sli = ingredientAmountNominal;
    final U_sli = ingredientUnitCodeNominal;

    final sizeUnit = product.sizeUnitCode;
    final sizeNumber = product.sizeNumber;

    final U_yield = product.yieldUnitCode;
    final B_yield = product.yieldAmount;

    // --------------------------------------------------------
    // FALL 1 – gleiche Einheit über sizeUnit → 1:1 / sizeNumber
    // --------------------------------------------------------
    if (sizeUnit != null && sizeUnit.isNotEmpty && sizeUnit == U_sli) {
      if (sizeNumber == null || sizeNumber <= 0) {
        print("ABBRUCH FALL 1: sizeNumber fehlt");
        return null;
      }
      final result = A_sli / sizeNumber;
      print("FALL 1 → result = A_sli / sizeNumber = $A_sli / $sizeNumber = $result");
      return result;
    }

    // Yield-Daten müssen vollständig sein
    if (U_yield == null || U_yield.isEmpty || B_yield == null || B_yield <= 0) {
      print("ABBRUCH: yieldUnit oder yieldAmount fehlt");
      return null;
    }

    print("A_sli=$A_sli, U_sli=$U_sli, B_yield=$B_yield, U_yield=$U_yield");

    // --------------------------------------------------------
    // FALL 2 – gleiche Einheit über yield → direkte Division
    // --------------------------------------------------------
    if (U_yield == U_sli) {
      final result = A_sli / B_yield;
      print("FALL 2 → result = A_sli / yieldAmount = $A_sli / $B_yield = $result");
      return result;
    }

    // --------------------------------------------------------
    // Units laden (für Kategorien + baseFactor)
    // --------------------------------------------------------
    final unitYield = await _getUnitByCode(U_yield);
    final unitSli = await _getUnitByCode(U_sli);

    if (unitYield == null || unitSli == null) {
      print("ABBRUCH: Unit nicht gefunden");
      return null;
    }

    final catYield = unitYield.categorie;
    final catSli = unitSli.categorie;

    final bfYield = unitYield.baseFactor;
    final bfSli = unitSli.baseFactor;

    final isMassYield = catYield == "Masse";
    final isMassSli = catSli == "Masse";

    print("unitYield: cat=$catYield, bf=$bfYield");
    print("unitSli  : cat=$catSli,   bf=$bfSli");
    print("isMassYield=$isMassYield, isMassSli=$isMassSli");

    // --------------------------------------------------------
    // FALL 3 – beide Masse → beide via baseFactor
    // --------------------------------------------------------
    if (isMassYield && isMassSli) {
      final c = A_sli * bfSli;
      final b = B_yield * bfYield;
      if (b == 0) return null;
      final result = c / b;
      print("FALL 3 → c=$c, b=$b, result=$result");
      return result;
    }

    // IngredientUnits laden
    print("IngredientUnits laden …");
    final iuYield = await _getIngredientUnit(
      ingredientId: product.ingredientId,
      unitCode: U_yield,
    );

    final iuSli = await _getIngredientUnit(
      ingredientId: ingredientIdNominal,
      unitCode: U_sli,
    );

    if (iuYield == null) print("WARNUNG: iuYield fehlt ($U_yield)");
    if (iuSli == null) print("WARNUNG: iuSli fehlt ($U_sli)");

    // --------------------------------------------------------
    // FALL 4 – genau eine Masse
    // --------------------------------------------------------
    if (isMassYield && !isMassSli) {
      if (iuSli == null) return null;
      final c = A_sli * iuSli.amount;
      final b = B_yield * bfYield;
      if (b == 0) return null;
      final result = c / b;
      print("FALL 4 (yield=Masse) → c=$c, b=$b, result=$result");
      return result;
    }

    if (!isMassYield && isMassSli) {
      if (iuYield == null) return null;
      final c = A_sli * bfSli;
      final b = B_yield * iuYield.amount;
      if (b == 0) return null;
      final result = c / b;
      print("FALL 4 (SLI=Masse) → c=$c, b=$b, result=$result");
      return result;
    }

    // --------------------------------------------------------
    // FALL 5 – keine Masse → beide via IngredientUnits
    // --------------------------------------------------------
    if (iuYield == null || iuSli == null) return null;

    final c = A_sli * iuSli.amount;
    final b = B_yield * iuYield.amount;

    if (b == 0) return null;

    final result = c / b;
    print("FALL 5 → c=$c, b=$b, result=$result");
    return result;
  }

  // --------------------------------------------------------
  // Helpers
  // --------------------------------------------------------

  Future<Unit?> _getUnitByCode(String code) async {
    print("_getUnitByCode('$code')…");
    return await (db.select(db.units)..where((u) => u.code.equals(code)))
        .getSingleOrNull();
  }

  Future<IngredientUnit?> _getIngredientUnit({
    required int ingredientId,
    required String unitCode,
  }) async {
    print("_getIngredientUnit(ingredientId=$ingredientId, unitCode='$unitCode')");
    return await (db.select(db.ingredientUnits)
          ..where((u) => u.ingredientId.equals(ingredientId))
          ..where((u) => u.unitCode.equals(unitCode)))
        .getSingleOrNull();
  }
}
