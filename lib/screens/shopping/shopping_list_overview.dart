// lib/screens/shopping/shopping_list_overview.dart
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/screens/shopping/shopping_list_history.dart';
import 'package:planty_flutter_starter/screens/recipe/recipe_detail.dart';
import 'package:planty_flutter_starter/screens/shopping/shopping_list_ingredient.dart';

import 'package:planty_flutter_starter/screens/ingredient/ingredients_list_screen.dart';

import 'package:planty_flutter_starter/utils/number_formatter.dart';
import 'package:planty_flutter_starter/services/unit_conversion_service.dart';
import 'package:planty_flutter_starter/services/ingredient_market_conversion_service.dart';
import 'package:planty_flutter_starter/services/ingredient_nominal_selection.dart';

import 'package:planty_flutter_starter/widgets/create_shopping_list_flow.dart';


double _effectiveIngredientMarketAmount(double summedAmount, String? unitCodeRaw) {
  final unitCode = unitCodeRaw?.trim().toLowerCase() ?? '';

  // Regel:
  // - "g"  -> NICHT runden
  // - "" / null -> NICHT runden
  // - alles andere -> CEIL()
  final shouldRound = unitCode.isNotEmpty && unitCode != 'g';

  if (shouldRound) {
    return summedAmount.ceilToDouble();
  } else {
    return summedAmount;
  }
}

Color? _parseHexColor(String? hex) {
  if (hex == null || hex.isEmpty) return null;
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  try {
    return Color(int.parse(h, radix: 16));
  } catch (_) {
    return null;
  }
}


class ShoppingListOverviewScreen extends StatefulWidget {
  final int? initialListId;              // ① Neuer Parameter

  const ShoppingListOverviewScreen({
    super.key,
    this.initialListId,                  // ② Annahme des Parameters
  });

  @override
  State<ShoppingListOverviewScreen> createState() =>
      _ShoppingListOverviewScreenState();
}


