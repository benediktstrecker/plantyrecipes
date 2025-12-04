// lib/screens/shopping/shopping_list_ingredient.dart

import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;

import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/design/layout.dart';

import 'package:planty_flutter_starter/screens/shopping/shopping_list_alternative.dart';
import 'package:planty_flutter_starter/screens/shopping/shopping_list_product.dart';

import 'package:planty_flutter_starter/services/unit_conversion_service.dart';
import 'package:planty_flutter_starter/services/ingredient_market_conversion_service.dart';
import 'package:planty_flutter_starter/services/ingredient_nominal_selection.dart';

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

class ShoppingListIngredientScreen extends StatefulWidget {
  final int shoppingListIngredientId;

  const ShoppingListIngredientScreen({
    super.key,
    required this.shoppingListIngredientId,
  });

  @override
  State<ShoppingListIngredientScreen> createState() =>
      _ShoppingListIngredientScreenState();
}

class _ShoppingListIngredientScreenState
    extends State<ShoppingListIngredientScreen> {
  List<ShoppingListIngredientData> allSli = [];
  ShoppingListIngredientData? activeSli;

  Ingredient? ingredient;
  Unit? activeUnit;
  List<Unit> allUnits = [];

  double totalAmount = 0;

  List<Recipe> recipes = [];
  int activePage = 0;

  bool _hasChanges = false;

  final PageController _pageController = PageController();

  late final UnitConversionService _conversionService;
  int? _shoppingListMarketId;

  String _formatAmount(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  String _formatAmountForInput(num value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }

  @override
  void initState() {
    super.initState();
    _conversionService = UnitConversionService(appDb);
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final startSli = await (appDb.select(appDb.shoppingListIngredient)
          ..where((t) => t.id.equals(widget.shoppingListIngredientId)))
        .getSingleOrNull();

    if (startSli == null) return;

    ShoppingListData? shoppingList;

    if (startSli.shoppingListId != null) {
      shoppingList = await (appDb.select(appDb.shoppingList)
            ..where((t) => t.id.equals(startSli.shoppingListId!)))
          .getSingleOrNull();
    }

    final marketId = shoppingList?.marketId;

    final ing = await (appDb.select(appDb.ingredients)
          ..where((t) => t.id.equals(startSli.ingredientIdNominal!)))
        .getSingleOrNull();

    final unitsList = await appDb.select(appDb.units).get();

    final all = await (appDb.select(appDb.shoppingListIngredient)
          ..where((t) => t.shoppingListId.equals(startSli.shoppingListId!))
          ..where((t) =>
              t.ingredientIdNominal.equals(startSli.ingredientIdNominal!)))
        .get();

    double sum = 0;
    for (final s in all) {
      sum += s.ingredientAmountNominal ?? 0;
    }

    final recipeIds = all.map((e) => e.recipeId).whereType<int>().toSet();
    final recs = <Recipe>[];

    for (final id in recipeIds) {
      final r = await (appDb.select(appDb.recipes)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (r != null) recs.add(r);
    }

    final idx =
        all.indexWhere((x) => x.id == widget.shoppingListIngredientId);
    final startIndex = idx == -1 ? 0 : idx;

    Unit? u;

    if (startSli.ingredientUnitCodeNominal != null &&
        startSli.ingredientUnitCodeNominal!.isNotEmpty) {
      u = await (appDb.select(appDb.units)
            ..where((t) =>
                t.code.equals(startSli.ingredientUnitCodeNominal!)))
          .getSingleOrNull();
    }

    setState(() {
      allSli = all;
      activeSli = all[startIndex];
      ingredient = ing;
      activeUnit = u;
      allUnits = unitsList;
      totalAmount = sum;
      recipes = recs;
      activePage = startIndex;
      _shoppingListMarketId = marketId;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(startIndex);
      }
    });

    await _recalculateAll();
  }

  void _switchActive(int index) async {
    if (index < 0 || index >= allSli.length) return;

    final sel = allSli[index];

    Unit? u;

    if (sel.ingredientUnitCodeNominal != null &&
        sel.ingredientUnitCodeNominal!.isNotEmpty) {
      u = await (appDb.select(appDb.units)
            ..where((t) => t.code.equals(sel.ingredientUnitCodeNominal!)))
          .getSingleOrNull();
    }

    setState(() {
      activeSli = sel;
      activeUnit = u;
      activePage = index;
      _hasChanges = false;
    });

    await _recalculateAll();
  }

  Future<double?> _getProductMarketPrice(int productId) async {
    if (_shoppingListMarketId == null) return null;

    final entry = await (appDb.select(appDb.productMarkets)
          ..where((t) => t.productsId.equals(productId))
          ..where((t) => t.marketId.equals(_shoppingListMarketId!)))
        .getSingleOrNull();

    return entry?.price;
  }

  // ---------------------------------------------------------
  // FIXED VERSION: Produkt neu berechnen (OHNE recalc & OHNE Preis setzen!)
  // ---------------------------------------------------------
  Future<void> _recalculateProductValues() async {
    if (activeSli == null) return;

    final sli = activeSli!;

    if (sli.productIdNominal == null) {
      setState(() {
        activeSli = sli.copyWith(
          productAmountNominal: const Value(null),
        );
      });
      return;
    }

    final ingredientIdNominal =
        sli.ingredientIdNominal ?? ingredient?.id;
    final ingredientAmountNominal = sli.ingredientAmountNominal;
    final ingredientUnitCodeNominal = sli.ingredientUnitCodeNominal;

    if (ingredientIdNominal == null ||
        ingredientAmountNominal == null ||
        ingredientAmountNominal <= 0 ||
        ingredientUnitCodeNominal == null ||
        ingredientUnitCodeNominal.isEmpty) {
      setState(() {
        activeSli = sli.copyWith(
          productAmountNominal: const Value(null),
          price: const Value(null), // Preis setzt später recalc
        );
      });
      return;
    }

    final product = await (appDb.select(appDb.products)
          ..where((p) => p.id.equals(sli.productIdNominal!)))
        .getSingleOrNull();

    if (product == null) {
      setState(() {
        activeSli = sli.copyWith(
          productAmountNominal: const Value(null),
          price: const Value(null),
        );
      });
      return;
    }

    final productAmount =
        await _conversionService.calculateProductAmountNominal(
      ingredientIdNominal: ingredientIdNominal,
      ingredientAmountNominal: ingredientAmountNominal,
      ingredientUnitCodeNominal: ingredientUnitCodeNominal,
      product: product,
    );

    if (productAmount == null || productAmount <= 0) {
      setState(() {
        activeSli = sli.copyWith(
          productAmountNominal: const Value(null),
          price: const Value(null),
        );
      });
      return;
    }

    // WICHTIG: KEIN PRICE SETZEN, KEIN RECALC hier!
    setState(() {
      activeSli = sli.copyWith(
        productAmountNominal: Value(productAmount),
      );
    });
  }

  // ---------------------------------------------------------
  // FIXED VERSION: IngredientMarket neu berechnen
  // ---------------------------------------------------------
  Future<void> _recalculateIngredientMarketValues() async {
    if (activeSli == null) return;

    final sli = activeSli!;

    if (sli.ingredientMarketIdNominal == null) {
      setState(() {
        activeSli = sli.copyWith(
          ingredientMarketAmountNominal: const Value(null),
        );
      });
      return;
    }

    final ingredientMarketId = sli.ingredientMarketIdNominal;
    final ingredientAmountNominal = sli.ingredientAmountNominal;
    final ingredientUnitCodeNominal = sli.ingredientUnitCodeNominal;

    if (ingredientMarketId == null ||
        ingredientAmountNominal == null ||
        ingredientAmountNominal <= 0 ||
        ingredientUnitCodeNominal == null ||
        ingredientUnitCodeNominal.isEmpty) {
      setState(() {
        activeSli = sli.copyWith(
          ingredientMarketAmountNominal: const Value(null),
        );
      });
      return;
    }

    final im = await (appDb.select(appDb.ingredientMarket)
          ..where((t) => t.id.equals(ingredientMarketId)))
        .getSingleOrNull();

    if (im == null) {
      setState(() {
        activeSli = sli.copyWith(
          ingredientMarketAmountNominal: const Value(null),
          price: const Value(null), // Preis kommt später von recalc
        );
      });
      return;
    }

    final ingredientIdNominal =
        sli.ingredientIdNominal ?? ingredient?.id;

    final imAmount =
        await IngredientMarketConversionService(appDb)
            .calculateIngredientMarketAmountNominal(
      ingredientId: ingredientIdNominal!,
      ingredientAmountNominal: ingredientAmountNominal,
      ingredientUnitCodeNominal: ingredientUnitCodeNominal,
      ingredientMarket: im,
    );

    if (imAmount == null || imAmount <= 0) {
      setState(() {
        activeSli = sli.copyWith(
          ingredientMarketAmountNominal: const Value(null),
          price: const Value(null),
        );
      });
      return;
    }

    // WICHTIG: KEIN price setzen!
    // KEIN recalc hier!
    setState(() {
      activeSli = sli.copyWith(
        ingredientMarketAmountNominal: Value(imAmount),
      );
    });
  }

  // ---------------------------------------------------------
  // MASTER RECALC – einzig hier läuft recalculateNominalsForSLI()
  // ---------------------------------------------------------
  Future<void> _recalculateAll() async {
    if (activeSli == null) return;

    final sli = activeSli!;

    if (sli.productIdNominal != null) {
      await _recalculateProductValues();
      await recalculateNominalsForSLI(sli.id);
      return;
    }

    if (sli.ingredientMarketIdNominal != null) {
      await _recalculateIngredientMarketValues();
      await recalculateNominalsForSLI(sli.id);
      return;
    }

    setState(() {
      activeSli = sli.copyWith(
        price: const Value(null),
        productAmountNominal: const Value(null),
        ingredientMarketAmountNominal: const Value(null),
      );
    });
  }
  // ---------------------------------------------------------
  // SLI zu einer anderen Liste verschieben
  // ---------------------------------------------------------
  Future<void> _moveSingleSliToList({
    required int sliId,
    required int sourceListId,
    required int targetListId,
  }) async {
    await (appDb.update(appDb.shoppingListIngredient)
          ..where((t) => t.id.equals(sliId)))
        .write(
      ShoppingListIngredientCompanion(
        shoppingListId: Value(targetListId),
      ),
    );

    final targetList = await (appDb.select(appDb.shoppingList)
          ..where((t) => t.id.equals(targetListId)))
        .getSingleOrNull();

    final newMarketId = targetList?.marketId;

    if (newMarketId != null) {
      await reapplyNominalsForSLI_AfterListMove(sliId, newMarketId);
    }

    await (appDb.update(appDb.shoppingList)
          ..where((t) => t.id.equals(sourceListId)))
        .write(
      ShoppingListCompanion(
        lastEdited: Value(DateTime.now()),
      ),
    );

    await (appDb.update(appDb.shoppingList)
          ..where((t) => t.id.equals(targetListId)))
        .write(
      ShoppingListCompanion(
        lastEdited: Value(DateTime.now()),
      ),
    );
  }

  // ---------------------------------------------------------
  // Editierbereich
  // ---------------------------------------------------------
  Widget _buildEditableSection() {
    final sli = activeSli!;
    final amount = sli.ingredientAmountNominal ?? 0;
    final price = sli.price;

    final priceText =
        price != null ? "${price.toStringAsFixed(2)} €" : "— €";

    return Row(
      children: [
        // MENGE
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Menge",
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 6),
              Row(
                children: [
                  // – Button
                  GestureDetector(
                    onTap: () async {
                      final old = amount;
                      final newVal = old > 1 ? old - 1 : 0;
                      final diff = newVal - old;

                      setState(() {
                        activeSli = sli.copyWith(
                          ingredientAmountNominal:
                              Value(newVal.toDouble()),
                        );
                        totalAmount += diff;
                        _hasChanges = true;
                      });

                      await _recalculateAll();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(Icons.remove_circle_outline,
                          color: Colors.white),
                    ),
                  ),

                  const SizedBox(width: 2),

                  // MENGE EDITIERBAR
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final controller = TextEditingController(
                          text: _formatAmountForInput(amount),
                        );

                        final result =
                            await showModalBottomSheet<double>(
                          context: context,
                          backgroundColor: Colors.black87,
                          isScrollControlled: true,
                          builder: (ctx) {
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(ctx).viewInsets.bottom,
                                left: 20,
                                right: 20,
                                top: 20,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: controller,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    autofocus: true,
                                    style:
                                        const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      hintText: "Neue Menge",
                                      hintStyle:
                                          TextStyle(color: Colors.white54),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () {
                                      final v = double.tryParse(
                                        controller.text.replaceAll(
                                            ',', '.'),
                                      );
                                      Navigator.pop(ctx, v);
                                    },
                                    child: const Text("Übernehmen"),
                                  ),
                                ],
                              ),
                            );
                          },
                        );

                        if (result != null) {
                          final cleaned =
                              result < 0 ? 0 : result.toDouble();
                          final diff = cleaned - amount;

                          setState(() {
                            activeSli = activeSli!.copyWith(
                              ingredientAmountNominal:
                                  Value(cleaned.toDouble()),
                            );
                            totalAmount += diff;
                            _hasChanges = true;
                          });

                          await _recalculateAll();
                        }
                      },
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white12,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          _formatAmount(amount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 2),

                  // + Button
                  GestureDetector(
                    onTap: () async {
                      final old = amount;
                      final newVal = old + 1;
                      final diff = newVal - old;

                      setState(() {
                        activeSli =
                            sli.copyWith(ingredientAmountNominal: Value(newVal));
                        totalAmount += diff;
                        _hasChanges = true;
                      });

                      await _recalculateAll();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(6.0),
                      child: Icon(Icons.add_circle_outline,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 14),

        // EINHEIT
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Einheit",
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white12,
                  border: Border.all(color: Colors.white24),
                ),
                child: DropdownButton<String>(
                  value: activeSli!.ingredientUnitCodeNominal,
                  dropdownColor: Colors.black87,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  isExpanded: true,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  items: allUnits
                      .map((u) => DropdownMenuItem(
                            value: u.code,
                            child: Text(u.label),
                          ))
                      .toList(),
                  onChanged: (v) async {
                    if (v != null) {
                      setState(() {
                        activeSli = activeSli!.copyWith(
                          ingredientUnitCodeNominal: Value(v),
                        );
                        activeUnit =
                            allUnits.firstWhere((u) => u.code == v);
                        _hasChanges = true;
                      });

                      await _recalculateAll();
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 14),

        // PREIS
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Preis",
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                priceText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------
  // Markt-Icon klein
  // ---------------------------------------------------------
  Widget _buildMarketIconSmall(int marketId) {
    return FutureBuilder<Market?>(
      future: (appDb.select(appDb.markets)
            ..where((m) => m.id.equals(marketId)))
          .getSingleOrNull(),
      builder: (context, snapshot) {
        final m = snapshot.data;

        if (!snapshot.hasData) {
          return const SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white24,
                ),
              ),
            ),
          );
        }

        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _parseHexColor(m?.color) ?? Colors.grey[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              m?.picture ?? "assets/images/shop/placeholder.png",
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------
  // Dialog – Ziel-Einkaufsliste
  // ---------------------------------------------------------
  Future<int?> _selectTargetShoppingList(int currentListId) async {
    final lists = await (appDb.select(appDb.shoppingList)
          ..where((t) => t.done.equals(false)))
        .get();

    final activeLists = lists.where((l) => l.id != currentListId).toList();

    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text("In welche Einkaufsliste?",
              style: TextStyle(color: Colors.white)),
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
                          horizontal: 10, vertical: 12),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(sl.name,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16)),
                          ),
                          if (sl.marketId != null)
                            _buildMarketIconSmall(sl.marketId!),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                GestureDetector(
                  onTap: () async {
                    final newListId = await _createShoppingListFlow();
                    if (newListId != null) {
                      Navigator.pop(ctx, newListId);
                    }
                  },
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const Text(
                      "+ Neue Einkaufsliste erstellen",
                      style:
                          TextStyle(color: Colors.white70, fontSize: 16),
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

  // ---------------------------------------------------------
  // Neue Einkaufsliste erstellen Flow
  // ---------------------------------------------------------
  Future<int?> _createShoppingListFlow() async {
    DateTime selectedDate = DateTime.now();

    final pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.black87,
              title: const Text("Datum wählen",
                  style: TextStyle(color: Colors.white)),
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
                    firstDate: DateTime.now()
                        .subtract(const Duration(days: 365)),
                    lastDate: DateTime.now()
                        .add(const Duration(days: 365)),
                    onDateChanged: (d) {
                      setStateDialog(() => selectedDate = d);
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Abbrechen",
                      style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, selectedDate),
                  child: const Text("Weiter",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );

    if (pickedDate == null) return null;

    final date = pickedDate;

    final markets = await appDb.select(appDb.markets).get();

    if (markets.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Keine Märkte vorhanden.")));
      }
      return null;
    }

    Market? defaultMarket;

    final fav = markets.where((m) => m.favorite == true).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    defaultMarket = fav.isNotEmpty ? fav.first : markets.first;

    final chosenMarket = await showDialog<Market>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text("Markt wählen",
              style: TextStyle(color: Colors.white)),
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
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color:
                                _parseHexColor(m.color) ?? Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              m.picture ??
                                  "assets/images/shop/placeholder.png",
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
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

    final newId = await appDb.into(appDb.shoppingList).insert(
          ShoppingListCompanion.insert(
            name: name,
            dateCreated: Value(DateTime.now()),
            lastEdited: Value(DateTime.now()),
            marketId: Value(market.id),
            dateShopping: Value(date),
          ),
        );

    return newId;
  }

  // ---------------------------------------------------------
  // Produkt wählen
  // ---------------------------------------------------------
  Future<void> _openProductSelection() async {
    if (ingredient == null || activeSli == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListProductScreen(
          ingredient: ingredient!,
          currentProductId: activeSli!.productIdNominal,
          shoppingListIngredientId: activeSli!.id,
          ingredientAmountNominal:
              activeSli!.ingredientAmountNominal ?? 0,
          ingredientUnitCodeNominal:
              activeSli!.ingredientUnitCodeNominal ?? "",
        ),
      ),
    );

    if (result == null) return;

    if (result is Product) {
      final updated = activeSli!.copyWith(
        productIdNominal: Value(result.id),
        ingredientMarketIdNominal: const Value(null),
        ingredientMarketAmountNominal: const Value(null),
      );

      setState(() {
        activeSli = updated;
        _hasChanges = true;
      });

      await _recalculateAll();

      await appDb.update(appDb.shoppingListIngredient).replace(activeSli!);
      return;
    }

    if (result is IngredientMarketData) {
      final updated = activeSli!.copyWith(
        ingredientMarketIdNominal: Value(result.id),
        productIdNominal: const Value(null),
        productAmountNominal: const Value(null),
      );

      setState(() {
        activeSli = updated;
        _hasChanges = true;
      });

      await _recalculateAll();
      await appDb.update(appDb.shoppingListIngredient).replace(activeSli!);
      return;
    }
  }

  // ---------------------------------------------------------
  // IngredientMarket wählen
  // ---------------------------------------------------------
  Future<void> _openIngredientMarketSelection() async {
    if (ingredient == null || activeSli == null) return;

    final selectedIm = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListProductScreen(
          ingredient: ingredient!,
          currentProductId: activeSli!.productIdNominal,
          shoppingListIngredientId: activeSli!.id,
          ingredientAmountNominal:
              activeSli!.ingredientAmountNominal ?? 0,
          ingredientUnitCodeNominal:
              activeSli!.ingredientUnitCodeNominal ?? "",
        ),
      ),
    );

    if (selectedIm == null || selectedIm is! IngredientMarketData) return;

    final freshSli = await (appDb.select(appDb.shoppingListIngredient)
          ..where((t) => t.id.equals(activeSli!.id)))
        .getSingle();

    setState(() {
      activeSli = freshSli;
      _hasChanges = true;
    });

    await _recalculateAll();
  }

  // ---------------------------------------------------------
  // Alternative Zutat wählen (ändert IngredientIdNominal)
  // ---------------------------------------------------------
  Future<void> _openAlternativeSelection() async {
    if (ingredient == null || activeSli == null) return;

    final selected = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShoppingListAlternativeScreen(
          ingredient: ingredient!,
        ),
      ),
    );

    if (selected == null || selected is! Ingredient) return;

    final old = activeSli!;

    final updated = old.copyWith(
      ingredientIdNominal: Value(selected.id),
      productIdNominal: const Value(null),
      ingredientMarketIdNominal: const Value(null),
      productAmountNominal: const Value(null),
      ingredientMarketAmountNominal: const Value(null),
      price: const Value(null),
    );

    await appDb.update(appDb.shoppingListIngredient).replace(updated);

    if (updated.shoppingListId != null &&
        updated.ingredientIdNominal != null) {
      final selection = await resolveNominalForIngredient(
        updated.ingredientIdNominal!,
        updated.shoppingListId!,
        updated.ingredientUnitCodeNominal,
        updated.ingredientAmountNominal,
      );

      await (appDb.update(appDb.shoppingListIngredient)
            ..where((t) => t.id.equals(updated.id)))
          .write(
        ShoppingListIngredientCompanion(
          productIdNominal: Value(selection.productId),
          ingredientMarketIdNominal: Value(selection.ingredientMarketId),
          productAmountNominal: Value(
            selection.productId != null
                ? updated.ingredientAmountNominal
                : null,
          ),
          ingredientMarketAmountNominal: Value(
            selection.ingredientMarketId != null
                ? updated.ingredientAmountNominal
                : null,
          ),
        ),
      );
    }

    await recalculateNominalsForSLI(updated.id);

    final fresh = await (appDb.select(appDb.shoppingListIngredient)
          ..where((t) => t.id.equals(updated.id)))
        .getSingle();

    setState(() {
      activeSli = fresh;
      ingredient = selected;
      _hasChanges = true;
    });

    await _recalculateAll();
  }

  // ---------------------------------------------------------
  // Löschen
  // ---------------------------------------------------------
  Future<void> _confirmDelete() async {
    if (activeSli == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text("Wirklich löschen?",
              style: TextStyle(color: Colors.white)),
          content: const Text(
            "Dieser Eintrag wird dauerhaft aus dieser Einkaufsliste entfernt.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Abbrechen",
                  style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Löschen",
                  style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final id = activeSli!.id;

    await (appDb.delete(appDb.shoppingListIngredient)
          ..where((tbl) => tbl.id.equals(id)))
        .go();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // ---------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (ingredient == null || activeSli == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final img = (ingredient!.picture == null ||
            ingredient!.picture!.isEmpty)
        ? "assets/images/placeholder.jpg"
        : ingredient!.picture!;

    final singular = ingredient!.singular?.trim().isNotEmpty == true
        ? ingredient!.singular!
        : ingredient!.name;

    final unitLabel =
        activeUnit?.label ?? activeSli!.ingredientUnitCodeNominal ?? "";

    final displayName = totalAmount == 1 ? singular : ingredient!.name;

    final totalFormatted = totalAmount.toStringAsFixed(
        totalAmount % 1 == 0 ? 0 : 1);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(displayName),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              img,
              width: MediaQuery.of(context).size.width / 3,
              height: MediaQuery.of(context).size.width / 3,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            "$totalFormatted $unitLabel $displayName",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 15),
            child: Container(
              height: 1.2,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // -----------------------------------------------------
          // HORIZONTALE REZEPTLISTE
          // -----------------------------------------------------
          SizedBox(
            height: 94,
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.horizontal,
              onPageChanged: _switchActive,
              itemCount: allSli.length,
              itemBuilder: (context, index) {
                final sli = allSli[index];

                final recipe = recipes.firstWhere(
                  (r) => r.id == (sli.recipeId ?? -1),
                  orElse: () => Recipe(
                    id: 0,
                    name: "Mit keinem Rezept verknüpft",
                    recipeCategory: 0,
                    picture: null,
                    portionNumber: null,
                    portionUnit: null,
                    cookCounter: 0,
                    favorite: 0,
                    bookmark: 0,
                    lastCooked: null,
                    lastUpdated: null,
                    inspiredBy: null,
                    description: null,
                    tip: null,
                  ),
                );

                final rImg = (recipe.picture == null ||
                        recipe.picture!.isEmpty)
                    ? 'assets/images/placeholder.jpg'
                    : recipe.picture!;

                final bool isActive = (index == activePage);

                return Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? Colors.white.withOpacity(0.15)
                            : Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 45,
                            height: 45,
                            color: Colors.black,
                            child: Image.asset(
                              rImg,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            recipe.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        recipe.bookmark == 1
                            ? const Icon(Icons.bookmark, color: Colors.white)
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // -----------------------------------------------------
          // EDITIERBARER UNTERER BEREICH
          // -----------------------------------------------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildEditableSection(),
                  const SizedBox(height: 28),

                  _actionButton("Produkt wählen", Colors.transparent,
                      _openProductSelection),

                  const SizedBox(height: 10),

                  _actionButton("Alternative wählen", Colors.transparent,
                      _openAlternativeSelection),

                  const SizedBox(height: 10),

                  _actionButton("Auf anderen Einkauf verschieben",
                      Colors.transparent, () async {
                    if (activeSli == null ||
                        activeSli!.shoppingListId == null) return;

                    final currentListId = activeSli!.shoppingListId!;
                    final newListId =
                        await _selectTargetShoppingList(currentListId);

                    if (newListId == null) return;

                    await _moveSingleSliToList(
                      sliId: activeSli!.id,
                      sourceListId: currentListId,
                      targetListId: newListId,
                    );

                    if (!mounted) return;

                    Navigator.pop(context);
                  }),

                  const SizedBox(height: 10),

                  _actionButton("Löschen", Colors.transparent, _confirmDelete),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      // -----------------------------------------------------
      // SPEICHERN-BUTTON
      // -----------------------------------------------------
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        offset: _hasChanges ? Offset.zero : const Offset(0, 1),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              height: 48,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkgreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _hasChanges ? _saveChanges : null,
                child: const Text(
                  "Änderungen speichern",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  // Änderungen speichern
  // ---------------------------------------------------------
  Future<void> _saveChanges() async {
    if (activeSli == null) return;

    await appDb.update(appDb.shoppingListIngredient).replace(activeSli!);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  // ---------------------------------------------------------
  // Action Buttons
  // ---------------------------------------------------------
  Widget _actionButton(
      String text, Color color, VoidCallback onTap) {
    final bool isDelete = (text == "Löschen");

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B0B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDelete
                ? Colors.redAccent
                : Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
