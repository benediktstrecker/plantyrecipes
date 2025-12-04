// lib/screens/Home_Screens/shopping.dart
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/utils/easy_swipe_nav.dart';
import 'package:planty_flutter_starter/main.dart' show routeObserver;
import 'package:planty_flutter_starter/design/drawer.dart';
import 'package:planty_flutter_starter/utils/number_formatter.dart';

// DB
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

// Screens
import 'package:planty_flutter_starter/screens/Home_Screens/mobile_view.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/ingredients.dart'
    as screen_ing;
import 'package:planty_flutter_starter/screens/Home_Screens/nutrition.dart';
import 'package:planty_flutter_starter/screens/Home_Screens/settings.dart';

// Produktliste
import 'package:planty_flutter_starter/screens/shopping/products_list_screen.dart';

// Shopping
import 'package:planty_flutter_starter/screens/shopping/shopping_list_overview.dart';
import 'package:planty_flutter_starter/screens/shopping/shopping_list_history.dart';

import 'package:planty_flutter_starter/screens/shopping/stock.dart';




class Shopping extends StatefulWidget {
  const Shopping({super.key});

  @override
  State<Shopping> createState() => _ShoppingState();
}

class _ShoppingState extends State<Shopping> 
    with EasySwipeNav, RouteAware {

  int _selectedIndex = 2;
  int _pageIndex = 0;

  List<ShoppingListData> _shoppingLists = [];
  int? _selectedListId;
  bool _loading = true;

  @override
  int get currentIndex => _selectedIndex;

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  // WICHTIG: RouteAware → wenn wir von Overview zurückkommen, neu laden!
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    // Diese Seite wurde erneut sichtbar → Listen aktualisieren
    _loadLists();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // NUR NICHT erledigte Listen laden
  // ---------------------------------------------------------------------------
  Future<void> _loadLists() async {
    final sl = appDb.shoppingList;

    final lists = await (appDb.select(sl)
          ..where((tbl) => tbl.done.equals(false)))
        .get();

    lists.sort((a, b) {
  final aDate = a.dateCreated ?? DateTime(1970);
  final bDate = b.dateCreated ?? DateTime(1970);
  return bDate.compareTo(aDate);
});


    setState(() {
      _shoppingLists = lists;
      _selectedListId = lists.isNotEmpty ? lists.first.id : null;
      _loading = false;
    });
  }

  // Navigation zwischen offenen Listen
  void _nextList() {
    if (_shoppingLists.isEmpty) return;
    final i = _shoppingLists.indexWhere((l) => l.id == _selectedListId);
    final ni = (i + 1) % _shoppingLists.length;
    setState(() {
      _selectedListId = _shoppingLists[ni].id;
      _pageIndex = 0;
    });
  }

  void _prevList() {
    if (_shoppingLists.isEmpty) return;
    final i = _shoppingLists.indexWhere((l) => l.id == _selectedListId);
    final ni = (i - 1 + _shoppingLists.length) % _shoppingLists.length;
    setState(() {
      _selectedListId = _shoppingLists[ni].id;
      _pageIndex = 0;
    });
  }

  // ---------------------------------------------------------------------------
  // Zutaten-Stream
  // ---------------------------------------------------------------------------
  Stream<List<_ShoppingIngredientDisplay>> _watchIngredients(int id) {
    final sli = appDb.shoppingListIngredient;
    final ing = appDb.ingredients;
    final u = appDb.units;

    final q = (appDb.select(sli)
          ..where((t) => t.shoppingListId.equals(id)))
        .join([
      d.leftOuterJoin(ing, ing.id.equalsExp(sli.ingredientIdNominal)),
      d.leftOuterJoin(u, u.code.equalsExp(sli.ingredientUnitCodeNominal)),
    ]);

    return q.watch().map((rows) {
      return rows.map((row) {
        final s = row.readTable(sli);
        final ir = row.readTableOrNull(ing);
        final ur = row.readTableOrNull(u);

        return _ShoppingIngredientDisplay(
          id: s.id,
          shoppingListId: s.shoppingListId,
          recipeId: s.recipeId,
          recipePortionNumberId: s.recipePortionNumberId,
          ingredientId: s.ingredientIdNominal,
          amount: s.ingredientAmountNominal,
          unitCode: s.ingredientUnitCodeNominal,
          unitLabel: ur?.label,
          ingredientName: ir?.name ?? 'Unbekannt',
          basket: s.basket,
        );
      }).toList();
    });
  }

  Future<void> _toggleBasket(_ShoppingIngredientDisplay i) async {
    final sli = appDb.shoppingListIngredient;

    await (appDb.update(sli)..where((t) => t.id.equals(i.id))).write(
      ShoppingListIngredientCompanion(basket: d.Value(!i.basket)),
    );
  }

  // Zutatenanzeige-Text
  String _buildDisplayText(_ShoppingIngredientDisplay i) {
    final amount = i.amount ?? 0;
    final formattedAmount = NumberFormatter.formatCustom(amount);

    if (i.unitCode == 'Stk') {
      return '$formattedAmount ${i.ingredientName}';
    }

    const symbolUnits = {'g', 'kg', 't', 'L', 'ml', 'EL', 'TL'};
    final useCodeAsLabel = i.unitCode != null && symbolUnits.contains(i.unitCode);

    final u = useCodeAsLabel
        ? i.unitCode
        : (amount <= 1 ? (i.unitLabel ?? i.unitCode) : (i.unitLabel ?? i.unitCode));

    return '$formattedAmount ${u ?? ''} ${i.ingredientName}';
  }

  // Zeile einer einzelnen Zutat
  Widget _buildItemRow(_ShoppingIngredientDisplay item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => _toggleBasket(item),
            child: Icon(
              item.basket ? Icons.check_box : Icons.check_box_outline_blank,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _buildDisplayText(item),
              style: TextStyle(
                color: item.basket ? Colors.white60 : Colors.white,
                fontSize: 16,
                decoration: item.basket
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Liste erledigt / nicht erledigt setzen
  Future<void> _toggleListDone(bool v) async {
    final current =
        _shoppingLists.firstWhere((l) => l.id == _selectedListId);

    await (appDb.update(appDb.shoppingList)
          ..where((t) => t.id.equals(current.id)))
        .write(ShoppingListCompanion(done: d.Value(v)));

    await _loadLists();
  }

  // Navigation Tabs (unten)
  Widget _widgetForIndex(int index) {
    switch (index) {
      case 0:
        return const MobileView();
      case 1:
        return const screen_ing.Ingredients();
      case 2:
        return const Shopping();
      case 3:
        return const Nutrition();
      default:
        return const Settings();
    }
  }

  void _navigateToPage(int index) {
    if (index == _selectedIndex) return;

    final fromRight = index > _selectedIndex;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => _widgetForIndex(index),
        transitionDuration: const Duration(milliseconds: 250),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween(
              begin: Offset(fromRight ? 1 : -1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );

    setState(() => _selectedIndex = index);
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.parse(h, radix: 16));
  }

  @override
  void goToIndex(int index) => _navigateToPage(index);


  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final bool noLists = !_loading && _shoppingLists.isEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: onSwipeStart,
      onHorizontalDragUpdate: onSwipeUpdate,
      onHorizontalDragEnd: onSwipeEnd,

      onVerticalDragEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond.dy;
        if (velocity < -300) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const ProductsListScreen(category: 'Alle Produkte'),
            ),
          );
        }
      },

      child: Scaffold(
        backgroundColor: darkgreen,
        appBar: AppBar(
          backgroundColor: darkgreen,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            "Planty Shopping",
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        drawer: const AppDrawer(currentIndex: 2),

        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
          child: GNav(
            backgroundColor: darkgreen,
            tabBackgroundColor: darkdarkgreen,
            color: Colors.white70,
            activeColor: Colors.white,
            padding: const EdgeInsets.all(16),
            gap: 8,
            selectedIndex: _selectedIndex,
            onTabChange: _navigateToPage,
            tabs: const [
              GButton(icon: Icons.list_alt, text: "Rezepte"),
              GButton(icon: Icons.eco, text: "Zutaten"),
              GButton(icon: Icons.shopping_bag, text: "Einkauf"),
              GButton(icon: Icons.stacked_bar_chart, text: "Nährwerte"),
              GButton(icon: Icons.settings, text: "Einstellungen"),
            ],
          ),
        ),

        // ---------------------------------------------------------------------
        // BODY
        // ---------------------------------------------------------------------
        body: Padding(
          padding: const EdgeInsets.all(16),

          child: LayoutBuilder(
            builder: (context, constraint) {
              final double height = constraint.maxHeight * 3 / 4;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // -------------------------------------------------------------
                  // GROßER BLOCK (soll IMMER angezeigt werden!)
                  // -------------------------------------------------------------
                  Container(
                    height: height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.transparent,
                    ),
                    child: Column(
                      children: [
                        // HEADER "Einkaufslisten"
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          decoration: const BoxDecoration(
                            color: Color(0xFF34774D),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ShoppingListOverviewScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Einkaufslisten",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // ---------------------------------------------------------
                        // FALL 1: KEINE OFFENEN LISTEN → Buttons anzeigen
                        // ---------------------------------------------------------
                        if (noLists)
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: darkdarkgreen,
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // BUTTON: Neue Einkaufsliste
                                  GestureDetector(
                                    onTap: () async {
      DateTime selectedDate = DateTime.now();

      // ------------------------------------------------------------
      // 1) Datum wählen
      // ------------------------------------------------------------
      final pickedDate = await showDialog<DateTime>(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(builder: (ctx, setStateDialog) {
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
                      primary: Colors.green,      // Kreis für ausgewählt
                      onPrimary: Colors.white,    // Text auf Kreis
                      onSurface: Colors.white,    // normale Tage weiß
                      surface: Colors.black,      // Hintergrund
                    ),
                    textTheme: const TextTheme(
                      bodyLarge: TextStyle(color: Colors.white),
                      bodyMedium: TextStyle(color: Colors.white),
                      bodySmall: TextStyle(color: Colors.white),
                      titleMedium: TextStyle(color: Colors.white),
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    onDateChanged: (d) {
                      setStateDialog(() => selectedDate = d);
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Abbrechen", style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, selectedDate),
                  child: const Text("Weiter", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          });
        },
      );

      if (pickedDate == null) return;
      final DateTime date = pickedDate;

      // ------------------------------------------------------------
      // 2) Märkte laden
      // ------------------------------------------------------------
      final markets = await (appDb.select(appDb.markets)
            ..orderBy([(m) => d.OrderingTerm(expression: m.id)]))
          .get();

      // Favorit oder erster
      Market? defaultMarket;
      final fav = markets.where((m) => m.favorite == true).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      defaultMarket = fav.isNotEmpty
          ? fav.first
          : (markets.isNotEmpty ? markets.first : null);

      // ------------------------------------------------------------
      // 3) Markt wählen — jetzt VERTIKAL, SCHMALE ZEILEN, SCROLLBAR
      // ------------------------------------------------------------
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black,       // << GANZER BACKGROUND SCHWARZ
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // *** NUR DAS LOGO-BACKGROUND FARBE ***
                    Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: _parseHexColor(m.color),  // Marktfarbe
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

                    // Marktname
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


      final Market? market = chosenMarket ?? defaultMarket;

      // ------------------------------------------------------------
      // 4) Name generieren
      // ------------------------------------------------------------
      const weekdayNames = [
        "",
        "Montag",
        "Dienstag",
        "Mittwoch",
        "Donnerstag",
        "Freitag",
        "Samstag",
        "Sonntag"
      ];

      final name =
          "${weekdayNames[date.weekday]}, ${date.day.toString().padLeft(2, '0')}"
          ".${date.month.toString().padLeft(2, '0')}.";

      // ------------------------------------------------------------
      // 5) Speichern
      // ------------------------------------------------------------
      await appDb.into(appDb.shoppingList).insert(
            ShoppingListCompanion.insert(
              name: name,
              dateCreated: d.Value(DateTime.now()),
              lastEdited: d.Value(DateTime.now()),
              marketId: d.Value(market?.id),
              dateShopping: d.Value(date),
            ),
          );

      setState(() {});
    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0B0B0B),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add,
                                              color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            "Neue Einkaufsliste",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // BUTTON: History
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ShoppingListHistoryScreen(),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0B0B0B),
                                        borderRadius:
                                            BorderRadius.circular(14),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.history,
                                              color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            "Historie",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )

                        // ---------------------------------------------------------
                        // FALL 2: ES GIBT OFFENE LISTEN → NORMALE ANSICHT
                        // ---------------------------------------------------------
                        else
                          _buildOpenListContent(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // -------------------------------------------------------------
                  // 2 zusätzliche Blöcke: Lager (links) & Statistik (rechts)
                  // -------------------------------------------------------------
                  Expanded(
                    child: Row(
                      children: [
                        // ---------------------------------------------------------
                        // BLOCK LINKS: LAGER (mit onTap auf gesamten Block)
                        // ---------------------------------------------------------
                        Expanded(
                          child: InkWell(
                            onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const StockScreen()),
                            );
                          },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.transparent,
                              ),
                              child: Column(
                                children: [
                                  // HEADER (grün)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF34774D),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      "Lager",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // INHALT (schwarzer Bereich)
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: darkdarkgreen,
                                        borderRadius: const BorderRadius.vertical(
                                          bottom: Radius.circular(16),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "–",
                                          style: TextStyle(color: Colors.white54),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        // ---------------------------------------------------------
                        // BLOCK RECHTS: STATISTIK (mit onTap auf gesamten Block)
                        // ---------------------------------------------------------
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              // TODO: Zielbildschirm
                              // Navigator.push(context, MaterialPageRoute(builder: (_) => const StatistikScreen()));
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: Colors.transparent,
                              ),
                              child: Column(
                                children: [
                                  // HEADER (grün)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF34774D),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      "Statistik",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // INHALT (schwarzer Bereich)
                                  Expanded(
                                    child: Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: darkdarkgreen,
                                        borderRadius: const BorderRadius.vertical(
                                          bottom: Radius.circular(16),
                                        ),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "–",
                                          style: TextStyle(color: Colors.white54),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Offene Listen (Zutatenliste)
  // ---------------------------------------------------------------------------
  Widget _buildOpenListContent() {
    if (_shoppingLists.isEmpty) return const SizedBox.shrink();

    final currentList =
        _shoppingLists.firstWhere((l) => l.id == _selectedListId);

    return Expanded(
      child: Column(
        children: [
          // Unterer Header
          Container(
            color: darkdarkgreen,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    currentList.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: _prevList,
                  icon: const Icon(Icons.arrow_left, color: Colors.white),
                ),
                IconButton(
                  onPressed: _nextList,
                  icon: const Icon(Icons.arrow_right, color: Colors.white),
                ),

                FutureBuilder<Market?>(
                  future: () async {
                    if (currentList.marketId == null) return null;
                    final q = appDb.select(appDb.markets)
                      ..where((m) => m.id.equals(currentList.marketId!));
                    return q.getSingleOrNull();
                  }(),
                  builder: (context, snap) {
                    final mk = snap.data;
                    if (mk == null) {
                      return const SizedBox(width: 32, height: 32);
                    }

                    return Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _parseHexColor(mk.color) ??
                            const Color(0xFF0B0B0B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            mk.picture ?? "",
                            width: 26,
                            height: 26,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Trenner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              height: 1.2,
              width: double.infinity,
              color: Colors.white24,
            ),
          ),

          // Zutatenliste
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: darkdarkgreen,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child:
                  StreamBuilder<List<_ShoppingIngredientDisplay>>(
                      stream: _watchIngredients(currentList.id),
                      builder: (context, snap) {
                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white),
                          );
                        }

                        final items = snap.data!;
                        if (items.isEmpty) {
                          return const Center(
                            child: Text(
                              "Keine Zutaten vorhanden.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, size) {
                            const double arrowsReservedHeight = 40;
                            final double available =
                                size.maxHeight -
                                    arrowsReservedHeight;

                            final double rowHeight =
                                available / 10;

                            const int itemsPerPage = 10;
                            final int totalPages =
                                (items.length / itemsPerPage)
                                    .ceil();

                            if (_pageIndex >= totalPages) {
                              _pageIndex = totalPages - 1;
                            }

                            final int start =
                                _pageIndex * itemsPerPage;
                            final int end = (start +
                                    itemsPerPage)
                                .clamp(0, items.length);
                            final visibleItems =
                                items.sublist(start, end);

                            return Column(
                              children: [
                                for (int i = 0; i < 10; i++)
                                  SizedBox(
                                    height: rowHeight,
                                    child: i <
                                            visibleItems
                                                .length
                                        ? _buildItemRow(
                                            visibleItems[i],
                                          )
                                        : const SizedBox
                                            .shrink(),
                                  ),
                                SizedBox(
                                  height:
                                      arrowsReservedHeight,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .end,
                                    children: [
                                      if (_pageIndex > 0)
                                        IconButton(
                                          padding:
                                              EdgeInsets
                                                  .zero,
                                          iconSize: 22,
                                          onPressed: () {
                                            setState(() {
                                              _pageIndex--;
                                            });
                                          },
                                          icon:
                                              const Icon(
                                            Icons
                                                .keyboard_arrow_up,
                                            color: Colors
                                                .white,
                                          ),
                                        ),
                                      if (_pageIndex <
                                          totalPages - 1)
                                        IconButton(
                                          padding:
                                              EdgeInsets
                                                  .zero,
                                          iconSize: 22,
                                          onPressed: () {
                                            setState(() {
                                              _pageIndex++;
                                            });
                                          },
                                          icon:
                                              const Icon(
                                            Icons
                                                .keyboard_arrow_down,
                                            color: Colors
                                                .white,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      }),
            ),
          ),
        ],
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// MODEL
// ---------------------------------------------------------------------------
class _ShoppingIngredientDisplay {
  final int id;
  final int shoppingListId;
  final int? recipeId;
  final int? recipePortionNumberId;
  final int? ingredientId;
  final double? amount;
  final String? unitCode;
  final String? unitLabel;
  final String ingredientName;
  bool basket;

  _ShoppingIngredientDisplay({
    required this.id,
    required this.shoppingListId,
    required this.recipeId,
    required this.recipePortionNumberId,
    required this.ingredientId,
    required this.amount,
    required this.unitCode,
    required this.unitLabel,
    required this.ingredientName,
    required this.basket,
  });
}
