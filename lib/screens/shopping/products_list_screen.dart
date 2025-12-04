// lib/screens/shopping/product_list_screen.dart
import 'package:flutter/material.dart';
import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/design/drawer.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:drift/drift.dart' as d;
import 'package:planty_flutter_starter/screens/shopping/product_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProductsListScreen extends StatefulWidget {
  final String category;
  const ProductsListScreen({super.key, required this.category});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shelfCtrl;
  double _dragStartValue = 0.0;
  bool _panLockedToHorizontal = false;
  bool _panDirectionChosen = false;
  Offset _panStart = Offset.zero;

  static const double _lockSlop = 6.0;
  static const _animDur = Duration(milliseconds: 220);
  static const Slidetime = Duration(milliseconds: 220);

  final ScrollController _listCtrl = ScrollController();

  final avgPrices = <int, double>{};

  int _viewMode = 2; // 1=textlist, 2=image list, 3=grid2, 4=grid3, 5=grid5
  int _sortMode = 1; // 1=Name, 2=Preis

  bool get _shelfOpen => _shelfCtrl.value >= 0.999;
  void _openShelf() => _shelfCtrl.fling(velocity: 2.0);
  void _closeShelf() => _shelfCtrl.fling(velocity: -2.0);
  void _toggleShelf() => _shelfOpen ? _closeShelf() : _openShelf();

  Future<void> _saveViewMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('product_view_mode', mode);
  }

  Future<int> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('product_view_mode') ?? 2;
  }

  Future<void> _saveSortMode(int mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('product_sort_mode', mode);
  }

  Future<int> _loadSortMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('product_sort_mode') ?? 1;
  }

  Future<void> _loadAvgPrices() async {
    final rows = await appDb.customSelect(
      '''
        SELECT products_id AS pid, AVG(price) AS avg_price
        FROM product_markets
        GROUP BY products_id
      ''',
    ).get();

    avgPrices.clear();
    for (final r in rows) {
      final pid = r.data['pid'] as int?;
      final avg = (r.data['avg_price'] as num?)?.toDouble();
      if (pid != null && avg != null) {
        avgPrices[pid] = avg;
      }
    }

    if (mounted) setState(() {});
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
        return Icons.list;
    }
  }

  IconData get _sortIcon {
    switch (_sortMode) {
      case 1:
        return Icons.sort_by_alpha;
      case 2:
        return Icons.attach_money;
      default:
        return Icons.sort_by_alpha;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAvgPrices();
    _shelfCtrl =
        AnimationController(vsync: this, duration: _animDur, value: 0.0);
    _loadViewMode().then((m) {
      setState(() => _viewMode = m);
    });
    _loadSortMode().then((m) {
      setState(() => _sortMode = m);
    });
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    _shelfCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double shelfMaxWidth =
        (size.width * 0.28).clamp(80.0, size.width * 0.6);

    final productsStream = (appDb.select(appDb.products)
          ..orderBy([(t) => d.OrderingTerm.asc(t.name)]))
        .watch();

    return StreamBuilder<List<Product>>(
      stream: productsStream,
      builder: (context, prodSnap) {
        if (prodSnap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final allProducts = prodSnap.data ?? const <Product>[];
        List<Product> items = List.of(allProducts);

        if (_sortMode == 1) {
          // Alphabetisch
          items.sort((a, b) =>
              a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        } else {
          // Sortierung nach Durchschnittspreis
          items.sort((a, b) {
            final pa = avgPrices[a.id] ?? double.maxFinite;
            final pb = avgPrices[b.id] ?? double.maxFinite;
            return pa.compareTo(pb);
          });
        }

        return Scaffold(
          backgroundColor: Colors.black,
          drawer: const AppDrawer(currentIndex: 2),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 48,
            actionsPadding: const EdgeInsets.only(right: 4),
            actionsIconTheme: const IconThemeData(size: 22),
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Zurück',
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            title: GestureDetector(
              onTap: _toggleShelf,
              child: Text(
                widget.category,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
            actions: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Sortierung ändern',
                onPressed: _toggleSortMode,
                icon: Icon(_sortIcon, color: Colors.white),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Ansicht wechseln',
                onPressed: _toggleViewMode,
                icon: Icon(_viewIcon, color: Colors.white),
              ),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/header_products.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.35), BlendMode.darken),
                ),
              ),
            ),
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) {
              _panStart = d.localPosition;
              _panDirectionChosen = false;
              _panLockedToHorizontal = false;
              _dragStartValue = _shelfCtrl.value;
            },
            onPanUpdate: (d) {
              if (!_panDirectionChosen) {
                final dx = (d.localPosition.dx - _panStart.dx).abs();
                final dy = (d.localPosition.dy - _panStart.dy).abs();
                if (dx > dy + _lockSlop) {
                  _panDirectionChosen = true;
                  _panLockedToHorizontal = true;
                } else if (dy > dx + _lockSlop) {
                  _panDirectionChosen = true;
                  _panLockedToHorizontal = false;
                } else {
                  return;
                }
              }
              if (_panLockedToHorizontal) {
                final next = (_dragStartValue +
                        (d.localPosition.dx - _panStart.dx) / shelfMaxWidth)
                    .clamp(0.0, 1.0);
                _shelfCtrl.value = next;
              }
            },
            onPanEnd: (d) {
              if (!_panLockedToHorizontal) return;
              final vx = d.velocity.pixelsPerSecond.dx;
              const vThresh = 350.0;
              if (vx > vThresh) {
                _openShelf();
              } else if (vx < -vThresh) {
                _closeShelf();
              } else {
                (_shelfCtrl.value >= 0.5)
                    ? _openShelf()
                    : _closeShelf();
              }
            },
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _shelfCtrl,
                  builder: (_, __) {
                    final w = shelfMaxWidth * _shelfCtrl.value;
                    return SizedBox(
                      width: w,
                      child: (w > 1)
                          ? Material(
                              color: Colors.black,
                              elevation: 6,
                              child: SafeArea(
                                child: _ProductShelf(
                                  onTapCategory: (catTitle) {
                                    Navigator.of(context)
                                        .pushReplacement(PageRouteBuilder(
                                      pageBuilder: (_, __, ___) =>
                                          ProductsListScreen(
                                              category: catTitle),
                                      transitionDuration: Slidetime,
                                      reverseTransitionDuration: Slidetime,
                                      transitionsBuilder: (_, a, __, child) =>
                                          FadeTransition(
                                        opacity: a,
                                        child: child,
                                      ),
                                    ));
                                  },
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    );
                  },
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0.10, 0.0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOutCubic,
                      ));
                      return SlideTransition(
                        position: offsetAnimation,
                        child:
                            FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: (items.isEmpty)
                        ? const _EmptyState(
                            onImportHint:
                                'CSV importieren: assets/data/products.csv',
                          )
                        : _SmoothContent(items: items, viewMode: _viewMode),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------- Content + Views ----------
class _SmoothContent extends StatelessWidget {
  final List<Product> items;
  final int viewMode;
  const _SmoothContent({required this.items, required this.viewMode});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: KeyedSubtree(
        key: ValueKey<int>(viewMode),
        child: switch (viewMode) {
          1 => _TextListView(items: items),
          2 => _ImageListView(items: items),
          3 => _GridViewProducts(items: items, columns: 2),
          4 => _GridViewProducts(items: items, columns: 3),
          5 => _GridViewProducts(items: items, columns: 5),
          _ => _ImageListView(items: items),
        },
      ),
    );
  }
}

class _TextListView extends StatelessWidget {
  final List<Product> items;
  const _TextListView({required this.items});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      addRepaintBoundaries: false,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(
        color: Colors.white.withOpacity(0.15),
        height: 4,    // statt ~16
        thickness: 0.5,
        ),
      itemBuilder: (_, i) {
        final p = items[i];
        return ListTile(
          dense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          title: Text(p.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          trailing: (p.favorite == 1)
            ? const Icon(Icons.favorite, color: Colors.white)
            : const SizedBox.shrink(),
          onTap: () {
            Navigator.of(context).push(PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 280),
              reverseTransitionDuration:
                  const Duration(milliseconds: 280),
              pageBuilder: (_, __, ___) =>
                  ProductDetailScreen(productId: p.id),
              transitionsBuilder: (_, animation, __, child) =>
                  FadeTransition(opacity: animation, child: child),
            ));
          },
        );
      },
    );
  }
}

