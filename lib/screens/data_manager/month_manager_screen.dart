// lib/screens/data_manager/month_screen.dart
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;
import 'package:planty_flutter_starter/design/layout.dart';

// DB
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

// CSV-Import/Seeding
import 'package:planty_flutter_starter/db/import_units.dart';

class MonthManagerScreen extends StatefulWidget {
  const MonthManagerScreen({super.key});

  @override
  State<MonthManagerScreen> createState() => _MonthManagerScreenState();
}

class _MonthManagerScreenState extends State<MonthManagerScreen> {
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
    _seedIfEmpty();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _closeSearch() => _searchFocus.unfocus();

  // ---------------- Initial-Seed / Re-Import ----------------
  Future<void> _seedIfEmpty() async {
    try {
      final count = await (appDb.selectOnly(appDb.months)
            ..addColumns([appDb.months.id.count()]))
          .map((row) => row.read(appDb.months.id.count()) ?? 0)
          .getSingle();

      if (count == 0) {
        setState(() => _importing = true);
        final affected = await seedMonthsIfEmpty();
        setState(() => _importing = false);
        if (affected > 0 && mounted) {
          _snack('Monate importiert: $affected Einträge.');
        }
      }
    } catch (e) {
      _snack('Fehler beim Initial-Import: $e');
      setState(() => _importing = false);
    }
  }

  Future<void> _reimportMonths() async {
    _closeSearch();
    setState(() => _importing = true);
    try {
      final affected = await seedMonthsIfEmpty();
      _snack('Re-Import abgeschlossen: $affected Zeilen verarbeitet.');
    } catch (e) {
      _snack('Fehler beim Import: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  // ---------------- CRUD ----------------
  Future<void> _addMonth() async {
    _closeSearch();
    _idCtrl.clear();
    _nameCtrl.clear();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _MonthEditDialog(
        title: 'Neuen Monat anlegen',
        idController: _idCtrl,
        nameController: _nameCtrl,
        showIdField: true,
        confirmLabel: 'Anlegen',
      ),
    );
    if (ok != true) return;

    final id = int.tryParse(_idCtrl.text.trim());
    final name = _nameCtrl.text.trim();

    if (id == null || id < 1 || id > 12 || name.isEmpty) {
      _snack('Bitte gültige ID (1–12) und Name eingeben.');
      return;
    }

    try {
      await appDb.into(appDb.months).insert(
            MonthsCompanion(id: d.Value(id), name: d.Value(name)),
          );
      _snack('Monat #$id – "$name" angelegt.');
    } catch (e) {
      _snack('Fehler beim Anlegen: $e');
    }
  }

  Future<void> _renameMonth(Month m) async {
    _closeSearch();
    _idCtrl.text = '${m.id}';
    _nameCtrl.text = m.name;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _MonthEditDialog(
        title: 'Monat umbenennen (ID ${m.id})',
        idController: _idCtrl,
        nameController: _nameCtrl,
        showIdField: false,
        confirmLabel: 'Speichern',
      ),
    );
    if (ok != true) return;

    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) {
      _snack('Name darf nicht leer sein.');
      return;
    }

    try {
      await (appDb.update(appDb.months)..where((t) => t.id.equals(m.id))).write(
        MonthsCompanion(name: d.Value(newName)),
      );
      _snack('Monat #${m.id} umbenannt zu "$newName".');
    } catch (e) {
      _snack('Fehler beim Umbenennen: $e');
    }
  }

  Future<void> _deleteMonth(Month m) async {
    _closeSearch();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Löschen bestätigen', style: TextStyle(color: Colors.white)),
        content: Text('Monat #${m.id} – "${m.name}" wirklich löschen?',
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
      await (appDb.delete(appDb.months)..where((t) => t.id.equals(m.id))).go();
      _snack('Monat #${m.id} – "${m.name}" gelöscht.');
    } catch (e) {
      _snack('Fehler beim Löschen: $e');
    }
  }

  // ---------------- Helpers ----------------
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  List<Month> _applyFilter(List<Month> input) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return input;
    return input.where((m) {
      return m.name.toLowerCase().contains(q) || '${m.id}'.contains(q);
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
      resizeToAvoidBottomInset: false, // wir managen über Stack/Positioned
      appBar: AppBar(
        title: const Text('Monate', style: TextStyle(color: Colors.white)),
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
              tooltip: 'CSV importieren / seed',
              onPressed: _reimportMonths,
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
                selectedIndex: 3, // Season, Nutr, Units, Months, Cat, Props
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
            child: StreamBuilder<List<Month>>(
              stream: (appDb.select(appDb.months)
                    ..orderBy([(t) => d.OrderingTerm.asc(t.id)]))
                  .watch(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                final all = snap.data ?? const <Month>[];
                final items = _applyFilter(all);

                if (all.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month, size: 48, color: Colors.white70),
                          const SizedBox(height: 12),
                          const Text('Noch keine Monate eingetragen.',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _reimportMonths,
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
                    final m = items[i];

                    return Dismissible(
                      key: ValueKey('month-${m.id}'),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _renameMonth(m);
                          return false;
                        } else {
                          return await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: Colors.black,
                                  title: const Text('Löschen bestätigen',
                                      style: TextStyle(color: Colors.white)),
                                  content: Text(
                                    'Monat #${m.id} – "${m.name}" wirklich löschen?',
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
                              ) ==
                              true
                          ? await (appDb.delete(appDb.months)..where((t) => t.id.equals(m.id))).go().then((_) {
                              _snack('Monat #${m.id} – "${m.name}" gelöscht.');
                              return true;
                            }).catchError((e) {
                              _snack('Fehler beim Löschen: $e');
                              return false;
                            })
                          : false;
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
                            '${m.id}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ),
                        title: Text(
                          m.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
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
                onAdd: _addMonth,
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
class _MonthEditDialog extends StatelessWidget {
  final String title;
  final TextEditingController idController;
  final TextEditingController nameController;
  final bool showIdField;
  final String confirmLabel;

  const _MonthEditDialog({
    required this.title,
    required this.idController,
    required this.nameController,
    required this.showIdField,
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
            if (showIdField)
              TextField(
                controller: idController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'ID (1–12)',
                  hintText: 'z. B. 1',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'z. B. Januar',
                labelStyle: TextStyle(color: Colors.white70),
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
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
              heroTag: 'addMonthFab',
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
