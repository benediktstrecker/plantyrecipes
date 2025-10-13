// lib/screens/nutrient_categorie_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;
import 'package:planty_flutter_starter/design/layout.dart';

// DB
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

// Import-Helper (enthält importNutrientCategoriesFromCsv)
import 'package:planty_flutter_starter/db/import_units.dart';

class NutrientCategorieManagerScreen extends StatefulWidget {
  const NutrientCategorieManagerScreen({super.key});

  @override
  State<NutrientCategorieManagerScreen> createState() =>
      _NutrientCategorieManagerScreenState();
}

class _NutrientCategorieManagerScreenState
    extends State<NutrientCategorieManagerScreen> {
  // Edit-Felder
  final TextEditingController _nameCtrl = TextEditingController();
  String? _selectedUnitCode;

  // Suche
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';

  bool _importing = false;

  // Lookups
  List<Unit> _unitCache = [];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final v = _searchCtrl.text;
      if (v != _query) setState(() => _query = v);
    });
    _loadUnits();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _closeSearch() => _searchFocus.unfocus();

  Future<void> _loadUnits() async {
    _unitCache = await appDb.select(appDb.units).get();
    if (_unitCache.isNotEmpty && _selectedUnitCode == null) {
      _selectedUnitCode = _unitCache.first.code;
    }
    if (mounted) setState(() {});
  }

  // ---------------- Import ----------------
  Future<void> _importCategories() async {
    _closeSearch();
    setState(() => _importing = true);
    try {
      final affected = await importNutrientCategoriesFromCsv();
      _snack('Kategorien importiert/aktualisiert: $affected Zeilen.');
    } catch (e) {
      _snack('Fehler beim Import: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  // ---------------- CRUD ----------------
  Future<void> _addCategorie() async {
    _closeSearch();
    _nameCtrl.clear();

    if (_unitCache.isEmpty) {
      _snack('Keine Units vorhanden. Bitte zuerst Units importieren/anlegen.');
      return;
    }
    _selectedUnitCode ??= _unitCache.first.code;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _CategorieEditDialog(
        title: 'Neue Nährstoff-Kategorie',
        nameController: _nameCtrl,
        unitCodes: _unitCache,
        selectedUnitCode: _selectedUnitCode,
        onUnitChanged: (v) => _selectedUnitCode = v,
        confirmLabel: 'Anlegen',
      ),
    );
    if (ok != true) return;

    final name = _nameCtrl.text.trim();
    final unitCode = _selectedUnitCode?.trim();

    if (name.isEmpty || unitCode == null || unitCode.isEmpty) {
      _snack('Bitte Name und Unit wählen.');
      return;
    }

    try {
      await appDb.into(appDb.nutrientsCategorie).insert(
            NutrientsCategorieCompanion(
              name: d.Value(name),
              unitCode: d.Value(unitCode),
            ),
          );
      _snack('Kategorie "$name" angelegt.');
    } catch (e) {
      _snack('Fehler beim Anlegen: $e');
    }
  }

  Future<void> _editCategorie(NutrientsCategorieData c) async {
    _closeSearch();
    _nameCtrl.text = c.name;
    _selectedUnitCode = c.unitCode;

    if (_unitCache.isEmpty) {
      await _loadUnits();
      if (_unitCache.isEmpty) {
        _snack('Keine Units vorhanden. Bitte zuerst Units importieren/anlegen.');
        return;
      }
    }

    // Falls die gespeicherte Unit nicht mehr existiert, fallback:
    final safeUnit = _unitCache.any((u) => u.code == _selectedUnitCode)
        ? _selectedUnitCode
        : (_unitCache.isNotEmpty ? _unitCache.first.code : null);

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _CategorieEditDialog(
        title: 'Kategorie bearbeiten',
        nameController: _nameCtrl,
        unitCodes: _unitCache,
        selectedUnitCode: safeUnit,
        onUnitChanged: (v) => _selectedUnitCode = v,
        confirmLabel: 'Speichern',
      ),
    );
    if (ok != true) return;

    final name = _nameCtrl.text.trim();
    final unitCode = _selectedUnitCode?.trim();

    if (name.isEmpty || unitCode == null || unitCode.isEmpty) {
      _snack('Bitte Name und Unit wählen.');
      return;
    }

    try {
      await (appDb.update(appDb.nutrientsCategorie)..where((t) => t.id.equals(c.id))).write(
        NutrientsCategorieCompanion(
          name: d.Value(name),
          unitCode: d.Value(unitCode),
        ),
      );
      _snack('Kategorie #${c.id} aktualisiert.');
    } catch (e) {
      _snack('Fehler beim Speichern: $e');
    }
  }

  Future<void> _deleteCategorie(NutrientsCategorieData c) async {
    _closeSearch();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Löschen bestätigen', style: TextStyle(color: Colors.white)),
        content:
            Text('Kategorie #${c.id} – "${c.name}" wirklich löschen?', style: const TextStyle(color: Colors.white70)),
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
      await (appDb.delete(appDb.nutrientsCategorie)..where((t) => t.id.equals(c.id))).go();
      _snack('Kategorie "${c.name}" gelöscht.');
    } catch (e) {
      _snack('Fehler beim Löschen: $e');
    }
  }

  // ---------------- Helpers ----------------
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<NutrientsCategorieData> _applyFilter(List<NutrientsCategorieData> input) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return input;
    return input.where((c) {
      return c.name.toLowerCase().contains(q) || '${c.id}'.contains(q);
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
      resizeToAvoidBottomInset: false, // wir managen via Stack/Positioned
      appBar: AppBar(
        title: const Text('Nährstoff-Kategorien', style: TextStyle(color: Colors.white)),
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
              tooltip: 'Kategorien aus CSV importieren',
              onPressed: _importCategories,
              icon: const Icon(Icons.file_download, color: Colors.white),
            ),
        ],
      ),

      // ✅ BottomNav fest am unteren Rand (kein Spalt), Suche bleibt Overlay
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
                labelTextStyle: MaterialStateProperty.all(const TextStyle(color: Colors.white70)),
              ),
              child: NavigationBar(
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                selectedIndex: 4, // Season, Nutr, Units, Months, Cat, Props
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
            child: StreamBuilder<List<NutrientsCategorieData>>(
              stream: (appDb.select(appDb.nutrientsCategorie)
                    ..orderBy([(t) => d.OrderingTerm.asc(t.id)])) // Sortierung nach ID
                  .watch(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                final all = snap.data ?? const <NutrientsCategorieData>[];
                final items = _applyFilter(all);

                if (all.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category, size: 48, color: Colors.white70),
                          const SizedBox(height: 12),
                          const Text('Noch keine Kategorien eingetragen.',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _importCategories,
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
                          Text('Keine Treffer für „$_query“', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  // nur Platz für die Suchleiste freilassen
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, searchRowHeight + 8),
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final c = items[i];

                    return Dismissible(
                      key: ValueKey('nc-${c.id}'),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _editCategorie(c);
                          return false;
                        } else {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: Colors.black,
                              title: const Text('Löschen bestätigen', style: TextStyle(color: Colors.white)),
                              content: Text('Kategorie #${c.id} – "${c.name}" wirklich löschen?',
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
                          if (ok == true) {
                            await (appDb.delete(appDb.nutrientsCategorie)..where((t) => t.id.equals(c.id))).go();
                            _snack('Kategorie "${c.name}" gelöscht.');
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
                        visualDensity: const VisualDensity(vertical: -2, horizontal: -2),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        tileColor: Colors.black,
                        leading: SizedBox(
                          width: 44,
                          child: Text(
                            '${c.id}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ),
                        title: Text(
                          c.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
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
                onAdd: _addCategorie,
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
class _CategorieEditDialog extends StatelessWidget {
  final String title;
  final TextEditingController nameController;
  final List<Unit> unitCodes;
  final String? selectedUnitCode;
  final ValueChanged<String?> onUnitChanged;
  final String confirmLabel;

  const _CategorieEditDialog({
    required this.title,
    required this.nameController,
    required this.unitCodes,
    required this.selectedUnitCode,
    required this.onUnitChanged,
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
            _buildTextField('Name', 'z. B. Makronährstoffe', nameController),
            const SizedBox(height: 12),
            _buildUnitDropdown(context),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      ),
    );
  }

  Widget _buildUnitDropdown(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Unit',
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedUnitCode,
          isExpanded: true,
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
          items: unitCodes.map((u) {
            return DropdownMenuItem<String>(
              value: u.code,
              child: Text('${u.code} — ${u.label}', style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: onUnitChanged,
        ),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
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
              heroTag: 'addNutrCatFab',
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
