import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as d;

import 'package:planty_flutter_starter/db/db_singleton.dart';
import 'package:planty_flutter_starter/db/app_db.dart';
import 'package:planty_flutter_starter/design/drawer.dart';
import 'package:planty_flutter_starter/design/layout.dart';

class UserEditScreen extends StatefulWidget {
  final int userId;

  const UserEditScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  final _nameCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  static const double _trackCenterY = 36;

  UserData? user;
  List<GenderData> genders = [];

  double? _liveWeight;
  DateTime? _liveBirthDate;

  double carbPct = 0;
  double fatPct = 0;
  double proteinPct = 0;
  double fiberPct = 0;

  double carbG = 0;
  double fatG = 0;
  double proteinG = 0;
  double fiberG = 0;


  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      user = await (appDb.select(appDb.user)
            ..where((u) => u.id.equals(widget.userId)))
          .getSingle();

      genders = await appDb.select(appDb.gender).get();

        debugPrint('🧪 GENDERS LOADED: ${genders.length}');
        for (final g in genders) {
          debugPrint('🧪 gender → id=${g.id}, name=${g.name}');
        }

        debugPrint('🧪 USER.genderId = ${user!.genderId}');


      final rows = await appDb.select(appDb.activityLevel).get();
      activityLevel = rows.cast<ActivityLevelData>();

      palValue = user!.palValue ?? 1.4;

      _nameCtrl.text = user!.name;
      _weightCtrl.text = user!.weight?.toString() ?? '';
      _heightCtrl.text = user!.height?.toString() ?? '';

      _liveWeight = user!.weight;
      _liveBirthDate = user!.dateOfBirth;

      final totalKcal = _calculateTotalCalories() ?? 0;

      // ---------------- FAT (nutrient_id = 2) ----------------
      final fatRef = await _nutritionRef(2);
      fatPct = fatRef?.target ?? fatRef?.lowerLimit ?? 0;

      // ---------------- PROTEIN (nutrient_id = 3) ----------------
      final protRef = await _nutritionRef(3);
      if (protRef?.target != null && _liveWeight != null) {
        proteinG = protRef!.target! * _liveWeight!;
        proteinPct = (proteinG * 4 / totalKcal) * 100;
      }

      // ---------------- FIBER (nutrient_id = 5) ----------------
      final fiberRef = await _nutritionRef(5);
      fiberG = fiberRef?.lowerLimit ?? 0;
      fiberPct = totalKcal > 0 ? (fiberG * 2 / totalKcal) * 100 : 0;

      // ---------------- CARBS = REST ----------------
      carbPct = 100 - fatPct - proteinPct - fiberPct;

      _recalculateGrams();


      setState(() {});
    } catch (e, st) {
      debugPrint('❌ UserEditScreen _load failed: $e\n$st');
    }
  }


  int? _ageFromBirth(DateTime? dob) {
    if (dob == null) return null;
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  }

  int? _liveAge() {
    if (_liveBirthDate == null) return null;

    final today = DateTime.now();
    int age = today.year - _liveBirthDate!.year;

    if (today.month < _liveBirthDate!.month ||
        (today.month == _liveBirthDate!.month &&
            today.day < _liveBirthDate!.day)) {
      age--;
    }
    return age;
  }


  bool _isFemale() {
    return user?.genderId == 1;
  }

  // ==========================================================
// Kalorien-Berechnung
// ==========================================================

double? _calculateBaseCalories() {
  if (_liveWeight == null || _liveBirthDate == null) return null;

  final age = _liveAge();
  if (age == null) return null;

  final gender = genders.firstWhere(
    (g) => g.id == user!.genderId,
    orElse: () => genders.first,
  );

  return (gender.baseEnergyWeightFactor * _liveWeight! +
          gender.baseEnergyAgePlus +
          gender.baseEnergyAgeFactor * age +
          gender.baseEnergyPlusAdd) *
      gender.baseEnergyMultiplikator;
}


double? _calculateActivityCalories(double base) {
  return base * (palValue - 1);
}


double? _calculateTotalCalories() {
  final base = _calculateBaseCalories();
  if (base == null) return null;
  return base + _calculateActivityCalories(base)!;
}