class _ShoppingListOverviewScreenState
    extends State<ShoppingListOverviewScreen> {
  int? _activeListId;
  int? _activeRecipeId;

  @override
  void initState() {
    super.initState();

    // ③ WICHTIG: initialListId in activeListId übernehmen!
    _activeListId = widget.initialListId;
  }

  // --------------------------------------------------
  // Multi-Select
  // --------------------------------------------------
  final Set<int> _selectedRecipeIds = {};
  bool _recipeSelectionMode = false;

  final PageController _pageController = PageController();
  bool _marketsExpanded = false;

  // --------------------------------------------------
  // Suchleiste + Ingredient-Suche
  // --------------------------------------------------
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchMode = false;

  bool _showAllSearchResults = false;
  bool _showAllSuggestions = false;
  List<Ingredient> _suggestions = [];
  List<Ingredient> _searchResults = [];

  // --------------------------------------------------
  // Produkt-Suchlogik
  // --------------------------------------------------
  List<Product> _productResults = [];
  List<Product> _productSuggestions = [];
  bool _showAllProductResults = false;
  bool _showAllProductSuggestions = false;
  String _currentMarketName = "";

  // =======================================================================
  // INGREDIENT-SUCHE
  // =======================================================================
  Future<void> _loadSuggestions() async {
    final sli = appDb.shoppingListIngredient;
    final ing = appDb.ingredients;

    final rows = await (appDb.select(ing)
          .join([
            d.leftOuterJoin(sli, sli.ingredientIdNominal.equalsExp(ing.id)),
          ])
          ..addColumns([sli.id.count()])
          ..groupBy([ing.id])
          ..orderBy([
            d.OrderingTerm.desc(sli.id.count()),
          ]))
        .get();

    final items = rows
        .map((r) => r.readTable(ing))
        .take(15)
        .toList();

    setState(() {
      _suggestions = items;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      await _loadSuggestions();
      setState(() {
        _searchResults = [];
        _showAllSearchResults = false;
      });
      return;
    }

    final q = appDb.ingredients;
    final items = await (appDb.select(q)
          ..where((t) => t.name.like('%${query.trim()}%')))
        .get();

    setState(() {
      _searchResults = items;
      _showAllSearchResults = false;
    });
  }

  // =======================================================================
  // PRODUKT-SUCHE
  // =======================================================================
  Future<void> _loadCurrentMarketName() async {
    if (_activeListId == null) return;

    final lists = await _loadLists();
    final list = lists.firstWhere((e) => e.list.id == _activeListId);
    _currentMarketName = list.market?.name ?? "";
  }

  Future<void> _loadProductSuggestions() async {
    final p = appDb.products;
    final sli = appDb.shoppingListIngredient;

    final rows = await (appDb.select(p)
          .join([
            d.leftOuterJoin(sli, sli.productIdNominal.equalsExp(p.id)),
          ])
          ..addColumns([sli.id.count()])
          ..groupBy([p.id])
          ..orderBy([
            d.OrderingTerm.desc(sli.id.count()),
          ]))
        .get();

    setState(() {
      _productSuggestions =
          rows.map((r) => r.readTable(p)).take(50).toList();
      _showAllProductSuggestions = false;
    });
  }

  Future<void> _performProductSearch(String query) async {
    final p = appDb.products;
    final sli = appDb.shoppingListIngredient;

    if (query.trim().isEmpty) {
      await _loadProductSuggestions();
      setState(() {
        _productResults = [];
        _showAllProductResults = false;
      });
      return;
    }

    final rows = await (appDb.select(p)
          .join([
            d.leftOuterJoin(sli, sli.productIdNominal.equalsExp(p.id)),
          ])
          ..where(p.name.like('%${query.trim()}%'))
          ..addColumns([sli.id.count()])
          ..groupBy([p.id])
          ..orderBy([
            d.OrderingTerm.desc(sli.id.count()),
          ]))
        .get();

    setState(() {
      _productResults = rows.map((r) => r.readTable(p)).toList();
      _showAllProductResults = false;
    });
  }

  // =======================================================================
  // BOTTOM-SHEET: Menge hinzufügen – INGREDIENT
  // =======================================================================
  void _openAddAmountSheetForIngredient(Ingredient ing) {
    setState(() => _isSearchMode = false);
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (_) {
        return _AddAmountBottomSheet(
          imagePath: ing.picture ?? "",
          name: ing.name,
          defaultUnitCode: "g", // feste Standard-Einheit
          initialAmount: 100, // feste Standard-Menge
          isProduct: false,
          onSave: (amount, unitCode) async {
            if (_activeListId == null) return;

            // automatische Vorauswahl ermitteln
            final selection = await resolveNominalForIngredient(
              ing.id,
              _activeListId!,
              unitCode,
              amount,
            );



            final inserted = await appDb
                .into(appDb.shoppingListIngredient)
                .insertReturning(
              ShoppingListIngredientCompanion.insert(
                shoppingListId: _activeListId!,
                recipeId: const d.Value(null),
                recipePortionNumberId: const d.Value(null),

                ingredientIdNominal: d.Value(ing.id),
                ingredientAmountNominal: d.Value(amount),
                ingredientUnitCodeNominal: d.Value(unitCode),

                // Product-Vorauswahl
                productIdNominal: d.Value(selection.productId),
                productAmountNominal: d.Value(
                  selection.productId != null ? amount : null,
                ),

                // IngredientMarket-Vorauswahl
                ingredientMarketIdNominal:
                    d.Value(selection.ingredientMarketId),
                ingredientMarketAmountNominal: d.Value(
                  selection.ingredientMarketId != null ? amount : null,
                ),
              ),
            );

            await recalculateNominalsForSLI(inserted.id);

            setState(() {});
          },
        );
      },
    );
  }

  // =======================================================================
  // BOTTOM-SHEET: Menge hinzufügen – PRODUCT
  // =======================================================================
  void _openAddAmountSheetForProduct(Product p) {
    setState(() => _isSearchMode = false);
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      builder: (_) {
        return _AddAmountBottomSheet(
          imagePath: p.image ?? "",
          name: p.name,
          defaultUnitCode: p.sizeUnitCode,
          initialAmount: p.sizeNumber ?? 1,
          isProduct: true,
          onSave: (amount, unitCode) async {
            if (_activeListId == null) return;

            final inserted = await appDb
                .into(appDb.shoppingListIngredient)
                .insertReturning(
              ShoppingListIngredientCompanion.insert(
                shoppingListId: _activeListId!,
                recipeId: const d.Value(null),
                recipePortionNumberId: const d.Value(null),
                ingredientIdNominal: d.Value(p.ingredientId),
                ingredientAmountNominal:
                    d.Value(p.yieldAmount ?? amount),
                ingredientUnitCodeNominal:
                    d.Value(p.yieldUnitCode ?? unitCode),
                productIdNominal: d.Value(p.id),
                productAmountNominal: d.Value(amount),
              ),
            );

            await recalculateNominalsForSLI(inserted.id);

            setState(() {});
          },
        );
      },
    );
  }

  // =======================================================================
  // OFFENE LISTEN LADEN & BEOBACHTEN
  // =======================================================================
  Future<List<_ShoppingListWithCount>> _loadLists() async {
    final sl = appDb.shoppingList;
    final sli = appDb.shoppingListIngredient;
    final markets = appDb.markets;

    final query = (appDb.select(sl)
          ..where((tbl) => tbl.done.equals(false))
          ..orderBy([
            (tbl) => d.OrderingTerm.desc(tbl.dateCreated),
          ]))
        .join([
      d.leftOuterJoin(sli, sli.shoppingListId.equalsExp(sl.id)),
      d.leftOuterJoin(markets, markets.id.equalsExp(sl.marketId)),
    ])
          ..addColumns([sli.id.count()])
          ..groupBy([sl.id]);

    final rows = await query.get();

    final lists = rows.map((r) {
      final list = r.readTable(sl);
      final count = r.read(sli.id.count()) ?? 0;
      final market = r.readTableOrNull(markets);
      return _ShoppingListWithCount(
        list: list,
        count: count,
        market: market,
      );
    }).toList();

    if (lists.isNotEmpty) {
      if (_activeListId == null ||
          !lists.any((e) => e.list.id == _activeListId)) {
        _activeListId = lists.first.list.id;
      }
    } else {
      _activeListId = null;
      _activeRecipeId = null;
    }

    return lists;
  }

  Stream<List<_ShoppingListWithCount>> _watchLists() {
    final sl = appDb.shoppingList;
    final sli = appDb.shoppingListIngredient;
    final markets = appDb.markets;

    final query = (appDb.select(sl)
          ..where((tbl) => tbl.done.equals(false)))
        .join([
      d.leftOuterJoin(sli, sli.shoppingListId.equalsExp(sl.id)),
      d.leftOuterJoin(markets, markets.id.equalsExp(sl.marketId)),
    ])
          ..addColumns([sli.id.count()])
          ..groupBy([sl.id]);

    return query.watch().map((rows) {
      return rows.map((r) {
        final list = r.readTable(sl);
        final count = r.read(sli.id.count()) ?? 0;
        final market = r.readTableOrNull(markets);
        return _ShoppingListWithCount(
          list: list,
          count: count,
          market: market,
        );
      }).toList();
    });
  }

  // =======================================================================
  // REZEPTE PRO LISTE LADEN
  // =======================================================================
  Future<List<_OverviewRecipeModel>> _loadRecipesForList(
      int shoppingListId) async {
    final sli = appDb.shoppingListIngredient;
    final r = appDb.recipes;
    final u = appDb.units;

    final joinQuery = (appDb.select(sli)
          ..where(
            (t) =>
                t.shoppingListId.equals(shoppingListId) &
                t.recipeId.isNotNull(),
          )
          ..orderBy([
            (t) => d.OrderingTerm(expression: t.recipeId),
          ]))
        .join([
      d.innerJoin(r, r.id.equalsExp(sli.recipeId)),
      d.leftOuterJoin(u, u.code.equalsExp(r.portionUnit)),
    ]);

    final rows = await joinQuery.get();

    final Map<int, _OverviewRecipeModel> byRecipeId = {};

    for (final row in rows) {
      final sliRow = row.readTable(sli);
      final rec = row.readTable(r);
      final unit = row.readTableOrNull(u);

      final recipeId = rec.id;
      if (byRecipeId.containsKey(recipeId)) continue;

      final basePortion = rec.portionNumber ?? 1;
      final storedPortion = sliRow.recipePortionNumberId ?? basePortion;

      byRecipeId[recipeId] = _OverviewRecipeModel(
        recipeId: recipeId,
        name: rec.name,
        picture: rec.picture,
        basePortion: basePortion,
        currentPortion: storedPortion,
        unitLabel: unit?.label ?? rec.portionUnit ?? '',
      );
    }

    final list = byRecipeId.values.toList()
      ..sort((a, b) => a.recipeId.compareTo(b.recipeId));

    if (list.isNotEmpty) {
      if (!_recipeSelectionMode) {
        _activeRecipeId = list.first.recipeId;
      }
    } else {
      _activeRecipeId = null;
    }

    return list;
  }

  // =======================================================================
  // PORTIONEN SKALIEREN
  // =======================================================================
  Future<void> _updateRecipePortion(
    int shoppingListId, int recipeId, int newPortion) async {
  final sli = appDb.shoppingListIngredient;

  final rows = await (appDb.select(sli)
        ..where((t) =>
            t.shoppingListId.equals(shoppingListId) &
            t.recipeId.equals(recipeId)))
      .get();

  if (rows.isEmpty) return;

  final oldPortion = rows.first.recipePortionNumberId ?? 1;
  if (oldPortion <= 0) return;

  final factor = newPortion / oldPortion;

  // 1) IngredientAmountNominal für alle SLI-Zeilen des Rezepts anpassen
  for (final row in rows) {
    final oldAmount = row.ingredientAmountNominal ?? 0;
    final rawAmount = oldAmount * factor;
    final roundedString = NumberFormatter.formatCustom(rawAmount);
    final roundedAmount = double.tryParse(roundedString) ?? rawAmount;

    await (appDb.update(sli)
          ..where((t) => t.id.equals(row.id)))
        .write(
      ShoppingListIngredientCompanion(
        recipePortionNumberId: d.Value(newPortion),
        ingredientAmountNominal: d.Value(roundedAmount),
      ),
    );
  }

  // 2) Danach: für alle diese Zeilen productAmount / ingredientMarketAmount neu berechnen
  await _recalculateForRecipe(shoppingListId, recipeId);
}


  Future<void> _recalculateForRecipe(int shoppingListId, int recipeId) async {
  final sli = appDb.shoppingListIngredient;

  final rows = await (appDb.select(sli)
        ..where((t) =>
            t.shoppingListId.equals(shoppingListId) &
            t.recipeId.equals(recipeId)))
      .get();

  for (final row in rows) {
    await recalculateNominalsForSLI(row.id);
  }
}


  // =======================================================================
  // ZUTATEN-STREAM – GRUPPIERT NACH REGAL + KORB
  // =======================================================================
  Stream<_IngredientsForList> _watchIngredientsForList(
      int shoppingListId) {
    final sli = appDb.shoppingListIngredient;
    final ing = appDb.ingredients;
    final shelf = appDb.shopshelf;
    final units = appDb.units;

    var baseQuery = (appDb.select(sli)
      ..where((t) => t.shoppingListId.equals(shoppingListId)));

    if (_recipeSelectionMode && _selectedRecipeIds.isNotEmpty) {
      baseQuery.where(
        (t) => t.recipeId.isIn(_selectedRecipeIds.toList()),
      );
    }

    final joinedQuery = baseQuery.join([
      d.leftOuterJoin(ing, ing.id.equalsExp(sli.ingredientIdNominal)),
      d.leftOuterJoin(shelf, shelf.id.equalsExp(ing.shelfId)),
      d.leftOuterJoin(units, units.code.equalsExp(
        sli.ingredientUnitCodeNominal,
      )),
    ]);

    return joinedQuery.watch().map((rows) {
      final Map<int?, List<_IngredientWithMeta>> grouped = {};

      for (final row in rows) {
        final s = row.readTable(sli);
        final i = row.readTableOrNull(ing);
        final sh = row.readTableOrNull(shelf);
        final unit = row.readTableOrNull(units);

        final sectionId = sh?.id;
        grouped.putIfAbsent(sectionId, () => []);

        grouped[sectionId]!.add(
          _IngredientWithMeta(
            id: s.id,
            ingredientId: s.ingredientIdNominal,
            name: i?.name ?? "Unbekannt",
            picture: i?.picture,
            amount: s.ingredientAmountNominal,
            unitLabel: unit?.label,
            bought: s.bought,
            basket: s.basket,
            shoppingListId: s.shoppingListId!,   // ← HIER KORRIGIEREN
            shelfId: sh?.id,
            shelfName: sh?.name ?? "Sonstiges",
            shelfIcon: sh?.icon,
            productIdNominal: s.productIdNominal,                  // ← HIER EINTRAGEN
            ingredientMarketIdNominal: s.ingredientMarketIdNominal // ← HIER EINTRAGEN
          ),
        );
      }

      final List<_IngredientSection> sections = [];
      final List<_IngredientWithMeta> basketItems = [];

      for (final entry in grouped.entries) {
        final rawItems = entry.value;
        final Map<int?, _IngredientWithMeta> merged = {};

        for (final ingItem in rawItems) {
          final key = ingItem.ingredientId;

          if (!merged.containsKey(key)) {
            merged[key] = ingItem;
          } else {
            final existing = merged[key]!;
            merged[key] = _IngredientWithMeta(
              id: existing.id,
              ingredientId: existing.ingredientId,
              name: existing.name,
              picture: existing.picture,
              amount: (existing.amount ?? 0) + (ingItem.amount ?? 0),
              unitLabel: existing.unitLabel,
              bought: existing.bought || ingItem.bought,
              basket: existing.basket || ingItem.basket,
              shoppingListId: existing.shoppingListId,
              shelfId: existing.shelfId,
              shelfName: existing.shelfName,
              shelfIcon: existing.shelfIcon,
            );
          }
        }

        final mergedList = merged.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));

        final nonBasket =
            mergedList.where((i) => !i.basket).toList();
        final onlyBasket =
            mergedList.where((i) => i.basket).toList();

        if (nonBasket.isNotEmpty) {
          sections.add(
            _IngredientSection(
              shelfId: nonBasket.first.shelfId,
              shelfName: nonBasket.first.shelfName,
              shelfIcon: nonBasket.first.shelfIcon,
              items: nonBasket,
            ),
          );
        }

        if (onlyBasket.isNotEmpty) {
          basketItems.addAll(onlyBasket);
        }
      }

      sections.sort((a, b) {
        if (a.shelfId == null && b.shelfId != null) return 1;
        if (a.shelfId != null && b.shelfId == null) return -1;
        if (a.shelfId == null && b.shelfId == null) return 0;
        return a.shelfId!.compareTo(b.shelfId!);
      });

      final version =
          DateTime.now().microsecondsSinceEpoch;

      return _IngredientsForList(
        sections: sections,
        basketItems: basketItems,
        version: DateTime.now().microsecondsSinceEpoch,
      );
    });
  }

  // =======================================================================
  // REZEPT-TAPS / MULTI-SELECT
  // =======================================================================
  void _onRecipeTap(_OverviewRecipeModel recipe) {
    if (_recipeSelectionMode) {
      setState(() {
        if (_selectedRecipeIds.contains(recipe.recipeId)) {
          _selectedRecipeIds.remove(recipe.recipeId);
          if (_selectedRecipeIds.isEmpty) {
            _recipeSelectionMode = false;
          }
        } else {
          _selectedRecipeIds.add(recipe.recipeId);
        }
      });
      return;
    }

    Navigator.of(context).push(
  PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    opaque: false,
    barrierColor: Colors.transparent,
    pageBuilder: (_, __, ___) => RecipeDetailScreen(
      recipeId: recipe.recipeId,
      title: recipe.name,
      imagePath: recipe.picture,
    ),
    transitionsBuilder: (_, animation, __, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ),
      );

      final fade = Tween<double>(
        begin: 0.7,
        end: 1.0,
      ).animate(animation);

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: child,
        ),
      );
    },
  ),
);

  }

  void _onRecipeLongPress(_OverviewRecipeModel recipe) {
    setState(() {
      _recipeSelectionMode = true;
      _selectedRecipeIds.add(recipe.recipeId);
    });
  }

  Future<void> _deleteAllIngredientsOfRecipe(
      int shoppingListId, int recipeId) async {
    final sli = appDb.shoppingListIngredient;

    await (appDb.delete(sli)
          ..where((t) =>
              t.shoppingListId.equals(shoppingListId) &
              t.recipeId.equals(recipeId)))
        .go();
  }

  // =======================================================================
  // MÄRKTE & LISTEN-OPERATIONEN
  // =======================================================================
  Future<List<_MarketWithCount>> _loadMarkets(
      int? selectedMarketId) async {
    final sl = appDb.shoppingList;
    final m = appDb.markets;

    final freqRows = await (appDb.select(sl)
          ..where((tbl) => tbl.marketId.isNotNull()))
        .get();

    final Map<int, int> freqMap = {};
    for (final row in freqRows) {
      final id = row.marketId!;
      freqMap[id] = (freqMap[id] ?? 0) + 1;
    }

    final allMarkets = await appDb.select(m).get();

    allMarkets.sort((a, b) {
      if (a.id == selectedMarketId) return -1;
      if (b.id == selectedMarketId) return 1;
      final fa = freqMap[a.id] ?? 0;
      final fb = freqMap[b.id] ?? 0;
      return fb.compareTo(fa);
    });

    return allMarkets
        .map(
          (mk) => _MarketWithCount(
            market: mk,
            count: freqMap[mk.id] ?? 0,
          ),
        )
        .toList();
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    try {
      return Color(int.parse(h, radix: 16));
    } catch (_) {
      return null;
    }
  }

  Future<void> _markAsDone(ShoppingListData list) async {
    await appDb.update(appDb.shoppingList).replace(
          list.copyWith(done: true),
        );
    setState(() {
      _marketsExpanded = false;
    });
  }

  Future<void> _deleteList(ShoppingListData list) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF171717),
        title: const Text(
          "Wirklich löschen?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Diese Einkaufsliste wird dauerhaft gelöscht.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Abbrechen",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Löschen",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await appDb.delete(appDb.shoppingList).delete(list);
      setState(() {
        _marketsExpanded = false;
      });
    }
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

    if (sli.productIdNominal != null) {
      final product = await (db.select(db.products)
            ..where((t) => t.id.equals(sli.productIdNominal!)))
          .getSingle();

      final service = UnitConversionService(db);

      final newAmount = await service.calculateProductAmountNominal(
  ingredientIdNominal: ingredientId!,                     // ok
  ingredientAmountNominal: sli.ingredientAmountNominal!,  // WICHTIG!
  ingredientUnitCodeNominal: sli.ingredientUnitCodeNominal!, // WICHTIG!
  product: product,
);
      await (db.update(db.shoppingListIngredient)
      ..where((t) => t.id.equals(sli.id)))
    .write(
  ShoppingListIngredientCompanion(
    productAmountNominal: d.Value(newAmount),
  ),
);


      return;
    }

    if (sli.ingredientMarketIdNominal != null) {
      final im = await (db.select(db.ingredientMarket)
            ..where((t) => t.id.equals(sli.ingredientMarketIdNominal!)))
          .getSingle();

      final service = IngredientMarketConversionService(db);

      final newAmount = await service
          .calculateIngredientMarketAmountNominal(
        ingredientId: ingredientId!,                  // FIX 1
  ingredientAmountNominal: amount!,             // FIX 2
  ingredientUnitCodeNominal: unit!,
        ingredientMarket: im,
      );

      await (db.update(db.shoppingListIngredient)
      ..where((t) => t.id.equals(sli.id)))
    .write(
  ShoppingListIngredientCompanion(
    ingredientMarketAmountNominal: d.Value(newAmount),
  ),
);

    }
  }

  
  // gruppiertes Toggeln des Korb-Status für alle SLI-Zeilen eines Ingredients

  Future<void> toggleBasketForIngredientGroup({
  required int shoppingListId,
  required int ingredientId,
  required bool newValue,
}) async {
  final sli = appDb.shoppingListIngredient;

  // 1) alle SLI-Zeilen laden, die zu diesem Ingredient gehören
  final rows = await (appDb.select(sli)
        ..where((t) =>
            t.shoppingListId.equals(shoppingListId) &
            t.ingredientIdNominal.equals(ingredientId)))
      .get();

  if (rows.isEmpty) return;

  // 2) alle toggeln
  for (final row in rows) {
    await (appDb.update(sli)
          ..where((t) => t.id.equals(row.id)))
        .write(
      ShoppingListIngredientCompanion(
        basket: d.Value(newValue),
      ),
    );
  }

  // 3) Recalculate für alle Zeilen
  for (final row in rows) {
    await recalculateNominalsForSLI(row.id);
  }
}

  // Berechnung Summe der im Korb befindlichen Artikel

  Future<double> calculateBasketTotalPrice(int shoppingListId) async {
  final sli = appDb.shoppingListIngredient;
  final sl = appDb.shoppingList;
  final pm = appDb.productMarkets;
  final im = appDb.ingredientMarket;

  final listRow = await (appDb.select(sl)
        ..where((t) => t.id.equals(shoppingListId)))
      .getSingleOrNull();

  if (listRow == null || listRow.marketId == null) return 0.0;
  final marketId = listRow.marketId!;

  // Nur SLIs im Korb
  final items = await (appDb.select(sli)
        ..where((t) =>
            t.shoppingListId.equals(shoppingListId) &
            t.basket.equals(true)))
      .get();

  double total = 0.0;

  final Map<int, double> productSums = {};
  final Map<int, double> ingredientMarketSums = {};

  for (final row in items) {
    if (row.productIdNominal != null &&
        row.productAmountNominal != null) {
      productSums[row.productIdNominal!] =
          (productSums[row.productIdNominal!] ?? 0) +
              row.productAmountNominal!;
    }

    if (row.ingredientMarketIdNominal != null &&
        row.ingredientMarketAmountNominal != null) {
      ingredientMarketSums[row.ingredientMarketIdNominal!] =
          (ingredientMarketSums[row.ingredientMarketIdNominal!] ?? 0) +
              row.ingredientMarketAmountNominal!;
    }
  }

  // Produkte: CEIL auf summedAmount
  for (final entry in productSums.entries) {
    final productId = entry.key;
    final sumRounded = entry.value.ceil();

    final priceRow = await (appDb.select(pm)
          ..where(
            (t) =>
                t.productsId.equals(productId) &
                t.marketId.equals(marketId),
          ))
        .getSingleOrNull();

    if (priceRow?.price != null) {
      total += sumRounded * priceRow!.price!;
    }
  }

  // IngredientMarket: gleiche Helper-Logik wie oben
  for (final entry in ingredientMarketSums.entries) {
    final ingredientMarketId = entry.key;
    final summedAmount = entry.value;

    final imRow = await (appDb.select(im)
          ..where((t) => t.id.equals(ingredientMarketId)))
        .getSingleOrNull();

    if (imRow == null || imRow.price == null) continue;

    final effectiveAmount =
        _effectiveIngredientMarketAmount(summedAmount, imRow.unitCode);

    total += effectiveAmount * imRow.price!;
  }

  return total;
}



