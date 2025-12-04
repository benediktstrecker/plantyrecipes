import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:drift/drift.dart' as d;
import 'package:planty_flutter_starter/db/db_singleton.dart';

import 'package:planty_flutter_starter/services/unit_conversion_service.dart';
import 'package:planty_flutter_starter/services/ingredient_market_conversion_service.dart';

// ===================================================================
// Vorauswahl-Hilfstypen
// ===================================================================

enum IngredientNominalCandidateType { product, ingredientMarket }

class IngredientNominalCandidate {
  final IngredientNominalCandidateType type;
  final int id;
  final bool isFavorite;

  IngredientNominalCandidate({
    required this.type,
    required this.id,
    required this.isFavorite,
  });
}

class IngredientNominalSelection {
  final int? productId;
  final int? ingredientMarketId;
  final int? countryId; // ← NEU !!!

  const IngredientNominalSelection({
    this.productId,
    this.ingredientMarketId,
    this.countryId,
  });

  static const none =
      IngredientNominalSelection(productId: null, ingredientMarketId: null, countryId: null);

  factory IngredientNominalSelection.fromCandidate(
    IngredientNominalCandidate c,
  ) {
    switch (c.type) {
      case IngredientNominalCandidateType.product:
        return IngredientNominalSelection(
          productId: c.id,
          ingredientMarketId: null,
          countryId: null,
        );
      case IngredientNominalCandidateType.ingredientMarket:
        return IngredientNominalSelection(
          productId: null,
          ingredientMarketId: c.id,
          countryId: null,
        );
    }
  }

  IngredientNominalSelection copyWith({
    int? productId,
    int? ingredientMarketId,
    int? countryId,
  }) {
    return IngredientNominalSelection(
      productId: productId ?? this.productId,
      ingredientMarketId: ingredientMarketId ?? this.ingredientMarketId,
      countryId: countryId ?? this.countryId,
    );
  }
}


class _AmountCandidate {
  final IngredientNominalCandidate c;
  final double diff;
  _AmountCandidate({required this.c, required this.diff});
}

class _PriceCandidate {
  final IngredientNominalCandidate c;
  final double price;
  _PriceCandidate({required this.c, required this.price});
}

Future<int?> resolveCountryForNominal({
  required bool isProduct,
  required int nominalId,          // productId oder ingredientMarketId
  required AppDb db,
}) async {
  if (isProduct) {
    // Alle Länder dieses Produkts
    final rows = await (db.select(db.productCountry)
          ..where((t) => t.productsId.equals(nominalId)))
        .get();

    if (rows.isEmpty) return null;
    if (rows.length == 1) return rows.first.countriesId;

    // Mehrere → historisch häufigstes Land für dieses Produkt
    final sli = db.shoppingListIngredient;
    final freq = await db.customSelect(
      '''
        SELECT country_id, COUNT(*) AS cnt
        FROM shopping_list_ingredient
        WHERE product_id_actual = ?
          AND country_id IS NOT NULL
        GROUP BY country_id
        ORDER BY cnt DESC
        LIMIT 1
      ''',
      variables: [d.Variable(nominalId)],
    ).get();

    if (freq.isNotEmpty) {
      return freq.first.data["country_id"] as int?;
    }

    return null;
  } else {
    // Alle Länder dieses IngredientMarket
    final rows = await (db.select(db.ingredientMarketCountry)
          ..where((t) => t.ingredientMarketId.equals(nominalId)))
        .get();

    if (rows.isEmpty) return null;
    if (rows.length == 1) return rows.first.countriesId;

    // Mehrere → historisch häufigstes Land für dieses IngredientMarket
    final freq = await db.customSelect(
      '''
        SELECT country_id, COUNT(*) AS cnt
        FROM shopping_list_ingredient
        WHERE ingredient_market_id_actual = ?
          AND country_id IS NOT NULL
        GROUP BY country_id
        ORDER BY cnt DESC
        LIMIT 1
      ''',
      variables: [d.Variable(nominalId)],
    ).get();

    if (freq.isNotEmpty) {
      return freq.first.data["country_id"] as int?;
    }

    return null;
  }
}

// ===================================================================
// Zentrale Vorauswahl-Logik
// ===================================================================