Future<int?> _currentAgeGroupId() async {
  final age = _liveAge();
  if (age == null) return null;

  final groups = await appDb.select(appDb.ageGroup).get();

  for (final g in groups) {
    if (age >= g.lowerLimit && age < g.upperLimit) {
      return g.id;
    }
  }
  return null;
}


Future<NutritionReferenceData?> _nutritionRef(int nutrientId) async {
  final ageGroupId = await _currentAgeGroupId();
  if (ageGroupId == null) return null;

  return (appDb.select(appDb.nutritionReference)
        ..where((r) =>
            r.genderId.equals(user!.genderId) &
            r.ageGroupId.equals(ageGroupId) &
            r.nutrientId.equals(nutrientId)))
      .getSingleOrNull();
}


void _recalculateGrams() {
  final total = _calculateTotalCalories() ?? 0;
  if (total <= 0) return;

  carbG = (carbPct / 100 * total) / 4;
  fatG = (fatPct / 100 * total) / 9;
  proteinG = (proteinPct / 100 * total) / 4;
  fiberG = (fiberPct / 100 * total) / 2;

}

void _syncMacrosFromCalories() {
  _recalculateGrams();
}


void _recalculatePctFromGrams() {
  final total = _calculateTotalCalories() ?? 0;
  if (total <= 0) return;

  carbPct = carbG * 4 / total * 100;
  fatPct = fatG * 9 / total * 100;
  proteinPct = proteinG * 4 / total * 100;
  fiberPct = fiberG * 2 / total * 100;
}

