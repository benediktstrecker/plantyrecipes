// lib/screens/shopping/product_detail.dart
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

// DB
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

class ProductDetailScreen extends StatelessWidget {
  final int productId;
  final String? imagePath;
  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.imagePath,
  });

  Stream<Product?> _watchProduct() {
    final t = appDb.products;
    return (appDb.select(t)..where((r) => r.id.equals(productId)))
        .watchSingleOrNull();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Product?>(
      stream: _watchProduct(),
      builder: (context, snap) {
        final product = snap.data;
        final title = product?.name ?? 'Produkt';
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text(title, style: const TextStyle(color: Colors.white)),
          ),
          body: product == null
              ? const Center(
                  child:
                      CircularProgressIndicator(color: Colors.white))
              : _OverviewTab(product: product, imagePath: imagePath),
        );
      },
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Product product;
  final String? imagePath;
  const _OverviewTab({required this.product, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    const labelStyle =
        TextStyle(color: Colors.white70, fontWeight: FontWeight.w600);
    const valueStyle =
        TextStyle(color: Colors.white, fontWeight: FontWeight.w500);

    final imgPath = imagePath ?? product.image ?? 'assets/images/placeholder.jpg';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ImageBox1x1(imagePath: imgPath),
        const SizedBox(height: 16),
        _InfoRow(label: 'Name', value: product.name),
        _InfoRow(label: 'Bio', value: product.bio ? 'Ja' : 'Nein'),
        _InfoRow(label: 'Favorit', value: product.favorite ? 'Ja' : 'Nein'),
        _InfoRow(label: 'EAN', value: product.EAN?.toString() ?? '-'),
        _InfoRow(label: 'Hersteller-ID', value: product.producerId.toString()),
        _InfoRow(label: 'Zutat-ID', value: product.ingredientId.toString()),
        const SizedBox(height: 12),
        const Divider(color: Colors.white24),
        const SizedBox(height: 12),
        Text('Einheit / Größe', style: labelStyle),
        const SizedBox(height: 4),
        Text(
          '${product.sizeNumber ?? '-'} ${product.sizeUnitCode ?? ''}',
          style: valueStyle,
        ),
        const SizedBox(height: 12),
        Text('Ausbeute', style: labelStyle),
        const SizedBox(height: 4),
        Text(
          '${product.yieldAmount ?? '-'} ${product.yieldUnitCode ?? ''}',
          style: valueStyle,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _ImageBox1x1 extends StatelessWidget {
  final String? imagePath;
  const _ImageBox1x1({required this.imagePath});

  bool _isHttp(String p) => p.startsWith('http');
  bool _isLocal(String p) =>
      p.startsWith('/') || RegExp(r'^[a-zA-Z]:').hasMatch(p);

  String? _normalize(String? p) {
    if (p == null || p.trim().isEmpty) return null;
    return p.trim();
  }

  @override
  Widget build(BuildContext context) {
    final norm = _normalize(imagePath);
    Widget img;
    if (norm == null) {
      img = const ColoredBox(color: Color(0xFF0B0B0B));
    } else if (_isHttp(norm)) {
      img = Image.network(norm, fit: BoxFit.cover);
    } else if (!kIsWeb && _isLocal(norm)) {
      img = Image.file(File(norm), fit: BoxFit.cover);
    } else {
      img = Image.asset(norm, fit: BoxFit.cover);
    }

    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: img,
      ),
    );
  }
}