Future<void> completeShoppingList(int shoppingListId) async {
  final db = appDb;

  final sli = db.shoppingListIngredient;
  final sl = db.shoppingList;
  final stock = db.stock;
  final im = db.ingredientMarket;
  final p = db.products;
  final ingStor = db.ingredientStorage;
  final stor = db.storage;

  // ---------------------------------------------------------
  // 0. Alle SLI der Liste laden
  // ---------------------------------------------------------
  final rows = await (db.select(sli)
        ..where((t) => t.shoppingListId.equals(shoppingListId)))
      .get();

  final rowsBought = rows.where((r) => r.basket == true).toList();
  final now = DateTime.now();

  // ---------------------------------------------------------
  // A) Gruppierung
  // ---------------------------------------------------------
  final Map<int, List<ShoppingListIngredientData>> productGroups = {};
  for (final r in rowsBought) {
    final pid = r.productIdNominal;
    if (pid != null && pid != 0) {
      productGroups.putIfAbsent(pid, () => []).add(r);
    }
  }

  final Map<int, List<ShoppingListIngredientData>> imGroups = {};
  for (final r in rowsBought) {
    final imId = r.ingredientMarketIdNominal;
    if (imId != null && imId != 0) {
      imGroups.putIfAbsent(imId, () => []).add(r);
    }
  }

  final plainIngredients = rowsBought.where((r) =>
      (r.productIdNominal == null || r.productIdNominal == 0) &&
      (r.ingredientMarketIdNominal == null ||
          r.ingredientMarketIdNominal == 0));

  // ---------------------------------------------------------
  // B) PRODUKT-ACTUAL
  // ---------------------------------------------------------
  for (final entry in productGroups.entries) {
    final productId = entry.key;
    final list = entry.value;

    final productRow = await (db.select(p)
          ..where((t) => t.id.equals(productId)))
        .getSingle();

    final sumNominal = list.fold<double>(
        0.0, (sum, r) => sum + (r.productAmountNominal ?? 0));

    final rounded = sumNominal.ceilToDouble();
    final perItem = rounded / list.length;

    for (final r in list) {
      await (db.update(sli)..where((t) => t.id.equals(r.id))).write(
        ShoppingListIngredientCompanion(
          bought: d.Value(true),

          productIdActual: d.Value(productId),
          productAmountActual: d.Value(perItem),

          ingredientIdActual: d.Value(productRow.ingredientId),
          ingredientUnitCodeActual: d.Value(productRow.yieldUnitCode),
          ingredientAmountActual:
              d.Value(perItem * (productRow.yieldAmount ?? 1.0)),

          ingredientMarketIdActual: d.Value(null),
          ingredientMarketAmountActual: d.Value(null),
        ),
      );
    }
  }

  // ---------------------------------------------------------
// C) INGREDIENT-MARKET-ACTUAL
// ---------------------------------------------------------
for (final entry in imGroups.entries) {
  final imId = entry.key;
  final list = entry.value;

  final imRow = await (db.select(im)..where((t) => t.id.equals(imId)))
      .getSingle();

  final sumNominal = list.fold<double>(
      0.0, (sum, r) => sum + (r.ingredientMarketAmountNominal ?? 0));

  // NEU: Package-Einheit existiert nur, wenn NICHT null UND NICHT leer
  final hasPackage = (imRow.packageUnitCode != null &&
                      imRow.packageUnitCode!.trim().isNotEmpty);

  // NEU: Nur bei Verpackungseinheiten aufrunden
  final effectiveSum = hasPackage
      ? sumNominal.ceilToDouble()
      : sumNominal;

  final perItem = list.isNotEmpty ? (effectiveSum / list.length) : 0.0;

  for (final r in list) {
    double ingredientAmountActual;

    if (!hasPackage) {
      // KEINE Verpackung → keine Berechnung → 1:1 die Ingredient-Menge
      ingredientAmountActual = r.ingredientAmountNominal ?? 0.0;
    } else {
      // Verpackung → hochrechnen auf unitAmount
      ingredientAmountActual =
          perItem * (imRow.unitAmount ?? 1.0);
    }

    await (db.update(sli)..where((t) => t.id.equals(r.id))).write(
      ShoppingListIngredientCompanion(
        bought: d.Value(true),

        ingredientMarketIdActual: d.Value(imId),
        ingredientMarketAmountActual: d.Value(perItem),
        ingredientUnitCodeActual: d.Value(imRow.unitCode),
        ingredientAmountActual: d.Value(ingredientAmountActual),

        ingredientIdActual: d.Value(r.ingredientIdNominal),

        productIdActual: d.Value(null),
        productAmountActual: d.Value(null),
      ),
    );
  }
}


  // ---------------------------------------------------------
  // D) PLAIN INGREDIENTS: 1:1 actual
  // ---------------------------------------------------------
  for (final r in plainIngredients) {
    await (db.update(sli)..where((t) => t.id.equals(r.id))).write(
      ShoppingListIngredientCompanion(
        bought: d.Value(true),

        ingredientIdActual: d.Value(r.ingredientIdNominal),
        ingredientAmountActual: d.Value(r.ingredientAmountNominal),
        ingredientUnitCodeActual: d.Value(r.ingredientUnitCodeNominal),

        productIdActual: d.Value(null),
        productAmountActual: d.Value(null),
        ingredientMarketIdActual: d.Value(null),
        ingredientMarketAmountActual: d.Value(null),
      ),
    );
  }

  // ---------------------------------------------------------
  // E) Liste selbst als "done" kennzeichnen
  // ---------------------------------------------------------
  await (db.update(sl)..where((t) => t.id.equals(shoppingListId))).write(
    ShoppingListCompanion(
      done: const d.Value(true),
      lastEdited: d.Value(now),
    ),
  );

  // ---------------------------------------------------------
  // F0) Aktualisierte SLI erneut laden
  // ---------------------------------------------------------
  final rowsBoughtUpdated = await (db.select(sli)
        ..where((t) => t.shoppingListId.equals(shoppingListId))
        ..where((t) => t.basket.equals(true)))
      .get();

  // ---------------------------------------------------------
  // F1) price_actual berechnen (JETZT sind alle Actual-Werte korrekt!)
  // ---------------------------------------------------------
  for (final r in rowsBoughtUpdated) {
    double? priceActual;

    if (r.productIdActual != null &&
        r.productAmountActual != null &&
        r.price != null) {
      priceActual = r.productAmountActual! * r.price!;
    } else if (r.ingredientMarketIdActual != null &&
        r.ingredientMarketAmountActual != null &&
        r.price != null) {
      priceActual = r.ingredientMarketAmountActual! * r.price!;
    }

    await (db.update(sli)..where((t) => t.id.equals(r.id))).write(
      ShoppingListIngredientCompanion(
        priceActual: d.Value(priceActual),
      ),
    );
  }

  // ---------------------------------------------------------
  // F2) STOCK-LOGIK (unverändert)
  // ---------------------------------------------------------
  for (final r in rowsBoughtUpdated) {
    final ingredientId = r.ingredientIdActual;
    if (ingredientId == null) continue;

    final unitCode = r.ingredientUnitCodeActual;
    final amount = r.ingredientAmountActual ?? 0.0;

    int storageId = 6; // fallback

    final allStor = await db.select(stor).get();
    final availableStorIds =
        allStor.where((s) => s.availability == true).map((e) => e.id).toSet();

    final existingStocks = await (db.select(stock)
          ..where((t) => t.ingredientId.equals(ingredientId)))
        .get();

    if (existingStocks.isNotEmpty) {
      final counts = <int, int>{};
      for (final s in existingStocks) {
        if (availableStorIds.contains(s.storageId)) {
          counts[s.storageId] = (counts[s.storageId] ?? 0) + 1;
        }
      }
      if (counts.isNotEmpty) {
        storageId = counts.entries.reduce((a, b) =>
            a.value >= b.value ? a : b).key;
      }
    }

    if (existingStocks.isEmpty || !availableStorIds.contains(storageId)) {
      final storRows = await (db.select(ingStor)
            ..where((t) => t.ingredientId.equals(ingredientId)))
          .get();

      if (storRows.isNotEmpty) {
        final filtered =
            storRows.where((s) => availableStorIds.contains(s.storageId)).toList();

        if (filtered.isNotEmpty) {
          filtered.sort((a, b) => b.amount.compareTo(a.amount));
          storageId = filtered.first.storageId;
        }
      }
    }

    await db.into(stock).insert(
      StockCompanion.insert(
        ingredientId: ingredientId,
        storageId: storageId,
        shoppingListId: d.Value(shoppingListId),
        dateEntry: d.Value(now),
        amount: d.Value(amount),
        unitCode: d.Value(unitCode),
      ),
    );
  }
}



Future<void> _onCompleteShoppingPressed() async {
  if (_activeListId == null) return;

  final ok = await _confirmCompleteShopping();
  if (!ok) return;

  await completeShoppingList(_activeListId!);
  setState(() {});
}