void _setCarbPct(double v) {
  final diff = v - carbPct;
  carbPct = v;

  // erst Fett anpassen
  fatPct -= diff;
  if (fatPct < 0) {
    final rest = -fatPct;
    fatPct = 0;
    proteinPct = (proteinPct - rest).clamp(0, 100);
  }

  _recalculateGrams();
}





  List<ActivityLevelData> activityLevel = [];
    double palValue = 1.4;





  Future<void> _update(UserCompanion c) async {
    await (appDb.update(appDb.user)
          ..where((u) => u.id.equals(widget.userId)))
        .write(c);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final age = _ageFromBirth(user!.dateOfBirth);

    return Scaffold(
      backgroundColor: Colors.black,
      drawer: const AppDrawer(currentIndex: 3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Benutzerprofil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _profileHeader(),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: _colorField()),
              const SizedBox(width: 12),
              Expanded(child: _portionSelector()),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _ageField(context)),
              const SizedBox(width: 12),
              Expanded(child: _genderDropdown()),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _heightField()),
              const SizedBox(width: 12),
              Expanded(child: _weightField()),
            ],
          ),

          if (_isFemale()) ...[
            const SizedBox(height: 24),
            _femaleBlock(),
          ],

          const SizedBox(height: 10),
          const Divider(color: Colors.white24),
          _activityBlock(),


          const SizedBox(height: 10),
          const Divider(color: Colors.white24),
          _calorieBlock(),
          const SizedBox(height: 10),

          //const Divider(color: Colors.white24),
          _macroSplitBlock(),

          const SizedBox(height: 40),


        ],
      ),
    );
  }

  // ==========================================================
  // Widgets
  // ==========================================================

  Widget _profileHeader() {
  final picturePath = user!.picture;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      CircleAvatar(
        radius: 36,
        backgroundColor: Colors.white24,
        backgroundImage:
            (picturePath != null && picturePath.isNotEmpty)
                ? AssetImage(picturePath)
                : null,
        child: (picturePath == null || picturePath.isEmpty)
            ? const Icon(Icons.person, size: 36, color: Colors.white54)
            : null,
      ),
      const SizedBox(width: 16),
      Expanded(
        child: TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: _dec(),
          onChanged: (v) =>
              _update(UserCompanion(name: d.Value(v))),
        ),
      ),
    ],
  );
}

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 14,
      ),
    );
  }

  Widget _textField(
    TextEditingController ctrl, {
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      decoration: _dec(),
    );
  }

  Widget _ageField(BuildContext context) {
  final age = _ageFromBirth(user!.dateOfBirth);

  return GestureDetector(
    onTap: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: user!.dateOfBirth ?? DateTime(2000),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: darkgreen, // Akzent (Buttons, Auswahl)
                surface: Colors.black,     // Hintergrund
                onSurface: Colors.white,   // Text
              ),
              dialogBackgroundColor: Colors.black,
            ),
            child: child!,
          );
        },
      );
      if (picked == null) return;

      await _update(
        UserCompanion(dateOfBirth: d.Value(picked)),
      );

      setState(() {
        _liveBirthDate = picked;
        _syncMacrosFromCalories();
      });



      _update(UserCompanion(dateOfBirth: d.Value(picked)));
    },
    child: AbsorbPointer(
      child: TextField(
        controller: TextEditingController(
          text: _liveAge()?.toString() ?? '',
        ),
        style: const TextStyle(color: Colors.white),
        decoration: _dec(suffix: 'Jahre'),
      ),
    ),
  );
}


  Widget _weightField() {
    return TextField(
      controller: _weightCtrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: _dec(suffix: 'kg'),
      onChanged: (v) {
        final parsed = double.tryParse(v.replaceAll(',', '.'));

        setState(() {
          _liveWeight = parsed;
          _syncMacrosFromCalories();
        });

        _update(
          UserCompanion(weight: d.Value(parsed)),
        );
      },
    );
  }


  Widget _heightField() {
    return TextField(
      controller: _heightCtrl,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: _dec(suffix: 'cm'),
      onChanged: (v) => _update(
        UserCompanion(
          height: d.Value(double.tryParse(v)),
        ),
      ),
    );
  }

  Widget _genderDropdown() {
    debugPrint('🧪 BUILD genderDropdown');
  debugPrint('🧪 genders.length = ${genders.length}');
  debugPrint('🧪 user.genderId = ${user?.genderId}');
  if (genders.isEmpty || user == null) {
    return const SizedBox(height: 56);
  }

  final int? selectedId = genders.any((g) => g.id == user!.genderId)
      ? user!.genderId
      : null;

  return DropdownButtonFormField<int>(
    value: selectedId,
    hint: const Text(
      'Geschlecht wählen',
      style: TextStyle(color: Colors.white70),
    ),
    dropdownColor: Colors.grey.shade900,
    style: const TextStyle(color: Colors.white),
    iconEnabledColor: Colors.white,

    items: genders.map((GenderData g) {
      return DropdownMenuItem<int>(
        value: g.id,
        child: Text(g.name),
      );
    }).toList(),

    onChanged: (v) async {
      if (v == null) return;

      await _update(UserCompanion(genderId: d.Value(v)));

      setState(() {
        user = user!.copyWith(genderId: v);
        _syncMacrosFromCalories();
      });
    },

    decoration: _dec().copyWith(
      labelText: 'Geschlecht',
      labelStyle: const TextStyle(color: Colors.white70),
    ),
  );
}





  Widget _colorField() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('Farbe'),
      const SizedBox(height: 6),
      TextFormField(
        enabled: false, // 🔒 nichts editierbar
        initialValue: 'Grün',
        style: const TextStyle(color: Colors.white),
        decoration: _dec().copyWith(
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white24),
          ),
        ),
      ),
    ],
  );
}




 Widget _portionSelector() {
  final dbValue = user!.portionSize ?? 1.0;
  final percent = (dbValue * 100).round();

  void _setPercent(int p) async {
  final newDbValue = p / 100.0;

  await _update(
    UserCompanion(
      portionSize: d.Value(newDbValue),
    ),
  );

  await _load();
}

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('Portionsgröße'),
      const SizedBox(height: 6),
      Row(
        children: [
          _roundBtn(Icons.remove, () {
            if (percent <= 50) return;
            _setPercent(percent - 10);
          }),
          const SizedBox(width: 8),
          Container(
            width: 70,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: darkgreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$percent %',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _roundBtn(Icons.add, () {
            _setPercent(percent + 10);
          }),
        ],
      ),
    ],
  );
}



  Widget _roundBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  InputDecoration _dec({String? suffix}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white10,
      suffixText: suffix,
      suffixStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _femaleBlock() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _toggleRow(
        label: 'Schwangerschaft',
        value: user!.isPregnant ?? false,
        onChanged: (v) async {
          await _update(UserCompanion(isPregnant: d.Value(v)));
          await _load();
        },
      ),

      if (user!.isPregnant == true) ...[
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _birthDateField()),
            const SizedBox(width: 12),
            Expanded(child: _trimesterBox()),
          ],
        ),
      ],

      const SizedBox(height: 12),

      _toggleRow(
        label: 'Stillend',
        value: user!.isBreastfeeding ?? false,
        onChanged: (v) async {
          await _update(UserCompanion(isBreastfeeding: d.Value(v)));
          await _load();
        },
      ),
    ],
  );
}

