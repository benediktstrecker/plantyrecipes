// lib/screens/recipe/recipe_ingredient.dart
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:drift/drift.dart' as d;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:planty_flutter_starter/utils/number_formatter.dart';

// Navigation
import 'package:planty_flutter_starter/utils/easy_swipe_nav.dart';

// DB
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

// Layout / Farben (darkgreen)
import 'package:planty_flutter_starter/design/layout.dart';

// Weitere Recipe-Screens
import 'package:planty_flutter_starter/screens/recipe/recipe_detail.dart' as det;
import 'package:planty_flutter_starter/screens/recipe/recipe_preparation.dart'
    as prep;
import 'package:planty_flutter_starter/screens/recipe/recipe_nutrient.dart'
    as nutr;

import 'package:planty_flutter_starter/screens/ingredient/ingredient_detail.dart';
import 'package:planty_flutter_starter/screens/shopping/shopping_list_overview.dart';

import 'package:planty_flutter_starter/services/ingredient_nominal_selection.dart';

import 'package:planty_flutter_starter/widgets/create_shopping_list_flow.dart';


class RecipeIngredientScreen extends StatefulWidget {
  final int recipeId;
  final String title;
  final String? imagePath;

  // NEU → Autoselect-Trigger
  final bool autoSelectNonStorageCat1;

  const RecipeIngredientScreen({
    super.key,
    required this.recipeId,
    required this.title,
    this.imagePath,
    this.autoSelectNonStorageCat1 = false,
  });


  @override
  State<RecipeIngredientScreen> createState() =>
      _RecipeIngredientScreenState();
}