Future<IngredientNominalSelection> resolveNominalForIngredient(
  int ingredientId,
  int shoppingListId,
  String? ingredientUnitCodeNominal,
  double? ingredientAmountNominal,
) async {
  final db = appDb;

  final sli = db.shoppingListIngredient;
  final sl = db.shoppingList;
  final p = db.products;
  final pm = db.productMarkets;
  final im = db.ingredientMarket;

  // aktuellen Markt der Liste holen
  final listRow = await (db.select(sl)
        ..where((t) => t.id.equals(shoppingListId)))
      .getSingle();

  final marketId = listRow.marketId;
  if (marketId == null) {
    return IngredientNominalSelection.none;
  }

  // 1. Produkte & IngredientMarket laden
  final products = await (db.select(p)
        ..where((t) => t.ingredientId.equals(ingredientId)))
      .get();

  final ingredientMarkets = await (db.select(im)
        ..where((t) => t.ingredientId.equals(ingredientId)))
      .get();

  final productMarketsForMarket = await (db.select(pm)
        ..where((t) => t.marketId.equals(marketId)))
      .get();

  final productIdsInMarket =
      productMarketsForMarket.map((e) => e.productsId).toSet();

  final List<IngredientNominalCandidate> candidates = [];

  // Produktkandidaten
  for (final prod in products) {
    if (productIdsInMarket.contains(prod.id)) {
      candidates.add(
        IngredientNominalCandidate(
          type: IngredientNominalCandidateType.product,
          id: prod.id,
          isFavorite: prod.favorite,
        ),
      );
    }
  }

  // IngredientMarket-Kandidaten
  for (final m in ingredientMarkets) {
    if (m.marketId == marketId) {
      candidates.add(
        IngredientNominalCandidate(
          type: IngredientNominalCandidateType.ingredientMarket,
          id: m.id,
          isFavorite: m.favorite,
        ),
      );
    }
  }

  if (candidates.isEmpty) return IngredientNominalSelection.none;

  // Regel 1: eindeutiger Treffer
if (candidates.length == 1) {
  final selection = IngredientNominalSelection.fromCandidate(candidates.first);

  // Country direkt ermitteln
  final resolvedCountry = await resolveCountryForNominal(
    isProduct: selection.productId != null,
    nominalId: selection.productId ?? selection.ingredientMarketId!,
    db: db,
  );

  return selection.copyWith(countryId: resolvedCountry);
}


  // Regel 2: Favoriten
  final favs = candidates.where((c) => c.isFavorite).toList();
if (favs.isNotEmpty) {
  final selection = IngredientNominalSelection.fromCandidate(favs.first);

  final resolvedCountry = await resolveCountryForNominal(
    isProduct: selection.productId != null,
    nominalId: selection.productId ?? selection.ingredientMarketId!,
    db: db,
  );

  return selection.copyWith(countryId: resolvedCountry);
}


  // Regel 3: historisch am häufigsten genutzt
  final usageCount = <int, int>{};

  final pastQuery = (db.select(sli)
        ..where((t) => t.ingredientIdActual.equals(ingredientId)))
      .join([d.innerJoin(sl, sl.id.equalsExp(sli.shoppingListId))]);

  pastQuery.where(sl.marketId.equals(marketId));
  final pastRows = await pastQuery.get();

  for (final row in pastRows) {
    final sliRow = row.readTable(sli);

    final pid = sliRow.productIdActual;
    if (pid != null &&
        candidates.any((c) =>
            c.type == IngredientNominalCandidateType.product &&
            c.id == pid)) {
      usageCount[pid] = (usageCount[pid] ?? 0) + 1;
    }

    final imId = sliRow.ingredientMarketIdActual;
    if (imId != null &&
        candidates.any((c) =>
            c.type == IngredientNominalCandidateType.ingredientMarket &&
            c.id == imId)) {
      usageCount[imId] = (usageCount[imId] ?? 0) + 1;
    }
  }

  if (usageCount.isNotEmpty) {
    final bestId = usageCount.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    final bestCandidate = candidates.firstWhere((c) => c.id == bestId);
    final selection = IngredientNominalSelection.fromCandidate(bestCandidate);

    // COUNTRY Vorauswahl hier einfügen
    final countryId = await resolveCountryForNominal(
      isProduct: selection.productId != null,
      nominalId: selection.productId ?? selection.ingredientMarketId!,
      db: db,
    );

    
return selection.copyWith(countryId: countryId);

  }

  // Regel 4: passende Unit bevorzugen
  final unitMatched = <IngredientNominalCandidate>[];

  for (final c in candidates) {
    if (c.type == IngredientNominalCandidateType.product) {
      final prod = products.firstWhere((p) => p.id == c.id);
      if (prod.yieldUnitCode == ingredientUnitCodeNominal) unitMatched.add(c);
    } else {
      final mk = ingredientMarkets.firstWhere((m) => m.id == c.id);
      if (mk.unitCode == ingredientUnitCodeNominal) unitMatched.add(c);
    }
  }

  List<IngredientNominalCandidate> pool =
      unitMatched.isNotEmpty ? unitMatched : candidates;

  // Regel 5: geringste Überschreitung der Menge
  final List<_AmountCandidate> diffs = [];
  final base = ingredientAmountNominal ?? 0;

  for (final c in pool) {
    if (c.type == IngredientNominalCandidateType.product) {
      final prod = products.firstWhere((p) => p.id == c.id);
      final diff = (prod.yieldAmount ?? 0) - base;
      if (diff >= 0) diffs.add(_AmountCandidate(c: c, diff: diff));
    } else {
      final mk = ingredientMarkets.firstWhere((m) => m.id == c.id);
      if (mk.packageUnitCode != null) {
        final diff = (mk.unitAmount ?? 0) - base;
        if (diff >= 0) diffs.add(_AmountCandidate(c: c, diff: diff));
      }
    }
  }

  if (diffs.isNotEmpty) {
    diffs.sort((a, b) => a.diff.compareTo(b.diff));
    final bestDiff = diffs.first.diff;
    pool = diffs.where((x) => x.diff == bestDiff).map((x) => x.c).toList();
  }

  // Regel 6: niedrigster Preis
  final List<_PriceCandidate> prices = [];

  for (final c in pool) {
    if (c.type == IngredientNominalCandidateType.product) {
      final priceRows =
          productMarketsForMarket.where((pm) => pm.productsId == c.id).toList();
      if (priceRows.isNotEmpty && priceRows.first.price != null) {
        prices.add(_PriceCandidate(c: c, price: priceRows.first.price!));
      }
    } else {
      final mk = ingredientMarkets.firstWhere((m) => m.id == c.id);
      if (mk.price != null) prices.add(_PriceCandidate(c: c, price: mk.price!));
    }
  }

  if (prices.isNotEmpty) {
  prices.sort((a, b) => a.price.compareTo(b.price));
  final selection = IngredientNominalSelection.fromCandidate(prices.first.c);

  final resolvedCountry = await resolveCountryForNominal(
    isProduct: selection.productId != null,
    nominalId: selection.productId ?? selection.ingredientMarketId!,
    db: db,
  );

  return selection.copyWith(countryId: resolvedCountry);
}


  // Regel 7: leer lassen
  return IngredientNominalSelection.none;
}

