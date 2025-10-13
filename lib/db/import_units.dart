// lib/db/import_units.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:drift/drift.dart' as d;
import 'db_singleton.dart';
import 'app_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// --------------------------------------------
/// Units-Import (UTF-8, ; als Trenner)
/// Header: code;label;dimension;baseFactor
/// --------------------------------------------
Future<int> importUnitsFromCsv({String assetPath = 'assets/data/unit.csv'}) async {
  int affected = 0;
  try {
    final csv = await rootBundle.loadString(assetPath);
    final lines = const LineSplitter().convert(csv).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return 0;

    final header = lines.first.split(';').map((e) => e.trim()).toList();
    if (header.length < 4 ||
        header[0] != 'code' ||
        header[1] != 'label' ||
        header[2] != 'dimension' ||
        header[3] != 'baseFactor') {
      print('[units import] Header ungültig. Erwartet: code;label;dimension;baseFactor');
      return 0;
    }

    final idxCode = 0;
    final idxLabel = 1;
    final idxDimension = 2;
    final idxBaseFactor = 3;

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final parts = lines[i].split(';').map((e) => e.trim()).toList();
        if (parts.length < 4) continue;

        final code = parts[idxCode];
        final label = parts[idxLabel];
        final dimension = parts[idxDimension];
        final factor = double.tryParse(parts[idxBaseFactor]);

        if (code.isEmpty || label.isEmpty || dimension.isEmpty || factor == null) continue;

        final existing = await (appDb.select(appDb.units)
      ..where((u) => u.code.equals(code)))
    .getSingleOrNull();

if (existing == null) {
  await appDb.into(appDb.units).insert(
    UnitsCompanion(
      code: d.Value(code),
      label: d.Value(label),
      dimension: d.Value(dimension),
      baseFactor: d.Value(factor),
    ),
  );
} else {
  await (appDb.update(appDb.units)..where((u) => u.code.equals(code))).write(
    UnitsCompanion(
      label: d.Value(label),
      dimension: d.Value(dimension),
      baseFactor: d.Value(factor),
    ),
  );
}
        affected++;
      }
    });

    print('[units import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[units import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// Months-Seed (fest im Code, ohne CSV)
/// Legt die Monate 1..12 an (Upsert), falls noch nicht vorhanden
/// ----------------------------------------------------------
Future<int> seedMonthsIfEmpty() async {
  int affected = 0;

  // Schon was drin?
  final count = await (appDb.selectOnly(appDb.months)
        ..addColumns([appDb.months.id.count()]))
      .map((row) => row.read(appDb.months.id.count()) ?? 0)
      .getSingle();

  if (count > 0) {
    // Optional: trotzdem sicherstellen, dass alle 12 existieren (Upsert)
    final months = const [
      { 'id': 1,  'name': 'Januar'   },
      { 'id': 2,  'name': 'Februar'  },
      { 'id': 3,  'name': 'März'     },
      { 'id': 4,  'name': 'April'    },
      { 'id': 5,  'name': 'Mai'      },
      { 'id': 6,  'name': 'Juni'     },
      { 'id': 7,  'name': 'Juli'     },
      { 'id': 8,  'name': 'August'   },
      { 'id': 9,  'name': 'September'},
      { 'id': 10, 'name': 'Oktober'  },
      { 'id': 11, 'name': 'November' },
      { 'id': 12, 'name': 'Dezember' },
    ];

    await appDb.transaction(() async {
      for (final m in months) {
        await appDb.into(appDb.months).insertOnConflictUpdate(
          MonthsCompanion(
            id: d.Value(m['id'] as int),
            name: d.Value(m['name'] as String),
          ),
        );
        affected++;
      }
    });

    print('[months seed] Upsert abgeschlossen: $affected Einträge geprüft/angelegt.');
    return affected;
  }

  // Wenn leer, komplett anlegen
  final months = const [
    { 'id': 1,  'name': 'Januar'   },
    { 'id': 2,  'name': 'Februar'  },
    { 'id': 3,  'name': 'März'     },
    { 'id': 4,  'name': 'April'    },
    { 'id': 5,  'name': 'Mai'      },
    { 'id': 6,  'name': 'Juni'     },
    { 'id': 7,  'name': 'Juli'     },
    { 'id': 8,  'name': 'August'   },
    { 'id': 9,  'name': 'September'},
    { 'id': 10, 'name': 'Oktober'  },
    { 'id': 11, 'name': 'November' },
    { 'id': 12, 'name': 'Dezember' },
  ];

  await appDb.transaction(() async {
    for (final m in months) {
      await appDb.into(appDb.months).insertOnConflictUpdate(
        MonthsCompanion(
          id: d.Value(m['id'] as int),
          name: d.Value(m['name'] as String),
        ),
      );
      affected++;
    }
  });

  print('[months seed] Fertig, angelegt: $affected Zeilen');
  return affected;
}


/// ----------------------------------------------------------
/// Nutrients-Categorie-Import (UTF-8/Latin-1 tolerant; ; oder ,)
/// Header: id;name;unit_code
/// - Upsert via id
/// - validiert unit_code gegen units.code
/// ----------------------------------------------------------
Future<int> importNutrientCategoriesFromCsv({
  String assetPath = 'assets/data/nutrient_categorie.csv',
}) async {
  int affected = 0;
  try {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = latin1.decode(bytes);
    }
    if (text.contains('�')) {
      final latin = latin1.decode(bytes, allowInvalid: true);
      if (latin.split('�').length < text.split('�').length) text = latin;
    }
    if (text.startsWith('\uFEFF')) text = text.substring(1);

    final lines = const LineSplitter().convert(text).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return 0;

    final header = _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    final idxId = header.indexOf('id');
    final idxName = header.indexOf('name');
    final idxUnitCode = header.indexOf('unit_code');

    if (idxId < 0 || idxName < 0 || idxUnitCode < 0) {
      print('[nutrient categories import] Ungültiger Header, erwartet: id;name;unit_code');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;

        while (raw.length < header.length) {
          raw.add('');
        }

        final id = int.tryParse(raw[idxId].trim());
        final name = raw[idxName].trim();
        final unitCode = raw[idxUnitCode].trim();

        if (id == null || name.isEmpty || unitCode.isEmpty) continue;

        final unitExists =
            await (appDb.select(appDb.units)..where((u) => u.code.equals(unitCode))).getSingleOrNull();

        if (unitExists == null) {
          print('[nutrient categories import] Warnung: unit_code "$unitCode" existiert nicht, Zeile ${i + 1} übersprungen.');
          continue;
        }

        await appDb.into(appDb.nutrientsCategorie).insertOnConflictUpdate(
              NutrientsCategorieCompanion(
                id: d.Value(id),
                name: d.Value(name),
                unitCode: d.Value(unitCode),
              ),
            );
        affected++;
      }
    });

    print('[nutrient categories import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[nutrient categories import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// Nutrients-Import (UTF-8/Latin-1 tolerant; ; oder ,)
/// Header: id;name;nutrients_categorie_id;picture;color
/// - Upsert via id
/// - validiert FK gegen nutrients_categorie.id
/// ----------------------------------------------------------
Future<int> importNutrientsFromCsv({
  String assetPath = 'assets/data/nutrient.csv',
}) async {
  int affected = 0;

  try {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = latin1.decode(bytes);
    }
    if (text.startsWith('\uFEFF')) text = text.substring(1);

    final lines = const LineSplitter()
        .convert(text)
        .where((l) => l.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return 0;

    final header = _splitSmart(lines.first)
        .map((s) => s.trim().toLowerCase())
        .toList();

    final idxId        = header.indexOf('id');
    final idxName      = header.indexOf('name');
    final idxCatId     = header.indexOf('nutrients_categorie_id');
    final idxUnitCode  = header.indexOf('unit_code');             // <— NEU
    final idxPicture   = header.indexOf('picture');
    final idxColor     = header.indexOf('color');

    if (idxId < 0 || idxName < 0 || idxCatId < 0 || idxUnitCode < 0) {
      print('[nutrients import] Ungültiger Header, erwartet: id;name;nutrients_categorie_id;unit_code;picture;color');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;
        while (raw.length < header.length) raw.add('');

        final id       = int.tryParse(raw[idxId].trim());
        final name     = raw[idxName].trim();
        final catId    = int.tryParse(raw[idxCatId].trim());
        final unitCode = raw[idxUnitCode].trim();                  // <— NEU
        final picture  = idxPicture >= 0 ? raw[idxPicture].trim() : null;
        final color    = idxColor   >= 0 ? raw[idxColor].trim()   : null;

        if (id == null || name.isEmpty || catId == null || unitCode.isEmpty) continue;

        // FK-Checks
        final cat = await (appDb.select(appDb.nutrientsCategorie)
              ..where((c) => c.id.equals(catId)))
            .getSingleOrNull();
        if (cat == null) {
          print('[nutrients import] Warnung: nutrients_categorie_id=$catId existiert nicht (Zeile ${i + 1}).');
          continue;
        }
        final unit = await (appDb.select(appDb.units)
              ..where((u) => u.code.equals(unitCode)))
            .getSingleOrNull();
        if (unit == null) {
          print('[nutrients import] Warnung: unit_code="$unitCode" existiert nicht (Zeile ${i + 1}).');
          continue;
        }

        await appDb.into(appDb.nutrient).insertOnConflictUpdate(
          NutrientCompanion(
            id: d.Value(id),
            name: d.Value(name),
            nutrientsCategorieId: d.Value(catId),
            unitCode: d.Value(unitCode),                              // <— NEU
            picture: d.Value(picture?.isEmpty == true ? null : picture),
            color:   d.Value(color?.isEmpty   == true ? null : color),
          ),
        );
        affected++;
      }
    });

    print('[nutrients import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[nutrients import] Fehler: $e\n$st');
    return 0;
  }
}


