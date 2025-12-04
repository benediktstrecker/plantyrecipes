// lib/screens/ingredient/ingredient_shopping.dart
import 'package:flutter/material.dart';
import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:drift/drift.dart' as d;
import 'package:planty_flutter_starter/screens/shopping/product_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IngredientShoppingScreen extends StatefulWidget {
  final int ingredientId;
  final String? ingredientName;
  final String? imagePath;

  const IngredientShoppingScreen({
    super.key,
    required this.ingredientId,
    this.ingredientName,
    this.imagePath,
  });

  @override
  State<IngredientShoppingScreen> createState() =>
      _IngredientShoppingScreenState();
}

class _IngredientShoppingScreenState extends State<IngredientShoppingScreen> {
  int _viewMode = 2; // 1=text, 2=image list, 3=grid2, 4=grid3, 5=grid5
  int _sortMode = 1; // 1=Name, 2=Durchschnittspreis

  final avgPrices = <int, double>{};

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadAvgPrices();
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

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _viewMode = prefs.getInt('product_view_mode') ?? 2;
      _sortMode = prefs.getInt('product_sort_mode') ?? 1;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('product_view_mode', _viewMode);
    await prefs.setInt('product_sort_mode', _sortMode);
  }

  void _toggleViewMode() {
    setState(() => _viewMode = (_viewMode % 5) + 1);
    _savePrefs();
  }

  void _toggleSortMode() {
    setState(() => _sortMode = (_sortMode % 2) + 1);
    _savePrefs();
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

  IconData get _sortIcon =>
      _sortMode == 1 ? Icons.sort_by_alpha : Icons.attach_money;

  @override
  Widget build(BuildContext context) {
    final productsStream = (appDb.select(appDb.products)
          ..where((p) => p.ingredientId.equals(widget.ingredientId))
          ..orderBy([(t) => d.OrderingTerm.asc(t.name)]))
        .watch();

    return StreamBuilder<List<Product>>(
      stream: productsStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final products = snap.data ?? const <Product>[];
        var items = List.of(products);

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
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              widget.ingredientName ?? 'Einkauf',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                tooltip: 'Sortierung ändern',
                icon: Icon(_sortIcon, color: Colors.white),
                onPressed: _toggleSortMode,
              ),
              IconButton(
                tooltip: 'Ansicht wechseln',
                icon: Icon(_viewIcon, color: Colors.white),
                onPressed: _toggleViewMode,
              ),
            ],
            flexibleSpace: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image:
                      const AssetImage('assets/images/header_products.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.35),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0.10, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                ),
              );
              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: (items.isEmpty)
                ? const _EmptyState(
                    onImportHint:
                        'Keine Produkte für diese Zutat vorhanden.',
                  )
                : _SmoothContent(items: items, viewMode: _viewMode),
          ),
        );
      },
    );
  }
}

// ---------- Produktdarstellung ----------
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          Divider(color: Colors.white.withOpacity(0.15)),
      itemBuilder: (_, i) {
        final p = items[i];
        return ListTile(
          title: Text(
            p.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
          onTap: () {
            Navigator.of(context).push(PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 280),
              pageBuilder: (_, __, ___) =>
                  ProductDetailScreen(productId: p.id),
              transitionsBuilder: (_, a, __, child) =>
                  FadeTransition(opacity: a, child: child),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final p = items[i];
        final img = (p.image == null || p.image!.isEmpty)
            ? 'assets/images/placeholder.jpg'
            : p.image!;
        return InkWell(
          onTap: () {
            Navigator.of(context).push(PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 280),
              pageBuilder: (_, __, ___) =>
                  ProductDetailScreen(productId: p.id),
              transitionsBuilder: (_, a, __, child) {
                final offset = Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
                );
                return FadeTransition(
                  opacity: a,
                  child: SlideTransition(position: offset, child: child),
                );
              },
            ));
          },
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
                  child:
                      Image.asset(img, width: 45, height: 45, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54),
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
        return InkWell(
          onTap: () {
            Navigator.of(context).push(PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 280),
              pageBuilder: (_, __, ___) =>
                  ProductDetailScreen(productId: p.id),
              transitionsBuilder: (_, a, __, child) {
                final offset = Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
                );
                return FadeTransition(
                  opacity: a,
                  child: SlideTransition(position: offset, child: child),
                );
              },
            ));
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: AssetImage(img),
                fit: BoxFit.cover,
              ),
            ),
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black.withOpacity(0.45),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Text(
                p.name,
                maxLines: 3,
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
        );
      },
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
            const Text(
              'Keine Produkte vorhanden.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 6),
            Text(
              onImportHint,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