Future<void> recalculateNominalsForSLI(int sliId) async {
  final db = appDb;

  final sli = await (db.select(db.shoppingListIngredient)
        ..where((t) => t.id.equals(sliId)))
      .getSingle();

  if (sli.productIdNominal == null &&
      sli.ingredientMarketIdNominal == null) {
    return;
  }

  final ingredientId = sli.ingredientIdNominal;
  final amount = sli.ingredientAmountNominal;
  final unit = sli.ingredientUnitCodeNominal;

  // Wir brauchen die Liste, um an den Markt zu kommen
  final listRow = await (db.select(db.shoppingList)
        ..where((t) => t.id.equals(sli.shoppingListId)))
      .getSingleOrNull();
  final marketId = listRow?.marketId;

  // --------------------------------------------------------------
  // PRODUCT KONVERTIERUNG + PRICE
  // --------------------------------------------------------------
  if (sli.productIdNominal != null) {
    final product = await (db.select(db.products)
          ..where((t) => t.id.equals(sli.productIdNominal!)))
        .getSingle();

    final service = UnitConversionService(db);

    final newAmount = await service.calculateProductAmountNominal(
      ingredientIdNominal: ingredientId!,
      ingredientAmountNominal: amount!,
      ingredientUnitCodeNominal: unit!,
      product: product,
    );

    double? price;

    if (marketId != null) {
      final pmRow = await (db.select(db.productMarkets)
            ..where((t) => t.productsId.equals(sli.productIdNominal!))
            ..where((t) => t.marketId.equals(marketId)))
          .getSingleOrNull();
      price = pmRow?.price;
    }

    await (db.update(db.shoppingListIngredient)
          ..where((t) => t.id.equals(sli.id)))
        .write(
      ShoppingListIngredientCompanion(
        productAmountNominal: d.Value(newAmount),
        price: d.Value(price),
      ),
    );

    return;
  }

  // --------------------------------------------------------------
  // INGREDIENT-MARKET KONVERTIERUNG + PRICE
  // --------------------------------------------------------------
  if (sli.ingredientMarketIdNominal != null) {
    final im = await (db.select(db.ingredientMarket)
          ..where((t) => t.id.equals(sli.ingredientMarketIdNominal!)))
        .getSingle();

    final service = IngredientMarketConversionService(db);

    final newAmount =
        await service.calculateIngredientMarketAmountNominal(
      ingredientId: ingredientId!,
      ingredientAmountNominal: amount!,
      ingredientUnitCodeNominal: unit!,
      ingredientMarket: im,
    );

    // Preis kommt direkt aus IngredientMarket
    final double? price = im.price;

    await (db.update(db.shoppingListIngredient)
          ..where((t) => t.id.equals(sli.id)))
        .write(
      ShoppingListIngredientCompanion(
        ingredientMarketAmountNominal: d.Value(newAmount),
        price: d.Value(price),
      ),
    );
  }
}


