// lib/screens/shopping/shopping_list_product.dart
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;
import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/services/unit_conversion_service.dart';
import 'package:planty_flutter_starter/services/ingredient_market_conversion_service.dart';

class ShoppingListProductScreen extends StatefulWidget {
  final Ingredient ingredient;
  final int? currentProductId;
  final int shoppingListIngredientId;
  final double ingredientAmountNominal;
  final String ingredientUnitCodeNominal;

  const ShoppingListProductScreen({
    super.key,
    required this.ingredient,
    required this.shoppingListIngredientId,
    required this.ingredientAmountNominal,
    required this.ingredientUnitCodeNominal,
    this.currentProductId,
  });

  @override
  State<ShoppingListProductScreen> createState() =>
      _ShoppingListProductScreenState();
}

class _ShoppingListProductScreenState
    extends State<ShoppingListProductScreen> {
  Product? currentProduct;
  IngredientMarketData? currentIngredientMarket;

  List<Product> products = [];
  List<IngredientMarketData> ingredientMarkets = [];

  ShoppingListIngredientData? _sli;
  ShoppingListData? _shoppingList;
  Market? _market;

  Map<int, Ingredient> _ingredientMap = {};

  String formatAmount(double? value) {
    if (value == null) return "";
    if (value % 1 == 0) return value.toInt().toString();
    return value.toString();
  }

  late final UnitConversionService conversionService;
  late final IngredientMarketConversionService ingredientMarketConversionService;

  @override
  void initState() {
    super.initState();
    conversionService = UnitConversionService(appDb);
    ingredientMarketConversionService = IngredientMarketConversionService(appDb);
    _load();
  }

  Future<void> _load() async {
    final sli = await (appDb.select(appDb.shoppingListIngredient)
          ..where((t) => t.id.equals(widget.shoppingListIngredientId)))
        .getSingle();

    final shoppingList = await (appDb.select(appDb.shoppingList)
          ..where((s) => s.id.equals(sli.shoppingListId)))
        .getSingle();

    Market? market;
    if (shoppingList.marketId != null) {
      market = await (appDb.select(appDb.markets)
            ..where((m) => m.id.equals(shoppingList.marketId!)))
          .getSingleOrNull();
    }

    final altIngredientLinks = await (appDb.select(appDb.ingredientAlternatives)
          ..where((ia) => ia.ingredientId.equals(widget.ingredient.id))
          ..where((ia) => ia.alternativesId.equals(4)))
        .get();

    final alternativeIngredientIds =
        altIngredientLinks.map((ia) => ia.relatedIngredientId).toSet();

    final ingList = await appDb.select(appDb.ingredients).get();
    _ingredientMap = {for (final ing in ingList) ing.id: ing};

    Product? curProduct;
    final int? effectiveCurrentProductId =
        widget.currentProductId ?? sli.productIdNominal;

    if (effectiveCurrentProductId != null) {
      curProduct = await (appDb.select(appDb.products)
            ..where((p) => p.id.equals(effectiveCurrentProductId)))
          .getSingleOrNull();
    }

    IngredientMarketData? curIngMarket;
    if (sli.ingredientMarketIdNominal != null) {
      curIngMarket = await (appDb.select(appDb.ingredientMarket)
            ..where((im) => im.id.equals(sli.ingredientMarketIdNominal!)))
          .getSingleOrNull();
    }

    final allIngredientIds = {widget.ingredient.id, ...alternativeIngredientIds};

    final prodList = await (appDb.select(appDb.products)
          ..where((p) => p.ingredientId.isIn(allIngredientIds)))
        .get();

    List<Product> filteredProducts = prodList;

    if (market != null) {
  final pmList = await (appDb.select(appDb.productMarkets)
        ..where((pm) => pm.marketId.equals(market!.id)))
      .get();


      final allowedIds = pmList.map((pm) => pm.productsId).toSet();

      filteredProducts =
          prodList.where((p) => allowedIds.contains(p.id)).toList();
    }

    final ingMarketQuery = appDb.select(appDb.ingredientMarket)
      ..where((im) => im.ingredientId.isIn(allIngredientIds));

    if (market != null) {
  ingMarketQuery.where((im) => im.marketId.equals(market!.id));
}


    final ingMarkets = await ingMarketQuery.get();

    setState(() {
      _sli = sli;
      _shoppingList = shoppingList;
      _market = market;
      currentProduct = curProduct;
      currentIngredientMarket = curIngMarket;
      products = filteredProducts;
      ingredientMarkets = ingMarkets;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;
    final hasCurrentProduct = currentProduct != null;
    final hasCurrentIngredientMarket = currentIngredientMarket != null;
    final hasCurrentSelection =
        hasCurrentProduct || hasCurrentIngredientMarket;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Produkt / Marktware wählen"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Auswahl für",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            _ingredientBox(ing),
            const SizedBox(height: 28),

            if (hasCurrentProduct) ...[
              const Text(
                "Aktuell ausgewählt",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              _productBox(currentProduct!, isTapable: true),
              const SizedBox(height: 24),
            ],

            if (hasCurrentIngredientMarket) ...[
              const Text(
                "Aktuell ausgewählt",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              _ingredientMarketBox(currentIngredientMarket!, isTapable: true),
              const SizedBox(height: 28),
            ],

            Text(
              hasCurrentSelection
                  ? "Alternativen"
                  : "Auswählen",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 8),

            if (products.isEmpty && ingredientMarkets.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(
                    "Keine Produkte oder Marktware vorhanden.",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),

            ...products
                .where((p) =>
                    currentProduct == null || p.id != currentProduct!.id)
                .map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _productBox(p, isTapable: true),
                    )),

            ...ingredientMarkets
                .where((im) =>
                    currentIngredientMarket == null ||
                    im.id != currentIngredientMarket!.id)
                .map((im) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ingredientMarketBox(im, isTapable: true),
                    )),
          ],
        ),
      ),
    );
  }

  Widget _ingredientBox(Ingredient ing) {
    final img = (ing.picture == null || ing.picture!.isEmpty)
        ? "assets/images/placeholder.jpg"
        : ing.picture!;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
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
                img,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ing.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
    );
  }

  Widget _productBox(Product p, {bool isTapable = false}) {
    final img =
        (p.image == null || p.image!.isEmpty) ? "assets/images/placeholder.jpg" : p.image!;
    final market = _market;

    final content = Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
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
              child: Image.asset(img, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                if (p.sizeUnitCode != null &&
                    p.sizeUnitCode!.isNotEmpty &&
                    p.yieldAmount != null &&
                    p.yieldUnitCode != null &&
                    p.yieldUnitCode!.isNotEmpty)
                  Text(
                    "${p.sizeUnitCode}-Inhalt: ${formatAmount(p.yieldAmount)} ${p.yieldUnitCode}",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),

          Row(
            children: [
              if (p.bio == true)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      -1, 0, 0, 0, 255,
                       0,-1, 0, 0, 255,
                       0, 0,-1, 0, 255,
                       0, 0, 0, 1,   0,
                    ]),
                    child: Image.asset(
                      "assets/images/icons/bio.png",
                      height: 18,
                    ),
                  ),
                ),
              SizedBox(width: 90, child: _productPriceWidget(p, market)),
            ],
          ),
        ],
      ),
    );

    if (!isTapable) return content;

    return InkWell(
      child: content,
      onTap: () async {
        if (_sli == null) return;

        final amount =
            await conversionService.calculateProductAmountNominal(
          ingredientIdNominal: widget.ingredient.id,
          ingredientAmountNominal: widget.ingredientAmountNominal,
          ingredientUnitCodeNominal: widget.ingredientUnitCodeNominal,
          product: p,
        );

        await appDb.into(appDb.shoppingListIngredient).insertOnConflictUpdate(
              ShoppingListIngredientCompanion(
                id: d.Value(widget.shoppingListIngredientId),
                shoppingListId: d.Value(_sli!.shoppingListId),
                ingredientIdNominal: d.Value(_sli!.ingredientIdNominal),
                ingredientAmountNominal: d.Value(_sli!.ingredientAmountNominal),
                ingredientUnitCodeNominal:
                    d.Value(_sli!.ingredientUnitCodeNominal),
                productIdNominal: d.Value(p.id),
                productAmountNominal: d.Value(amount),
                ingredientMarketIdNominal: const d.Value(null),
                ingredientMarketAmountNominal: const d.Value(null),
              ),
            );

        if (mounted) Navigator.pop(context, p);
      },
    );
  }

  Widget _productPriceWidget(Product p, Market? market) {
    if (market == null) return const SizedBox.shrink();

    return FutureBuilder<ProductMarket?>(
      future: (appDb.select(appDb.productMarkets)
            ..where((pm) => pm.productsId.equals(p.id))
            ..where((pm) => pm.marketId.equals(market.id))
            ..orderBy([
              (pm) => d.OrderingTerm(
                    expression: pm.date,
                    mode: d.OrderingMode.desc,
                  )
            ]))
          .getSingleOrNull(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final pm = snapshot.data;

        if (pm == null || pm.price == null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.do_not_disturb, color: Colors.redAccent),
              const SizedBox(height: 2),
              Text(
                'bei "${market.name}"\nnicht im Sortiment',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ],
          );
        }

        final priceStr = pm.price!.toStringAsFixed(2).replaceAll('.', ',');

        return Text(
          "$priceStr €",
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        );
      },
    );
  }

  Widget _ingredientMarketBox(IngredientMarketData im,
      {bool isTapable = false}) {
    final ingredient = _ingredientMap[im.ingredientId]!;

    final displayName =
        (im.name != null && im.name!.trim().isNotEmpty) ? im.name! : ingredient.name;

    final img = (ingredient.picture == null || ingredient.picture!.isEmpty)
        ? "assets/images/placeholder.jpg"
        : ingredient.picture!;

    final market = _market;

    final content = Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
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
              child: Image.asset(img, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),

                Builder(builder: (_) {
                  if (im.unitAmount == null ||
                      im.unitCode == null ||
                      im.unitCode!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final base = "${formatAmount(im.unitAmount)} ${im.unitCode}";

                  if (im.packageUnitCode == null ||
                      im.packageUnitCode!.isEmpty) {
                    return Text(
                      base,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    );
                  }

                  return Text(
                    "${im.packageUnitCode}-Inhalt: $base",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  );
                }),
              ],
            ),
          ),

          Row(
            children: [
              if (im.bio == true)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix([
                      -1, 0, 0, 0, 255,
                       0,-1, 0, 0, 255,
                       0, 0,-1, 0, 255,
                       0, 0, 0, 1,   0,
                    ]),
                    child: Image.asset(
                      "assets/images/icons/bio.png",
                      height: 18,
                    ),
                  ),
                ),

              SizedBox(
                width: 90,
                child: Builder(
                  builder: (_) {
                    if (im.price == null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Icon(Icons.do_not_disturb,
                              color: Colors.redAccent),
                          const SizedBox(height: 2),
                          Text(
                            market != null
                                ? 'bei "${market.name}"\nkein Preis'
                                : 'kein Preis',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 10,
                            ),
                          )
                        ],
                      );
                    }

                    final priceStr =
                        im.price!.toStringAsFixed(2).replaceAll('.', ',');

                    return Text(
                      "$priceStr €",
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ],
      ),
    );

    if (!isTapable) return content;

    return InkWell(
      child: content,
      onTap: () async {
        if (_sli == null) return;

        final amount =
            await ingredientMarketConversionService
                .calculateIngredientMarketAmountNominal(
          ingredientId: widget.ingredient.id,
          ingredientAmountNominal: widget.ingredientAmountNominal,
          ingredientUnitCodeNominal: widget.ingredientUnitCodeNominal,
          ingredientMarket: im,
        );

        await appDb.into(appDb.shoppingListIngredient).insertOnConflictUpdate(
              ShoppingListIngredientCompanion(
                id: d.Value(widget.shoppingListIngredientId),
                shoppingListId: d.Value(_sli!.shoppingListId),
                ingredientIdNominal: d.Value(_sli!.ingredientIdNominal),
                ingredientAmountNominal:
                    d.Value(_sli!.ingredientAmountNominal),
                ingredientUnitCodeNominal:
                    d.Value(_sli!.ingredientUnitCodeNominal),
                productIdNominal: const d.Value(null),
                productAmountNominal: const d.Value(null),
                ingredientMarketIdNominal: d.Value(im.id),
                ingredientMarketAmountNominal: d.Value(amount),
              ),
            );

        if (mounted) Navigator.pop(context, im);
      },
    );
  }
}