Widget _toggleRow({
  required String label,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return Row(
    children: [
      Expanded(child: _label(label)),
      Switch(
        value: value,
        activeColor: const Color(0xFF1FA37C),
        onChanged: onChanged,
      ),
    ],
  );
}

Widget _trimesterBox() {
  final d = user!.dateChildBirth;
  if (d == null) return const SizedBox();

  final months =
      DateTime.now().difference(d).inDays.abs() / 30.0;
  final trimester = (months / 3).ceil().clamp(1, 3);

  return InputDecorator(
    decoration: _dec(),
    child: Text(
      '$trimester. Trimester',
      style: const TextStyle(color: Colors.white),
    ),
  );
}

Widget _activityBlock() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _label('Aktivitätslevel'),
      const SizedBox(height: 12),
      _activityIcons(),
      const SizedBox(height: 16),
      _palSliderWithScale(),
      const SizedBox(height: 8),
      Center(
        child: Text(
          _currentActivityName(),
          style: const TextStyle(color: Colors.white70),
        ),
      ),
    ],
  );
}

Widget _activityIcons() {
  final icons = [
    Icons.airline_seat_flat,
    Icons.elderly,
    Icons.airline_seat_recline_normal,
    Icons.directions_walk,
    Icons.directions_run,
    Icons.sports_martial_arts,
  ];

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List.generate(activityLevel.length, (i) {
      final lvl = activityLevel[i];
      final active = lvl ==
        activityLevel.firstWhere(
          (l) => palValue <= l.palValue,
          orElse: () => activityLevel.last,
        );


      return CircleAvatar(
        radius: 22,
        backgroundColor:
            active ? darkgreen : Colors.white24,
        child: Icon(icons[i], color: Colors.white),
      );
    }),
  );
}

void _handlePalGesture(double dx) {
  const min = 0.9;
  const max = 2.8;

  final box = context.findRenderObject() as RenderBox;
  final w = box.size.width;

  double v = min + (dx / w) * (max - min);
  v = (v * 10).round() / 10; // auf 0.1 runden
  v = v.clamp(min, max);

  setState(() => palValue = v);
  _syncMacrosFromCalories();
}

Widget _palSliderWithScale() {
  return SizedBox(
    height: 72,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // 🔹 Skala exakt AUF Track-Höhe
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CustomPaint(
              painter: _PalScalePainter(
                min: 0.9,
                max: 2.4,
                centerY: _trackCenterY,
              ),
            ),
          ),
        ),

        // 🔹 Slider exakt gleiche Track-Höhe
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            trackShape: const RectangularSliderTrackShape(),
            activeTrackColor: darkgreen,
            inactiveTrackColor: Colors.white,
            thumbColor: darkgreen,
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            min: 0.9,
            max: 2.4,
            divisions: 15, // (2.4 - 0.9) / 0.1 = 15
            value: palValue,
            onChanged: (v) {
              setState(() => palValue = v);
              _syncMacrosFromCalories();
            },
            onChangeEnd: (v) async {
              await _update(UserCompanion(palValue: d.Value(v)));
              await _load();
            },
          ),
        ),
      ],
    ),
  );
}


Future<void> _savePalValue() async {
  await _update(UserCompanion(palValue: d.Value(palValue)));
}



  Widget _birthDateField() {
    final childBirth = user!.dateChildBirth;

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: childBirth ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 300)),
          builder: (context, child) {
            return Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(
                  primary: darkgreen,
                  surface: Colors.black,
                  onSurface: Colors.white,
                ),
                dialogBackgroundColor: Colors.black,
              ),
              child: child!,
            );
          },
        );

        if (picked == null) return;

        await _update(
          UserCompanion(
            dateChildBirth: d.Value(picked), // ✅ jetzt ist d wieder Drift
          ),
        );

        await _load();
      },
      child: AbsorbPointer(
        child: TextField(
          controller: TextEditingController(
            text: childBirth != null
                ? '${childBirth.day}.${childBirth.month}.${childBirth.year}'
                : '',
          ),
          style: const TextStyle(color: Colors.white),
          decoration: _dec(),
        ),
      ),
    );
  }


