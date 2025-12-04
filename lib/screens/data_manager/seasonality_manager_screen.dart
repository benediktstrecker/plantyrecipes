// lib/screens/data_manager/seasonality_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

// Design
import 'package:planty_flutter_starter/design/layout.dart';

// DB
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

// Import-Helper
import 'package:planty_flutter_starter/db/import_units.dart';

class SeasonalityManagerScreen extends StatefulWidget {
  const SeasonalityManagerScreen({super.key});

  @override
  State<SeasonalityManagerScreen> createState() => _SeasonalityManagerScreenState();
}

class _SeasonalityManagerScreenState extends State<SeasonalityManagerScreen> {
  // Edit-Felder
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _colorCtrl = TextEditingController();

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

  // ---------- Import ----------
  Future<void> _importSeasonality() async {
    _closeSearch();
    setState(() => _importing = true);
    try {
      final affected = await importSeasonalityFromCsv(); // assets/data/seasonality.csv
      _snack('Saisonalität importiert/aktualisiert: $affected Zeilen.');
    } catch (e) {
      _snack('Fehler beim Import: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  // ---------- CRUD ----------
  Future<void> _addSeasonality() async {
    _closeSearch();
    _nameCtrl.clear();
    _colorCtrl.clear();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _SeasonalityEditDialog(
        title: 'Neue Saisonalität anlegen',
        nameController: _nameCtrl,
        colorController: _colorCtrl,
        confirmLabel: 'Anlegen',
      ),
    );
    if (ok != true) return;

    final name = _nameCtrl.text.trim();
    final color = _colorCtrl.text.trim();

    if (name.isEmpty) {
      _snack('Bitte einen Namen eingeben.');
      return;
    }

    try {
      await appDb.into(appDb.seasonality).insert(
            SeasonalityCompanion(
              name: d.Value(name),
              color: d.Value(color.isEmpty ? null : color),
            ),
          );
      _snack('Saisonalität "$name" angelegt.');
    } catch (e) {
      _snack('Fehler beim Anlegen: $e');
    }
  }

  Future<void> _editSeasonality(SeasonalityData s) async {
    _closeSearch();
    _nameCtrl.text = s.name;
    _colorCtrl.text = s.color ?? '';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _SeasonalityEditDialog(
        title: 'Saisonalität bearbeiten',
        nameController: _nameCtrl,
        colorController: _colorCtrl,
        confirmLabel: 'Speichern',
      ),
    );
    if (ok != true) return;

    final name = _nameCtrl.text.trim();
    final color = _colorCtrl.text.trim();

    if (name.isEmpty) {
      _snack('Bitte einen Namen eingeben.');
      return;
    }

    try {
      await (appDb.update(appDb.seasonality)..where((t) => t.id.equals(s.id))).write(
        SeasonalityCompanion(
          name: d.Value(name),
          color: d.Value(color.isEmpty ? null : color),
        ),
      );
      _snack('Saisonalität #${s.id} aktualisiert.');
    } catch (e) {
      _snack('Fehler beim Speichern: $e');
    }
  }

  Future<void> _deleteSeasonality(SeasonalityData s) async {
    _closeSearch();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Löschen bestätigen', style: TextStyle(color: Colors.white)),
        content: Text('Saisonalität #${s.id} – "${s.name}" wirklich löschen?',
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
      await (appDb.delete(appDb.seasonality)..where((t) => t.id.equals(s.id))).go();
      _snack('Saisonalität "${s.name}" gelöscht.');
    } catch (e) {
      _snack('Fehler beim Löschen: $e');
    }
  }

  // ---------- Helpers ----------
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Color _safeParseColor(String? input) {
    if (input == null) return Colors.transparent;
    var s = input.trim();
    if (s.isEmpty) return Colors.transparent;
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s'; // Alpha ergänzen
    final val = int.tryParse(s, radix: 16);
    return val == null ? Colors.transparent : Color(val);
  }

  List<SeasonalityData> _applyFilter(List<SeasonalityData> input) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return input;
    return input.where((s) {
      return s.name.toLowerCase().contains(q) ||
             (s.color ?? '').toLowerCase().contains(q) ||
             '${s.id}'.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Eingeklappte Tastatur: BottomNav sichtbar am echten Rand; Suchleiste als Overlay
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final keyboardOpen = bottomInset > 0.0;

    const double searchRowHeight = 60;
    final double overlayBottom = keyboardOpen ? bottomInset : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // wir managen via Stack

      appBar: AppBar(
        title: const Text('Saisonalität', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_importing)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Center(
                child: SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Aus CSV importieren',
              onPressed: _importSeasonality,
              icon: const Icon(Icons.file_download, color: Colors.white),
            ),
        ],
      ),

      // *** FIX: NavigationBar sitzt jetzt am echten unteren Rand, nicht mehr im Overlay ***
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
                selectedIndex: 0, // Season, Nutr, Units, Months, Cat, Props
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
          // -------- Inhalt --------
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is UserScrollNotification) _closeSearch();
              return false;
            },
            child: StreamBuilder<List<SeasonalityData>>(
              stream: (appDb.select(appDb.seasonality)
                    ..orderBy([(t) => d.OrderingTerm.asc(t.id)])).watch(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                final all = snap.data ?? const <SeasonalityData>[];
                final items = _applyFilter(all);

                if (all.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.eco, size: 48, color: Colors.white70),
                          const SizedBox(height: 12),
                          const Text('Noch keine Saisonalitätseinträge.',
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _importSeasonality,
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
                  // Nur Platz für die Suchleiste lassen
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, searchRowHeight + 8),
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final s = items[i];

                    return Dismissible(
                      key: ValueKey('season-${s.id}'),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _editSeasonality(s);
                          return false;
                        } else {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: Colors.black,
                              title: const Text('Löschen bestätigen', style: TextStyle(color: Colors.white)),
                              content: Text('Saisonalität #${s.id} – "${s.name}" wirklich löschen?',
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
                            await (appDb.delete(appDb.seasonality)..where((t) => t.id.equals(s.id))).go();
                            _snack('Saisonalität "${s.name}" gelöscht.');
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
                            '${s.id}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                          ),
                        ),
                        title: Text(
                          s.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        trailing: (s.color != null && s.color!.isNotEmpty)
                            ? Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _safeParseColor(s.color),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              )
                            : const SizedBox(width: 20, height: 20),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // -------- Overlay unten: nur die Suchleiste --------
          Positioned(
            left: 0,
            right: 0,
            bottom: overlayBottom,
            child: SafeArea(
              top: false,
              child: _SearchRow(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onAdd: _addSeasonality,
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

// =================== Edit-Dialog (Name + Farbe mit HSV-Picker) ===================
class _SeasonalityEditDialog extends StatefulWidget {
  final String title;
  final TextEditingController nameController;
  final TextEditingController colorController;
  final String confirmLabel;

  const _SeasonalityEditDialog({
    required this.title,
    required this.nameController,
    required this.colorController,
    required this.confirmLabel,
  });

  @override
  State<_SeasonalityEditDialog> createState() => _SeasonalityEditDialogState();
}

class _SeasonalityEditDialogState extends State<_SeasonalityEditDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black,
      title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField('Name', 'z. B. Freiland / Lagerware / EU-Import …', widget.nameController),
            const SizedBox(height: 12),
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
          style: FilledButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(context, true),
          child: Text(widget.confirmLabel),
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
  bool _updatingText = false;

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
              child: Text('Farbe (optional)', style: TextStyle(color: Colors.white70, fontSize: 12)),
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

        // Regler: HUE
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

        // Regler: VALUE (Helligkeit)
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

        // Regler: SATURATION
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
              heroTag: 'addSeasonFab',
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