class _RecipeIngredientScreenState extends State<RecipeIngredientScreen>
    with EasySwipeNav<RecipeIngredientScreen> {
  @override
  int get currentIndex => _selectedIndex;

  int _selectedIndex = 1;
  int _viewMode = 4;
  int _sortMode = 1;

  int? _portionNumber;
  int? _basePortionNumber;
  String? _portionUnitLabel;
  String? _portionUnitPlural;

  final ScrollController _scrollController = ScrollController();

  // Auswahl-Logik
  bool _selectionMode = false;
  final Set<int> _selectedIngredientIds = {};

  // Slide-Up-Bar Logik
  final ValueNotifier<int> _selectedCount = ValueNotifier<int>(0);
  bool _showListSelector = false;

  bool get _swipeEnabled => !_selectionMode && !_showListSelector;

  @override
void initState() {
  super.initState();
  _loadViewMode().then((m) => setState(() => _viewMode = m));
  _loadSortMode().then((m) => setState(() => _sortMode = m));
  _loadPortionInfo();

  if (widget.autoSelectNonStorageCat1) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Zutaten stream EINMAL laden (korrekt!)
      final ingredients =
          await _watchIngredients(widget.recipeId).firstWhere((l) => l.isNotEmpty);

      setState(() {
        for (final ing in ingredients) {
          if (ing.storageCatId != 1) {
            _selectedIngredientIds.add(ing.recipeIngredientId);
          }
        }

        _selectionMode = _selectedIngredientIds.isNotEmpty;
        _updateSelectionState();
        _showListSelector = true; // Slide-Up öffnen
      });
    });
  }
}


  @override
  void dispose() {
    _scrollController.dispose();
    _selectedCount.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // Portionen laden / ändern
  // ----------------------------------------------------------
  Future<void> _loadPortionInfo() async {
    final r = appDb.recipes;
    final u = appDb.units;

    final query = (appDb.select(r)
          ..where((tbl) => tbl.id.equals(widget.recipeId)))
        .join([
      d.leftOuterJoin(u, u.code.equalsExp(r.portionUnit)),
    ]);

    final row = await query.getSingleOrNull();
    if (row == null) return;

    final rec = row.readTable(r);
    final unit = row.readTableOrNull(u);

    setState(() {
      _portionNumber = rec.portionNumber ?? 1;
      _basePortionNumber = rec.portionNumber ?? 1;
      _portionUnitLabel = unit?.label ?? rec.portionUnit;
      _portionUnitPlural = unit?.plural ?? unit?.label ?? rec.portionUnit;
    });
  }

  void _changePortion(int delta) {
    final newValue = (_portionNumber ?? 1) + delta;
    if (newValue < 1) return;
    setState(() => _portionNumber = newValue);
  }

  // ----------------------------------------------------------
  // View-/Sortier-Modus persistieren
  // ----------------------------------------------------------
  Future<void> _saveViewMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('recipe_ing_view_mode', mode);
  }

  Future<int> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('recipe_ing_view_mode') ?? 3;
  }

  Future<void> _saveSortMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('recipe_ing_sort_mode', mode);
  }

  Future<int> _loadSortMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('recipe_ing_sort_mode') ?? 1;
  }

  void _toggleViewMode() {
    setState(() {
      _viewMode = (_viewMode % 5) + 1;
    });
    _saveViewMode(_viewMode);
  }

  void _toggleSortMode() {
    setState(() {
      _sortMode = (_sortMode % 2) + 1;
    });
    _saveSortMode(_sortMode);
  }

  IconData get _viewIcon {
    switch (_viewMode) {
      case 1:
        return Icons.view_headline;
      case 2:
        return Icons.list;
      case 3:
        return Icons.window_outlined;
      case 4:
        return Icons.grid_on;
      case 5:
        return Icons.view_compact_outlined;
      default:
        return Icons.grid_on;
    }
  }

  IconData get _sortIcon {
    switch (_sortMode) {
      case 1:
        return Icons.onetwothree;
      case 2:
        return Icons.sort_by_alpha;
      default:
        return Icons.onetwothree;
    }
  }

  // ----------------------------------------------------------
  // Navigation Tabs
  // ----------------------------------------------------------
  void _navigateToPage(int index) {
    if (!mounted || index == _selectedIndex) return;
    if (index < 0 || index > 3) return;

    final fromRight = index > _selectedIndex;
    final next = _widgetForIndex(index);

    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (_, __, ___) => next,
      transitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, __, child) {
        final begin = fromRight ? const Offset(1, 0) : const Offset(-1, 0);
        final tween = Tween(begin: begin, end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOut));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ));
    setState(() => _selectedIndex = index);
  }

  Widget _widgetForIndex(int index) {
    switch (index) {
      case 0:
        return det.RecipeDetailScreen(
          recipeId: widget.recipeId,
          title: widget.title,
          imagePath: widget.imagePath,
        );
      case 1:
  return RecipeIngredientScreen(
    recipeId: widget.recipeId,
    title: widget.title,
    imagePath: widget.imagePath,
    autoSelectNonStorageCat1: widget.autoSelectNonStorageCat1,  // WICHTIG
  );

      case 2:
        return prep.RecipePreparationScreen(
          recipeId: widget.recipeId,
          title: widget.title,
          imagePath: widget.imagePath,
        );
      case 3:
      default:
        return nutr.RecipeNutrientScreen(
          recipeId: widget.recipeId,
          title: widget.title,
          imagePath: widget.imagePath,
        );
    }
  }

  @override
  void goToIndex(int index) => _navigateToPage(index);

  // ----------------------------------------------------------
  // DB: Zutaten + StorageCategories
  // ----------------------------------------------------------
  Stream<List<_RecipeIngredientDisplay>> _watchIngredients(int recipeId) {
    final ri = appDb.recipeIngredients;
    final ing = appDb.ingredients;
    final u = appDb.units;
    final sc = appDb.storageCategories;

    final query = (appDb.select(ri)
          ..where((r) => r.recipeId.equals(recipeId)))
        .join([
      d.innerJoin(ing, ing.id.equalsExp(ri.ingredientId)),
      d.innerJoin(u, u.code.equalsExp(ri.unitCode)),
      d.leftOuterJoin(sc, sc.id.equalsExp(ing.storagecatId)),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final riRow = row.readTable(ri);
        final ingRow = row.readTable(ing);
        final unitRow = row.readTable(u);
        final scRow = row.readTableOrNull(sc);

        return _RecipeIngredientDisplay(
          recipeIngredientId: riRow.id,
          id: ingRow.id,
          name: ingRow.name,
          image: ingRow.picture ?? 'assets/images/placeholder.jpg',
          amount: riRow.amount,
          unitCode: riRow.unitCode,
          unitLabel: unitRow.label,
          unitSingular: unitRow.label,
          unitPlural: unitRow.plural ?? unitRow.label,
          ingredientSingular: ingRow.singular,
          ingredientPlural: ingRow.name,
          storageCatId: scRow?.id,
          storageCatDescription: scRow?.description ?? 'Sonstige',
          storageCatColor: scRow?.color,
          isSelected: false,
        );
      }).toList();
    });
  }

  // ----------------------------------------------------------