Future<void> reapplyNominalsForSLI_AfterListMove(
  int sliId,
  int newMarketId,
) async {
  final db = appDb;
  final sli = await (db.select(db.shoppingListIngredient)
        ..where((t) => t.id.equals(sliId)))
      .getSingle();

  final ingredientId = sli.ingredientIdNominal;
  if (ingredientId == null) return;

  final ingredientAmount = sli.ingredientAmountNominal;
  final ingredientUnit = sli.ingredientUnitCodeNominal;

  // ------------------------------
  // FALL 1: Produkt-Verknüpfung vorhanden?
  // ------------------------------
  if (sli.productIdNominal != null) {
    final prodId = sli.productIdNominal!;

    // Prüfen, ob Produkt im neuen Markt verfügbar ist
    final pm = await (db.select(db.productMarkets)
          ..where((t) => t.productsId.equals(prodId))
          ..where((t) => t.marketId.equals(newMarketId)))
        .getSingleOrNull();

    if (pm != null) {
      // → Nur Preis aktualisieren, KEINE neue Vorauswahl
      await (db.update(db.shoppingListIngredient)
            ..where((t) => t.id.equals(sliId)))
          .write(
        ShoppingListIngredientCompanion(
          price: d.Value(pm.price),
        ),
      );

      // Konversion neu durchführen, da Markt gewechselt hat
      await recalculateNominalsForSLI(sliId);
      return;
    }

    // → Produkt existiert NICHT in diesem Markt → vollständige Logik
  }

  // ------------------------------
  // FALL 2: IngredientMarket-Verknüpfung vorhanden?
  // ------------------------------
  if (sli.ingredientMarketIdNominal != null) {
    final imId = sli.ingredientMarketIdNominal!;

    final imRow = await (db.select(db.ingredientMarket)
          ..where((t) => t.id.equals(imId))
          ..where((t) => t.marketId.equals(newMarketId)))
        .getSingleOrNull();

    if (imRow != null) {
      // → nur Preis setzen
      await (db.update(db.shoppingListIngredient)
            ..where((t) => t.id.equals(sliId)))
          .write(
        ShoppingListIngredientCompanion(
          price: d.Value(imRow.price),
        ),
      );

      await recalculateNominalsForSLI(sliId);
      return;
    }

    // → IngredientMarket existiert nicht in neuem Markt → vollständige Logik
  }

  // ------------------------------
  // FALL 3: Weder passendes Produkt noch passendes IngredientMarket → vollständige Vorauswahl
  // ------------------------------
  final selection = await resolveNominalForIngredient(
  ingredientId,
  sli.shoppingListId!,
  ingredientUnit,
  ingredientAmount,
);


  await (db.update(db.shoppingListIngredient)
      ..where((t) => t.id.equals(sliId)))
    .write(
  ShoppingListIngredientCompanion(
    productIdNominal: d.Value(selection.productId),
    ingredientMarketIdNominal: d.Value(selection.ingredientMarketId),
    productAmountNominal: d.Value(
      selection.productId != null ? ingredientAmount : null,
    ),
    ingredientMarketAmountNominal: d.Value(
      selection.ingredientMarketId != null ? ingredientAmount : null,
    ),
    countryId: selection.countryId != null
        ? d.Value(selection.countryId)
        : const d.Value.absent(),
  ),
);




  await recalculateNominalsForSLI(sliId);
}