class _ImageListView extends StatelessWidget {
  final List<Product> items;
  const _ImageListView({required this.items});
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      addRepaintBoundaries: false,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 4),
      itemBuilder: (_, i) {
        final p = items[i];
        final img = (p.image == null || p.image!.isEmpty)
            ? 'assets/images/placeholder.jpg'
            : p.image!;
        return InkWell(
          onTap: () {
            Navigator.of(context).push(PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 280),
              reverseTransitionDuration:
                  const Duration(milliseconds: 280),
              pageBuilder: (_, __, ___) =>
                  ProductDetailScreen(productId: p.id),
              transitionsBuilder: (_, animation, __, child) {
                final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0, 0.05), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic));
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                      position: offsetAnimation, child: child),
                );
              },
            ));
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withOpacity(0.15), width: 1),
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
                  child: Text(p.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                ),
                (p.favorite == 1)
                  ? const Icon(Icons.favorite, color: Colors.white)
                  : const SizedBox.shrink(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GridViewProducts extends StatelessWidget {
  final List<Product> items;
  final int columns;
  const _GridViewProducts({required this.items, required this.columns});
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      addRepaintBoundaries: false,
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final p = items[i];
        final img = (p.image == null || p.image!.isEmpty)
            ? 'assets/images/placeholder.jpg'
            : p.image!;
        if (columns >= 5) {
          return InkWell(
            onTap: () {
              Navigator.of(context).push(PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 280),
                pageBuilder: (_, __, ___) =>
                    ProductDetailScreen(productId: p.id),
                transitionsBuilder: (_, animation, __, child) {
                  final offsetAnimation = Tween<Offset>(
                          begin: const Offset(0, 0.05), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: animation, curve: Curves.easeOutCubic));
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                        position: offsetAnimation, child: child),
                  );
                },
              ));
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(img, fit: BoxFit.cover),
            ),
          );
        }
        return InkWell(
          onTap: () {
            Navigator.of(context).push(PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 280),
              pageBuilder: (_, __, ___) =>
                  ProductDetailScreen(productId: p.id),
              transitionsBuilder: (_, animation, __, child) {
                final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0, 0.05), end: Offset.zero)
                    .animate(CurvedAnimation(
                        parent: animation, curve: Curves.easeOutCubic));
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                      position: offsetAnimation, child: child),
                );
              },
            ));
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image:
                  DecorationImage(image: AssetImage(img), fit: BoxFit.cover),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black.withOpacity(0.45),
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(p.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: columns == 2 ? 16 : 12,
                      height: 1.1)),
            ),
          ),
        );
      },
    );
  }
}

// ---------- Shelf + Empty ----------
class _ProductShelf extends StatelessWidget {
  final void Function(String catTitle) onTapCategory;
  const _ProductShelf({required this.onTapCategory});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _ProductShelfTile(
          title: 'Alle Produkte',
          image: 'assets/images/placeholder.jpg',
          count: 0,
          onTap: () => onTapCategory('Alle Produkte'),
        ),
      ],
    );
  }
}

class _ProductShelfTile extends StatelessWidget {
  final String title;
  final String image;
  final int count;
  final VoidCallback onTap;
  const _ProductShelfTile(
      {required this.title,
      required this.image,
      required this.count,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.white10,
      highlightColor: Colors.white10,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: AssetImage(image),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.35), BlendMode.darken),
          ),
        ),
        padding: const EdgeInsets.all(10),
        alignment: Alignment.bottomLeft,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: "$title\n",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              TextSpan(
                  text: "$count Produkte",
                  style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 11.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String onImportHint;
  const _EmptyState({required this.onImportHint});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_bag, size: 48, color: Colors.white70),
            const SizedBox(height: 12),
            const Text('Noch keine Produkte vorhanden.',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text(onImportHint,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12.5)),
          ],
        ),
      ),
    );
  }
}