/// ----------------------------------------------------------
/// Ingredient-Categories-Import
/// Header: id;title;image
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importIngredientCategoriesFromCsv({
  String assetPath = 'assets/data/ingredient_category.csv',
}) async {
  int affected = 0;

  try {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = latin1.decode(bytes);
    }
    if (text.contains('�')) {
      final latin = latin1.decode(bytes, allowInvalid: true);
      if (latin.split('�').length < text.split('�').length) text = latin;
    }
    if (text.startsWith('\uFEFF')) text = text.substring(1);

    final lines = const LineSplitter().convert(text).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return 0;

    final header = _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    final idxId = header.indexOf('id');
    int idxTitle = header.indexOf('title');
    if (idxTitle < 0) idxTitle = header.indexOf('name'); // Fallback
    final idxImage = header.indexOf('image');

    if (idxId < 0 || idxTitle < 0) {
      print('[ingredient categories import] Ungültiger Header, erwartet: id;title;image');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;

        while (raw.length < header.length) {
          raw.add('');
        }

        final id = int.tryParse(raw[idxId].trim());
        final title = raw[idxTitle].trim();
        final image = idxImage >= 0 ? raw[idxImage].trim() : null;

        if (id == null || title.isEmpty) continue;

        final existing =
            await (appDb.select(appDb.ingredientCategories)..where((t) => t.id.equals(id)))
                .getSingleOrNull();

        if (existing != null) {
          await (appDb.update(appDb.ingredientCategories)..where((t) => t.id.equals(id))).write(
            IngredientCategoriesCompanion(
              title: d.Value(title),
              image: d.Value(image?.isEmpty == true ? existing.image : image),
            ),
          );
        } else {
          await appDb.into(appDb.ingredientCategories).insert(
                IngredientCategoriesCompanion(
                  id: d.Value(id),
                  title: d.Value(title),
                  image: d.Value(image?.isEmpty == true ? null : image),
                ),
              );
        }
        affected++;
      }
    });

    print('[ingredient categories import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[ingredient categories import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// Ingredient-Property-Import
/// Fester Pfad: assets/data/ingredient_property.csv
/// Erwarteter Header: id;name
/// Upsert via id (IDs 1..10)
/// ----------------------------------------------------------
Future<int> importIngredientPropertiesFromCsv() async {
  const assetPath = 'assets/data/ingredient_property.csv';
  int affected = 0;

  try {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = latin1.decode(bytes);
    }
    if (text.startsWith('\uFEFF')) text = text.substring(1);

    final lines = const LineSplitter()
        .convert(text)
        .where((l) => l.trim().isNotEmpty && !l.trimLeft().startsWith('#'))
        .toList();
    if (lines.isEmpty) return 0;

    final header = _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    final idxId = header.indexOf('id');
    final idxName = header.indexOf('name');
    if (idxId < 0 || idxName < 0) {
      print('[ingredient_properties import] Ungültiger Header, erwartet: id;name');
      return 0;
    }

    await appDb.transaction(() async {
      for (var i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;

        while (raw.length < header.length) {
          raw.add('');
        }

        final id = int.tryParse(raw[idxId].trim());
        final name = raw[idxName].trim();

        if (id == null || name.isEmpty) {
          print('[ingredient_properties import] Zeile ${i + 1} übersprungen: ungültige Werte.');
          continue;
        }

        await appDb.into(appDb.ingredientProperties).insertOnConflictUpdate(
              IngredientPropertiesCompanion(
                id: d.Value(id),
                name: d.Value(name),
              ),
            );
        affected++;
      }
    });

    print('[ingredient_properties import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[ingredient_properties import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// Ingredients-Import
/// CSV: assets/data/ingredient.csv
/// Header: id;name;ingredient_category;unit_id;picture
/// - Upsert via id
/// - Validiert FK: ingredient_category gegen IngredientCategories.id
/// - Validiert optionalen FK: unit_id gegen Units.id
/// ----------------------------------------------------------
Future<int> importIngredientsFromCsv({
  String assetPath = 'assets/data/ingredient.csv',
}) async {
  int affected = 0;

  try {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = latin1.decode(bytes);
    }
    if (text.startsWith('\uFEFF')) text = text.substring(1);

    final lines = const LineSplitter()
        .convert(text)
        .where((l) => l.trim().isNotEmpty && !l.trimLeft().startsWith('#'))
        .toList();
    if (lines.isEmpty) return 0;

    final header = _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    final idxId = header.indexOf('id');
    final idxName = header.indexOf('name');
    final idxCat = header.indexOf('ingredient_category');
    final idxUnit = header.indexOf('unit_id');
    final idxPic = header.indexOf('picture');

    if (idxId < 0 || idxName < 0 || idxCat < 0) {
      print('[ingredients import] Ungültiger Header, erwartet: id;name;ingredient_category;unit_id;picture');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;
        while (raw.length < header.length) raw.add('');

        final id = int.tryParse(raw[idxId].trim());
        final name = raw[idxName].trim();
        final catId = int.tryParse(raw[idxCat].trim());
        final unitId = idxUnit >= 0 ? int.tryParse(raw[idxUnit].trim()) : null;
        final picture = idxPic >= 0 ? raw[idxPic].trim() : null;

        if (id == null || name.isEmpty || catId == null) {
          print('[ingredients import] Zeile ${i + 1} übersprungen: ungültige Werte.');
          continue;
        }

        // FK check: Kategorie
        final catExists =
            await (appDb.select(appDb.ingredientCategories)..where((c) => c.id.equals(catId)))
                .getSingleOrNull();
        if (catExists == null) {
          print('[ingredients import] Warnung: ingredient_category=$catId existiert nicht (Zeile ${i + 1}). Übersprungen.');
          continue;
        }

        // FK check: Unit (optional)
        if (unitId != null) {
          final unitExists = await (appDb.select(appDb.units)..where((u) => u.id.equals(unitId)))
              .getSingleOrNull();
          if (unitExists == null) {
            print('[ingredients import] Warnung: unit_id=$unitId existiert nicht (Zeile ${i + 1}). unit_id wird ignoriert.');
          }
        }

        await appDb.into(appDb.ingredients).insertOnConflictUpdate(
              IngredientsCompanion(
                id: d.Value(id),
                name: d.Value(name),
                ingredientCategoryId: d.Value(catId),
                unitId: d.Value(unitId), // kann null sein
                picture: d.Value(picture?.isEmpty == true ? null : picture),
              ),
            );
        affected++;
      }
    });

    print('[ingredients import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[ingredients import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// NEW: Ingredient-Nutrients-Import
/// CSV: assets/data/ingredient_nutrient.csv
/// Header (empfohlen): ingredient_id;nutrient_id;amount_per_100g
/// - Upsert via (ingredient_id, nutrient_id)
/// - validiert FKs: ingredients.id / nutrient.id
/// ----------------------------------------------------------
Future<int> importIngredientNutrientsFromCsv({
  String assetPath = 'assets/data/ingredient_nutrient.csv',
}) async {
  int affected = 0;

  try {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = latin1.decode(bytes);
    }
    if (text.startsWith('\uFEFF')) text = text.substring(1);

    final lines = const LineSplitter().convert(text).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return 0;

    final header = _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    final idxIng = header.indexOf('ingredient_id');
    final idxNut = header.indexOf('nutrient_id');
    int idxAmount = header.indexOf('amount_per_100g');
    if (idxAmount < 0) idxAmount = header.indexOf('amount'); // Fallback

    if (idxIng < 0 || idxNut < 0 || idxAmount < 0) {
      print('[ingredient_nutrients import] Ungültiger Header, erwartet: ingredient_id;nutrient_id;amount_per_100g');
      return 0;
    }

    double? _parseNum(String s) {
      final t = s.trim().replaceAll(',', '.');
      return double.tryParse(t);
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;
        while (raw.length < header.length) raw.add('');

        final ingId = int.tryParse(raw[idxIng].trim());
        final nutId = int.tryParse(raw[idxNut].trim());
        final amount = _parseNum(raw[idxAmount]);

        if (ingId == null || nutId == null || amount == null) {
          print('[ingredient_nutrients import] Zeile ${i + 1} übersprungen: ungültige Werte.');
          continue;
        }

        // FK check: ingredient
        final ingExists =
            await (appDb.select(appDb.ingredients)..where((i) => i.id.equals(ingId))).getSingleOrNull();
        if (ingExists == null) {
          print('[ingredient_nutrients import] Warnung: ingredient_id=$ingId existiert nicht (Zeile ${i + 1}). Übersprungen.');
          continue;
        }

        // FK check: nutrient
        final nutExists =
            await (appDb.select(appDb.nutrient)..where((n) => n.id.equals(nutId))).getSingleOrNull();
        if (nutExists == null) {
          print('[ingredient_nutrients import] Warnung: nutrient_id=$nutId existiert nicht (Zeile ${i + 1}). Übersprungen.');
          continue;
        }

        // Upsert (setzt voraus, dass (ingredient_id, nutrient_id) UNIQUE ist)
        await appDb.into(appDb.ingredientNutrients).insertOnConflictUpdate(
              IngredientNutrientsCompanion(
                ingredientId: d.Value(ingId),
                nutrientId: d.Value(nutId),
                amount: d.Value(amount),
              ),
            );
        affected++;
      }
    });

    print('[ingredient_nutrients import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[ingredient_nutrients import] Fehler: $e\n$st');
    return 0;
  }
}

