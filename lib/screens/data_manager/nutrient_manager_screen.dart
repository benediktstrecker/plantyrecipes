import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/design/layout.dart';
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

// CSV-Import (importNutrientsFromCsv ist hier drin)
import 'package:planty_flutter_starter/db/import_units.dart';

class NutrientManagerScreen extends StatefulWidget {
  const NutrientManagerScreen({super.key});

  @override
  State<NutrientManagerScreen> createState() => _NutrientManagerScreenState();
}

class _NutrientManagerScreenState extends State<NutrientManagerScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _pictureCtrl = TextEditingController();
  final TextEditingController _colorCtrl = TextEditingController();

  // Suche
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';

  int? _selectedCategorieId;
  String? _selectedUnitCode;

  bool _importing = false;

  // Caches
  List<NutrientsCategorieData> _categorieCache = [];
  List<_UnitOption> _unitOptions = [];

  // Expand/Collapse-Zustand pro Kategorie
  final Map<int, bool> _expanded = {}; // catId -> expanded?

  @override
  void initState() {
    super.initState();
    _loadLookups();
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

  Future<void> _loadLookups() async {
    // Kategorien laden
    _categorieCache = await appDb.select(appDb.nutrientsCategorie).get();

    // Units laden (code + label)
    final rows = await (appDb.selectOnly(appDb.units)
          ..addColumns([appDb.units.code, appDb.units.label])
          ..orderBy([d.OrderingTerm.asc(appDb.units.code)]))
        .map((row) => _UnitOption(
              code: row.read(appDb.units.code)!,
              label: row.read(appDb.units.label)!,
            ))
        .get();

    _unitOptions = rows;

    // Defaults
    if (_unitOptions.isNotEmpty && _selectedUnitCode == null) {
      _selectedUnitCode = _unitOptions.first.code;
    }
    if (_categorieCache.isNotEmpty && _selectedCategorieId == null) {
      _selectedCategorieId = _categorieCache.first.id;
    }

    // Standard: alles ZU, außer Energie & Makronährstoffe
    for (final c in _categorieCache) {
      final n = c.name.toLowerCase();
      final isMacro = n.contains('makronährstoffe') || n.contains('makronaehrstoffe');
      final isEnergy = n == 'energie' || n == 'energy';
      _expanded.putIfAbsent(c.id, () => (isMacro || isEnergy));
    }

    if (mounted) setState(() {});
  }

  Future<void> _importNutrients() async {
    _closeSearch();
    setState(() => _importing = true);
    try {
      final affected = await importNutrientsFromCsv();
      _snack('Nährstoffe importiert/aktualisiert: $affected Zeilen.');
    } catch (e) {
      _snack('Fehler beim Import: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _addNutrient() async {
    _closeSearch();
    _nameCtrl.clear();
    _pictureCtrl.clear();
    _colorCtrl.clear();

    if (_categorieCache.isEmpty) {
      _snack('Keine Kategorien vorhanden. Bitte zuerst Kategorien importieren/anlegen.');
      return;
    }
    if (_unitOptions.isEmpty) {
      _snack('Keine Units vorhanden. Bitte zuerst Units importieren/anlegen.');
      return;
    }

    // Startwerte
    _selectedCategorieId ??= _categorieCache.first.id;
    _selectedUnitCode ??= _unitOptions.first.code;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _NutrientEditDialog(
        title: 'Neuen Nährstoff anlegen',
        nameController: _nameCtrl,
        pictureController: _pictureCtrl,
        colorController: _colorCtrl,
        categories: _categorieCache,
        initialCategorieId: _selectedCategorieId!,
        unitOptions: _unitOptions,
        initialUnitCode: _selectedUnitCode!,
        confirmLabel: 'Anlegen',
        onChanged: (catId, unitCode) {
          _selectedCategorieId = catId;
          _selectedUnitCode = unitCode;
        },
      ),
    );
    if (ok != true) return;

    final name = _nameCtrl.text.trim();
    final picture = _pictureCtrl.text.trim();
    final color = _colorCtrl.text.trim();
    final catId = _selectedCategorieId;
    final unitCode = _selectedUnitCode;

    if (name.isEmpty || catId == null || unitCode == null || unitCode.isEmpty) {
      _snack('Bitte Name, Kategorie und Einheit auswählen.');
      return;
    }

    try {
      await appDb.into(appDb.nutrient).insert(
            NutrientCompanion(
              name: d.Value(name),
              nutrientsCategorieId: d.Value(catId),
              unitCode: d.Value(unitCode),
              picture: d.Value(picture.isEmpty ? null : picture),
              color: d.Value(color.isEmpty ? null : color),
            ),
          );
      _snack('Nährstoff "$name" angelegt.');
    } catch (e) {
      _snack('Fehler beim Anlegen: $e');
    }
  }

  Future<void> _editNutrient(NutrientData n) async {
    _closeSearch();
    _nameCtrl.text = n.name;
    _pictureCtrl.text = n.picture ?? '';
    _colorCtrl.text = n.color ?? '';
    _selectedCategorieId = n.nutrientsCategorieId;
    _selectedUnitCode = n.unitCode;

    if (_categorieCache.isEmpty || _unitOptions.isEmpty) {
      await _loadLookups();
      if (_categorieCache.isEmpty || _unitOptions.isEmpty) {
        _snack('Fehlende Stammdaten. Bitte Units & Kategorien importieren.');
        return;
      }
    }

    final safeUnit = _unitOptions.any((u) => u.code == _selectedUnitCode)
        ? _selectedUnitCode!
        : _unitOptions.first.code;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _NutrientEditDialog(
        title: 'Nährstoff bearbeiten',
        nameController: _nameCtrl,
        pictureController: _pictureCtrl,
        colorController: _colorCtrl,
        categories: _categorieCache,
        initialCategorieId: _selectedCategorieId!,
        unitOptions: _unitOptions,
        initialUnitCode: safeUnit,
        confirmLabel: 'Speichern',
        onChanged: (catId, unitCode) {
          _selectedCategorieId = catId;
          _selectedUnitCode = unitCode;
        },
      ),
    );
    if (ok != true) return;

    final name = _nameCtrl.text.trim();
    final picture = _pictureCtrl.text.trim();
    final color = _colorCtrl.text.trim();
    final catId = _selectedCategorieId;
    final unitCode = _selectedUnitCode;

    if (name.isEmpty || catId == null || unitCode == null || unitCode.isEmpty) {
      _snack('Bitte Name, Kategorie und Einheit auswählen.');
      return;
    }

    try {
      await (appDb.update(appDb.nutrient)..where((t) => t.id.equals(n.id))).write(
        NutrientCompanion(
          name: d.Value(name),
          nutrientsCategorieId: d.Value(catId),
          unitCode: d.Value(unitCode),
          picture: d.Value(picture.isEmpty ? null : picture),
          color: d.Value(color.isEmpty ? null : color),
        ),
      );
      _snack('Nährstoff #${n.id} aktualisiert.');
    } catch (e) {
      _snack('Fehler beim Speichern: $e');
    }
  }

  Future<void> _deleteNutrient(NutrientData n) async {
    _closeSearch();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Löschen bestätigen', style: TextStyle(color: Colors.white)),
        content: Text('Nährstoff #${n.id} – "${n.name}" wirklich löschen?',
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
      await (appDb.delete(appDb.nutrient)..where((t) => t.id.equals(n.id))).go();
      _snack('Nährstoff "${n.name}" gelöscht.');
    } catch (e) {
      _snack('Fehler beim Löschen: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _catNameFor(int catId) {
    final cat = _categorieCache.firstWhere(
      (c) => c.id == catId,
      orElse: () => NutrientsCategorieData(id: -1, name: 'Unbekannt', unitCode: ''),
    );
    return cat.name;
  }

  /// Einfache Filter-Logik für die Suche (Name + unitCode + Kategorie)
  List<NutrientData> _filter(List<NutrientData> list) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((n) {
      return n.name.toLowerCase().contains(q) ||
          n.unitCode.toLowerCase().contains(q) ||
          _catNameFor(n.nutrientsCategorieId).toLowerCase().contains(q);
    }).toList();
  }

  /// Gruppiert nach Kategorie, sortiert: Kategorie-ID ↑, innerhalb je Kategorie Nutrient-ID ↑.
  Map<int, List<NutrientData>> _groupByCategorieId(List<NutrientData> nutrients) {
    final map = <int, List<NutrientData>>{};
    for (final n in nutrients) {
      map.putIfAbsent(n.nutrientsCategorieId, () => []).add(n);
    }
    for (final entry in map.entries) {
      entry.value.sort((a, b) => a.id.compareTo(b.id)); // <— strikt nach Nutrient-ID!
    }
    return map;
  }

  Color _parseHexColorOrTransparent(String? hex) {
    if (hex == null || hex.trim().isEmpty) return Colors.transparent;
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    final val = int.tryParse(s, radix: 16);
    return val == null ? Colors.transparent : Color(val);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom; // Tastaturhöhe
    final keyboardOpen = bottomInset > 0.0;

    // Nur noch die Suchzeile ist Overlay; die NavigationBar kommt in Scaffold.bottomNavigationBar
    const double searchRowHeight = 60;
    final double overlayBottom = keyboardOpen ? bottomInset : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Nährstoffe verwalten', style: TextStyle(color: Colors.white)),
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              ),
            )
          else
            IconButton(
              tooltip: 'Nährstoffe aus CSV importieren',
              onPressed: _importNutrients,
              icon: const Icon(Icons.file_download, color: Colors.white),
            ),
        ],
      ),

      // *** Nav-Bar sitzt jetzt fest am unteren Rand – kein Spalt mehr. ***
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
                selectedIndex: 1,
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
          // Inhalt
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is UserScrollNotification) _closeSearch();
              return false;
            },
            child: StreamBuilder<List<NutrientData>>(
              stream: (appDb.select(appDb.nutrient)
                    ..orderBy([(t) => d.OrderingTerm.asc(t.id)]))
                  .watch(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                final all = snap.data ?? const <NutrientData>[];
                if (all.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department, size: 48, color: Colors.white70),
                          const SizedBox(height: 12),
                          const Text('Noch keine Nährstoffe eingetragen.',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _importNutrients,
                            icon: const Icon(Icons.file_download),
                            label: const Text('Aus CSV importieren'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filtered = _filter(all);
                if (filtered.isEmpty && _query.isNotEmpty) {
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

                // Gruppieren & sortieren
                final grouped = _groupByCategorieId(filtered);
                final catIds = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, searchRowHeight + 8),
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                  itemCount: catIds.length,
                  itemBuilder: (_, idx) {
                    final catId = catIds[idx];
                    final title = _catNameFor(catId);
                    final items = grouped[catId]!;
                    final isOpen = _expanded[catId] ?? false;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header mit Pfeil (ein-/ausklappen) – größerer Text
                        Material(
                          color: Colors.black,
                          child: InkWell(
                            onTap: () => setState(() => _expanded[catId] = !isOpen),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$title (ID $catId)',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18, // größer
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: .2,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    isOpen ? Icons.expand_less : Icons.expand_more,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Items (nur wenn offen)
                        if (isOpen)
                          ...items.map((n) {
                            final color = _parseHexColorOrTransparent(n.color);
                            return Dismissible(
                              key: ValueKey('nutrient-${n.id}'),
                              direction: DismissDirection.horizontal,
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  _editNutrient(n);
                                  return false;
                                } else {
                                  final ok = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      backgroundColor: Colors.black,
                                      title: const Text('Löschen bestätigen',
                                          style: TextStyle(color: Colors.white)),
                                      content: Text(
                                          'Nährstoff #${n.id} – "${n.name}" wirklich löschen?',
                                          style: const TextStyle(color: Colors.white70)),
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
                                    await (appDb.delete(appDb.nutrient)
                                          ..where((t) => t.id.equals(n.id)))
                                        .go();
                                    _snack('Nährstoff "${n.name}" gelöscht.');
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
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                tileColor: Colors.black,
                                leading: SizedBox(
                                  width: 44,
                                  child: Text(
                                    '${n.id}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    if (n.color != null &&
                                        n.color!.trim().isNotEmpty)
                                      Container(
                                        width: 18,
                                        height: 18,
                                        margin: const EdgeInsets.only(left: 8),
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 2),
                                        ),
                                      ),
                                  ],
                                ),
                                // KEIN subtitle mehr
                              ),
                            );
                          }),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Overlay unten: Suche (keyboard-aware)
          Positioned(
            left: 0,
            right: 0,
            bottom: overlayBottom,
            child: SafeArea(
              top: false,
              child: _SearchRow(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onAdd: _addNutrient,
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

/// --- Wiederverwendbare Suchzeile (TextField + Plus) ---
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
              heroTag: 'addNutrientFab',
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

/// --- lightweight Option für Units (code + label) ---
class _UnitOption {
  final String code;
  final String label;
  const _UnitOption({required this.code, required this.label});
}

/// ---------------------------
/// Edit-Dialog (inkl. Farbeingabe + 3-Regler-Picker)
/// ---------------------------
class _NutrientEditDialog extends StatefulWidget {
  final String title;
  final TextEditingController nameController;
  final TextEditingController pictureController;
  final TextEditingController colorController;
  final List<NutrientsCategorieData> categories;
  final int initialCategorieId;

  final List<_UnitOption> unitOptions;
  final String initialUnitCode;

  final String confirmLabel;

  /// Callback, um Auswahl zurück an den Parent zu geben (Kategorie + Unit)
  final void Function(int selectedCategorieId, String selectedUnitCode)? onChanged;

  const _NutrientEditDialog({
    required this.title,
    required this.nameController,
    required this.pictureController,
    required this.colorController,
    required this.categories,
    required this.initialCategorieId,
    required this.unitOptions,
    required this.initialUnitCode,
    required this.confirmLabel,
    this.onChanged,
  });

  @override
  State<_NutrientEditDialog> createState() => _NutrientEditDialogState();
}

class _NutrientEditDialogState extends State<_NutrientEditDialog> {
  late int _catId;
  late String _unitCode;

  @override
  void initState() {
    super.initState();
    _catId = widget.initialCategorieId;
    _unitCode = widget.initialUnitCode;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField('Name', 'z. B. Kalorien', widget.nameController),
            const SizedBox(height: 12),
            _buildCategorieDropdown(context),
            const SizedBox(height: 12),
            if (widget.unitOptions.isEmpty)
              const Text('Keine Units vorhanden. Importiere zuerst "units".',
                  style: TextStyle(color: Colors.redAccent))
            else
              _buildUnitDropdown(context),
            const SizedBox(height: 12),
            _buildTextField('Bild (optional)', 'z. B. asset/path.png oder URL',
                widget.pictureController),
            const SizedBox(height: 12),

            // ----- Farbe: Textfeld + HSV-Picker mit 3 Reglern -----
            _ColorFieldWithPicker(controller: widget.colorController),
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
          onPressed: () {
            widget.onChanged?.call(_catId, _unitCode);
            Navigator.pop(context, true);
          },
          child: Text(widget.confirmLabel),
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

  Widget _buildCategorieDropdown(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Kategorie',
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder:
            OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder:
            OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _catId,
          isExpanded: true,
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
          items: widget.categories.map((c) {
            return DropdownMenuItem<int>(
              value: c.id,
              child: Text('${c.id} — ${c.name}',
                  style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _catId = v);
          },
        ),
      ),
    );
  }

  Widget _buildUnitDropdown(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Einheit (unit_code)',
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder:
            OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder:
            OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _unitCode,
          isExpanded: true,
          dropdownColor: Colors.black,
          style: const TextStyle(color: Colors.white),
          items: widget.unitOptions.map((u) {
            return DropdownMenuItem<String>(
              value: u.code,
              child:
                  Text('${u.code} — ${u.label}', style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _unitCode = v);
          },
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Farbfeld + HSV-3-Regler-Picker (ohne externe Packages)
/// ------------------------------------------------------------
class _ColorFieldWithPicker extends StatefulWidget {
  final TextEditingController controller;
  const _ColorFieldWithPicker({required this.controller});

  @override
  State<_ColorFieldWithPicker> createState() => _ColorFieldWithPickerState();
}

class _ColorFieldWithPickerState extends State<_ColorFieldWithPicker> {
  late HSVColor _hsv;
  bool _updatingText = false; // Re-Entryschutz

  @override
  void initState() {
    super.initState();
    _hsv = _initialHsvFromText(widget.controller.text);
    widget.controller.addListener(_onTextChanged);
    _writeTextFromHsv();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (_updatingText) return;
    final parsed = _parseHexColor(widget.controller.text);
    if (parsed == null) return;
    setState(() {
      _hsv = HSVColor.fromColor(parsed);
    });
  }

  HSVColor _initialHsvFromText(String text) {
    final c = _parseHexColor(text) ?? const Color(0xFF3366FF);
    return HSVColor.fromColor(c);
  }

  // akzeptiert #RRGGBB oder #AARRGGBB (mit/ohne #)
  Color? _parseHexColor(String? input) {
    if (input == null) return null;
    var s = input.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s'; // alpha ergänzen
    if (s.length != 8) return null;
    final val = int.tryParse(s, radix: 16);
    if (val == null) return null;
    return Color(val);
  }

  String _formatHexRGB(Color c) {
    final r = c.red.toRadixString(16).padLeft(2, '0');
    final g = c.green.toRadixString(16).padLeft(2, '0');
    final b = c.blue.toRadixString(16).padLeft(2, '0');
    return '#${(r + g + b).toUpperCase()}';
  }

  void _writeTextFromHsv() {
    final hex = _formatHexRGB(_hsv.toColor());
    _updatingText = true;
    widget.controller.text = hex;
    _updatingText = false;
  }

  @override
  Widget build(BuildContext context) {
    final current = _hsv.toColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label + Vorschau
        Row(
          children: [
            const Expanded(
              child: Text('Farbe (optional)',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: current,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Textfeld
        TextField(
          controller: widget.controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '#RRGGBB oder #AARRGGBB',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          ),
        ),

        const SizedBox(height: 12),

        // Regler: HUE (Regenbogen)
        _GradientPickerBar(
          value: _hsv.hue / 360.0,
          knobColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
          gradient: LinearGradient(colors: [
            HSVColor.fromAHSV(1, 0, 1, 1).toColor(),
            HSVColor.fromAHSV(1, 60, 1, 1).toColor(),
            HSVColor.fromAHSV(1, 120, 1, 1).toColor(),
            HSVColor.fromAHSV(1, 180, 1, 1).toColor(),
            HSVColor.fromAHSV(1, 240, 1, 1).toColor(),
            HSVColor.fromAHSV(1, 300, 1, 1).toColor(),
            HSVColor.fromAHSV(1, 360, 1, 1).toColor(),
          ]),
          onChanged: (v) {
            setState(() {
              _hsv = _hsv.withHue((v * 360).clamp(0, 360));
              _writeTextFromHsv();
            });
          },
        ),
        const SizedBox(height: 10),

        // Regler: VALUE/Helligkeit (schwarz -> Farbe)
        _GradientPickerBar(
          value: _hsv.value,
          knobColor: _hsv.toColor(),
          gradient: LinearGradient(colors: [
            HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 0).toColor(),
            HSVColor.fromAHSV(1, _hsv.hue, _hsv.saturation, 1).toColor(),
          ]),
          onChanged: (v) {
            setState(() {
              _hsv = _hsv.withValue(v);
              _writeTextFromHsv();
            });
          },
        ),
        const SizedBox(height: 10),

        // Regler: SATURATION (weiß -> Farbe)
        _GradientPickerBar(
          value: _hsv.saturation,
          knobColor: _hsv.toColor(),
          gradient: LinearGradient(colors: [
            HSVColor.fromAHSV(1, _hsv.hue, 0, _hsv.value).toColor(),
            HSVColor.fromAHSV(1, _hsv.hue, 1, _hsv.value).toColor(),
          ]),
          onChanged: (v) {
            setState(() {
              _hsv = _hsv.withSaturation(v);
              _writeTextFromHsv();
            });
          },
        ),
      ],
    );
  }
}

/// Ein einzelner Slider mit Verlauf & Drag-Handle.
class _GradientPickerBar extends StatefulWidget {
  final double value; // 0..1
  final LinearGradient gradient;
  final ValueChanged<double> onChanged;
  final Color knobColor;

  const _GradientPickerBar({
    super.key,
    required this.value,
    required this.gradient,
    required this.onChanged,
    required this.knobColor,
  });

  @override
  State<_GradientPickerBar> createState() => _GradientPickerBarState();
}

class _GradientPickerBarState extends State<_GradientPickerBar> {
  final GlobalKey _trackKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    const double height = 28;
    const double radius = 16;
    const double knob = 20;

    void handle(Offset local) {
      final box = _trackKey.currentContext?.findRenderObject() as RenderBox?;
      final w = box?.size.width ?? 1.0;
      final v = (local.dx / w).clamp(0.0, 1.0);
      widget.onChanged(v);
    }

    return GestureDetector(
      onPanDown: (d) => handle(d.localPosition),
      onPanUpdate: (d) => handle(d.localPosition),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                key: _trackKey,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(radius),
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
            Align(
              alignment: Alignment((widget.value * 2) - 1, 0), // -1..1
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  width: knob,
                  height: knob,
                  decoration: BoxDecoration(
                    color: widget.knobColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black, blurRadius: 4, spreadRadius: 0.5),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