String _currentActivityName() {
  if (activityLevel.isEmpty) return '';

  final lvl = activityLevel.firstWhere(
    (l) => palValue <= l.palValue,
    orElse: () => activityLevel.last,
  );

  return lvl.name;
}

// ==========================================================
// Kalorien-Block
// ==========================================================

Widget _calorieBlock() {
  final base = _calculateBaseCalories();
  if (base == null) return const SizedBox();

  final activity = _calculateActivityCalories(base)!;
  final total = base + activity;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 20),
      const Text(
        'Kalorien',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),

      // ▓▓ Balken
      _calorieBar(
        base: base,
        activity: activity,
        total: total,
      ),

      const SizedBox(height: 12),

      _calorieRow('Grundumsatz', base),
      _calorieRow('Aktivitätskalorien', activity),

      const Divider(color: Colors.white24, height: 24),

      _calorieRow(
        'Gesamt',
        total,
        isBold: true,
      ),
    ],
  );
}

Widget _calorieBar({
  required double base,
  required double activity,
  required double total,
}) {
  return SizedBox(
    height: 18,
    child: Row(
      children: [
        Expanded(
          flex: (base / total * 1000).round(),
          child: Container(
            decoration: BoxDecoration(
              color: darkgreen,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        Expanded(
          flex: (activity / total * 1000).round(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _calorieRow(String label, double value, {bool isBold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          '${value.round()} kcal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}

Widget _macroColumn({
  required String title,
  required double pct,
  required double grams,
  required ValueChanged<double> onPctChanged,
}) {
  final ctrl = TextEditingController(text: pct.toStringAsFixed(0));

  return Expanded( // ❗ MUSS drin sein
    child: Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
          decoration: _dec(suffix: '%'),
          onSubmitted: (v) {
            final p = double.tryParse(v) ?? 0;
            setState(() => onPctChanged(p));
          },
        ),
        const SizedBox(height: 6),
        Text(
          '${grams.toStringAsFixed(1)} g',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    ),
  );
}


Widget _macroSplitBlock() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 20),
      const Text(
        'Makronährstoffe',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 12),

      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _macroColumn(
            title: 'Kohlenhydrate',
            pct: carbPct,
            grams: carbG,
            onPctChanged: _setCarbPct,
          ),
          const SizedBox(width: 4),
          _macroColumn(
            title: 'Fett',
            pct: fatPct,
            grams: fatG,
            onPctChanged: (v) {
              setState(() {
                fatPct = v;
                carbPct = 100 - fatPct - proteinPct - fiberPct;
                _recalculateGrams();
              });
            },
          ),
          const SizedBox(width: 4),
          _macroColumn(
            title: 'Protein',
            pct: proteinPct,
            grams: proteinG,
            onPctChanged: (v) {
              setState(() {
                proteinPct = v;
                _recalculateGrams();
              });
            },
          ),
          const SizedBox(width: 4),
          _macroColumn(
            title: 'Ballaststoffe',
            pct: fiberPct,
            grams: fiberG,
            onPctChanged: (v) {
              setState(() {
                fiberPct = v;
                _recalculateGrams();
              });
            },
          ),
        ],
      ),

    ],
  );
}







}

class _PalScalePainter extends CustomPainter {
  final double min;
  final double max;
  final double centerY;

  _PalScalePainter({
    required this.min,
    required this.max,
    required this.centerY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1;

    final thick = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    final steps = ((max - min) / 0.1).round();
    final width = size.width;

    for (int i = 0; i <= steps; i++) {
      final value = min + i * 0.1;
      final x = width * (value - min) / (max - min);

      final isMajor = ((value * 10).round() % 2 == 0);
      final h = isMajor ? 12.0 : 6.0;

      // 🔹 Strich exakt von Track nach unten
      canvas.drawLine(
        Offset(x, centerY),
        Offset(x, centerY + h),
        isMajor ? thick : thin,
      );

      if (isMajor) {
        textPainter.text = TextSpan(
          text: value.toStringAsFixed(1),
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, centerY + h + 4),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}