//// ----------------------------------------------------------
/// Seasonality-Import
/// Header: id;name;color
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importSeasonalityFromCsv({
  String assetPath = 'assets/data/seasonality.csv',
}) async {
  int affected = 0;
  try {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = latin1.decode(bytes);
    }
    if (text.startsWith('\uFEFF')) text = text.substring(1);

    final lines = const LineSplitter().convert(text).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return 0;

    final header = _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();
    final idxId    = header.indexOf('id');
    final idxName  = header.indexOf('name');
    final idxColor = header.indexOf('color');

    if (idxId < 0 || idxName < 0) {
      print('[seasonality import] Ungültiger Header, erwartet: id;name;color');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        while (raw.length < header.length) raw.add('');

        final id    = int.tryParse(raw[idxId].trim());
        final name  = raw[idxName].trim();
        final color = (idxColor >= 0) ? raw[idxColor].trim() : null;

        if (id == null || name.isEmpty) continue;

        await appDb.into(appDb.seasonality).insertOnConflictUpdate(
          SeasonalityCompanion(
            id: d.Value(id),
            name: d.Value(name),
            color: d.Value(color?.isEmpty == true ? null : color),
          ),
        );
        affected++;
      }
    });

    print('[seasonality import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[seasonality import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// Ingredient-Seasonality-Import
/// Header: ingredients_id;months_id;seasonality_id
/// Upsert via PK (ingredients_id, months_id)
/// ----------------------------------------------------------
Future<int> importIngredientSeasonalityFromCsv({
  String assetPath = 'assets/data/ingredient_seasonality.csv',
}) async {
  int affected = 0;
  try {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();

    String text;
    try {
      text = utf8.decode(bytes);
    } catch (_) {
      text = latin1.decode(bytes);
    }
    if (text.startsWith('\uFEFF')) text = text.substring(1);

    final lines = const LineSplitter()
        .convert(text)
        .where((l) => l.trim().isNotEmpty && !l.trimLeft().startsWith('#'))
        .toList();
    if (lines.isEmpty) return 0;

    final header = _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();
    final idxIng    = header.indexOf('ingredients_id');
    final idxMonth  = header.indexOf('months_id');
    final idxSeason = header.indexOf('seasonality_id');

    if (idxIng < 0 || idxMonth < 0 || idxSeason < 0) {
      print('[ingredient_seasonality import] Ungültiger Header, erwartet: ingredients_id;months_id;seasonality_id');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        while (raw.length < header.length) raw.add('');

        final ingId    = int.tryParse(raw[idxIng].trim());
        final monthId  = int.tryParse(raw[idxMonth].trim());
        final seasonId = int.tryParse(raw[idxSeason].trim());

        if (ingId == null || monthId == null || seasonId == null) {
          print('[ingredient_seasonality import] Zeile ${i + 1} übersprungen: ungültige Werte.');
          continue;
        }

        // optionale FK-Checks (gut für Log/Robustheit)
        final ingExists =
            await (appDb.select(appDb.ingredients)..where((t) => t.id.equals(ingId))).getSingleOrNull();
        if (ingExists == null) {
          print('[ingredient_seasonality import] Warnung: ingredient_id=$ingId existiert nicht (Zeile ${i + 1}).');
          continue;
        }
        final monthExists =
            await (appDb.select(appDb.months)..where((t) => t.id.equals(monthId))).getSingleOrNull();
        if (monthExists == null) {
          print('[ingredient_seasonality import] Warnung: months_id=$monthId existiert nicht (Zeile ${i + 1}).');
          continue;
        }
        final seasonExists =
            await (appDb.select(appDb.seasonality)..where((t) => t.id.equals(seasonId))).getSingleOrNull();
        if (seasonExists == null) {
          print('[ingredient_seasonality import] Warnung: seasonality_id=$seasonId existiert nicht (Zeile ${i + 1}).');
          continue;
        }

        await appDb.into(appDb.ingredientSeasonality).insertOnConflictUpdate(
          IngredientSeasonalityCompanion(
            ingredientsId: d.Value(ingId),
            monthsId: d.Value(monthId),
            seasonalityId: d.Value(seasonId),
          ),
        );
        affected++;
      }
    });

    print('[ingredient_seasonality import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[ingredient_seasonality import] Fehler: $e\n$st');
    return 0;
  }
}


