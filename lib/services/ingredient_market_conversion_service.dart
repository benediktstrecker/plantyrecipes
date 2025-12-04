import 'package:planty_flutter_starter/db/app_db.dart';

/// IngredientMarket Conversion:
/// -----------------------------------------------
/// Es gelten GENAU diese 4 Fälle (von dir definiert):
///
/// FALL 1: gleiche Einheit
///   → A_sli / A_im
///
/// FALL 2: beide categorie = "Masse"
///   → beide via baseFactor
///     c = A_sli * bfSli
///     a = A_im * bfIm
///     result = c / a
///
/// FALL 3: EXAKT eine Einheit ist Masse
///   → Masse-Einheit via baseFactor
///   → Nicht-Masse via IngredientUnit.amount
///     result = c / a
///
/// FALL 4: KEINE Einheit ist Masse
///   → beide via IngredientUnit.amount
///     result = c / a
///
/// Rückgabe:
///   double > 0  oder null wenn unlösbar
///
class IngredientMarketConversionService {
  final AppDb db;

  IngredientMarketConversionService(this.db);

  Future<double?> calculateIngredientMarketAmountNominal({
    required int ingredientId,
    required double ingredientAmountNominal,
    required String ingredientUnitCodeNominal,
    required IngredientMarketData ingredientMarket,
  }) async {
    print("=== IngredientMarketConversionService.calculateIngredientMarketAmountNominal ===");
    print("INPUT ingredientId=$ingredientId, ingredientAmountNominal=$ingredientAmountNominal, ingredientUnitCodeNominal=$ingredientUnitCodeNominal");
    print("INPUT IngredientMarket: id=${ingredientMarket.id}, unitCode=${ingredientMarket.unitCode}, unitAmount=${ingredientMarket.unitAmount}, price=${ingredientMarket.price}");

    if (ingredientAmountNominal <= 0) {
      print("ABBRUCH: ingredientAmountNominal <= 0");
      return null;
    }

    final double A_sli = ingredientAmountNominal;
    final String U_sli = ingredientUnitCodeNominal;

    final String? U_im = ingredientMarket.unitCode;
    final double? A_im = ingredientMarket.unitAmount;

    if (U_im == null || U_im.isEmpty) {
      print("ABBRUCH: U_im fehlt");
      return null;
    }
    if (A_im == null || A_im <= 0) {
      print("ABBRUCH: A_im <= 0 oder null");
      return null;
    }

    print("Berechnungsbasis: A_sli=$A_sli, U_sli=$U_sli, A_im=$A_im, U_im=$U_im");

    // -------------------------------------------------------------------
    // FALL 1: gleiche Einheit
    // -------------------------------------------------------------------
    print("CHECK FALL 1: gleiche Einheit? (U_im == U_sli) → $U_im == $U_sli");
    if (U_im == U_sli) {
      final result = A_sli / A_im;
      print("Fall 1 → result=$result");
      return result;
    }

    // -------------------------------------------------------------------
    // Units laden
    // -------------------------------------------------------------------
    final unitSli = await _getUnitByCode(U_sli);
    final unitIm = await _getUnitByCode(U_im);

    if (unitSli == null || unitIm == null) {
      print("ABBRUCH: Unit nicht gefunden → unitSli=$unitSli, unitIm=$unitIm");
      return null;
    }

    final catSli = unitSli.categorie;
    final catIm = unitIm.categorie;

    final bfSli = unitSli.baseFactor;
    final bfIm = unitIm.baseFactor;

    final isMassSli = catSli == "Masse";
    final isMassIm = catIm == "Masse";

    print("unitSli: cat=$catSli, bf=$bfSli");
    print("unitIm : cat=$catIm, bf=$bfIm");
    print("isMassSli=$isMassSli, isMassIm=$isMassIm");

    // -------------------------------------------------------------------
    // FALL 2: beide Masse
    // -------------------------------------------------------------------
    if (isMassSli && isMassIm) {
      print("FALL 2: beide Einheiten sind Masse → baseFactor für beide");

      final c = A_sli * bfSli;
      final a = A_im * bfIm;

      print("c = A_sli * bfSli = $A_sli * $bfSli = $c");
      print("a = A_im * bfIm   = $A_im * $bfIm = $a");

      if (a == 0) {
        print("ABBRUCH: a == 0");
        return null;
      }

      final result = c / a;
      print("Fall 2 → result=$result");
      return result;
    }

    // -------------------------------------------------------------------
    // IngredientUnits laden (für Fall 3 & Fall 4)
    // -------------------------------------------------------------------
    print("Lade IngredientUnits…");

    final iuSli = await _getIngredientUnit(ingredientId: ingredientId, unitCode: U_sli);
    final iuIm  = await _getIngredientUnit(ingredientId: ingredientId, unitCode: U_im);

    print("iuSli: $iuSli");
    print("iuIm : $iuIm");

    // -------------------------------------------------------------------
    // FALL 3: exakt eine Einheit ist Masse
    // -------------------------------------------------------------------
    if (isMassSli && !isMassIm) {
      print("FALL 3: SLI=Masse, IM=Nicht-Masse → bfSli + iuIm.amount");

      if (iuIm == null) {
        print("ABBRUCH: iuIm fehlt");
        return null;
      }

      final c = A_sli * bfSli;
      final a = A_im * iuIm.amount;

      print("c = A_sli * bfSli       = $A_sli * $bfSli = $c");
      print("a = A_im * iuIm.amount  = $A_im * ${iuIm.amount} = $a");

      if (a == 0) {
        print("ABBRUCH: a==0");
        return null;
      }

      final result = c / a;
      print("Fall 3 → result=$result");
      return result;
    }

    if (!isMassSli && isMassIm) {
      print("FALL 3: SLI=Nicht-Masse, IM=Masse → iuSli.amount + bfIm");

      if (iuSli == null) {
        print("ABBRUCH: iuSli fehlt");
        return null;
      }

      final c = A_sli * iuSli.amount;
      final a = A_im * bfIm;

      print("c = A_sli * iuSli.amount = $A_sli * ${iuSli.amount} = $c");
      print("a = A_im * bfIm          = $A_im * $bfIm = $a");

      if (a == 0) {
        print("ABBRUCH: a==0");
        return null;
      }

      final result = c / a;
      print("Fall 3 → result=$result");
      return result;
    }

    // -------------------------------------------------------------------
    // FALL 4: beide NICHT Masse → IngredientUnits für beide
    // -------------------------------------------------------------------
    print("FALL 4: keine Einheit ist Masse → IngredientUnits für beide");

    if (iuSli == null || iuIm == null) {
      print("ABBRUCH: iuSli oder iuIm fehlt → iuSli=$iuSli, iuIm=$iuIm");
      return null;
    }

    final c = A_sli * iuSli.amount;
    final a = A_im * iuIm.amount;

    print("c = A_sli * iuSli.amount = $A_sli * ${iuSli.amount} = $c");
    print("a = A_im * iuIm.amount   = $A_im * ${iuIm.amount} = $a");

    if (a == 0) {
      print("ABBRUCH: a==0");
      return null;
    }

    final result = c / a;
    print("Fall 4 → result=$result");
    return result;
  }

  // -------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------

  Future<Unit?> _getUnitByCode(String code) async {
    print("_getUnitByCode('$code')…");
    return await (db.select(db.units)..where((u) => u.code.equals(code)))
        .getSingleOrNull();
  }

  Future<IngredientUnit?> _getIngredientUnit({
    required int ingredientId,
    required String unitCode,
  }) async {
    print("_getIngredientUnit(ingredientId=$ingredientId, unitCode='$unitCode')…");
    return await (db.select(db.ingredientUnits)
          ..where((u) => u.ingredientId.equals(ingredientId))
          ..where((u) => u.unitCode.equals(unitCode)))
        .getSingleOrNull();
  }
}