// -----------------------------------------------------------------------------
// Wendet die Nominal-Auswahl-Logik für eine komplette Einkaufsliste neu an
// -> z.B. wenn der Markt geändert wurde
// -----------------------------------------------------------------------------
Future<void> reapplyNominalsForList(int shoppingListId) async {
  // Alle SLI der Liste laden
  final rows = await (appDb.select(appDb.shoppingListIngredient)
        ..where((t) => t.shoppingListId.equals(shoppingListId)))
      .get();

  for (final sli in rows) {
    // Wenn keine Zutat -> überspringen
    final ingredientId = sli.ingredientIdNominal;
    if (ingredientId == null) continue;

    // Sicherstellen, dass wir korrekte Ausgangswerte haben
    final String? unit = sli.ingredientUnitCodeNominal;
    final double? amount = sli.ingredientAmountNominal;

    if (unit == null || amount == null) continue;

    // NEUE Marktlogik anwenden
    final selection = await resolveNominalForIngredient(
      ingredientId,
      shoppingListId,
      unit,
      amount,
    );

    // 1) Product oder IngredientMarket setzen
    await (appDb.update(appDb.shoppingListIngredient)
      ..where((t) => t.id.equals(sli.id)))
    .write(
  ShoppingListIngredientCompanion(
    productIdNominal: d.Value(selection.productId),
    ingredientMarketIdNominal: d.Value(selection.ingredientMarketId),

    productAmountNominal: d.Value(
      selection.productId != null ? amount : null,
    ),
    ingredientMarketAmountNominal: d.Value(
      selection.ingredientMarketId != null ? amount : null,
    ),
    countryId: selection.countryId != null
        ? d.Value(selection.countryId)
        : const d.Value.absent(),
  ),
);


    // 2) Mengen-Konvertierung NEU berechnen
    await recalculateNominalsForSLI(sli.id);
  }
}

Future<void> applyNominalSelection({
  required AppDb db,
  required int sliId,
  required IngredientNominalSelection selection,
}) async {
  // SLI laden
  final sli = await (db.select(db.shoppingListIngredient)
        ..where((t) => t.id.equals(sliId)))
      .getSingle();

  final amount = sli.ingredientAmountNominal;
  final unit = sli.ingredientUnitCodeNominal;

  // Country automatisch bestimmen
  final countryId = await resolveCountryForNominal(
    isProduct: selection.productId != null,
    nominalId: selection.productId ?? selection.ingredientMarketId!,
    db: db,
  );

  // Neue Werte setzen
await (db.update(db.shoppingListIngredient)
      ..where((t) => t.id.equals(sliId)))
    .write(
  ShoppingListIngredientCompanion(
    productIdNominal: d.Value(selection.productId),
    ingredientMarketIdNominal: d.Value(selection.ingredientMarketId),

    productAmountNominal: d.Value(
      selection.productId != null ? amount : null,
    ),
    ingredientMarketAmountNominal: d.Value(
      selection.ingredientMarketId != null ? amount : null,
    ),

    // Preis wird später von recalculateNominalsForSLI berechnet.
    // price: const d.Value(null),
    countryId: countryId != null
        ? d.Value(countryId)
        : const d.Value.absent(),
  ),
);

  // Konvertierung neu berechnen (Preis + Mengen)
  await recalculateNominalsForSLI(sliId);
}