/// ----------------------------------------------------------
/// CSV-Helfer
/// ----------------------------------------------------------
List<String> _splitSmart(String line) {
  final delim = line.contains(';') ? ';' : ',';
  final out = <String>[];
  final buf = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    final ch = line[i];
    if (ch == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        buf.write('"');
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch == delim && !inQuotes) {
      out.add(buf.toString());
      buf.clear();
    } else {
      buf.write(ch);
    }
  }
  out.add(buf.toString());
  return out;
}

/// Führt einen einmaligen Erstimport durch …
Future<void> importInitialDataIfEmpty() async {
  final prefs = await SharedPreferences.getInstance();
  const flag = 'initial_data_imported_v5'; // <— Flag bump!

if (prefs.getBool(flag) == true) return;

  // Prüfen, ob schon Daten existieren:
  final MonthCount = await appDb.customSelect('SELECT COUNT(*) c FROM months').getSingle();
  final unitCount = await appDb.customSelect('SELECT COUNT(*) c FROM units').getSingle();
  final nutCatCount = await appDb.customSelect('SELECT COUNT(*) c FROM nutrients_categorie').getSingle();
  final nutCount = await appDb.customSelect('SELECT COUNT(*) c FROM nutrient').getSingle();
  final ingCatCount = await appDb.customSelect('SELECT COUNT(*) c FROM ingredient_categories').getSingle();
  final propCount = await appDb.customSelect('SELECT COUNT(*) c FROM ingredient_properties').getSingle();
  final ingCount = await appDb.customSelect('SELECT COUNT(*) c FROM ingredients').getSingle();
  final ingNutCount = await appDb.customSelect('SELECT COUNT(*) c FROM ingredient_nutrients').getSingle();
  final seasonCount = await appDb.customSelect('SELECT COUNT(*) c FROM seasonality').getSingle();
  final ingseasonCount = await appDb.customSelect('SELECT COUNT(*) c FROM ingredient_seasonality').getSingle();

  int parseCount(row) => (row.data['c'] as int?) ?? (row.data['c'] as num?)?.toInt() ?? 0;

  final hasMonths = parseCount(MonthCount) > 0;
  final hasUnits = parseCount(unitCount) > 0;
  final hasNutCats = parseCount(nutCatCount) > 0;
  final hasNuts = parseCount(nutCount) > 0;
  final hasIngCats = parseCount(ingCatCount) > 0;
  final hasProps = parseCount(propCount) > 0;
  final hasIngs = parseCount(ingCount) > 0;
  final hasIngNuts = parseCount(ingNutCount) > 0;
  final hasSeasons = parseCount(seasonCount) > 0;
  final hasIngSeason = parseCount(ingseasonCount) > 0;

  // Import-Chain (nur fehlende Teile)
  if (!hasMonths)    await seedMonthsIfEmpty();
  if (!hasUnits) await importUnitsFromCsv();
  if (!hasNutCats) await importNutrientCategoriesFromCsv();
  if (!hasNuts) await importNutrientsFromCsv();
  if (!hasIngCats) await importIngredientCategoriesFromCsv();
  if (!hasProps) await importIngredientPropertiesFromCsv();
  if (!hasIngs) await importIngredientsFromCsv();
  if (!hasIngNuts) await importIngredientNutrientsFromCsv();
  if (!hasSeasons)   await importSeasonalityFromCsv();
  if (!hasIngSeason) await importIngredientSeasonalityFromCsv();

  await prefs.setBool(flag, true);
}

