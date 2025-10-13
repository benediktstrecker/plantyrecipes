// lib/screens/ingredient_property_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

// Import-Helper (enthält importIngredientPropertiesFromCsv)
import 'package:planty_flutter_starter/db/import_units.dart';

class IngredientPropertyManagerScreen extends StatefulWidget {
  const IngredientPropertyManagerScreen({super.key});

  @override
  State<IngredientPropertyManagerScreen> createState() =>
      _IngredientPropertyManagerScreenState();
}

class _IngredientPropertyManagerScreenState
    extends State<IngredientPropertyManagerScreen> {
  // Edit
  final TextEditingController _idCtrl = TextEditingController();
  final TextEditingController _nameCtrl = TextEditingController();

  // Suche
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

  // ---------------- CSV-Import ----------------
  Future<void> _importProperties() async {
    _closeSearch();
    setState(() => _importing = true);
    try {
      // assets/data/ingredient_property.csv – Header: id;name
      final affected = await importIngredientPropertiesFromCsv();
      _snack('Zutaten-Eigenschaften importiert/aktualisiert: $affected Zeilen.');
    } catch (e) {
      _snack('Import fehlgeschlagen: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  // ---------------- CRUD ----------------
  Future<void> _addProperty() async {
    _closeSearch();
    _idCtrl.clear();
    _nameCtrl.clear();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _PropertyEditDialog(
        title: 'Neue Zutaten-Eigenschaft',
        idController: _idCtrl,
        nameController: _nameCtrl,
        confirmLabel: 'Anlegen',
        enableId: true, // neue ID eingeben
      ),
    );
    if (ok != true) return;

    final id = int.tryParse(_idCtrl.text.trim());
    final name = _nameCtrl.text.trim();

    if (id == null || id <= 0) {
      _snack('Bitte eine gültige ID > 0 eingeben.');
      return;
    }
    if (name.isEmpty) {
      _snack('Bitte einen Namen eingeben.');
      return;
    }

    try {
      await appDb.into(appDb.ingredientProperties).insert(
            IngredientPropertiesCompanion(
              id: d.Value(id),
              name: d.Value(name),
            ),
          );
      _snack('Eigenschaft "$name" (#$id) angelegt.');
    } catch (e) {
      _snack('Fehler beim Anlegen: $e');
    }
  }

  Future<void> _editProperty(IngredientProperty p) async {
    _closeSearch();
    _idCtrl.text = p.id.toString();
    _nameCtrl.text = p.name;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _PropertyEditDialog(
        title: 'Eigenschaft bearbeiten (ID ${p.id})',
        idController: _idCtrl,
        nameController: _nameCtrl,
        confirmLabel: 'Speichern',
        enableId: false, // ID bleibt fix
      ),
    );
    if (ok != true) return;

    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _snack('Bitte einen Namen eingeben.');
      return;
    }

    try {
      await (appDb.update(appDb.ingredientProperties)
            ..where((t) => t.id.equals(p.id)))
          .write(
        IngredientPropertiesCompanion(name: d.Value(name)),
      );
      _snack('Eigenschaft #${p.id} aktualisiert.');
    } catch (e) {
      _snack('Fehler beim Speichern: $e');
    }
  }

  Future<void> _deleteProperty(IngredientProperty p) async {
    _closeSearch();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Löschen bestätigen', style: TextStyle(color: Colors.white)),
        content: Text('Eigenschaft #${p.id} – "${p.name}" wirklich löschen?',
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
      await (appDb.delete(appDb.ingredientProperties)
            ..where((t) => t.id.equals(p.id)))
          .go();
      _snack('Eigenschaft "${p.name}" (#${p.id}) gelöscht.');
    } catch (e) {
      _snack('Fehler beim Löschen: $e');
    }
  }

  // ---------------- Helpers ----------------
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<IngredientProperty> _applyFilter(List<IngredientProperty> input) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return input;
    return input.where((p) {
      return p.name.toLowerCase().contains(q) || '${p.id}'.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom; // Tastaturhöhe
    final keyboardOpen = bottomInset > 0.0;

    const double searchRowHeight = 60;
    final double overlayBottom = keyboardOpen ? bottomInset : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // wir managen selbst via Stack/Positioned
      appBar: AppBar(
        title: const Text('Zutaten-Eigenschaften', style: TextStyle(color: Colors.white)),
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
              tooltip: 'Aus CSV importieren',
              onPressed: _importProperties,
              icon: const Icon(Icons.file_download, color: Colors.white),
            ),
        ],
      ),

      // ✅ BottomNav fest am Rand (kein Scroll-Spalt). Suche bleibt Overlay.
      bottomNavigationBar: keyboardOpen
          ? null
          : NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: Colors.black,
                indicatorColor: Colors.green.shade700.withOpacity(0.25),
                iconTheme: MaterialStateProperty.resolveWith<IconThemeData>((states) {
                  if (states.contains(MaterialState.selected)) {
                    return IconThemeData(color: Colors.green.shade700);
                  }
                  return const IconThemeData(color: Colors.white70);
                }),
                labelTextStyle: MaterialStateProperty.all(
                  const TextStyle(color: Colors.white70),
                ),
              ),
              child: NavigationBar(
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                selectedIndex: 5, // Season, Nutr, Units, Months, Cat, Props
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.eco_outlined),
                    selectedIcon: Icon(Icons.eco),
                    label: 'Season',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.local_fire_department_outlined),
                    selectedIcon: Icon(Icons.local_fire_department),
                    label: 'Nutr',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.straighten_outlined),
                    selectedIcon: Icon(Icons.straighten),
                    label: 'Units',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month),
                    label: 'Months',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.category_outlined),
                    selectedIcon: Icon(Icons.category),
                    label: 'Cat',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.tune_outlined),
                    selectedIcon: Icon(Icons.tune),
                    label: 'Props',
                  ),
                ],
              ),
            ),

      body: Stack(
        children: [
          // ---------------- Inhalt ----------------
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is UserScrollNotification) _closeSearch();
              return false;
            },
            child: StreamBuilder<List<IngredientProperty>>(
              stream: (appDb.select(appDb.ingredientProperties)
                    ..orderBy([(t) => d.OrderingTerm.asc(t.id)])) // Sortierung nach ID
                  .watch(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                final all = snap.data ?? const <IngredientProperty>[];
                final items = _applyFilter(all);

                if (all.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tune, size: 48, color: Colors.white70),
                          const SizedBox(height: 12),
                          const Text('Noch keine Eigenschaften eingetragen.',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _importProperties,
                            icon: const Icon(Icons.file_download),
                            label: const Text('Aus CSV importieren'),
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
                  // 👇 Nur für die Suchzeile Platz lassen
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, searchRowHeight + 8),
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white12, height: 1),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final p = items[i];

                    return Dismissible(
                      key: ValueKey('iprop-${p.id}'),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _editProperty(p);
                          return false;
                        } else {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: Colors.black,
                              title: const Text('Löschen bestätigen',
                                  style: TextStyle(color: Colors.white)),
                              content: Text(
                                'Eigenschaft #${p.id} – "${p.name}" wirklich löschen?',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Abbrechen',
                                      style: TextStyle(color: Colors.white70)),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Löschen',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) {
                            await (appDb.delete(appDb.ingredientProperties)
                                  ..where((t) => t.id.equals(p.id)))
                                .go();
                            _snack('Eigenschaft "${p.name}" (#${p.id}) gelöscht.');
                          }
                          return ok == true;
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
                        visualDensity:
                            const VisualDensity(vertical: -2, horizontal: -2),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        tileColor: Colors.black,
                        leading: SizedBox(
                          width: 44,
                          child: Text(
                            '${p.id}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ),
                        title: Text(
                          p.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ---------------- Overlay unten: nur die Suche ----------------
          Positioned(
            left: 0,
            right: 0,
            bottom: overlayBottom,
            child: SafeArea(
              top: false,
              child: _SearchRow(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onAdd: _addProperty,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Swipe-Hintergründe
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
class _PropertyEditDialog extends StatelessWidget {
  final String title;
  final TextEditingController idController;
  final TextEditingController nameController;
  final String confirmLabel;
  final bool enableId;

  const _PropertyEditDialog({
    required this.title,
    required this.idController,
    required this.nameController,
    required this.confirmLabel,
    required this.enableId,
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
            _buildNumberField(
              label: 'ID',
              hint: 'z. B. 5',
              controller: idController,
              enabled: enableId,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              label: 'Name',
              hint: 'z. B. Hauptsaison Beginn',
              controller: nameController,
            ),
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
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
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

  Widget _buildNumberField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool enabled,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
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
                onTap: () => FocusScope.of(context).requestFocus(focusNode),
                onTapOutside: (_) => focusNode.unfocus(),
                onSubmitted: (_) => focusNode.unfocus(),
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
              heroTag: 'addIngredientPropFab',
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
