// lib/screens/data_manager/countries_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/db/import_units.dart';

class CountriesManagerScreen extends StatefulWidget {
  const CountriesManagerScreen({super.key});

  @override
  State<CountriesManagerScreen> createState() => _CountriesManagerScreenState();
}

class _CountriesManagerScreenState extends State<CountriesManagerScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _imageCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String _query = '';
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final v = _searchCtrl.text;
      if (v != _query) setState(() => _query = v);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _closeSearch() => _searchFocus.unfocus();

  // ---------- Import ----------
  Future<void> _importCountries() async {
    _closeSearch();
    setState(() => _importing = true);
    try {
      final affected = await importCountriesFromCsv();
      _snack('Länder importiert/aktualisiert: $affected Zeilen.');
    } catch (e) {
      _snack('Fehler beim Import: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  // ---------- CRUD ----------
  Future<void> _addCountry() async {
    _closeSearch();
    _nameCtrl.clear();
    _imageCtrl.clear();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _CountryEditDialog(
        title: 'Neues Land anlegen',
        nameController: _nameCtrl,
        imageController: _imageCtrl,
        confirmLabel: 'Anlegen',
      ),
    );
    if (ok != true) return;

    final name = _nameCtrl.text.trim();
    final image = _imageCtrl.text.trim();

    if (name.isEmpty) {
      _snack('Bitte einen Namen eingeben.');
      return;
    }

    try {
      await appDb.into(appDb.countries).insert(
            CountriesCompanion(
              name: d.Value(name),
              image: d.Value(image.isEmpty ? null : image),
            ),
          );
      _snack('Land "$name" angelegt.');
    } catch (e) {
      _snack('Fehler beim Anlegen: $e');
    }
  }

  Future<void> _editCountry(Country c) async {
    _closeSearch();
    _nameCtrl.text = c.name;
    _imageCtrl.text = c.image ?? '';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _CountryEditDialog(
        title: 'Land bearbeiten (ID ${c.id})',
        nameController: _nameCtrl,
        imageController: _imageCtrl,
        confirmLabel: 'Speichern',
      ),
    );
    if (ok != true) return;

    final name = _nameCtrl.text.trim();
    final image = _imageCtrl.text.trim();

    if (name.isEmpty) {
      _snack('Bitte einen Namen eingeben.');
      return;
    }

    try {
      await (appDb.update(appDb.countries)..where((t) => t.id.equals(c.id))).write(
        CountriesCompanion(
          name: d.Value(name),
          image: d.Value(image.isEmpty ? null : image),
        ),
      );
      _snack('Land #${c.id} aktualisiert.');
    } catch (e) {
      _snack('Fehler beim Speichern: $e');
    }
  }

  Future<void> _deleteCountry(Country c) async {
    _closeSearch();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Löschen bestätigen', style: TextStyle(color: Colors.white)),
        content: Text('Land #${c.id} – "${c.name}" wirklich löschen?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await (appDb.delete(appDb.countries)..where((t) => t.id.equals(c.id))).go();
      _snack('Land "${c.name}" gelöscht.');
    } catch (e) {
      _snack('Fehler beim Löschen: $e');
    }
  }

  // ---------- Helpers ----------
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<Country> _applyFilter(List<Country> input) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return input;
    return input.where((s) {
      return s.name.toLowerCase().contains(q) ||
          (s.image ?? '').toLowerCase().contains(q) ||
          '${s.id}'.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    const double searchRowHeight = 60;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Länder verwalten', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_importing)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Länder aus CSV importieren',
              onPressed: _importCountries,
              icon: const Icon(Icons.file_download, color: Colors.white),
            ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Country>>(
            stream: (appDb.select(appDb.countries)
                  ..orderBy([(t) => d.OrderingTerm.asc(t.id)])).watch(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              final all = snap.data ?? const <Country>[];
              final items = _applyFilter(all);

              if (all.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag_circle, size: 48, color: Colors.white70),
                        const SizedBox(height: 12),
                        const Text('Noch keine Länder eingetragen.',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _importCountries,
                          icon: const Icon(Icons.file_download),
                          label: const Text('Länder aus CSV importieren'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (items.isEmpty && _query.isNotEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search_off, size: 42, color: Colors.white70),
                        const SizedBox(height: 10),
                        Text('Keine Treffer für „$_query“',
                            style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, searchRowHeight + 8),
                separatorBuilder: (_, __) =>
                    const Divider(color: Colors.white12, height: 1),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final c = items[i];
                  return Dismissible(
                    key: ValueKey('country-${c.id}'),
                    direction: DismissDirection.horizontal,
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        _editCountry(c);
                        return false;
                      } else {
                        await _deleteCountry(c);
                        return false;
                      }
                    },
                    background: _swipeBg(
                      alignment: Alignment.centerLeft,
                      color: Colors.green.shade700,
                      icon: Icons.edit,
                    ),
                    secondaryBackground: _swipeBg(
                      alignment: Alignment.centerRight,
                      color: Colors.red.shade700,
                      icon: Icons.delete,
                    ),
                    child: ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -2, horizontal: -2),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      tileColor: Colors.black,
                      leading: SizedBox(
                        width: 44,
                        child: Text(
                          '${c.id}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      title: Text(
                        c.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500),
                      ),
                      trailing: SizedBox(
                        width: 40,
                        height: 30,
                        child: c.image != null
                            ? Image.asset(
                                c.image!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.flag, color: Colors.white54),
                              )
                            : const Icon(Icons.flag_outlined, color: Colors.white54),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _SearchRow(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onAdd: _addCountry,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _swipeBg({
    required Alignment alignment,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

// =================== Edit-Dialog ===================
class _CountryEditDialog extends StatelessWidget {
  final String title;
  final TextEditingController nameController;
  final TextEditingController imageController;
  final String confirmLabel;

  const _CountryEditDialog({
    required this.title,
    required this.nameController,
    required this.imageController,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField('Name', 'z. B. Deutschland', nameController),
            const SizedBox(height: 12),
            _buildTextField('Bildpfad',
                'z. B. assets/images/flags/deutschland.webp', imageController),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }

  Widget _buildTextField(
      String label, String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
        enabledBorder:
            const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder:
            const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      ),
    );
  }
}

// =================== Wiederverwendbare Suchzeile ===================
class _SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onAdd;

  const _SearchRow({
    required this.controller,
    required this.focusNode,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.white),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  hintText: 'Suchen …',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF111111),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 44,
            width: 44,
            child: FloatingActionButton(
              heroTag: 'addCountryFab',
              backgroundColor: darkgreen,
              shape: const CircleBorder(),
              onPressed: onAdd,
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
