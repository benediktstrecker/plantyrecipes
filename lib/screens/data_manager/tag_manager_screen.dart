// lib/screens/data_manager/tag_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

// Design
import 'package:planty_flutter_starter/design/layout.dart';

// DB
import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';

// Import-Helper
import 'package:planty_flutter_starter/db/import_units.dart';

class TagManagerScreen extends StatefulWidget {
  const TagManagerScreen({super.key});

  @override
  State<TagManagerScreen> createState() => _TagManagerScreenState();
}

class _TagManagerScreenState extends State<TagManagerScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _colorCtrl = TextEditingController();

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
  Future<void> _importTags() async {
    _closeSearch();
    setState(() => _importing = true);
    try {
      final affected = await importTagsFromCsv(); // assets/data/tags.csv
      _snack('Tags importiert/aktualisiert: $affected Zeilen.');
    } catch (e) {
      _snack('Fehler beim Import: $e');
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  // ---------- CRUD ----------
  Future<void> _addTag() async {
  _closeSearch();
  _nameCtrl.clear();
  _colorCtrl.clear();

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _TagEditDialog(
      title: 'Neuen Tag anlegen',
      nameController: _nameCtrl,
      colorController: _colorCtrl,
      confirmLabel: 'Anlegen',
    ),
  );

  if (result == null || result['ok'] != true) return;

  final name = _nameCtrl.text.trim();
  final color = _colorCtrl.text.trim();
  final catId = result['categorieId'] as int?;

  try {
    await appDb.into(appDb.tags).insert(
  TagsCompanion(
    name: d.Value(name),
    color: d.Value(color.isEmpty ? null : color),
    tagCategorieId: catId != null ? d.Value(catId) : const d.Value.absent(),
  ),
);

    _snack('Tag "$name" angelegt.');
  } catch (e) {
    _snack('Fehler beim Anlegen: $e');
  }
}


  Future<void> _editTag(Tag t) async {
  _closeSearch();
  _nameCtrl.text = t.name;
  _colorCtrl.text = t.color ?? '';

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => _TagEditDialog(
      title: 'Tag bearbeiten',
      nameController: _nameCtrl,
      colorController: _colorCtrl,
      confirmLabel: 'Speichern',
      initialCategorieId: t.tagCategorieId, // <— hier wichtig
    ),
  );

  if (result == null || result['ok'] != true) return;

  final name = _nameCtrl.text.trim();
  final color = _colorCtrl.text.trim();
  final catId = result['categorieId'] as int?;

  try {
    await (appDb.update(appDb.tags)..where((c) => c.id.equals(t.id))).write(
  TagsCompanion(
    name: d.Value(name),
    color: d.Value(color.isEmpty ? null : color),
    tagCategorieId: catId != null ? d.Value(catId) : const d.Value.absent(),
  ),
);

    _snack('Tag #${t.id} aktualisiert.');
  } catch (e) {
    _snack('Fehler beim Speichern: $e');
  }
}


  Future<void> _deleteTag(Tag t) async {
    _closeSearch();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: const Text('Löschen bestätigen', style: TextStyle(color: Colors.white)),
        content: Text('Tag #${t.id} – "${t.name}" wirklich löschen?',
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
      await (appDb.delete(appDb.tags)..where((c) => c.id.equals(t.id))).go();
      _snack('Tag "${t.name}" gelöscht.');
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
    if (s.length == 6) s = 'FF$s';
    final val = int.tryParse(s, radix: 16);
    return val == null ? Colors.transparent : Color(val);
  }

  List<Tag> _applyFilter(List<Tag> input) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return input;
    return input.where((t) {
      return t.name.toLowerCase().contains(q) ||
          (t.color ?? '').toLowerCase().contains(q) ||
          '${t.id}'.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final keyboardOpen = bottomInset > 0.0;

    const double searchRowHeight = 60;
    final double overlayBottom = keyboardOpen ? bottomInset : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Tags', style: TextStyle(color: Colors.white)),
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
              onPressed: _importTags,
              icon: const Icon(Icons.file_download, color: Colors.white),
            ),
        ],
      ),
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is UserScrollNotification) _closeSearch();
              return false;
            },
            child: StreamBuilder<List<Tag>>(
              stream: (appDb.select(appDb.tags)
                    ..orderBy([(t) => d.OrderingTerm.asc(t.id)])).watch(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                final all = snap.data ?? const <Tag>[];
                final items = _applyFilter(all);

                if (all.isEmpty) {
                  return const Center(
                    child: Text('Noch keine Tags.', style: TextStyle(color: Colors.white70)),
                  );
                }

                if (items.isEmpty && _query.isNotEmpty) {
                  return Center(
                    child: Text('Keine Treffer für „$_query“',
                        style: const TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, searchRowHeight + 8),
                  separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final t = items[i];
                    return Dismissible(
                      key: ValueKey('tag-${t.id}'),
                      direction: DismissDirection.horizontal,
                      confirmDismiss: (direction) async {
                        if (direction == DismissDirection.startToEnd) {
                          _editTag(t);
                          return false;
                        } else {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: Colors.black,
                              title: const Text('Löschen bestätigen',
                                  style: TextStyle(color: Colors.white)),
                              content: Text(
                                  'Tag #${t.id} – "${t.name}" wirklich löschen?',
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
                            await (appDb.delete(appDb.tags)
                                  ..where((c) => c.id.equals(t.id)))
                                .go();
                            _snack('Tag "${t.name}" gelöscht.');
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
                          child: Text('${t.id}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70)),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                t.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                            if (t.color != null && t.color!.trim().isNotEmpty)
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: _safeParseColor(t.color),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                              )
                            else
                              const SizedBox(width: 20, height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: overlayBottom,
            child: SafeArea(
              top: false,
              child: _SearchRow(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                onAdd: _addTag,
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

// Edit-Dialog mit Dropdown (Tag-Kategorie) + HSV-Picker
class _TagEditDialog extends StatefulWidget {
  final String title;
  final TextEditingController nameController;
  final TextEditingController colorController;
  final String confirmLabel;
  final int? initialCategorieId;

  const _TagEditDialog({
    required this.title,
    required this.nameController,
    required this.colorController,
    required this.confirmLabel,
    this.initialCategorieId,
  });

  @override
  State<_TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<_TagEditDialog> {
  int? _selectedCategorieId;
  List<TagCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _selectedCategorieId = widget.initialCategorieId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await appDb.select(appDb.tagCategories).get();
    if (!mounted) return;
    setState(() {
      _categories = cats;
      // fallback, falls initiale id fehlt oder ungültig
      if (_selectedCategorieId == null && cats.isNotEmpty) {
        _selectedCategorieId = cats.first.id;
      } else if (_selectedCategorieId != null &&
          !_categories.any((c) => c.id == _selectedCategorieId)) {
        _selectedCategorieId = cats.isNotEmpty ? cats.first.id : null;
      }
    });
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
            _buildTextField('Name', 'z. B. vegan, saisonal …', widget.nameController),
            const SizedBox(height: 12),
            _buildCategorieDropdown(),
            const SizedBox(height: 12),
            _ColorFieldWithPicker(controller: widget.colorController),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, {'ok': false}),
          child: const Text('Abbrechen', style: TextStyle(color: Colors.white70)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: Colors.green, foregroundColor: Colors.white),
          onPressed: () {
            Navigator.pop(context, {
              'ok': true,
              'categorieId': _selectedCategorieId,
            });
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }

  Widget _buildCategorieDropdown() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Tag-Kategorie',
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder:
            OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder:
            OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          dropdownColor: Colors.black,
          iconEnabledColor: Colors.white,
          value: _selectedCategorieId,
          items: _categories.map((c) {
            return DropdownMenuItem<int>(
              value: c.id,
              child: Text('${c.id} — ${c.name}',
                  style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          hint: const Text('Kategorie wählen',
              style: TextStyle(color: Colors.white54)),
          onChanged: (v) => setState(() => _selectedCategorieId = v),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
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



// HSV-Picker-Komponente
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
    setState(() => _hsv = HSVColor.fromColor(parsed));
  }

  HSVColor _initialHsvFromText(String text) {
    final c = _parseHexColor(text) ?? const Color(0xFF3366FF);
    return HSVColor.fromColor(c);
  }

  Color? _parseHexColor(String? input) {
    if (input == null) return null;
    var s = input.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
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
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '#RRGGBB',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder:
                OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder:
                OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
          ),
        ),
        const SizedBox(height: 12),
        _GradientPickerBar(
          value: _hsv.hue / 360.0,
          knobColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
          gradient: LinearGradient(colors: [
            for (var h in [0, 60, 120, 180, 240, 300, 360])
              HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor()
          ]),
          onChanged: (v) {
            setState(() {
              _hsv = _hsv.withHue((v * 360).clamp(0, 360));
              _writeTextFromHsv();
            });
          },
        ),
        const SizedBox(height: 10),
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
  final double value;
  final LinearGradient gradient;
  final ValueChanged<double> onChanged;
  final Color knobColor;
  const _GradientPickerBar({
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                key: _trackKey,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            Align(
              alignment: Alignment((widget.value * 2) - 1, 0),
              child: IgnorePointer(
                ignoring: true,
                child: Container(
                  width: knob,
                  height: knob,
                  decoration: BoxDecoration(
                    color: widget.knobColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
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

// Suchzeile
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
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 44,
            width: 44,
            child: FloatingActionButton(
              heroTag: 'addTagFab',
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