// Einkaufslisten (ShoppingList)
// ----------------------------------------------------------
Future<List<ShoppingListData>> _loadShoppingLists() async {
  final sl = appDb.shoppingList;
  return (appDb.select(sl)..where((tbl) => tbl.done.equals(false))).get();
}

// Lieblings-Markt mit kleinster ID laden
Future<int?> _loadDefaultMarketId() async {
  final m = appDb.markets;

  final query = (appDb.select(m)
        ..where((t) => t.favorite.equals(true))
        ..orderBy([
          (t) => d.OrderingTerm(expression: t.id),
        ])
        ..limit(1) // WICHTIG: limit MUSS hier rein!
      );

  final fav = await query.getSingleOrNull();
  return fav?.id;
}


Future<void> _addSelectedIngredientsToList(int shoppingListId) async {
  final ri = appDb.recipeIngredients;
  final slIng = appDb.shoppingListIngredient;

  // Aktuelle Portionen
  final factor = (_portionNumber ?? 1) / (_basePortionNumber ?? 1);

  // 1. Alle ausgewählten RecipeIngredient-IDs laden
  final selected = _selectedIngredientIds.toList();
  if (selected.isEmpty) return;

  for (final rid in selected) {
    // RecipeIngredient + Ingredient + Unit laden
    final row = await ((appDb.select(ri)
              ..where((tbl) => tbl.id.equals(rid)))
            .join([
      d.innerJoin(
          appDb.ingredients, appDb.ingredients.id.equalsExp(ri.ingredientId)),
      d.innerJoin(appDb.units, appDb.units.code.equalsExp(ri.unitCode)),
    ]))
        .getSingle();

    final riRow = row.readTable(ri);
    final ingRow = row.readTable(appDb.ingredients);

    // Menge skalieren
    final scaledAmount = (riRow.amount * factor);

    // NEU: Vorauswahl product_id_nominal / ingredient_market_id_nominal
    
    final selection = await resolveNominalForIngredient(
      ingRow.id,
      shoppingListId,
      riRow.unitCode,       // ingredient_unit_code_nominal
      scaledAmount,         // ingredient_amount_nominal
    );

    // 2. Eintrag schreiben (mit Vorauswahl)
    final sliId = await appDb.into(slIng).insert(
  ShoppingListIngredientCompanion(
    shoppingListId: d.Value(shoppingListId),

    recipeId: d.Value(widget.recipeId),
    recipePortionNumberId: d.Value(_portionNumber),

    ingredientIdNominal: d.Value(ingRow.id),
    ingredientAmountNominal: d.Value(scaledAmount),
    ingredientUnitCodeNominal: d.Value(riRow.unitCode),

    productIdNominal: d.Value(selection.productId),
    productAmountNominal: d.Value(
      selection.productId != null ? scaledAmount : null,
    ),

    ingredientMarketIdNominal: d.Value(selection.ingredientMarketId),
    ingredientMarketAmountNominal: d.Value(
      selection.ingredientMarketId != null ? scaledAmount : null,
    ),

    basket: const d.Value(false),
    bought: const d.Value(false),
  ),
);

// WICHTIG: Jetzt die Neuberechnung triggern!
await recalculateNominalsForSLI(sliId);

  }

  // Auswahl löschen + UI schließen
  setState(() {
    _selectedIngredientIds.clear();
    _selectionMode = false;
    _showListSelector = false;
    _updateSelectionState();
  });
}


  void _updateSelectionState() {
    _selectedCount.value = _selectedIngredientIds.length;
    if (_selectedIngredientIds.isEmpty) {
      _selectionMode = false;
      _showListSelector = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeId = widget.recipeId;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _swipeEnabled ? onSwipeStart : null,
      onHorizontalDragUpdate: _swipeEnabled ? onSwipeUpdate : null,
      onHorizontalDragEnd: _swipeEnabled ? onSwipeEnd : null,
      child: WillPopScope(
        onWillPop: () async {
          // 1) Slide-Up offen? → nur schließen
          if (_showListSelector) {
            setState(() => _showListSelector = false);
            return false;
          }

          // 2) Zutaten ausgewählt? → Auswahl löschen
          if (_selectedIngredientIds.isNotEmpty) {
            setState(() {
              _selectedIngredientIds.clear();
              _selectionMode = false;
              _updateSelectionState();
            });
            return false;
          }

          // 3) Sonst normal zurück
          return true;
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            actions: [
              /*IconButton(
                tooltip: 'Sortierung ändern',
                onPressed: _toggleSortMode,
                icon: Icon(_sortIcon, color: Colors.white),
              ),*/
              IconButton(
                tooltip: 'Ansicht wechseln',
                onPressed: _toggleViewMode,
                icon: Icon(_viewIcon, color: Colors.white),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  // -------------------------------------
                  // PORTIONEN
                  // -------------------------------------
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Container(
                      decoration: BoxDecoration(
                        color: darkgreen,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1A1A1A)),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${_portionNumber ?? 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                (_portionNumber ?? 1) <= 1
                                    ? (_portionUnitLabel ?? '')
                                    : (_portionUnitPlural ??
                                        _portionUnitLabel ??
                                        ''),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _changePortion(-1),
                                child: const Icon(Icons.remove_circle_outline,
                                    color: Colors.white70, size: 28),
                              ),
                              const SizedBox(width: 18),
                              InkWell(
                                onTap: () => _changePortion(1),
                                child: const Icon(Icons.add_circle_outline,
                                    color: Colors.white70, size: 28),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // -------------------------------------
                  // ZUTATEN-LISTEN / GRID
                  // -------------------------------------
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, anim) =>
                          FadeTransition(opacity: anim, child: child),
                      child: StreamBuilder<List<_RecipeIngredientDisplay>>(
                        key: ValueKey(_viewMode),
                        stream: _watchIngredients(recipeId),
                        builder: (context, snapshot) {
                          final data = snapshot.data ?? [];
                          if (data.isEmpty) {
                            return const Center(
                              child: Text(
                                'Keine Zutaten vorhanden',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }

                          // Sortieren
                          var items =
                              List<_RecipeIngredientDisplay>.from(data);
                          switch (_sortMode) {
                            case 1:
                              items.sort((a, b) => a.recipeIngredientId
                                  .compareTo(b.recipeIngredientId));
                              break;
                            case 2:
                              items.sort((a, b) => a.name
                                  .toLowerCase()
                                  .compareTo(b.name.toLowerCase()));
                              break;
                          }

                          // Skalierung
                          final factor = (_portionNumber ?? 1) /
                              (_basePortionNumber ?? 1);
                          for (final i in items) {
                            i.scaledAmount = i.amount * factor;
                            i.isSelected = _selectedIngredientIds
                                .contains(i.recipeIngredientId);
                          }

                          // Gruppieren
                          final Map<String,
                              List<_RecipeIngredientDisplay>> grouped = {};
                          for (final ing in items) {
                            grouped
                                .putIfAbsent(
                                    ing.storageCatDescription, () => [])
                                .add(ing);
                          }

                          // Auswahlfunktionen
                          void toggleSelection(
                              _RecipeIngredientDisplay ing) {
                            setState(() {
                              if (_selectedIngredientIds
                                  .contains(ing.recipeIngredientId)) {
                                _selectedIngredientIds
                                    .remove(ing.recipeIngredientId);
                              } else {
                                _selectedIngredientIds
                                    .add(ing.recipeIngredientId);
                              }
                              _selectionMode =
                                  _selectedIngredientIds.isNotEmpty;
                              _updateSelectionState();
                            });
                          }

                          void handleItemTap(
                              _RecipeIngredientDisplay ing) {
                            if (_selectionMode) {
                              toggleSelection(ing);
                            } else {
                              Navigator.of(context).push(PageRouteBuilder(
                                transitionDuration:
                                    const Duration(milliseconds: 280),
                                reverseTransitionDuration:
                                    const Duration(milliseconds: 280),
                                pageBuilder: (_, __, ___) =>
                                    IngredientDetailScreen(
                                  ingredientId: ing.id,
                                  ingredientName: ing.name,
                                  imagePath: ing.image,
                                ),
                                transitionsBuilder:
                                    (_, animation, __, child) {
                                  final offsetAnimation =
                                      Tween<Offset>(
                                    begin: const Offset(0, 0.05),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ));
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: offsetAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                              ));
                            }
                          }

                          void handleItemLongPress(
                              _RecipeIngredientDisplay ing) {
                            setState(() {
                              _selectionMode = true;
                            });
                            toggleSelection(ing);
                          }

                          void handleGroupSelect(String catName) {
                            setState(() {
                              _selectionMode = true;
                              for (final ing in grouped[catName]!) {
                                _selectedIngredientIds
                                    .add(ing.recipeIngredientId);
                              }
                              _updateSelectionState();
                            });
                          }

                          return _GroupedByStorageView(
                            groupedItems: grouped,
                            viewMode: _viewMode,
                            scrollController: _scrollController,
                            onGroupSelect: handleGroupSelect,
                            onItemTap: handleItemTap,
                            onItemLongPress: handleItemLongPress,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // ---------------------------------------------------
              // BOTTOM BUTTON (X Zutaten zur Einkaufsliste hinzufügen)
              // ---------------------------------------------------
              ValueListenableBuilder<int>(
                valueListenable: _selectedCount,
                builder: (_, count, __) {
                  if (count == 0) return const SizedBox.shrink();

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    left: 0,
                    right: 0,
                    bottom: _showListSelector ? 260 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      color: Colors.black,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkgreen,
                          //foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          setState(() => _showListSelector = true);
                        },
                        child: Text(
                          "${count == 1 ? '1 Zutat' : '$count Zutaten'} zur Einkaufsliste hinzufügen",
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // ---------------------------------------------------
              // SLIDE-UP LIST SELECTOR
              // ---------------------------------------------------
              if (_showListSelector)
                FutureBuilder<List<ShoppingListData>>(
                  future: _loadShoppingLists(),
                  builder: (context, snapshot) {
                    final lists = snapshot.data ?? [];

                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 260,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0B0B0B),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(22),
                            topRight: Radius.circular(22),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 20,
                              offset: Offset(0, -6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    "In welche Einkaufsliste?",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white),
                                  onPressed: () {
                                    setState(() => _showListSelector =
                                        false);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView(
                                children: [
                                  for (final sl in lists)
                                    InkWell(
    onTap: () async {
      await _addSelectedIngredientsToList(sl.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Zur Einkaufsliste hinzugefügt"),
          backgroundColor: darkgreen,
          duration: const Duration(seconds: 2),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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

          // Market-Logo rechts (Zeilenhöhe nicht vergrößern)
          FutureBuilder<Market?>(
  future: (appDb.select(appDb.markets)
        ..where((m) => m.id.equals(sl.marketId ?? -1)))
      .getSingleOrNull(),
  builder: (_, snap) {
    final mk = snap.data;

    final imgPath = mk?.picture ?? "assets/images/placeholder.jpg";

    // Hintergrundfarbe aus DB
    Color bgColor;
    if (mk?.color != null) {
      String hex = mk!.color!.replaceAll('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      try {
        bgColor = Color(int.parse(hex, radix: 16));
      } catch (_) {
        bgColor = const Color(0xFF0B0B0B);
      }
    } else {
      bgColor = const Color(0xFF0B0B0B);
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.asset(
            imgPath,
            width: 22,   // 80% von 28px
            height: 22,
            fit: BoxFit.contain,  // wichtig: Bild NICHT beschneiden
          ),
        ),
      ),
    );
  },
),


        ],
      ),
    ),
  ),
                                  const SizedBox(height: 18),
                                  Divider(color: Colors.white24),
                                  const SizedBox(height: 18),
                                  InkWell(
 onTap: () async {
  final newListId = await CreateShoppingListFlow.start(context);

  if (newListId != null) {
    await _addSelectedIngredientsToList(newListId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Neue Liste erstellt + Zutaten hinzugefügt"),
        backgroundColor: darkgreen,
      ),
    );

    setState(() => _showListSelector = false);
  }
},

  child: const Text(
    "+ Neue Einkaufsliste erstellen",
    style: TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  ),
),

                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
            child: GNav(
              backgroundColor: Colors.black,
              tabBackgroundColor: const Color(0xFF0B0B0B),
              color: Colors.white70,
              activeColor: Colors.white,
              padding: const EdgeInsets.all(16),
              gap: 8,
              selectedIndex: _selectedIndex,
              onTabChange: _navigateToPage,
              tabs: const [
                GButton(icon: Icons.info_outline, text: 'Details'),
                GButton(icon: Icons.eco, text: 'Zutaten'),
                GButton(icon: Icons.local_dining, text: 'Zubereitung'),
                GButton(icon: Icons.stacked_bar_chart, text: 'Nährwerte'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------
// Anzeige: Zutaten-Datenmodell
// ----------------------------------------------------------
class _RecipeIngredientDisplay {
  final int recipeIngredientId;
  final int id;
  final String name;
  final String image;
  final double amount;
  double scaledAmount;
  final String unitCode;
  final String unitLabel;
  final String? unitSingular;
  final String? unitPlural;
  final String? ingredientSingular;
  final String ingredientPlural;

  final int? storageCatId;
  final String storageCatDescription;
  final String? storageCatColor;

  bool isSelected;

  _RecipeIngredientDisplay({
    required this.recipeIngredientId,
    required this.id,
    required this.name,
    required this.image,
    required this.amount,
    required this.unitCode,
    required this.unitLabel,
    this.unitSingular,
    this.unitPlural,
    this.ingredientSingular,
    required this.ingredientPlural,
    required this.storageCatId,
    required this.storageCatDescription,
    required this.storageCatColor,
    this.isSelected = false,
  }) : scaledAmount = amount;
}

// -------------------------------------------------------------
// Gruppierte Darstellung nach StorageCategory (DESCRIPTION)
// -------------------------------------------------------------
class _GroupedByStorageView extends StatelessWidget {
  final Map<String, List<_RecipeIngredientDisplay>> groupedItems;
  final int viewMode;
  final ScrollController scrollController;
  final void Function(String catName) onGroupSelect;
  final void Function(_RecipeIngredientDisplay ing) onItemTap;
  final void Function(_RecipeIngredientDisplay ing) onItemLongPress;

  const _GroupedByStorageView({
    required this.groupedItems,
    required this.viewMode,
    required this.scrollController,
    required this.onGroupSelect,
    required this.onItemTap,
    required this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final categories = groupedItems.keys.toList()
      ..sort((a, b) => b.toLowerCase().compareTo(a.toLowerCase()));


    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      children: [
        for (final cat in categories) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Builder(
              builder: (_) {
                final items = groupedItems[cat]!;
                final int selectedCount =
                    items.where((i) => i.isSelected).length;
                final bool noneSelected = selectedCount == 0;

                final IconData bagIcon = noneSelected
                    ? Icons.shopping_bag_outlined
                    : Icons.shopping_bag;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        cat,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(bagIcon, color: Colors.white70),
                      onPressed: () {
                        if (noneSelected) {
                          onGroupSelect(cat);
                        } else {
                          for (final ing in items) {
                            if (ing.isSelected) {
                              onItemTap(ing);
                            }
                          }
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          _buildContent(
            groupedItems[cat]!,
            viewMode,
            onItemTap,
            onItemLongPress,
          ),
        ],
      ],
    );
  }

  Widget _buildContent(
    List<_RecipeIngredientDisplay> list,
    int mode,
    void Function(_RecipeIngredientDisplay) onItemTap,
    void Function(_RecipeIngredientDisplay) onItemLongPress,
  ) {
    switch (mode) {
      case 1:
        return _TextListView(
          items: list,
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
        );
      case 2:
        return _ImageListView(
          items: list,
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
        );
      case 3:
        return _GridViewIngredients(
          items: list,
          columns: 2,
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
        );
      case 4:
        return _GridViewIngredients(
          items: list,
          columns: 3,
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
        );
      case 5:
        return _GridViewIngredients(
          items: list,
          columns: 5,
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
        );
      default:
        return _ImageListView(
          items: list,
          onItemTap: onItemTap,
          onItemLongPress: onItemLongPress,
        );
    }
  }
}

// ----------------------------------------------------------
// Hilfsfunktion für Menge + Einheit
// ----------------------------------------------------------
String _buildDisplayText(_RecipeIngredientDisplay i) {
  final formattedAmount = NumberFormatter.formatCustom(i.scaledAmount);

  if (i.unitCode == 'Stk') {
    return '$formattedAmount ${i.ingredientPlural}';
  }

  const symbolUnits = {'g', 'kg', 't', 'L', 'ml', 'EL', 'TL'};
  final useCodeAsLabel = symbolUnits.contains(i.unitCode);

  final u = useCodeAsLabel
      ? i.unitCode
      : (i.scaledAmount <= 1 ? i.unitLabel : i.unitPlural ?? i.unitLabel);

  final n = (i.scaledAmount <= 1 && i.ingredientSingular != null)
      ? i.ingredientSingular
      : i.ingredientPlural;

  return '$formattedAmount $u $n';
}

// ----------------------------------------------------------
// Text-Ansicht
// ----------------------------------------------------------
class _TextListView extends StatelessWidget {
  final List<_RecipeIngredientDisplay> items;
  final void Function(_RecipeIngredientDisplay ing) onItemTap;
  final void Function(_RecipeIngredientDisplay ing) onItemLongPress;

  const _TextListView({
    required this.items,
    required this.onItemTap,
    required this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      itemBuilder: (_, i) {
        final ing = items[i];

        return GestureDetector(
          onTap: () => onItemTap(ing),
          onLongPress: () => onItemLongPress(ing),
          child: Opacity(
            opacity: ing.isSelected ? 0.6 : 1.0,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _buildDisplayText(ing),
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  if (ing.isSelected)
                    const Icon(Icons.check_box,
                        color: Colors.white, size: 22),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------
// Bild-Ansicht
// ----------------------------------------------------------
class _ImageListView extends StatelessWidget {
  final List<_RecipeIngredientDisplay> items;
  final void Function(_RecipeIngredientDisplay ing) onItemTap;
  final void Function(_RecipeIngredientDisplay ing) onItemLongPress;

  const _ImageListView({
    required this.items,
    required this.onItemTap,
    required this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final ing = items[i];

        return InkWell(
          onTap: () => onItemTap(ing),
          onLongPress: () => onItemLongPress(ing),
          splashColor: Colors.white10,
          highlightColor: Colors.white10,
          child: Opacity(
            opacity: ing.isSelected ? 0.6 : 1.0,
            child: Container(
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
                    child: Image.asset(
                      ing.image,
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _buildDisplayText(ing),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (ing.isSelected)
                    const Icon(Icons.check_box,
                        color: Colors.white, size: 22),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------
// Grid-Ansicht
// ----------------------------------------------------------
class _GridViewIngredients extends StatelessWidget {
  final List<_RecipeIngredientDisplay> items;
  final int columns;
  final void Function(_RecipeIngredientDisplay ing) onItemTap;
  final void Function(_RecipeIngredientDisplay ing) onItemLongPress;

  const _GridViewIngredients({
    required this.items,
    required this.columns,
    required this.onItemTap,
    required this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final ing = items[i];

        return InkWell(
          onTap: () => onItemTap(ing),
          onLongPress: () => onItemLongPress(ing),
          splashColor: Colors.white10,
          highlightColor: Colors.white10,
          child: Stack(
  children: [
    // Bild
    Opacity(
      opacity: ing.isSelected ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: AssetImage(ing.image),
            fit: BoxFit.cover,
          ),
        ),
      ),
    ),

    // Untere Textbox – nur wenn NICHT 5-Grid
    if (columns != 5)
      Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          color: Colors.black.withOpacity(0.45),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Text(
            _buildDisplayText(ing),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: columns == 2 ? 16 : 12,
              height: 1.1,
            ),
          ),
        ),
      ),

    // Auswahl-Haken
    if (ing.isSelected)
      const Positioned.fill(
        child: Center(
          child: Icon(Icons.check, color: Colors.white, size: 34),
        ),
      ),
  ],
),

        );
      },
    );
  }
}