//Sicherheitsabfrage zum Abschließen der Einkaufsliste
Future<bool> _confirmCompleteShopping() async {
  return await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: const Color(0xFF171717),
        title: const Text(
          "Einkauf abschließen?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Diese Einkaufsliste wird in die Historie verschoben.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "Abbrechen",
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "Bestätigen",
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        ],
      );
    },
  ) ?? false;
}

// Einkaufslisten bearbeiten: Datum + Markt ändern
Future<void> _editShoppingList(ShoppingListData list) async {
  DateTime selectedDate = list.dateShopping ?? DateTime.now();

  // ---------- 1) Datum wählen ----------
  final pickedDate = await showDialog<DateTime>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            backgroundColor: Colors.black87,
            title: const Text(
              "Datum wählen",
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: Colors.green,
                    onPrimary: Colors.white,
                    onSurface: Colors.white,
                    surface: Colors.black,
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: selectedDate,
                  firstDate: DateTime.now().subtract(
                    const Duration(days: 365),
                  ),
                  lastDate: DateTime.now().add(
                    const Duration(days: 365),
                  ),
                  onDateChanged: (d) {
                    setStateDialog(() => selectedDate = d);
                  },
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  "Abbrechen",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, selectedDate),
                child: const Text(
                  "Weiter",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  if (pickedDate == null) return;
  final DateTime date = pickedDate;

  // ---------- 2) Markt auswählen ----------
  final markets = await (appDb.select(appDb.markets)
        ..orderBy([
          (m) => d.OrderingTerm(expression: m.id),
        ]))
      .get();

  if (markets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Keine Märkte vorhanden.")),
    );
    return;
  }

  final previousMarket = markets.firstWhere(
    (m) => m.id == list.marketId,
    orElse: () => markets.first,
  );

  final chosenMarket = await showDialog<Market>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          "Markt wählen",
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: markets.length,
            itemBuilder: (context, index) {
              final m = markets[index];
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, m),
                child: Container(
  margin: const EdgeInsets.symmetric(vertical: 6),
  padding: const EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 8,
  ),
  decoration: BoxDecoration(
    color: Colors.black,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(
      color: (m.id == previousMarket.id)
          ? Colors.greenAccent
          : Colors.transparent,
      width: 2,
    ),
  ),
  child: Row(
    children: [
      Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          color: _parseHexColor(m.color),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            m.picture ?? "assets/images/shop/placeholder.png",
            fit: BoxFit.cover,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          m.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      if (m.id == previousMarket.id)
        const Icon(
          Icons.check,
          color: Colors.greenAccent,
        ),
    ],
  ),
),

              );
            },
          ),
        ),
      );
    },
  );

  final Market market = chosenMarket ?? previousMarket;

  // ---------- 3) Neuen Namen erzeugen ----------
  const weekdayNames = [
    "",
    "Montag",
    "Dienstag",
    "Mittwoch",
    "Donnerstag",
    "Freitag",
    "Samstag",
    "Sonntag",
  ];

  final name =
      "${weekdayNames[date.weekday]}, ${date.day.toString().padLeft(2, '0')}."
      "${date.month.toString().padLeft(2, '0')}.";

  // ---------- 4) Update statt Insert ----------
  await (appDb.update(appDb.shoppingList)
      ..where((t) => t.id.equals(list.id)))
    .write(
  ShoppingListCompanion(
    name: d.Value(name),
    dateShopping: d.Value(date),
    marketId: d.Value(market.id),
    lastEdited: d.Value(DateTime.now()),
  ),
);

// NEU → alle SLIs im neuen Markt neu berechnen
await reapplyNominalsForList(list.id);

setState(() {});

}

Future<void> _moveListContentTo(int sourceListId, int targetListId) async {
  final db = appDb;
  final sli = db.shoppingListIngredient;

  // Ziel-Liste laden, um den neuen Markt zu kennen
  final targetList = await (db.select(db.shoppingList)
        ..where((t) => t.id.equals(targetListId)))
      .getSingle();

  final newMarketId = targetList.marketId;

  // 1. Alle Zeilen der alten Liste holen
  final rows = await (db.select(sli)
        ..where((t) => t.shoppingListId.equals(sourceListId)))
      .get();

  // 2. Jede Zeile verschieben + Nominals neu bewerten
  for (final row in rows) {
    // Schritt A: zur neuen Liste verschieben
    await (db.update(sli)..where((t) => t.id.equals(row.id))).write(
      ShoppingListIngredientCompanion(
        shoppingListId: d.Value(targetListId),
      ),
    );

    // Schritt B: Nominals nur dann neu berechnen,
    //            wenn die Ziel-Liste einen Markt hat
    if (newMarketId != null) {
      await reapplyNominalsForSLI_AfterListMove(row.id, newMarketId);
    }
  }

  // 3. Quellliste aktualisieren (Zeitstempel)
  await (db.update(db.shoppingList)
        ..where((t) => t.id.equals(sourceListId)))
      .write(
    ShoppingListCompanion(
      lastEdited: d.Value(DateTime.now()),
    ),
  );

  setState(() {});
}