/// Re-Import: Upsert aller CSVs in sinnvoller Reihenfolge.
/// Löscht nichts; aktualisiert/füllt nur auf.
Future<void> reimportAllCsvs() async {
  await seedMonthsIfEmpty();
  await importUnitsFromCsv();
  await importNutrientCategoriesFromCsv();
  await importNutrientsFromCsv();
  await importIngredientCategoriesFromCsv();
  await importIngredientPropertiesFromCsv();
  await importIngredientsFromCsv();
  await importIngredientNutrientsFromCsv();
  await importSeasonalityFromCsv();
  await importIngredientSeasonalityFromCsv();
}

/*  // Counts
Future<int> _count(String table) async {
  final row = await appDb
      .customSelect('SELECT COUNT(*) AS c FROM $table')
      .getSingle();

  final v = row.data['c'];
  if (v is int) return v;
  if (v is BigInt) return v.toInt(); // falls SQLite/Drift 64-bit liefert
  return (v as num?)?.toInt() ?? 0;
}

  final hasUnits     = (await _count('units')) > 0;
  final hasNutCats   = (await _count('nutrients_categorie')) > 0;
  final hasNuts      = (await _count('nutrient')) > 0;
  final hasIngCats   = (await _count('ingredient_categories')) > 0;
  final hasProps     = (await _count('ingredient_properties')) > 0;
  final hasIngs      = (await _count('ingredients')) > 0;
  final hasIngNuts   = (await _count('ingredient_nutrients')) > 0;
  final hasMonths    = (await _count('months')) > 0;
  final hasSeasons   = (await _count('seasonality')) > 0;
  final hasIngSeason = (await _count('ingredient_seasonality')) > 0;

  // Import-Kette
  if (!hasUnits)     await importUnitsFromCsv();
  if (!hasNutCats)   await importNutrientCategoriesFromCsv();
  if (!hasNuts)      await importNutrientsFromCsv();
  if (!hasIngCats)   await importIngredientCategoriesFromCsv();
  if (!hasProps)     await importIngredientPropertiesFromCsv();
  if (!hasIngs)      await importIngredientsFromCsv();
  if (!hasIngNuts)   await importIngredientNutrientsFromCsv();

  if (!hasMonths)    await importMonthsFromCsv();
  if (!hasSeasons)   await importSeasonalityFromCsv();
  if (!hasIngSeason) await importIngredientSeasonalityFromCsv();

  await prefs.setBool(flag, true);
}

Future<void> reimportAllCsvs() async {
  await importUnitsFromCsv();
  await importNutrientCategoriesFromCsv();
  await importNutrientsFromCsv();
  await importIngredientCategoriesFromCsv();
  await importIngredientPropertiesFromCsv();
  await importIngredientsFromCsv();
  await importIngredientNutrientsFromCsv();

  await importMonthsFromCsv();
  await importSeasonalityFromCsv();
  await importIngredientSeasonalityFromCsv();
}
*/