Future<int?> _selectTargetShoppingList(int currentListId) async {
  final lists = await (appDb.select(appDb.shoppingList)
        ..where((t) => t.done.equals(false)))
      .get();

  // Nur aktive Listen anzeigen, außer die aktuelle
  final activeLists = lists.where((l) => l.id != currentListId).toList();

  return showDialog<int>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          "In welche Einkaufsliste?",
          style: TextStyle(color: Colors.white),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final sl in activeLists)
                GestureDetector(
                  onTap: () => Navigator.pop(ctx, sl.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            sl.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (sl.marketId != null)
                          _buildMarketIconSmall(sl.marketId!),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 10),

              // → Neue Liste erstellen
              GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx); // Dialog schließen

                  final newListId = await CreateShoppingListFlow.start(context);
                  if (newListId != null) {
                    // Neue Liste direkt als Ziel verwenden
                    await _moveListContentTo(currentListId, newListId);
                  }
                },
                child: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const Text(
                    "+ Neue Einkaufsliste erstellen",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  void _onMenuSelected(String value, ShoppingListData list) {
  switch (value) {
    case "edit":
  _editShoppingList(list);
  break;


    case "move":
  _selectTargetShoppingList(list.id).then((targetId) async {
    if (targetId == null) return;
    await _moveListContentTo(list.id, targetId);
  });
  break;


    case "done":
  _confirmCompleteShopping().then((ok) async {
    if (!ok) return;
    await completeShoppingList(list.id);
    setState(() {});
  });
  break;


    case "delete":
      _deleteList(list);
      break;
  }
}

Future<Map<String, dynamic>> _loadProductDisplayData(int productId) async {
  final p = await (appDb.select(appDb.products)
        ..where((t) => t.id.equals(productId)))
      .getSingleOrNull();

  if (p == null) return {};

  final producer = await (appDb.select(appDb.producers)
        ..where((t) => t.id.equals(p.producerId)))
      .getSingleOrNull();

  return {
    'producerName': producer?.name ?? '',
    'sizeUnit': p.sizeUnitCode ?? '',
    'yieldAmount': p.yieldAmount ?? '',
    'yieldUnit': p.yieldUnitCode ?? '',
    'image': p.image ?? '',
  };
}

Future<Map<String, dynamic>> _loadIngredientMarketDisplayData(int id) async {
  final im = await (appDb.select(appDb.ingredientMarket)
        ..where((t) => t.id.equals(id)))
      .getSingleOrNull();

  if (im == null) return {};

  return {
    'price': im.price ?? 0,
    'unitAmount': im.unitAmount ?? 0,
    'unitCode': im.unitCode ?? '',
  };
}

Future<List<String>> _loadProductCountryImages(int productId) async {
  final rows = await appDb.customSelect(
    '''
      SELECT c.image AS img, c.id AS id, c.short AS short
      FROM product_country pc
      JOIN countries c ON c.id = pc.countries_id
      WHERE pc.products_id = ?
    ''',
    variables: [d.Variable(productId)],
  ).get();

  return rows
      .map((r) => r.data['img'] as String? ?? '')
      .where((s) => s.isNotEmpty)
      .toList();
}

Future<List<String>> _loadIngredientMarketCountryImages(int id) async {
  final rows = await appDb.customSelect(
    '''
      SELECT c.image AS img, c.id AS id, c.short AS short
      FROM ingredient_market_country ic
      JOIN countries c ON c.id = ic.countries_id
      WHERE ic.ingredient_market_id = ?
    ''',
    variables: [d.Variable(id)],
  ).get();

  return rows
      .map((r) => r.data['img'] as String? ?? '')
      .where((s) => s.isNotEmpty)
      .toList();
}





  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          "Einkaufslisten",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              DateTime selectedDate = DateTime.now();

              final pickedDate = await showDialog<DateTime>(
                context: context,
                builder: (ctx) {
                  return StatefulBuilder(
                    builder: (ctx, setStateDialog) {
                      return AlertDialog(
                        backgroundColor: Colors.black87,
                        title: const Text(
                          "Datum wählen",
                          style: TextStyle(color: Colors.white),
                        ),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Colors.green,
                                onPrimary: Colors.white,
                                onSurface: Colors.white,
                                surface: Colors.black,
                              ),
                            ),
                            child: CalendarDatePicker(
                              initialDate: selectedDate,
                              firstDate: DateTime.now().subtract(
                                const Duration(days: 365),
                              ),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              onDateChanged: (d) {
                                setStateDialog(() => selectedDate = d);
                              },
                            ),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text(
                              "Abbrechen",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(ctx, selectedDate),
                            child: const Text(
                              "Weiter",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              );

              if (pickedDate == null) return;
              final DateTime date = pickedDate;

              final markets = await (appDb.select(appDb.markets)
                    ..orderBy([
                      (m) => d.OrderingTerm(expression: m.id),
                    ]))
                  .get();

              if (markets.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Keine Märkte vorhanden."),
                  ),
                );
                return;
              }

              Market? defaultMarket;
              final fav =
                  markets.where((m) => m.favorite == true).toList()
                    ..sort((a, b) => a.id.compareTo(b.id));

              defaultMarket = fav.isNotEmpty ? fav.first : markets.first;

              final chosenMarket = await showDialog<Market>(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    backgroundColor: Colors.black87,
                    title: const Text(
                      "Markt wählen",
                      style: TextStyle(color: Colors.white),
                    ),
                    content: SizedBox(
                      width: double.maxFinite,
                      height: 300,
                      child: ListView.builder(
                        itemCount: markets.length,
                        itemBuilder: (context, index) {
                          final m = markets[index];
                          return GestureDetector(
                            onTap: () => Navigator.pop(ctx, m),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                vertical: 6,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 45,
                                    height: 45,
                                    decoration: BoxDecoration(
                                      color: _parseHexColor(m.color),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.asset(
                                        m.picture ??
                                            "assets/images/shop/placeholder.png",
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      m.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );

              final Market market = chosenMarket ?? defaultMarket;

              const weekdayNames = [
                "",
                "Montag",
                "Dienstag",
                "Mittwoch",
                "Donnerstag",
                "Freitag",
                "Samstag",
                "Sonntag",
              ];

              final name =
                  "${weekdayNames[date.weekday]}, ${date.day.toString().padLeft(2, '0')}."
                  "${date.month.toString().padLeft(2, '0')}.";

              await appDb.into(appDb.shoppingList).insert(
                    ShoppingListCompanion.insert(
                      name: name,
                      dateCreated: d.Value(DateTime.now()),
                      lastEdited: d.Value(DateTime.now()),
                      marketId: d.Value(market.id),
                      dateShopping: d.Value(date),
                    ),
                  );

              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 260),
                  reverseTransitionDuration: const Duration(milliseconds: 220),
                  opaque: false,
                  barrierColor: Colors.transparent,
                  pageBuilder: (_, __, ___) => const ShoppingListHistoryScreen(),
                  transitionsBuilder: (_, animation, __, child) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    );

                    final fade = Tween<double>(
                      begin: 0.8,   // verhindert Weiß-Aufblitzen
                      end: 1.0,
                    ).animate(animation);

                    return FadeTransition(
                      opacity: fade,
                      child: SlideTransition(
                        position: slide,
                        child: child,
                      ),
                    );
                  },
                ),
              );
            },
          )

        ],
      ),
      body: Stack(
        children: [
          // =================================================================
          // LISTEN + REZEPTE + ZUTATEN
          // =================================================================
          StreamBuilder<List<_ShoppingListWithCount>>(
            stream: _watchLists(),
            builder: (context, snapshot) {
              if (snapshot.connectionState ==
                      ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                );
              }

              final lists = snapshot.data ?? [];
              final hasAnyLists = lists.isNotEmpty;

              if (hasAnyLists) {
                if (_activeListId == null ||
                    !lists.any(
                      (e) => e.list.id == _activeListId,
                    )) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) {
                    setState(() {
                      _activeListId = lists.first.list.id;
                    });
                  });
                }
              } else {
                WidgetsBinding.instance
                    .addPostFrameCallback((_) {
                  setState(() {
                    _activeListId = null;
                    _activeRecipeId = null;
                  });
                });
              }

              if (hasAnyLists) {
                final activeIndex = lists.indexWhere(
                  (e) => e.list.id == _activeListId,
                );

                if (activeIndex != -1) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) {
                    if (_pageController.hasClients &&
                        _pageController.page?.round() !=
                            activeIndex) {
                      _pageController.jumpToPage(activeIndex);
                    }
                  });
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),

                  // PageView mit Listen
                  if (hasAnyLists)
                    SizedBox(
                      height: 100,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: lists.length,
                        onPageChanged: (index) {
                          setState(() {
                            _activeListId = lists[index].list.id;
                            _marketsExpanded = false;
                            _activeRecipeId = null;
                            _selectedRecipeIds.clear();
                            _recipeSelectionMode = false;
                          });
                        },
                        itemBuilder: (context, index) {
                          final item = lists[index];
                          return _ShoppingListTile(
                            shoppingListId: item.list.id,
                            name: item.list.name,
                            productCount: item.count,
                            marketImagePath: item.market?.picture ??
                                "assets/images/shop/placeholder.png",
                            backgroundColor:
                                _parseHexColor(item.market?.color) ??
                                    const Color(0xFF0B0B0B),
                            onLogoTap: () {
                              setState(() {
                                _marketsExpanded =
                                    !_marketsExpanded;
                              });
                            },
                            onMenuSelected: (value) =>
                                _onMenuSelected(
                              value,
                              item.list,
                            ),
                          );
                        },
                      ),
                    ),

                  // Markt-Leiste
                  if (hasAnyLists)
                    AnimatedSize(
                      duration:
                          const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _marketsExpanded
                          ? FutureBuilder<
                              List<_MarketWithCount>>(
                              future: _loadMarkets(
                                lists
                                    .firstWhere(
                                      (e) =>
                                          e.list.id ==
                                          _activeListId,
                                    )
                                    .list
                                    .marketId,
                              ),
                              builder: (context, marketSnap) {
                                final markets =
                                    marketSnap.data ?? [];
                                final selectedMarketId = lists
                                    .firstWhere(
                                      (e) =>
                                          e.list.id ==
                                          _activeListId,
                                    )
                                    .list
                                    .marketId;

                                if (markets.isEmpty) {
                                  return const SizedBox
                                      .shrink();
                                }

                                return Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    vertical: 8,
                                  ),
                                  child: SizedBox(
                                    height: 55,
                                    child: ListView.builder(
                                      scrollDirection:
                                          Axis.horizontal,
                                      padding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 12,
                                      ),
                                      itemCount:
                                          markets.length,
                                      itemBuilder:
                                          (context, index) {
                                        final mk =
                                            markets[index];
                                        final isSelected =
                                            selectedMarketId ==
                                                mk.market.id;

                                        return GestureDetector(
                                          onTap: () async {
                                            final currentList =
                                                lists.firstWhere(
                                              (e) =>
                                                  e.list.id ==
                                                  _activeListId,
                                            );

                                            await appDb
                                              .update(appDb.shoppingList)
                                              .replace(
                                                currentList.list.copyWith(
                                                  marketId: d.Value(mk.market.id),
                                                  lastEdited: d.Value(DateTime.now()),
                                                ),
                                              );

                                          // NEU → alle SLIs neu berechnen, basierend auf neuem Markt
                                          await reapplyNominalsForList(currentList.list.id);


                                          setState(() {});

                                          },
                                          child: Container(
                                            margin:
                                                const EdgeInsets
                                                    .only(
                                              right: 4,
                                            ),
                                            width: 45,
                                            height: 45,
                                            decoration:
                                                BoxDecoration(
                                              borderRadius:
                                                  BorderRadius
                                                      .circular(
                                                8,
                                              ),
                                              color:
                                                  _parseHexColor(
                                                        mk
                                                            .market
                                                            .color,
                                                      ) ??
                                                      Colors
                                                          .grey[
                                                              800],
                                            ),
                                            child: Stack(
                                              children: [
                                                Center(
                                                  child:
                                                      ClipRRect(
                                                    borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                      8,
                                                    ),
                                                    child:
                                                        Image.asset(
                                                      mk.market.picture ??
                                                          "assets/images/shop/placeholder.png",
                                                      width:
                                                          35,
                                                      height:
                                                          35,
                                                      fit: BoxFit
                                                          .cover,
                                                    ),
                                                  ),
                                                ),
                                                if (!isSelected)
                                                  Container(
                                                    decoration:
                                                        BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                        8,
                                                      ),
                                                      color: Colors
                                                          .black
                                                          .withOpacity(
                                                        0.6,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            )
                          : const SizedBox.shrink(),
                    ),

                  const SizedBox(height: 2),

                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(12, 0, 12, 15),
                    child: Container(
                      height: 1.2,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Rezept-Leiste
                  if (_activeListId != null)
                    FutureBuilder<
                        List<_OverviewRecipeModel>>(
                      future:
                          _loadRecipesForList(_activeListId!),
                      builder: (context, rsnap) {
                        final recipes =
                            rsnap.data ?? [];

                        if (recipes.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return ShoppingOverviewRecipeBar(
                          recipes: recipes,
                          activeRecipeId: _activeRecipeId,
                          tileBuilder: (r) {
                            return GestureDetector(
                              onTap: () =>
                                  _onRecipeTap(r),
                              onLongPress: () =>
                                  _onRecipeLongPress(r),
                              child: OverviewRecipeTile(
                                recipe: r,
                                portionNumber:
                                    r.currentPortion,
                                unitLabel: r.unitLabel,
                                isDimmed:
                                    _recipeSelectionMode &&
                                        !_selectedRecipeIds
                                            .contains(
                                      r.recipeId,
                                    ),
                                onIncrease: () async {
                                await _updateRecipePortion(
                                  _activeListId!,
                                  r.recipeId,
                                  r.currentPortion + 1,
                                );
                                setState(() {}); // UI neu zeichnen -> FutureBuilder / StreamBuilder holen neue Werte
                              },
                              onDecrease: () async {
                                if (r.currentPortion <= 1) {
                                  return;
                                }

                                await _updateRecipePortion(
                                  _activeListId!,
                                  r.recipeId,
                                  r.currentPortion - 1,
                                );
                                setState(() {});
                              },

                                onDeleteRecipe:
                                    () async {
                                  await _deleteAllIngredientsOfRecipe(
                                    _activeListId!,
                                    r.recipeId,
                                  );
                                  setState(() {});
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),

                  // Zutatenliste
                  if (_activeListId != null)
                    Expanded(
                      child: StreamBuilder<_IngredientsForList>(
                        stream:
                            _watchIngredientsForList(
                          _activeListId!,
                        ),
                        builder: (context, snapshot) {
  if (snapshot.connectionState == ConnectionState.waiting &&
      !snapshot.hasData) {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.white,
      ),
    );
  }

  final data = snapshot.data;

  if (data == null ||
      (data.sections.isEmpty && data.basketItems.isEmpty)) {
    return const Center(
      child: Text(
        "Keine Zutaten",
        style: TextStyle(
          color: Colors.white54,
        ),
      ),
    );
  }

  return ShoppingIngredientSectionedList(
  sections: data.sections,
  basketItems: data.basketItems,
  version: data.version,
  onChanged: () => setState(() {}),
  onIngredientTap: _openAddAmountSheetForIngredient,
  onRecalc: (id) => recalculateNominalsForSLI(id),
  onCompleteShopping: _onCompleteShoppingPressed,
  calculateBasketTotalPrice: calculateBasketTotalPrice, // NEU
  getBasketTotalPrice: () async {
    if (_activeListId == null) return 0.0;
    return await calculateBasketTotalPrice(_activeListId!);
  },
  toggleBasketForIngredientGroup: ({
    required int shoppingListId,
    required int ingredientId,
    required bool newValue,
  }) {
    return toggleBasketForIngredientGroup(
      shoppingListId: shoppingListId,
      ingredientId: ingredientId,
      newValue: newValue,
    );
   },
);


}
,
                      ),
                    ),
                ],
              );
            },
          ),

          // =================================================================
          // SUCH-OVERLAY (INGREDIENTS + PRODUCTS)
          // =================================================================
          if (_isSearchMode) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () =>
                    FocusScope.of(context).unfocus(),
                child: Container(
                  color:
                      Colors.black.withOpacity(0.85),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius:
                      BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white24,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (txt) async {
                    await _performSearch(txt);
                    await _performProductSearch(txt);
                  },
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Ich brauche noch...",
                    hintStyle: const TextStyle(
                      color: Colors.white54,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearchMode = false;
                          _searchController.clear();
                        });
                        FocusScope.of(context)
                            .unfocus();
                      },
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 70,
              bottom: 0,
              child: ListView(
                padding:
                    const EdgeInsets.only(bottom: 220),
                children: [
                  _SectionWithLimit<Ingredient>(
                    title: null,
                    items:
                        _searchController.text.trim().isEmpty
                            ? _suggestions
                            : _searchResults,
                    showAll:
                        _searchController.text.trim().isEmpty
                            ? _showAllSuggestions
                            : _showAllSearchResults,
                    onToggle: () {
                      setState(() {
                        if (_searchController.text
                            .trim()
                            .isEmpty) {
                          _showAllSuggestions =
                              !_showAllSuggestions;
                        } else {
                          _showAllSearchResults =
                              !_showAllSearchResults;
                        }
                      });
                    },
                    tileBuilder: (ing) =>
                        GestureDetector(
                      onTap: () =>
                          _openAddAmountSheetForIngredient(
                        ing,
                      ),
                      child: _IngredientTileForGrid(
                        ing,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if ((_searchController.text.isEmpty &&
                          _productSuggestions
                              .isNotEmpty) ||
                      (_searchController.text
                              .isNotEmpty &&
                          _productResults
                              .isNotEmpty))
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      child: Text(
                        "Passende Artikel bei $_currentMarketName",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  _SectionWithLimit<Product>(
                    title: null,
                    items:
                        _searchController.text.trim().isEmpty
                            ? _productSuggestions
                            : _productResults,
                    showAll:
                        _searchController.text.trim().isEmpty
                            ? _showAllProductSuggestions
                            : _showAllProductResults,
                    onToggle: () {
                      setState(() {
                        if (_searchController.text
                            .trim()
                            .isEmpty) {
                          _showAllProductSuggestions =
                              !_showAllProductSuggestions;
                        } else {
                          _showAllProductResults =
                              !_showAllProductResults;
                        }
                      });
                    },
                    tileBuilder: (p) =>
                        GestureDetector(
                      onTap: () =>
                          _openAddAmountSheetForProduct(
                        p,
                      ),
                      child: _ProductTileForGrid(p),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // =================================================================
          // UNTERE LEISTE "Zutat hinzufügen..."
          // =================================================================
          if (!_isSearchMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black,
                padding:
                    const EdgeInsets.fromLTRB(
                  12,
                  8,
                  12,
                  20,
                ),
                child: GestureDetector(
                  onTap: () async {
                    await _loadSuggestions();
                    await _loadProductSuggestions();
                    await _loadCurrentMarketName();
                    setState(() {
                      _isSearchMode = true;
                      _showAllSuggestions = false;
                      _showAllProductSuggestions = false;
                    });
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius:
                          BorderRadius.circular(30),
                      border: Border.all(
                        color: Colors.white24,
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 16,
                    ),
                    child: const Text(
                      "Zutat hinzufügen...",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
// -----------------------------------------------------------------------------
// DATA HOLDER
// -----------------------------------------------------------------------------
class _ShoppingListWithCount {
  final ShoppingListData list;
  final int count;
  final Market? market;

  _ShoppingListWithCount({
    required this.list,
    required this.count,
    required this.market,
  });
}

class _MarketWithCount {
  final Market market;
  final int count;

  const _MarketWithCount({
    required this.market,
    required this.count,
  });
}

class _OverviewRecipeModel {
  final int recipeId;
  final String name;
  final String? picture;
  final int basePortion;
  final int currentPortion;
  final String unitLabel;

  _OverviewRecipeModel({
    required this.recipeId,
    required this.name,
    required this.picture,
    required this.basePortion,
    required this.currentPortion,
    required this.unitLabel,
  });
}

class _IngredientWithMeta {
  final int id;
  final int? ingredientId;
  final String name;
  final String? picture;
  final double? amount;
  final String? unitLabel;
  final bool bought;
  final bool basket;
  final int shoppingListId;
  final int? shelfId;
  final String shelfName;
  final String? shelfIcon;
  final int? productIdNominal;
  final int? ingredientMarketIdNominal;


  bool expanded;

  _IngredientWithMeta({
    required this.id,
    required this.ingredientId,
    required this.name,
    required this.picture,
    required this.amount,
    required this.unitLabel,
    required this.bought,
    required this.basket,
    required this.shoppingListId,
    required this.shelfId,
    required this.shelfName,
    required this.shelfIcon,
    this.expanded = false,
    this.productIdNominal,           // ← NEU
    this.ingredientMarketIdNominal,  // ← NEU
  });
}

class _IngredientSection {
  final int? shelfId;
  final String shelfName;
  final String? shelfIcon;
  final List<_IngredientWithMeta> items;

  _IngredientSection({
    required this.shelfId,
    required this.shelfName,
    required this.shelfIcon,
    required this.items,
  });
}

class _IngredientsForList {
  final List<_IngredientSection> sections;
  final List<_IngredientWithMeta> basketItems;
  final int version;

  _IngredientsForList({
    required this.sections,
    required this.basketItems,
    required this.version,
  });
}
// -----------------------------------------------------------------------------
// REZEPT-LEISTE (HORIZONTALE BAR)
// -----------------------------------------------------------------------------
class ShoppingOverviewRecipeBar extends StatelessWidget {
  final List<_OverviewRecipeModel> recipes;
  final int? activeRecipeId;
  final Widget Function(_OverviewRecipeModel r) tileBuilder;

  const ShoppingOverviewRecipeBar({
    super.key,
    required this.recipes,
    required this.activeRecipeId,
    required this.tileBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: recipes.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (_, i) {
          final r = recipes[i];
          return Container(
            margin: const EdgeInsets.only(right: 14),
            child: tileBuilder(r),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ZUTATENLISTE – NACH SHOPSHELF SECTIONS + KORB
// -----------------------------------------------------------------------------
class ShoppingIngredientSectionedList extends StatelessWidget {
  final List<_IngredientSection> sections;
  final List<_IngredientWithMeta> basketItems;
  final VoidCallback onChanged;
  final void Function(Ingredient ing) onIngredientTap;
  final Future<void> Function(int sliId) onRecalc;
  final Future<void> Function() onCompleteShopping;
  final Future<double> Function() getBasketTotalPrice;   // NEU
  final int version;

  // NEU: toggle-Funktion als Callback
  final Future<void> Function({
    required int shoppingListId,
    required int ingredientId,
    required bool newValue,
  }) toggleBasketForIngredientGroup;


  // NEU: Callback zum Berechnen des Basket-Gesamtpreises
  final Future<double> Function(int shoppingListId) calculateBasketTotalPrice;

  const ShoppingIngredientSectionedList({
    super.key,
    required this.sections,
    required this.basketItems,
    required this.onChanged,
    required this.onIngredientTap,
    required this.onRecalc,
    required this.onCompleteShopping,
    required this.getBasketTotalPrice,   // NEU
    required this.version,
    required this.calculateBasketTotalPrice, // NEU
    required this.toggleBasketForIngredientGroup, // NEU
  });



  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 200),
      children: [
        for (final section in sections) ...[
          Row(
            children: [
              if (section.shelfIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Image.asset(
                    section.shelfIcon!,
                    width: 22,
                    height: 22,
                    color: Colors.white,
                  ),
                ),
              Text(
                section.shelfName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final ing in section.items)
            GestureDetector(
  onTap: () async {
    if (ing.ingredientId == null) return;
    final realIngredient =
        await (appDb.select(appDb.ingredients)
              ..where((t) => t.id.equals(ing.ingredientId!)))
            .getSingle();
    onIngredientTap(realIngredient);
  },
  child: _IngredientTile(
    ing: ing,
    version: version,
    onChanged: onChanged,
    toggleBasketForIngredientGroup: toggleBasketForIngredientGroup,
  ),
),

          const SizedBox(height: 24),
        ],

        if (basketItems.isNotEmpty) ...[
  FutureBuilder<double>(
    future: () async {
      final first = basketItems.first;

      final row = await (appDb.select(appDb.shoppingListIngredient)
            ..where((t) => t.id.equals(first.id)))
          .getSingle();

      return calculateBasketTotalPrice(row.shoppingListId);
    }(),
    builder: (context, snap) {
      final total = snap.data ?? 0.0;

      return FutureBuilder<double>(
  future: getBasketTotalPrice(),
  builder: (context, snapshot) {
    final total = snapshot.data ?? 0.0;

    return GestureDetector(
      onTap: () async {
        await onCompleteShopping();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF0A5A38),
          borderRadius: BorderRadius.circular(40),
        ),
        alignment: Alignment.center,
        child: Text(
          "Einkauf abschließen (${total.toStringAsFixed(2)} €)",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  },
);


    },
  ),
  const SizedBox(height: 20),
  const Text(
    "Im Korb",
    style: TextStyle(
      color: Colors.white,
      fontSize: 17,
      fontWeight: FontWeight.w700,
    ),
  ),
  const SizedBox(height: 10),
],



        for (final ing in basketItems)
  _IngredientTile(
    ing: ing,
    version: version,
    onChanged: onChanged,
    toggleBasketForIngredientGroup: toggleBasketForIngredientGroup,
  ),

      ],
    );
  }
}

// -----------------------------------------------------------------------------
// HEADER TILE (EINKAUFSLISTE)
// -----------------------------------------------------------------------------
class _ShoppingListTile extends StatelessWidget {
  final int shoppingListId;
  final String name;
  final int productCount;
  final String marketImagePath;
  final Color backgroundColor;
  final VoidCallback onLogoTap;
  final ValueChanged<String> onMenuSelected;

  const _ShoppingListTile({
    required this.shoppingListId,
    required this.name,
    required this.productCount,
    required this.marketImagePath,
    required this.backgroundColor,
    required this.onLogoTap,
    required this.onMenuSelected,
  });

    // -----------------------------------------------------------
  // Anzahl nicht verfügbarer Einträge (kein product + kein IM)
  // -----------------------------------------------------------
  Future<int> _countUnavailableItems() async {
    final sli = appDb.shoppingListIngredient;

    final rows = await (appDb.select(sli)
          ..where((t) => t.shoppingListId.equals(shoppingListId)))
        .get();

    int count = 0;
    for (final row in rows) {
      final hasNominal =
          row.productIdNominal != null ||
          row.ingredientMarketIdNominal != null;

      if (!hasNominal) count++;
    }

    return count;
  }


  Future<void> calculateActualPricesForList(int shoppingListId) async {
  final sli = appDb.shoppingListIngredient;

  final rows = await (appDb.select(sli)
        ..where((t) => t.shoppingListId.equals(shoppingListId)))
      .get();

  for (final row in rows) {
    double? priceActual;

    // Produktfall
    if (row.productIdActual != null &&
        row.productAmountActual != null &&
        row.price != null) {
      priceActual = row.productAmountActual! * row.price!;
    }

    // IngredientMarket-Fall
    else if (row.ingredientMarketIdActual != null &&
        row.ingredientMarketAmountActual != null &&
        row.price != null) {
      priceActual = row.ingredientMarketAmountActual! * row.price!;
    }

    await appDb.into(sli).insertOnConflictUpdate(
          ShoppingListIngredientCompanion(
            id: d.Value(row.id),
            priceActual: d.Value(priceActual),
          ),
        );
  }
}

Future<double> _calculateTotalPrice() async {
  final sli = appDb.shoppingListIngredient;
  final sl = appDb.shoppingList;
  final pm = appDb.productMarkets;
  final im = appDb.ingredientMarket;

  // ShoppingList laden → MarketID notwendig
  final listRow = await (appDb.select(sl)
        ..where((t) => t.id.equals(shoppingListId)))
      .getSingleOrNull();

  if (listRow == null || listRow.marketId == null) return 0.0;
  final marketId = listRow.marketId!;

  // Alle SLI der Liste
  final items = await (appDb.select(sli)
        ..where((t) => t.shoppingListId.equals(shoppingListId)))
      .get();

  double total = 0.0;

  final Map<int, double> productSums = {};
  final Map<int, double> ingredientMarketSums = {};

  for (final row in items) {
    // Produktfall
    if (row.productIdNominal != null &&
        row.productAmountNominal != null) {
      productSums[row.productIdNominal!] =
          (productSums[row.productIdNominal!] ?? 0) +
              row.productAmountNominal!;
    }

    // IngredientMarket-Fall
    if (row.ingredientMarketIdNominal != null &&
        row.ingredientMarketAmountNominal != null) {
      ingredientMarketSums[row.ingredientMarketIdNominal!] =
          (ingredientMarketSums[row.ingredientMarketIdNominal!] ?? 0) +
              row.ingredientMarketAmountNominal!;
    }
  }

  // Produkte berechnen (CEIL)
  for (final entry in productSums.entries) {
    final productId = entry.key;
    final sumRounded = entry.value.ceil();

    final priceRow = await (appDb.select(pm)
          ..where(
            (t) =>
                t.productsId.equals(productId) &
                t.marketId.equals(marketId),
          ))
        .getSingleOrNull();

    if (priceRow?.price != null) {
      total += sumRounded * priceRow!.price!;
    }
  }

  // IngredientMarket berechnen
  for (final entry in ingredientMarketSums.entries) {
    final ingredientMarketId = entry.key;
    final summedAmount = entry.value;

    final imRow = await (appDb.select(im)
          ..where((t) => t.id.equals(ingredientMarketId)))
        .getSingleOrNull();

    if (imRow == null || imRow.price == null) continue;

    final effectiveAmount =
        _effectiveIngredientMarketAmount(summedAmount, imRow.unitCode);

    total += effectiveAmount * imRow.price!;
  }

  return total;
}




  @override
  Widget build(BuildContext context) {
    final pText = productCount == 1 ? "Eintrag" : "Einträge";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0B0B),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onLogoTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    marketImagePath,
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<int>(
                  future: _countUnavailableItems(),
                  builder: (context, snap) {
                    final unavailable = snap.data ?? 0;

                    String suffix = "";
                    if (unavailable > 0) {
                      suffix = " ($unavailable nicht verfügbar)";
                    }

                    return Text(
                      "$productCount $pText$suffix",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          FutureBuilder<double>(
            key: ValueKey("${shoppingListId}_total"),
            future: _calculateTotalPrice(),
            builder: (context, snapshot) {
              final total = snapshot.data ?? 0.0;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  "${total.toStringAsFixed(2)} €",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white54,
            ),
            color: const Color(0xFF1A1A1A),
            elevation: 6,
            onSelected: onMenuSelected,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: "edit",
                child: Text(
                  "Liste bearbeiten",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              PopupMenuItem(
                value: "move",
                child: Text(
                  "Auf anderen Einkauf verschieben",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              PopupMenuItem(
                value: "done",
                child: Text(
                  "Als erledigt markieren",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              PopupMenuItem(
                value: "delete",
                child: Text(
                  "Löschen",
                  style:
                      TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// RECIPE TILE
// -----------------------------------------------------------------------------
class OverviewRecipeTile extends StatelessWidget {
  final _OverviewRecipeModel recipe;
  final int portionNumber;
  final String unitLabel;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback? onDeleteRecipe;
  final bool isDimmed;

  const OverviewRecipeTile({
    super.key,
    required this.recipe,
    required this.portionNumber,
    required this.unitLabel,
    required this.onIncrease,
    required this.onDecrease,
    this.onDeleteRecipe,
    this.isDimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final img = (recipe.picture == null || recipe.picture!.isEmpty)
        ? 'assets/images/placeholder.jpg'
        : recipe.picture!;

    return Opacity(
      opacity: isDimmed ? 0.35 : 1.0,
      child: SizedBox(
        width: 120,
        child: Column(
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(img),
                  fit: BoxFit.cover,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                color: Colors.black.withOpacity(0.45),
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 6,
                ),
                child: Text(
                  recipe.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    height: 1.1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (portionNumber == 1) {
                      if (onDeleteRecipe != null) {
                        onDeleteRecipe!();
                      }
                    } else {
                      onDecrease();
                    }
                  },
                  child: Icon(
                    portionNumber == 1
                        ? Icons.delete_forever
                        : Icons.remove_circle_outline,
                    color: portionNumber == 1
                        ? Colors.redAccent
                        : Colors.white70,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "$portionNumber",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onIncrease,
                  child: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white70,
                    size: 26,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// -----------------------------------------------------------------------------
// EINZELNES INGREDIENT TILE
// -----------------------------------------------------------------------------
class _IngredientTile extends StatefulWidget {
  final _IngredientWithMeta ing;
  final VoidCallback onChanged;
  final int version;
  final Future<void> Function({
    required int shoppingListId,
    required int ingredientId,
    required bool newValue,
  }) toggleBasketForIngredientGroup;

  const _IngredientTile({
    required this.ing,
    required this.onChanged,
    required this.version,
    required this.toggleBasketForIngredientGroup,
  });

  @override
  State<_IngredientTile> createState() => _IngredientTileState();
}

class _IngredientTileState extends State<_IngredientTile> {
  late ValueNotifier<bool> _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = ValueNotifier(widget.ing.expanded);
  }

  @override
  void dispose() {
    _isExpanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = (widget.ing.picture == null || widget.ing.picture!.isEmpty)
        ? 'assets/images/placeholder.jpg'
        : widget.ing.picture!;

    // NEU: prüfen, ob gültiges Nominal existiert
    final bool hasValidNominal =
        widget.ing.productIdNominal != null ||
        widget.ing.ingredientMarketIdNominal != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 260),
            reverseTransitionDuration: const Duration(milliseconds: 220),
            opaque: false,
            barrierColor: Colors.transparent,
            pageBuilder: (_, __, ___) => ShoppingListIngredientScreen(
              shoppingListIngredientId: widget.ing.id,
            ),
            transitionsBuilder: (_, animation, __, child) {
              final slide = Tween<Offset>(
                begin: const Offset(0, 0.04),   // kleiner = smoother
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
              );

              final fade = Tween<double>(
                begin: 0.8,   // startet leicht sichtbar → kein Flash
                end: 1.0,
              ).animate(animation);

              return FadeTransition(
                opacity: fade,
                child: SlideTransition(
                  position: slide,
                  child: child,
                ),
              );
            },
          ),
        );
      },
      onLongPress: () {
        _isExpanded.value = !_isExpanded.value;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    img,
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ing.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (widget.ing.amount != null)
                        Text(
                          "${widget.ing.amount!.toStringAsFixed(
                            widget.ing.amount! % 1 == 0 ? 0 : 1,
                          )} ${widget.ing.unitLabel ?? ''}",
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // -----------------------------
                // PREIS-FUTUREBUILDER (unverändert)
                // -----------------------------
                FutureBuilder<double?>(
                  key: ValueKey("${widget.ing.id}_${widget.version}"),
                  future: (() async {
                    final sli = appDb.shoppingListIngredient;
                    final sl = appDb.shoppingList;
                    final pm = appDb.productMarkets;
                    final im = appDb.ingredientMarket;

                    final sliRow = await (appDb.select(sli)
                          ..where((t) => t.id.equals(widget.ing.id)))
                        .getSingle();

                    final listRow = await (appDb.select(sl)
                          ..where((t) => t.id.equals(sliRow.shoppingListId)))
                        .getSingleOrNull();

                    if (listRow == null || listRow.marketId == null) {
                      return null;
                    }
                    final marketId = listRow.marketId!;

                    if (sliRow.productIdNominal != null) {
                      final productId = sliRow.productIdNominal!;

                      final sumRow = await (appDb.selectOnly(sli)
                            ..addColumns([sli.productAmountNominal.sum()])
                            ..where(
                              sli.shoppingListId.equals(sliRow.shoppingListId) &
                                  sli.productIdNominal.equals(productId),
                            ))
                          .getSingle();

                      final summedAmount =
                          sumRow.read(sli.productAmountNominal.sum()) ?? 0.0;

                      if (summedAmount == 0) return 0.0;

                      final roundedAmount = summedAmount.ceil();

                      final priceRow = await (appDb.select(pm)
                            ..where(
                              (t) =>
                                  t.productsId.equals(productId) &
                                  t.marketId.equals(marketId),
                            ))
                          .getSingleOrNull();

                      if (priceRow == null || priceRow.price == null) {
                        return null;
                      }

                      return priceRow.price! * roundedAmount;
                    }

                    if (sliRow.ingredientMarketIdNominal != null) {
                      final mid = sliRow.ingredientMarketIdNominal!;

                      final sumRow = await (appDb.selectOnly(sli)
                            ..addColumns([sli.ingredientMarketAmountNominal.sum()])
                            ..where(
                              sli.shoppingListId.equals(sliRow.shoppingListId) &
                                  sli.ingredientMarketIdNominal.equals(mid),
                            ))
                          .getSingle();

                      final summedAmount =
                          sumRow.read(sli.ingredientMarketAmountNominal.sum()) ??
                              0.0;

                      if (summedAmount == 0) return 0.0;

                      final imRow = await (appDb.select(im)
                            ..where((t) => t.id.equals(mid)))
                          .getSingleOrNull();

                      if (imRow == null || imRow.price == null) return null;

                      final unitCode =
                          imRow.unitCode?.trim().toLowerCase() ?? '';

                      final shouldRound =
                          unitCode.isNotEmpty && unitCode != 'g';

                      final effective =
                          shouldRound ? summedAmount.ceilToDouble() : summedAmount;

                      return imRow.price! * effective;
                    }

                    return null;
                  })(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const SizedBox(width: 52);
                    }

                    final total = snap.data;
                    if (total == null) return const SizedBox(width: 52);

                    return SizedBox(
                      width: 52,
                      child: Text(
                        "${total.toStringAsFixed(2)} €",
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 10),

                // ----------------------------------------------------
                // NEUE CHECKBOX MIT GRÖSSEREM TAP-BEREICH + ROT BEI FEHLER
                // ----------------------------------------------------
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () async {
                    await widget.toggleBasketForIngredientGroup(
                      shoppingListId: widget.ing.shoppingListId!,
                      ingredientId: widget.ing.ingredientId!,
                      newValue: !widget.ing.basket,
                    );
                    widget.onChanged();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: Icon(
                        widget.ing.basket
                            ? Icons.check_circle_outline
                            : Icons.circle_outlined,
                        key: ValueKey(
                            "${widget.ing.basket}_${hasValidNominal}"),

                        // Farben:
                        color: widget.ing.basket
                            ? Colors.white
                            : (hasValidNominal
                                ? Colors.white38
                                : Colors.redAccent),

                        size: 26,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ValueListenableBuilder<bool>(
              valueListenable: _isExpanded,
              builder: (context, isExpanded, child) {
                if (!isExpanded) return const SizedBox.shrink();

                return Column(
                  children: [
                    const Divider(
                      color: Colors.white24,
                      thickness: 1,
                      height: 4,
                    ),
                    const SizedBox(height: 14),
                    FutureBuilder(
                      future: () async {
                        final sli = await (appDb.select(appDb.shoppingListIngredient)
                              ..where((t) => t.id.equals(widget.ing.id)))
                          .getSingleOrNull();

                        if (sli == null) return null;

                        if (sli.productIdNominal != null) {
                          final productId = sli.productIdNominal!;
                          final product = await (appDb.select(appDb.products)
                                ..where((t) => t.id.equals(productId)))
                              .getSingleOrNull();

                          final producer = await (appDb.select(appDb.producers)
                                ..where((t) => t.id.equals(product!.producerId)))
                              .getSingleOrNull();

                          final countryRows = await appDb.customSelect(
                            '''
                              SELECT 
                                c.image AS img,
                                c.id    AS country_id,
                                c.short AS short
                              FROM product_country pc
                              JOIN countries c ON c.id = pc.countries_id
                              WHERE pc.products_id = ?
                            ''',
                            variables: [d.Variable(productId)],
                          ).get();

                          return <String, dynamic>{
                            "type": "product",
                            "product": product,
                            "producer": producer,
                            "sli": sli,
                            "countries": countryRows
                                .map((r) => {
                                      "img": (r.data['img'] as String?) ?? '',
                                      "id": (r.data['country_id'] as int?) ?? 0,
                                      "short": (r.data['short'] as String?) ?? "",
                                    })
                                .where((c) => (c["img"] as String).isNotEmpty)
                                .toList(),
                          };
                        }

                        if (sli.ingredientMarketIdNominal != null) {
                          final imId = sli.ingredientMarketIdNominal!;
                          final im = await (appDb.select(appDb.ingredientMarket)
                                ..where((t) => t.id.equals(imId)))
                              .getSingleOrNull();

                          final countryRows = await appDb.customSelect(
                            '''
                              SELECT 
                                c.image AS img,
                                c.id    AS country_id,
                                c.short AS short
                              FROM ingredient_market_country ic
                              JOIN countries c ON c.id = ic.countries_id
                              WHERE ic.ingredient_market_id = ?
                            ''',
                            variables: [d.Variable(imId)],
                          ).get();

                          return <String, dynamic>{
                            "type": "ingredientMarket",
                            "im": im,
                            "sli": sli,
                            "countries": countryRows
                                .map((r) => {
                                      "img": (r.data['img'] as String?) ?? '',
                                        "id": (r.data['country_id'] as int?) ?? 0,
                                        "short": (r.data['short'] as String?) ?? "",
                                    })
                                .where((c) => (c["img"] as String).isNotEmpty)
                                .toList(),
                          };
                        }

                        return null;
                      }(),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              color: Colors.white38,
                              strokeWidth: 1.2,
                            ),
                          );
                        }

                        final data = snap.data as Map<String, dynamic>?;
                        if (data == null) return const SizedBox();

                        final type = data["type"] as String;
                        final sli = data["sli"] as ShoppingListIngredientData;

                        if (type == "product") {
                          final product = data["product"] as Product;
                          final producer = data["producer"];
                          final countries =
                              data["countries"] as List<Map<String, dynamic>>;

                          final img = (product.image == null || product.image!.isEmpty)
                              ? 'assets/images/placeholder.jpg'
                              : product.image!;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  img,
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      producer?.name ?? "",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "${product.sizeUnitCode ?? ''}-Inhalt: "
                                      "${product.yieldAmount ?? ''} "
                                      "${product.yieldUnitCode ?? ''}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _buildCountryFlagsInteractive(
                                context,
                                countries,
                                sli.id,
                                sli.countryId,
                              ),
                            ],
                          );
                        }

                        if (type == "ingredientMarket") {
                          final im = data["im"];
                          final countries =
                              data["countries"] as List<Map<String, dynamic>>;

                          return Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "${im.price ?? ''} € / "
                                  "${im.unitAmount ?? ''} ${im.unitCode ?? ''}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              _buildCountryFlagsInteractive(
                                context,
                                countries,
                                sli.id,
                                sli.countryId,
                              ),
                            ],
                          );
                        }

                        return const SizedBox();
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildCountryFlagsInteractive(
  BuildContext context,
  List<Map<String, dynamic>> flags,
  int sliId,
  int? selectedCountryId,
) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      // ADD-BUTTON • Öffnet Slide-Up
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          _openCountrySelector(context, sliId, selectedCountryId);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 33,
              height: 33,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white30),
              ),
              child: const Icon(
                Icons.add,
                size: 20,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              "NEU",
              style: TextStyle(
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),

      // Bestehende Flaggen
      ...flags.take(4).map((c) {       // max. 4 Flaggen anzeigen
        final img = c["img"] as String;
        final id = c["id"] as int;
        final isSelected = id == selectedCountryId;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () async {
            await (appDb.update(appDb.shoppingListIngredient)
                  ..where((t) => t.id.equals(sliId)))
                .write(
              ShoppingListIngredientCompanion(
                countryId: d.Value(id),
              ),
            );

            if (context.mounted) {
              final parentState = context
                  .findAncestorStateOfType<_ShoppingListOverviewScreenState>();
              parentState?.setState(() {});
            }
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Opacity(
              opacity: isSelected ? 1.0 : 0.45,   // AUSGEWÄHLT / NICHT AUSGEWÄHLT BEIBEHALTEN
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      img,
                      width: 33,
                      height: 33,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(width: 33, height: 33, color: Colors.red),
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    (c["short"] ?? "").toString().toUpperCase(),   // GROSSBUCHSTABEN
                    style: const TextStyle(
                      fontSize: 10,        // klein
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    ],
  );
}

Future<void> _openCountrySelector(
  BuildContext context,
  int sliId,
  int? selectedCountryId,
) async {
  final TextEditingController searchController = TextEditingController();

  // SLI laden
  final sli = await (appDb.select(appDb.shoppingListIngredient)
        ..where((t) => t.id.equals(sliId)))
      .getSingle();

  final bool isProduct = sli.productIdNominal != null;

  // TOP 5 Länder laden (sortiert nach Häufigkeit)
  final allCountries = await _loadAllCountries();
  final topCountries = await _loadTopCountries(isProduct, sli);


  // Modal anzeigen
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.black87,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
  return StatefulBuilder(
    builder: (ctx, setStateModal) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) {
          final query = searchController.text.trim().toLowerCase();

          List<Map<String, dynamic>> filtered;

          if (query.isEmpty) {
            filtered = topCountries;
          } else {
            filtered = allCountries.where((c) {
              final name = (c["name"] ?? "").toLowerCase();
              return name.contains(query);
            }).toList();
          }


          return Container(
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                // HEADER
                const Text(
                  "Land auswählen",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // LISTE (jetzt scrollend)
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      final id = c["id"] as int;
                      final img = c["img"] as String;
                      final name = c["name"] as String;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          // 1. SLI laden
                          final sli = await (appDb.select(appDb.shoppingListIngredient)
                                ..where((t) => t.id.equals(sliId)))
                              .getSingle();

                          // 2. SELECTED COUNTRY ID speichern
                          final int countryId = id;

                          // 3. Korrekte m:n Tabelle beschreiben
                          if (sli.productIdNominal != null) {
                            // Fall 1 – Produkt
                            await appDb.into(appDb.productCountry).insertOnConflictUpdate(
                              ProductCountryCompanion(
                                productsId: d.Value(sli.productIdNominal!),
                                countriesId: d.Value(countryId),
                              ),
                            );

                          } else if (sli.ingredientMarketIdNominal != null) {
                            // Fall 2 – IngredientMarket
                            await appDb.into(appDb.ingredientMarketCountry).insertOnConflictUpdate(
                              IngredientMarketCountryCompanion(
                                ingredientMarketId: d.Value(sli.ingredientMarketIdNominal!),
                                countriesId: d.Value(countryId),
                              ),
                            );
                          }

                          // 4. Die SLI-Anzeige aktualisieren (wie bisher)
                          await (appDb.update(appDb.shoppingListIngredient)
                                ..where((t) => t.id.equals(sliId)))
                              .write(
                            ShoppingListIngredientCompanion(countryId: d.Value(countryId)),
                          );

                          // 5. SlideUp schließen
                          Navigator.pop(context);

                          // 6. IngredientTile refreshen
                          final parentState = context
                              .findAncestorStateOfType<_ShoppingListOverviewScreenState>();
                          parentState?.setState(() {});
                        },

                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  img,
                                  width: 33,
                                  height: 33,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // SUCHLEISTE
                TextField(
                  controller: searchController,
                  onChanged: (_) => setStateModal(() {}),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Suchen …",
                    hintStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
,
  );
}

Future<List<Map<String, dynamic>>> _loadAllCountries() async {
  final rows = await appDb.select(appDb.countries).get();

  return rows.map((c) {
    return {
      "id": c.id,
      "name": c.name,
      "img": c.image ?? "",
    };
  }).toList();
}


Future<List<Map<String, dynamic>>> _loadTopCountries(
  bool isProduct,
  ShoppingListIngredientData sli,
) async {
  final country = appDb.countries;

  // Häufigkeiten laden
  final freqRows = await (appDb.customSelect(
    """
    SELECT country_id, COUNT(*) AS freq
    FROM shopping_list_ingredient
    WHERE country_id IS NOT NULL
    GROUP BY country_id
    ORDER BY freq DESC
    LIMIT 5
    """,
    readsFrom: {appDb.shoppingListIngredient},
  ).get());

  final topIds =
      freqRows.map((r) => r.data["country_id"] as int).toList();

  // Bilder + Namen laden
  final rows = await (appDb.select(country)
        ..where((c) => c.id.isIn(topIds)))
      .get();

  return rows.map((c) {
    return {
      "id": c.id,
      "name": c.name,
      "img": c.image ?? "",
    };
  }).toList();
}





// -----------------------------------------------------------------------------
// GRID / SECTION / TILE-HILFSFUNKTIONEN
// -----------------------------------------------------------------------------
class _GridViewIngredients extends StatelessWidget {
  final List<Ingredient> items;
  final int columns;
  final void Function(Ingredient ing) onTap;

  const _GridViewIngredients({
    required this.items,
    required this.columns,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final ing = items[i];
        return InkWell(
          onTap: () => onTap(ing),
          child: _IngredientTileForGrid(ing),
        );
      },
    );
  }
}

class _GridViewProducts extends StatelessWidget {
  final List<Product> items;
  final int columns;
  final void Function(Product p) onTap;

  const _GridViewProducts({
    required this.items,
    required this.columns,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final p = items[i];
        return InkWell(
          onTap: () => onTap(p),
          child: _ProductTileForGrid(p),
        );
      },
    );
  }
}

class _SectionWithLimit<T> extends StatelessWidget {
  final String? title;
  final List<T> items;
  final bool showAll;
  final VoidCallback onToggle;
  final Widget Function(T) tileBuilder;

  const _SectionWithLimit({
    required this.title,
    required this.items,
    required this.showAll,
    required this.onToggle,
    required this.tileBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final visible =
        showAll ? items : items.take(6).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            child: Text(
              title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        GridView.builder(
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          itemCount: visible.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemBuilder: (_, i) =>
              tileBuilder(visible[i]),
        ),
        if (items.length > 6)
          GestureDetector(
            onTap: onToggle,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(
                vertical: 14,
              ),
              child: Center(
                child: Text(
                  showAll
                      ? "Weniger anzeigen"
                      : "Alle anzeigen",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Widget _IngredientTileForGrid(Ingredient ing) {
  final img = (ing.picture == null || ing.picture!.isEmpty)
      ? 'assets/images/placeholder.jpg'
      : ing.picture!;

  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.asset(
      img,
      fit: BoxFit.cover,
    ),
  );
}

Widget _ProductTileForGrid(Product p) {
  final img = (p.image == null || p.image!.isEmpty)
      ? 'assets/images/placeholder.jpg'
      : p.image!;

  return ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Image.asset(
      img,
      fit: BoxFit.cover,
    ),
  );
}

Widget _buildMarketIconSmall(int marketId) {
  return FutureBuilder<Market>(
    future: (appDb.select(appDb.markets)
          ..where((m) => m.id.equals(marketId)))
        .getSingle(),
    builder: (context, snap) {
      if (!snap.hasData) return const SizedBox.shrink();
      final m = snap.data!;
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: _parseHexColor(m.color),
          borderRadius: BorderRadius.circular(6),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.asset(
            m.picture ?? "assets/images/shop/placeholder.png",
            fit: BoxFit.cover,
          ),
        ),
      );
    },
  );
}

// -----------------------------------------------------------------------------
// BOTTOM SHEET: MENGEN-EINGABE
// -----------------------------------------------------------------------------
class _AddAmountBottomSheet extends StatefulWidget {
  final String imagePath;
  final String name;
  final String? defaultUnitCode;
  final double initialAmount;
  final bool isProduct;
  final void Function(double amount, String unitCode) onSave;

  const _AddAmountBottomSheet({
    required this.imagePath,
    required this.name,
    required this.defaultUnitCode,
    required this.initialAmount,
    required this.isProduct,
    required this.onSave,
  });

  @override
  State<_AddAmountBottomSheet> createState() =>
      _AddAmountBottomSheetState();
}

class _AddAmountBottomSheetState
    extends State<_AddAmountBottomSheet> {
  late double _amount;
  String? _unit;
  List<Unit> _units = [];

  bool get _isProduct => widget.isProduct;

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount;
    _loadUnits();
  }

  Future<void> _loadUnits() async {
    final list = await appDb.select(appDb.units).get();

    setState(() {
      _units = list;
      _unit = widget.defaultUnitCode;

      if (_isProduct) {
        _units = list
            .where(
              (u) => u.code == widget.defaultUnitCode,
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final img = widget.imagePath.isEmpty
        ? "assets/images/placeholder.jpg"
        : widget.imagePath;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context)
            .viewInsets
            .bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              img,
              width:
                  MediaQuery.of(context).size.width / 3,
              height:
                  MediaQuery.of(context).size.width / 3,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _amount =
                              _amount > 1 ? _amount - 1 : 0;
                        });
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.remove_circle_outline,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final controller =
                              TextEditingController(
                            text: _amount.toString(),
                          );

                          final result =
                              await showDialog<double>(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                backgroundColor:
                                    Colors.black87,
                                title: const Text(
                                  "Menge eingeben",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                content: TextField(
                                  controller: controller,
                                  autofocus: true,
                                  keyboardType:
                                      const TextInputType
                                          .numberWithOptions(
                                    decimal: true,
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  decoration:
                                      const InputDecoration(
                                    hintText: "Menge",
                                    hintStyle: TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      final v =
                                          double.tryParse(
                                        controller.text
                                            .replaceAll(
                                          ',',
                                          '.',
                                        ),
                                      );
                                      Navigator.pop(
                                        ctx,
                                        v,
                                      );
                                    },
                                    child: const Text(
                                      "OK",
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );

                          if (result != null) {
                            setState(() {
                              _amount =
                                  result < 0 ? 0 : result;
                            });
                          }
                        },
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius:
                                BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white24,
                            ),
                          ),
                          child: Text(
                            (_amount % 1 == 0)
                                ? _amount
                                    .toInt()
                                    .toString()
                                : _amount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () {
                        setState(() => _amount += 1);
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  height: 44,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius:
                        BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white24,
                    ),
                  ),
                  child: widget.isProduct
                      ? Align(
                          alignment:
                              Alignment.centerLeft,
                          child: Text(
                            widget.defaultUnitCode ??
                                "",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        )
                      : DropdownButton<String>(
                          value: _unit,
                          dropdownColor:
                              Colors.black87,
                          underline:
                              const SizedBox(),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                          isExpanded: true,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                          items: _units
                              .map(
                                (u) =>
                                    DropdownMenuItem<
                                        String>(
                                  value: u.code,
                                  child: Text(
                                    u.label,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() {
                            _unit = v;
                          }),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFF0A5A38),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                if (_unit != null) {
                  widget.onSave(_amount, _unit!);
                }
                Navigator.pop(context);
              },
              child: const Text(
                "Speichern",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
