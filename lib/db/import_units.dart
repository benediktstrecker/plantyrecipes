// lib/db/import_units.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:drift/drift.dart' as d;
import 'db_singleton.dart';
import 'app_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// --------------------------------------------
/// Units-Import (UTF-8, ; als Trenner)
/// Header: code;label;categorie;baseFactor;plural
/// --------------------------------------------
Future<int> importUnitsFromCsv({String assetPath = 'assets/data/unit.csv'}) async {
  int affected = 0;
  try {
    final csv = await rootBundle.loadString(assetPath);
    final lines = const LineSplitter()
        .convert(csv)
        .where((l) => l.trim().isNotEmpty && !l.trimLeft().startsWith('#'))
        .toList();
    if (lines.isEmpty) return 0;

    final header = lines.first.split(';').map((e) => e.trim().toLowerCase()).toList();
    if (header.length < 4 ||
        header[0] != 'code' ||
        header[1] != 'label' ||
        header[2] != 'categorie' ||
        header[3] != 'basefactor') {
      print('[units import] Header ungültig. Erwartet: code;label;categorie;baseFactor;plural');
      return 0;
    }

    final idxCode = header.indexOf('code');
    final idxLabel = header.indexOf('label');
    final idxCategorie = header.indexOf('categorie');
    final idxBaseFactor = header.indexOf('basefactor');
    final idxPlural = header.indexOf('plural'); // optional

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final parts = lines[i].split(';').map((e) => e.trim()).toList();
        if (parts.length < 4) continue;

        final code = parts[idxCode];
        final label = parts[idxLabel];
        final categorie = parts[idxCategorie];
        final factor = double.tryParse(parts[idxBaseFactor]);
        final plural = idxPlural >= 0 ? parts[idxPlural] : null;

        if (code.isEmpty || label.isEmpty || categorie.isEmpty || factor == null) {
          print('[units import] Zeile ${i + 1} übersprungen: ungültige Werte.');
          continue;
        }

        final existing = await (appDb.select(appDb.units)
              ..where((u) => u.code.equals(code)))
            .getSingleOrNull();

        if (existing == null) {
          await appDb.into(appDb.units).insert(
                UnitsCompanion(
                  code: d.Value(code),
                  label: d.Value(label),
                  categorie: d.Value(categorie),
                  baseFactor: d.Value(factor),
                  plural: d.Value(plural?.isEmpty == true ? null : plural),
                ),
              );
        } else {
          await (appDb.update(appDb.units)..where((u) => u.code.equals(code))).write(
                UnitsCompanion(
                  label: d.Value(label),
                  categorie: d.Value(categorie),
                  baseFactor: d.Value(factor),
                  plural: d.Value(plural?.isEmpty == true ? null : plural),
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
/// Countries-Import
/// CSV: assets/data/countries.csv
/// Header: id;name;image;short;continent
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importCountriesFromCsv({
  String assetPath = 'assets/data/countries.csv',
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

    final header =
        _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    final idxId = header.indexOf('id');
    final idxName = header.indexOf('name');
    final idxImage = header.indexOf('image');
    final idxShort = header.indexOf('short');
    final idxContinent = header.indexOf('continent');

    if (idxId < 0 || idxName < 0) {
      print('[countries import] Ungültiger Header, erwartet: id;name;image;short;continent');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;
        while (raw.length < header.length) raw.add('');

        final id = int.tryParse(raw[idxId].trim());
        final name = raw[idxName].trim();
        final image = idxImage >= 0 ? raw[idxImage].trim() : null;
        final short = idxShort >= 0 ? raw[idxShort].trim() : null;
        final continent = idxContinent >= 0 ? raw[idxContinent].trim() : null;

        if (id == null || name.isEmpty) continue;

        await appDb.into(appDb.countries).insertOnConflictUpdate(
          CountriesCompanion(
            id: d.Value(id),
            name: d.Value(name),
            image: d.Value(image?.isEmpty == true ? null : image),
            short: d.Value(short?.isEmpty == true ? null : short),
            continent: d.Value(continent?.isEmpty == true ? null : continent),
          ),
        );
        affected++;
      }
    });

    print('[countries import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[countries import] Fehler: $e\n$st');
    return 0;
  }
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
/// Trafficlight-Import
/// CSV: assets/data/trafficlight.csv
/// Header: id;name;color
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importTrafficlightFromCsv({
  String assetPath = 'assets/data/trafficlight.csv',
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

    final header =
        _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    final idxId = header.indexOf('id');
    int idxName = header.indexOf('name');
    if (idxName < 0) idxName = header.indexOf('title'); // fallback
    final idxColor = header.indexOf('color');

    if (idxId < 0 || idxName < 0) {
      print('[trafficlight import] Ungültiger Header, erwartet: id;name;color');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;
        while (raw.length < header.length) raw.add('');

        final id = int.tryParse(raw[idxId].trim());
        final name = raw[idxName].trim();
        final color = idxColor >= 0 ? raw[idxColor].trim() : null;

        if (id == null || name.isEmpty) continue;

        await appDb.into(appDb.trafficlight).insertOnConflictUpdate(
          TrafficlightCompanion(
            id: d.Value(id),
            name: d.Value(name),
            color: d.Value(color?.isEmpty == true ? null : color),
          ),
        );
        affected++;
      }
    });

    print('[trafficlight import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[trafficlight import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// Shopshelf-Import
/// CSV: assets/data/shopshelf.csv
/// Header: id;name;color;icon
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importShopshelfFromCsv({
  String assetPath = 'assets/data/shopshelf.csv',
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

    final header =
        _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    final idxId = header.indexOf('id');
    final idxName = header.indexOf('name');
    final idxColor = header.indexOf('color');
    final idxIcon = header.indexOf('icon');

    if (idxId < 0 || idxName < 0) {
      print('[shopshelf import] Ungültiger Header, erwartet: id;name;color;icon');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;
        while (raw.length < header.length) raw.add('');

        final id = int.tryParse(raw[idxId].trim());
        final name = raw[idxName].trim();
        final color = idxColor >= 0 ? raw[idxColor].trim() : null;
        final icon = idxIcon >= 0 ? raw[idxIcon].trim() : null;

        if (id == null || name.isEmpty) continue;

        await appDb.into(appDb.shopshelf).insertOnConflictUpdate(
          ShopshelfCompanion(
            id: d.Value(id),
            name: d.Value(name),
            color: d.Value(color?.isEmpty == true ? null : color),
            icon: d.Value(icon?.isEmpty == true ? null : icon),
          ),
        );
        affected++;
      }
    });

    print('[shopshelf import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[shopshelf import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// StorageCategories-Import
/// CSV: assets/data/storage_categories.csv
/// Header: id;name;icon;color;description
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importStorageCategoriesFromCsv({
  String assetPath = 'assets/data/storage_categories.csv',
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

    final header =
        _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    final idxId = header.indexOf('id');
    final idxName = header.indexOf('name');
    final idxIcon = header.indexOf('icon');
    final idxColor = header.indexOf('color');
    final idxDescription = header.indexOf('description');

    if (idxId < 0 || idxName < 0) {
      print('[storage_categories import] Ungültiger Header, erwartet: id;name;icon;color;description');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;
        while (raw.length < header.length) raw.add('');

        final id = int.tryParse(raw[idxId].trim());
        final name = raw[idxName].trim();
        final icon = idxIcon >= 0 ? raw[idxIcon].trim() : null;
        final color = idxColor >= 0 ? raw[idxColor].trim() : null;
        final description = idxDescription >= 0 ? raw[idxDescription].trim() : null;

        if (id == null || name.isEmpty) continue;

        await appDb.into(appDb.storageCategories).insertOnConflictUpdate(
          StorageCategoriesCompanion(
            id: d.Value(id),
            name: d.Value(name),
            icon: d.Value(icon?.isEmpty == true ? null : icon),
            color: d.Value(color?.isEmpty == true ? null : color),
            description: d.Value(description?.isEmpty == true ? null : description),
          ),
        );
        affected++;
      }
    });

    print('[storage_categories import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[storage_categories import] Fehler: $e\n$st');
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
/// Ingredients-Import
/// CSV: assets/data/ingredient.csv
/// Header:
/// id;name;ingredient_category;picture;singular;
/// products;favorite;bookmark;last_updated;
/// trafficlight_id;storage_cat_id;shelf_id;description;tip
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

    final header =
        _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    final idxId = header.indexOf('id');
    final idxName = header.indexOf('name');
    final idxCat = header.indexOf('ingredient_category');
    final idxPic = header.indexOf('picture');
    final idxSingular = header.indexOf('singular');
    final idxFavorite = header.indexOf('favorite');
    final idxBookmark = header.indexOf('bookmark');
    final idxLastUpdated = header.indexOf('last_updated');
    final idxTrafficlight = header.indexOf('trafficlight_id');
    final idxStoragecat = header.indexOf('storage_cat_id');
    final idxShelf = header.indexOf('shelf_id');
    final idxDescription = header.indexOf('description');
    final idxTip = header.indexOf('tip');

    if (idxId < 0 || idxName < 0 || idxCat < 0) {
      print('[ingredients import] Ungültiger Header.');
      return 0;
    }

    int? _parseInt(String s) => int.tryParse(s.trim());
    int _parseBoolNum(String s) =>
        (s.trim() == '1' || s.trim().toLowerCase() == 'true') ? 1 : 0;

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;
        while (raw.length < header.length) raw.add('');

        final id = _parseInt(raw[idxId]);
        final name = raw[idxName].trim();
        final catId = _parseInt(raw[idxCat]);
        final picture = idxPic >= 0 ? raw[idxPic].trim() : null;
        final singular =
            idxSingular >= 0 ? raw[idxSingular].trim() : null;

        final favorite =
            idxFavorite >= 0 ? _parseBoolNum(raw[idxFavorite]) : 0;
        final bookmark =
            idxBookmark >= 0 ? _parseBoolNum(raw[idxBookmark]) : 0;

        final lastUpdated =
            idxLastUpdated >= 0 ? raw[idxLastUpdated].trim() : null;

        final trafficlightId =
            idxTrafficlight >= 0 ? _parseInt(raw[idxTrafficlight]) : null;
        final storagecatId =
            idxStoragecat >= 0 ? _parseInt(raw[idxStoragecat]) : null;
        final shelfId =
            idxShelf >= 0 ? _parseInt(raw[idxShelf]) : null;

        final description =
            idxDescription >= 0 ? raw[idxDescription].trim() : null;
        final tip =
            idxTip >= 0 ? raw[idxTip].trim() : null;

        if (id == null || name.isEmpty || catId == null) {
          print('[ingredients import] Zeile ${i + 1} ungültig.');
          continue;
        }

        // --- FK Checks ---
        final catExists = await (appDb.select(appDb.ingredientCategories)
              ..where((c) => c.id.equals(catId)))
            .getSingleOrNull();
        if (catExists == null) {
          print('[ingredients import] ingredient_category $catId fehlt (Z${i + 1}).');
          continue;
        }

        if (trafficlightId != null) {
          final t = await (appDb.select(appDb.trafficlight)
                ..where((x) => x.id.equals(trafficlightId)))
              .getSingleOrNull();
          if (t == null) {
            print('[ingredients import] trafficlight_id $trafficlightId fehlt (Z${i + 1}).');
            continue;
          }
        }

        if (storagecatId != null) {
          final s = await (appDb.select(appDb.storageCategories)
                ..where((x) => x.id.equals(storagecatId)))
              .getSingleOrNull();
          if (s == null) {
            print('[ingredients import] storage_cat_id $storagecatId fehlt (Z${i + 1}).');
            continue;
          }
        }

        if (shelfId != null) {
          final sh = await (appDb.select(appDb.shopshelf)
                ..where((x) => x.id.equals(shelfId)))
              .getSingleOrNull();
          if (sh == null) {
            print('[ingredients import] shelf_id $shelfId fehlt (Z${i + 1}).');
            continue;
          }
        }

        await appDb.into(appDb.ingredients).insertOnConflictUpdate(
          IngredientsCompanion(
            id: d.Value(id),
            name: d.Value(name),
            ingredientCategoryId: d.Value(catId),
            picture: d.Value(picture?.isEmpty == true ? null : picture),
            singular: d.Value(singular?.isEmpty == true ? null : singular),
            favorite: d.Value(favorite == 1),
            bookmark: d.Value(bookmark == 1),
            lastUpdated:
                d.Value(lastUpdated?.isEmpty == true ? null : lastUpdated),
            trafficlightId: d.Value(trafficlightId),
            storagecatId: d.Value(storagecatId),
            shelfId: d.Value(shelfId),
            description:
                d.Value(description?.isEmpty == true ? null : description),
            tip: d.Value(tip?.isEmpty == true ? null : tip),
          ),
        );

        affected++;
      }
    });

    print('[ingredients import] Fertig: $affected Zeilen');
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

/// ----------------------------------------------------------
/// Ingredient-Units-Import
/// CSV: assets/data/ingredient_unit.csv
/// Header: id;ingredient_id;unit_code;amount
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importIngredientUnitsFromCsv({
  String assetPath = 'assets/data/ingredient_unit.csv',
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

    final header =
        _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    final idxId = header.indexOf('id');
    final idxIng = header.indexOf('ingredient_id');
    final idxUnit = header.indexOf('unit_code');
    final idxAmount = header.indexOf('amount');

    if (idxId < 0 || idxIng < 0 || idxUnit < 0 || idxAmount < 0) {
      print('[ingredient_units import] Ungültiger Header, erwartet: id;ingredient_id;unit_code;amount');
      return 0;
    }

    double? _parseNum(String s) {
      final t = s.trim().replaceAll(',', '.');
      return double.tryParse(t);
    }

    await appDb.transaction(() async {
      for (var i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;
        while (raw.length < header.length) raw.add('');

        final id = int.tryParse(raw[idxId].trim());
        final ingId = int.tryParse(raw[idxIng].trim());
        final unitCode = raw[idxUnit].trim();
        final amount = _parseNum(raw[idxAmount]);

        if (id == null || ingId == null || unitCode.isEmpty || amount == null) {
          print('[ingredient_units import] Zeile ${i + 1} übersprungen: ungültige Werte.');
          continue;
        }

        // FK-Prüfungen
        final ingExists = await (appDb.select(appDb.ingredients)
              ..where((t) => t.id.equals(ingId)))
            .getSingleOrNull();
        if (ingExists == null) {
          print('[ingredient_units import] Warnung: ingredient_id=$ingId existiert nicht (Zeile ${i + 1}).');
          continue;
        }

        final unitExists = await (appDb.select(appDb.units)
              ..where((u) => u.code.equals(unitCode)))
            .getSingleOrNull();
        if (unitExists == null) {
          print('[ingredient_units import] Warnung: unit_code=$unitCode existiert nicht (Zeile ${i + 1}).');
          continue;
        }

        await appDb.into(appDb.ingredientUnits).insertOnConflictUpdate(
          IngredientUnitsCompanion(
            id: d.Value(id),
            ingredientId: d.Value(ingId),
            unitCode: d.Value(unitCode),
            amount: d.Value(amount),
          ),
        );
        affected++;
      }
    });

    print('[ingredient_units import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[ingredient_units import] Fehler: $e\n$st');
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
/// Import: alternatives.csv
/// CSV-Header: id;name;show
/// ----------------------------------------------------------
Future<int> importAlternativesFromCsv({
  String assetPath = 'assets/data/alternatives.csv',
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

    if (lines.length <= 1) return 0;

    final header =
        lines.first.split(';').map((e) => e.trim().toLowerCase()).toList();

    final idxId = header.indexOf('id');
    final idxName = header.indexOf('name');
    final idxShow = header.indexOf('show');

    if (idxId < 0 || idxName < 0 || idxShow < 0) {
      print('[alternatives import] Fehler: ungültiger CSV-Header!');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final row = lines[i].split(';');

        final id = int.tryParse(row[idxId].trim());
        final name = row[idxName].trim();
        final show = row[idxShow].trim() == '1';

        if (id == null) {
          print('[alternatives import] Zeile ${i + 1} ignoriert (keine ID)');
          continue;
        }

        await appDb.into(appDb.alternatives).insertOnConflictUpdate(
              AlternativesCompanion(
                id: d.Value(id),
                name: d.Value(name),
                show: d.Value(show),
              ),
            );

        affected++;
      }
    });

    print('[alternatives import] Fertig → $affected Zeilen verarbeitet');
    return affected;
  } catch (e, st) {
    print('[alternatives import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// Import: ingredient_alternatives.csv
/// CSV-Header:
/// ingredient_id;related_ingredient_id;alternatives_id;share
/// ----------------------------------------------------------
Future<int> importIngredientAlternativesFromCsv({
  String assetPath = 'assets/data/ingredient_alternatives.csv',
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

    if (lines.length <= 1) return 0;

    final header =
        lines.first.split(';').map((e) => e.trim().toLowerCase()).toList();

    final idxIng = header.indexOf('ingredient_id');
    final idxRel = header.indexOf('related_ingredient_id');
    final idxAlt = header.indexOf('alternatives_id');
    final idxShare = header.indexOf('share');

    if (idxIng < 0 || idxRel < 0 || idxAlt < 0) {
      print('[ingredient_alternatives import] Fehler: Ungültiger Header!');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final row = lines[i].split(';');

        final ingredientId = int.tryParse(row[idxIng]);
        final relatedId = int.tryParse(row[idxRel]);
        final altId = int.tryParse(row[idxAlt]);
        final share = row[idxShare].trim().isEmpty
            ? null
            : double.tryParse(row[idxShare]);

        if (ingredientId == null || relatedId == null || altId == null) {
          print(
              '[ingredient_alternatives import] Zeile ${i + 1} ignoriert (fehlende ID)');
          continue;
        }

        await appDb.into(appDb.ingredientAlternatives).insert(
              IngredientAlternativesCompanion(
                ingredientId: d.Value(ingredientId),
                relatedIngredientId: d.Value(relatedId),
                alternativesId: d.Value(altId),
                share: share == null ? const d.Value.absent() : d.Value(share),
              ),
            );

        affected++;
      }
    });

    print('[ingredient_alternatives import] Fertig → $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[ingredient_alternatives import] Fehler: $e\n$st');
    return 0;
  }
}


/// ----------------------------------------------------------
/// Recipe-Categories-Import
/// Header: id;title;image
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importRecipeCategoriesFromCsv({
  String assetPath = 'assets/data/recipe_category.csv',
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
    int idxTitle = header.indexOf('title');
    if (idxTitle < 0) idxTitle = header.indexOf('name');
    final idxImage = header.indexOf('image');
    if (idxId < 0 || idxTitle < 0) {
      print('[recipe categories import] Ungültiger Header.');
      return 0;
    }

    await appDb.transaction(() async {
      for (var i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;
        while (raw.length < header.length) raw.add('');
        final id = int.tryParse(raw[idxId].trim());
        final title = raw[idxTitle].trim();
        final image = idxImage >= 0 ? raw[idxImage].trim() : null;
        if (id == null || title.isEmpty) continue;

        await appDb.into(appDb.recipeCategories).insertOnConflictUpdate(
          RecipeCategoriesCompanion(
            id: d.Value(id),
            title: d.Value(title),
            image: d.Value(image?.isEmpty == true ? null : image),
          ),
        );
        affected++;
      }
    });

    print('[recipe categories import] Fertig: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[recipe categories import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// Recipes-Import (UTF-8/Latin-1 tolerant; ; oder ,)
/// Header:
/// id;name;recipe_category;picture;portion_number;portion_unit;cook_counter;
/// favorite;bookmark;last_cooked;last_updated;inspired_by;description;tip
/// ----------------------------------------------------------
Future<int> importRecipesFromCsv({
  String assetPath = 'assets/data/recipe.csv',
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

    final header =
        _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    // Indexe definieren
    final idxId = header.indexOf('id');
    final idxName = header.indexOf('name');
    final idxCat = header.indexOf('recipe_category');
    final idxPic = header.indexOf('picture');
    final idxPortNum = header.indexOf('portion_number');
    final idxPortUnit = header.indexOf('portion_unit');
    final idxCookCounter = header.indexOf('cook_counter');
    final idxFavorite = header.indexOf('favorite');
    final idxBookmark = header.indexOf('bookmark');
    final idxLastCooked = header.indexOf('last_cooked');
    final idxLastUpdated = header.indexOf('last_updated');
    final idxInspiredBy = header.indexOf('inspired_by');
    final idxDescription = header.indexOf('description');
    final idxTip = header.indexOf('tip');

    if (idxId < 0 || idxName < 0 || idxCat < 0) {
      print('[recipes import] Ungültiger Header. Erwartet: id;name;recipe_category;picture;portion_number;portion_unit;...');
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

        final id = int.tryParse(raw[idxId].trim());
        final name = raw[idxName].trim();
        final catId = int.tryParse(raw[idxCat].trim());
        final picture = idxPic >= 0 ? raw[idxPic].trim() : null;

        if (id == null || name.isEmpty || catId == null) {
          print('[recipes import] Zeile ${i + 1} übersprungen: ungültige Werte.');
          continue;
        }

        // Optionalfelder
        final portionNumber =
            idxPortNum >= 0 ? _parseNum(raw[idxPortNum])?.toInt() : null;
        final portionUnit = idxPortUnit >= 0 ? raw[idxPortUnit].trim() : null;

        final cookCounter =
            idxCookCounter >= 0 ? _parseNum(raw[idxCookCounter])?.toInt() ?? 0 : 0;
        final favorite =
            idxFavorite >= 0 ? _parseNum(raw[idxFavorite])?.toInt() ?? 0 : 0;
        final bookmark =
            idxBookmark >= 0 ? _parseNum(raw[idxBookmark])?.toInt() ?? 0 : 0;
        final lastCooked = idxLastCooked >= 0 ? raw[idxLastCooked].trim() : null;
        final lastUpdated = idxLastUpdated >= 0 ? raw[idxLastUpdated].trim() : null;
        final inspiredBy = idxInspiredBy >= 0 ? raw[idxInspiredBy].trim() : null;
        final description = idxDescription >= 0 ? raw[idxDescription].trim() : null;
        final tip = idxTip >= 0 ? raw[idxTip].trim() : null;

        // FK check: Kategorie
        final catExists = await (appDb.select(appDb.recipeCategories)
              ..where((c) => c.id.equals(catId)))
            .getSingleOrNull();
        if (catExists == null) {
          print('[recipes import] Warnung: recipe_category=$catId existiert nicht (Zeile ${i + 1}). Übersprungen.');
          continue;
        }

        // FK check: Portionseinheit (Unit-Code)
        if (portionUnit != null && portionUnit.isNotEmpty) {
          final unitExists = await (appDb.select(appDb.units)
                ..where((u) => u.code.equals(portionUnit)))
              .getSingleOrNull();
          if (unitExists == null) {
            print('[recipes import] Warnung: portion_unit="$portionUnit" existiert nicht (Zeile ${i + 1}).');
            continue;
          }
        }

        await appDb.into(appDb.recipes).insertOnConflictUpdate(
              RecipesCompanion(
                id: d.Value(id),
                name: d.Value(name),
                recipeCategory: d.Value(catId),
                picture: d.Value(picture?.isEmpty == true ? null : picture),
                portionNumber: d.Value(portionNumber),
                portionUnit: d.Value(portionUnit?.isEmpty == true ? null : portionUnit),
                cookCounter: d.Value(cookCounter),
                favorite: d.Value(favorite),
                bookmark: d.Value(bookmark),
                lastCooked: d.Value(lastCooked?.isEmpty == true ? null : lastCooked),
                lastUpdated: d.Value(lastUpdated?.isEmpty == true ? null : lastUpdated),
                inspiredBy: d.Value(inspiredBy?.isEmpty == true ? null : inspiredBy),
                description: d.Value(description?.isEmpty == true ? null : description),
                tip: d.Value(tip?.isEmpty == true ? null : tip),
              ),
            );

        affected++;
      }
    });

    print('[recipes import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[recipes import] Fehler: $e\n$st');
    return 0;
  }
}



/// ----------------------------------------------------------
/// Recipe-Ingredients-Import
/// CSV: assets/data/recipe_ingredient.csv
/// Header: id;recipe_id;ingredient_id;unit_code;amount
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importRecipeIngredientsFromCsv({
  String assetPath = 'assets/data/recipe_ingredient.csv',
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

    final header =
        _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    final idxId = header.indexOf('id');
    final idxRec = header.indexOf('recipe_id');
    final idxIng = header.indexOf('ingredient_id');
    final idxUnit = header.indexOf('unit_code');
    final idxAmount = header.indexOf('amount');

    if (idxId < 0 || idxRec < 0 || idxIng < 0 || idxUnit < 0 || idxAmount < 0) {
      print('[recipe_ingredient import] Ungültiger Header, erwartet: id;recipe_id;ingredient_id;unit_code;amount');
      return 0;
    }

    double? _parseNum(String s) {
      final t = s.trim().replaceAll(',', '.');
      return double.tryParse(t);
    }

    await appDb.transaction(() async {
      for (var i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;
        while (raw.length < header.length) raw.add('');

        final id = int.tryParse(raw[idxId].trim());
        final recipeId = int.tryParse(raw[idxRec].trim());
        final ingredientId = int.tryParse(raw[idxIng].trim());
        final unitCode = raw[idxUnit].trim();
        final amount = _parseNum(raw[idxAmount]);

        if (id == null || recipeId == null || ingredientId == null || unitCode.isEmpty || amount == null) {
          print('[recipe_ingredient import] Zeile ${i + 1} übersprungen: ungültige Werte.');
          continue;
        }

        // FK-Prüfungen
        final recipeExists = await (appDb.select(appDb.recipes)
              ..where((t) => t.id.equals(recipeId)))
            .getSingleOrNull();
        if (recipeExists == null) {
          print('[recipe_ingredient import] Warnung: recipe_id=$recipeId existiert nicht (Zeile ${i + 1}).');
          continue;
        }

        final ingredientExists = await (appDb.select(appDb.ingredients)
              ..where((t) => t.id.equals(ingredientId)))
            .getSingleOrNull();
        if (ingredientExists == null) {
          print('[recipe_ingredient import] Warnung: ingredient_id=$ingredientId existiert nicht (Zeile ${i + 1}).');
          continue;
        }

        final unitExists = await (appDb.select(appDb.units)
              ..where((u) => u.code.equals(unitCode)))
            .getSingleOrNull();
        if (unitExists == null) {
          print('[recipe_ingredient import] Warnung: unit_code=$unitCode existiert nicht (Zeile ${i + 1}).');
          continue;
        }

        await appDb.into(appDb.recipeIngredients).insertOnConflictUpdate(
          RecipeIngredientsCompanion(
            id: d.Value(id),
            recipeId: d.Value(recipeId),
            ingredientId: d.Value(ingredientId),
            unitCode: d.Value(unitCode),
            amount: d.Value(amount),
          ),
        );

        affected++;
      }
    });

    print('[recipe_ingredient import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[recipe_ingredient import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// Tag-Categories-Import
/// Header: id;name;color
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importTagCategoriesFromCsv({
  String assetPath = 'assets/data/tag_categorie.csv',
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

    final header =
        _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();
    final idxId = header.indexOf('id');
    final idxName = header.indexOf('name');
    final idxColor = header.indexOf('color');

    if (idxId < 0 || idxName < 0) {
      print('[tag categories import] Ungültiger Header, erwartet: id;name;color');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        while (raw.length < header.length) raw.add('');
        final id = int.tryParse(raw[idxId].trim());
        final name = raw[idxName].trim();
        final color = idxColor >= 0 ? raw[idxColor].trim() : null;
        if (id == null || name.isEmpty) continue;

        await appDb.into(appDb.tagCategories).insertOnConflictUpdate(
          TagCategoriesCompanion(
            id: d.Value(id),
            name: d.Value(name),
            color: d.Value(color?.isEmpty == true ? null : color),
          ),
        );
        affected++;
      }
    });

    print('[tag categories import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[tag categories import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// Tags-Import
/// Header: id;name;tag_categorie_id;image;color
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importTagsFromCsv({
  String assetPath = 'assets/data/tags.csv',
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

    final header =
        _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();
    final idxId = header.indexOf('id');
    final idxName = header.indexOf('name');
    final idxCat = header.indexOf('tag_categorie_id');
    final idxImg = header.indexOf('image');
    final idxColor = header.indexOf('color');

    if (idxId < 0 || idxName < 0 || idxCat < 0) {
      print('[tags import] Ungültiger Header, erwartet: id;name;tag_categorie_id;image;color');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        while (raw.length < header.length) raw.add('');

        final id = int.tryParse(raw[idxId].trim());
        final name = raw[idxName].trim();
        final catId = int.tryParse(raw[idxCat].trim());
        final image = idxImg >= 0 ? raw[idxImg].trim() : null;
        final color = idxColor >= 0 ? raw[idxColor].trim() : null;

        if (id == null || name.isEmpty || catId == null) continue;

        // FK check
        final catExists = await (appDb.select(appDb.tagCategories)
              ..where((c) => c.id.equals(catId)))
            .getSingleOrNull();
        if (catExists == null) {
          print('[tags import] Warnung: tag_categorie_id=$catId existiert nicht (Zeile ${i + 1}). Übersprungen.');
          continue;
        }

        await appDb.into(appDb.tags).insertOnConflictUpdate(
          TagsCompanion(
            id: d.Value(id),
            name: d.Value(name),
            tagCategorieId: d.Value(catId),
            image: d.Value(image?.isEmpty == true ? null : image),
            color: d.Value(color?.isEmpty == true ? null : color),
          ),
        );
        affected++;
      }
    });

    print('[tags import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[tags import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// Recipe-Tags-Import
/// CSV: assets/data/recipe_tag.csv
/// Header: recipe_id;tags_id        // keine id-Spalte
/// Upsert via PK (recipe_id, tags_id)
/// ----------------------------------------------------------
Future<int> importRecipeTagsFromCsv({
  String assetPath = 'assets/data/recipe_tag.csv',
}) async {
  int affected = 0;
  try {
    final data = await rootBundle.load(assetPath);
    var text = utf8.decode(data.buffer.asUint8List(), allowMalformed: true);
    if (text.startsWith('\uFEFF')) text = text.substring(1);

    final lines = const LineSplitter()
        .convert(text)
        .where((l) => l.trim().isNotEmpty && !l.trimLeft().startsWith('#'))
        .toList();
    if (lines.isEmpty) return 0;

    final header = _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();
    final idxRec = header.indexOf('recipe_id');
    final idxTag = header.indexOf('tags_id');
    if (idxRec < 0 || idxTag < 0) {
      print('[recipe_tags import] Ungültiger Header, erwartet: recipe_id;tags_id');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;
        while (raw.length < header.length) raw.add('');

        final recipeId = int.tryParse(raw[idxRec].trim());
        final tagId    = int.tryParse(raw[idxTag].trim());
        if (recipeId == null || tagId == null) continue;

        // FK-Checks
        final rec = await (appDb.select(appDb.recipes)..where((r) => r.id.equals(recipeId))).getSingleOrNull();
        if (rec == null) { print('[recipe_tags import] recipe_id=$recipeId fehlt (Z${i+1})'); continue; }
        final tag = await (appDb.select(appDb.tags)..where((t) => t.id.equals(tagId))).getSingleOrNull();
        if (tag == null) { print('[recipe_tags import] tags_id=$tagId fehlt (Z${i+1})'); continue; }

        // Upsert via zusammengesetztem PK
        await appDb.into(appDb.recipeTags).insertOnConflictUpdate(
          RecipeTagsCompanion(
            recipeId: d.Value(recipeId),
            tagId: d.Value(tagId),
          ),
        );
        affected++;
      }
    });

    print('[recipe_tags import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[recipe_tags import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// Ingredient-Tags-Import
/// CSV: assets/data/ingredient_tag.csv
/// Header: ingredient_id;tags_id     // keine id-Spalte
/// Upsert via PK (ingredient_id, tags_id)
/// ----------------------------------------------------------
Future<int> importIngredientTagsFromCsv({
  String assetPath = 'assets/data/ingredient_tag.csv',
}) async {
  int affected = 0;
  try {
    final data = await rootBundle.load(assetPath);
    var text = utf8.decode(data.buffer.asUint8List(), allowMalformed: true);
    if (text.startsWith('\uFEFF')) text = text.substring(1);

    final lines = const LineSplitter()
        .convert(text)
        .where((l) => l.trim().isNotEmpty && !l.trimLeft().startsWith('#'))
        .toList();
    if (lines.isEmpty) return 0;

    final header =
        _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();
    final idxIng = header.indexOf('ingredient_id');
    final idxTag = header.indexOf('tags_id');

    if (idxIng < 0 || idxTag < 0) {
      print('[ingredient_tags import] Ungültiger Header, erwartet: ingredient_id;tags_id');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;
        while (raw.length < header.length) raw.add('');

        final ingId = int.tryParse(raw[idxIng].trim());
        final tagId = int.tryParse(raw[idxTag].trim());
        if (ingId == null || tagId == null) continue;

        // FK-Checks
        final ingExists = await (appDb.select(appDb.ingredients)
              ..where((i) => i.id.equals(ingId)))
            .getSingleOrNull();
        if (ingExists == null) {
          print('[ingredient_tags import] ingredient_id=$ingId fehlt (Z${i + 1})');
          continue;
        }

        final tagExists = await (appDb.select(appDb.tags)
              ..where((t) => t.id.equals(tagId)))
            .getSingleOrNull();
        if (tagExists == null) {
          print('[ingredient_tags import] tags_id=$tagId fehlt (Z${i + 1})');
          continue;
        }

        await appDb.into(appDb.ingredientTags).insertOnConflictUpdate(
          IngredientTagsCompanion(
            ingredientId: d.Value(ingId),
            tagsId: d.Value(tagId),
          ),
        );
        affected++;
      }
    });

    print('[ingredient_tags import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[ingredient_tags import] Fehler: $e\n$st');
    return 0;
  }
}


/// ----------------------------------------------------------
/// Markets-Import
/// CSV: assets/data/markets.csv
/// Header: id;name;picture;color;favorite
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importMarketsFromCsv({
  String assetPath = 'assets/data/markets.csv',
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

    final header = _splitSmart(lines.first)
        .map((s) => s.trim().toLowerCase())
        .toList();

    final idxId       = header.indexOf('id');
    final idxName     = header.indexOf('name');
    final idxPicture  = header.indexOf('picture');
    final idxColor    = header.indexOf('color');
    final idxFavorite = header.indexOf('favorite');

    if (idxId < 0 || idxName < 0) {
      print('[markets import] Ungültiger Header, erwartet: id;name;picture;color;favorite');
      return 0;
    }

    bool _parseBool(String s) {
      final v = s.trim().toLowerCase();
      return v == '1' || v == 'true' || v == 'yes' || v == 'ja';
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;

        while (raw.length < header.length) raw.add('');

        final id      = int.tryParse(raw[idxId].trim());
        final name    = raw[idxName].trim();
        final picture = idxPicture >= 0 ? raw[idxPicture].trim() : null;
        final color   = idxColor >= 0 ? raw[idxColor].trim() : null;

        final favStr  = idxFavorite >= 0 ? raw[idxFavorite].trim() : '0';
        final favorite = _parseBool(favStr);

        if (id == null || name.isEmpty) continue;

        await appDb.into(appDb.markets).insertOnConflictUpdate(
          MarketsCompanion(
            id: d.Value(id),
            name: d.Value(name),
            picture: d.Value(picture?.isEmpty == true ? null : picture),
            color: d.Value(color?.isEmpty == true ? null : color),
            favorite: d.Value(favorite),
          ),
        );

        affected++;
      }
    });

    print('[markets import] Fertig, verarbeitet: $affected Zeilen');
    return affected;

  } catch (e, st) {
    print('[markets import] Fehler: $e\n$st');
    return 0;
  }
}


/// ----------------------------------------------------------
/// Producers-Import
/// CSV: assets/data/producers.csv
/// Header: id;name;picture;color
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importProducersFromCsv({
  String assetPath = 'assets/data/producers.csv',
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
    final idxPicture = header.indexOf('picture');
    final idxColor = header.indexOf('color');

    if (idxId < 0 || idxName < 0) {
      print('[producers import] Ungültiger Header, erwartet: id;name;picture;color');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        while (raw.length < header.length) raw.add('');

        final id = int.tryParse(raw[idxId].trim());
        final name = raw[idxName].trim();
        final picture = idxPicture >= 0 ? raw[idxPicture].trim() : null;
        final color = idxColor >= 0 ? raw[idxColor].trim() : null;

        if (id == null || name.isEmpty) continue;

        await appDb.into(appDb.producers).insertOnConflictUpdate(
          ProducersCompanion(
            id: d.Value(id),
            name: d.Value(name),
            picture: d.Value(picture?.isEmpty == true ? null : picture),
            color: d.Value(color?.isEmpty == true ? null : color),
          ),
        );
        affected++;
      }
    });

    print('[producers import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[producers import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// Products-Import (NEU)
/// CSV: assets/data/products.csv
/// Neuer Header:
/// id;name;ingredient_name;ingredient_id;producer_name;producer_id;
/// image;favorite;EAN;bio;size_number;size_unit_code;yield_unit_code;yield_amount
/// ----------------------------------------------------------
Future<int> importProductsFromCsv({
  String assetPath = 'assets/data/products.csv',
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

    final header =
        _splitSmart(lines.first).map((e) => e.trim().toLowerCase()).toList();

    // Index Mapping
    final idxId = header.indexOf('id');
    final idxName = header.indexOf('name');
    final idxIngId = header.indexOf('ingredient_id');
    final idxProdId = header.indexOf('producer_id');
    final idxImage = header.indexOf('image');
    final idxFavorite = header.indexOf('favorite');
    final idxEAN = header.indexOf('ean');
    final idxBio = header.indexOf('bio');
    final idxSizeNumber = header.indexOf('size_number');
    final idxSizeUnit = header.indexOf('size_unit_code');
    final idxYieldUnit = header.indexOf('yield_unit_code');
    final idxYieldAmount = header.indexOf('yield_amount');

    if (idxId < 0 || idxName < 0) {
      print('[products import] Ungültiger Header für neue Products-Struktur.');
      return 0;
    }

    double? _parseNum(String s) {
      final t = s.trim().replaceAll(',', '.');
      return double.tryParse(t);
    }

    bool _parseBool(String s) {
      final v = s.trim().toLowerCase();
      return v == '1' || v == 'true' || v == 'yes' || v == 'ja';
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final row = _splitSmart(lines[i]);
        if (row.isEmpty) continue;
        while (row.length < header.length) row.add('');

        final id = int.tryParse(row[idxId].trim());
        final name = row[idxName].trim();

        final ingredientId =
            idxIngId >= 0 ? int.tryParse(row[idxIngId].trim()) : null;

        final producerId =
            idxProdId >= 0 ? int.tryParse(row[idxProdId].trim()) : null;

        final image = idxImage >= 0 ? row[idxImage].trim() : null;

        final favorite =
            idxFavorite >= 0 ? _parseBool(row[idxFavorite]) : false;

        final ean = idxEAN >= 0 ? int.tryParse(row[idxEAN].trim()) : null;

        final bio = idxBio >= 0 ? _parseBool(row[idxBio]) : false;

        final sizeNumber =
            idxSizeNumber >= 0 ? _parseNum(row[idxSizeNumber]) : null;

        final sizeUnit =
            idxSizeUnit >= 0 ? row[idxSizeUnit].trim() : null;

        final yieldUnit =
            idxYieldUnit >= 0 ? row[idxYieldUnit].trim() : null;

        final yieldAmount =
            idxYieldAmount >= 0 ? _parseNum(row[idxYieldAmount]) : null;

        if (id == null || name.isEmpty) continue;

        // ------------------------------------------
        // FK-Prüfungen
        // ------------------------------------------
        if (ingredientId != null) {
          final ing = await (appDb.select(appDb.ingredients)
                ..where((t) => t.id.equals(ingredientId)))
              .getSingleOrNull();
          if (ing == null) {
            print('[products import] ingredient_id=$ingredientId nicht gefunden (Z${i + 1})');
            continue;
          }
        }

        if (producerId != null) {
          final prod = await (appDb.select(appDb.producers)
                ..where((t) => t.id.equals(producerId)))
              .getSingleOrNull();
          if (prod == null) {
            print('[products import] producer_id=$producerId nicht gefunden (Z${i + 1})');
            continue;
          }
        }

        if (sizeUnit != null && sizeUnit.isNotEmpty) {
          final u = await (appDb.select(appDb.units)
                ..where((t) => t.code.equals(sizeUnit)))
              .getSingleOrNull();
          if (u == null) {
            print('[products import] size_unit_code="$sizeUnit" fehlt (Z${i + 1})');
            continue;
          }
        }

        if (yieldUnit != null && yieldUnit.isNotEmpty) {
          final u = await (appDb.select(appDb.units)
                ..where((t) => t.code.equals(yieldUnit)))
              .getSingleOrNull();
          if (u == null) {
            print('[products import] yield_unit_code="$yieldUnit" fehlt (Z${i + 1})');
            continue;
          }
        }

        // ------------------------------------------
        // INSERT / UPSERT
        // ------------------------------------------
        await appDb.into(appDb.products).insertOnConflictUpdate(
          ProductsCompanion(
            id: d.Value(id),
            name: d.Value(name),
            ingredientId: d.Value(ingredientId ?? 0),
            producerId: d.Value(producerId ?? 0),
            image: d.Value(image?.isEmpty == true ? null : image),
            favorite: d.Value(favorite),
            EAN: d.Value(ean),
            bio: d.Value(bio),
            sizeNumber: d.Value(sizeNumber),
            sizeUnitCode:
                d.Value(sizeUnit?.isEmpty == true ? null : sizeUnit),
            yieldUnitCode:
                d.Value(yieldUnit?.isEmpty == true ? null : yieldUnit),
            yieldAmount: d.Value(yieldAmount),
          ),
        );

        affected++;
      }
    });

    print('[products import] Fertig, verarbeitet: $affected Zeilen');
    return affected;

  } catch (e, st) {
    print('[products import] Fehler: $e\n$st');
    return 0;
  }
}


// ----------------------------------------------------------
// Product-Markets-Import
// CSV: assets/data/product_markets.csv
// Neuer Header: id;products_id;market_id;price;date
// Upsert via PK: id
// ----------------------------------------------------------
Future<int> importProductMarketsFromCsv({
  String assetPath = 'assets/data/product_markets.csv',
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

    final header =
        _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    // Neue Indexe
    final idxId      = header.indexOf('id');
    final idxProd    = header.indexOf('products_id');
    final idxMarket  = header.indexOf('market_id');
    final idxPrice   = header.indexOf('price');
    final idxDate    = header.indexOf('date');

    if (idxId < 0 || idxProd < 0 || idxMarket < 0 || idxPrice < 0) {
      print('[product_markets import] Ungültiger Header.');
      return 0;
    }

    double? _parseNum(String s) {
      final t = s.trim().replaceAll(',', '.');
      return double.tryParse(t);
    }

    DateTime? _parseDate(String s) {
      final v = s.trim();
      if (v.isEmpty) return null;

      // Timestamp?
      final ts = int.tryParse(v);
      if (ts != null) {
        try {
          return DateTime.fromMillisecondsSinceEpoch(ts);
        } catch (_) {}
      }

      // ISO oder andere gängige Formate
      try {
        return DateTime.parse(v);
      } catch (_) {}

      // Versuch DD.MM.YYYY
      final parts = v.split('.');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          return DateTime(y, m, d);
        }
      }

      print('[product_markets import] Ungültiges Datum "$v".');
      return null;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);

        while (raw.length < header.length) raw.add('');

        final id        = int.tryParse(raw[idxId].trim());
        final productId = int.tryParse(raw[idxProd].trim());
        final marketId  = int.tryParse(raw[idxMarket].trim());
        final price     = _parseNum(raw[idxPrice]);
        final dateValue = idxDate >= 0 ? _parseDate(raw[idxDate]) : null;

        if (id == null || productId == null || marketId == null) {
          print('[product_markets import] Zeile ${i + 1} übersprungen.');
          continue;
        }

        // FK-Checks: Produkt
        final prodExists =
            await (appDb.select(appDb.products)..where((t) => t.id.equals(productId)))
                .getSingleOrNull();
        if (prodExists == null) {
          print('[product_markets import] Warning: products_id=$productId fehlt (Z${i + 1}).');
          continue;
        }

        // FK-Checks: Markt
        final marketExists =
            await (appDb.select(appDb.markets)..where((t) => t.id.equals(marketId)))
                .getSingleOrNull();
        if (marketExists == null) {
          print('[product_markets import] Warning: market_id=$marketId fehlt (Z${i + 1}).');
          continue;
        }

        await appDb.into(appDb.productMarkets).insertOnConflictUpdate(
          ProductMarketsCompanion(
            id: d.Value(id),
            productsId: d.Value(productId),
            marketId: d.Value(marketId),
            price: d.Value(price),
            date: d.Value(dateValue),
          ),
        );

        affected++;
      }
    });

    print('[product_markets import] Fertig, verarbeitet: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[product_markets import] Fehler: $e\n$st');
    return 0;
  }
}


// ----------------------------------------------------------
// Ingredient-Market-Import
// CSV: assets/data/ingredient_market.csv
// Neuer Header:
// id;ingredient_name;ingredient_id;market_name;market_id;
// name;bio;unit_code;unit_amount;price;package_unit_code;favorite
// ----------------------------------------------------------
Future<int> importIngredientMarketFromCsv({
  String assetPath = 'assets/data/ingredient_market.csv',
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

    final header = _splitSmart(lines.first)
        .map((s) => s.trim().toLowerCase())
        .toList();

    // --------------------------------------------------
    // Header-Indizes
    // --------------------------------------------------
    final idxId              = header.indexOf('id');
    final idxIng             = header.indexOf('ingredient_id');
    final idxMarket          = header.indexOf('market_id');
    final idxName            = header.indexOf('name');
    final idxBio             = header.indexOf('bio');
    final idxUnitCode        = header.indexOf('unit_code');
    final idxUnitAmount      = header.indexOf('unit_amount');
    final idxPrice           = header.indexOf('price');
    final idxPackageUnitCode = header.indexOf('package_unit_code');
    final idxFavorite        = header.indexOf('favorite');

    if (idxId < 0 || idxIng < 0 || idxMarket < 0) {
      print('[ingredient_market import] Ungültiger Header.');
      return 0;
    }

    bool _parseBool(String s) {
      final v = s.trim().toLowerCase();
      return v == '1' || v == 'true' || v == 'yes' || v == 'ja';
    }

    double? _parseNum(String s) {
      final t = s.trim().replaceAll(',', '.');
      return double.tryParse(t);
    }

    // --------------------------------------------------
    // Import als Transaktion
    // --------------------------------------------------
    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;
        while (raw.length < header.length) raw.add('');

        final id     = int.tryParse(raw[idxId].trim());
        final ingId  = int.tryParse(raw[idxIng].trim());
        final market = int.tryParse(raw[idxMarket].trim());

        final name   = idxName >= 0 ? raw[idxName].trim() : null;
        final bio    = idxBio >= 0 ? _parseBool(raw[idxBio]) : false;

        final unitCode =
            idxUnitCode >= 0 ? raw[idxUnitCode].trim() : null;

        final packageUnitCode =
            idxPackageUnitCode >= 0 ? raw[idxPackageUnitCode].trim() : null;

        final unitAmount =
            idxUnitAmount >= 0 ? _parseNum(raw[idxUnitAmount]) : null;

        final price =
            idxPrice >= 0 ? _parseNum(raw[idxPrice]) : null;

        final favorite =
            idxFavorite >= 0 ? _parseBool(raw[idxFavorite]) : false;

        if (id == null || ingId == null || market == null) {
          print('[ingredient_market import] Zeile ${i + 1} übersprungen.');
          continue;
        }

        // --------------------------------------------------
        // FK-Checks
        // --------------------------------------------------

        final ingExists = await (appDb.select(appDb.ingredients)
              ..where((t) => t.id.equals(ingId)))
            .getSingleOrNull();

        if (ingExists == null) {
          print('[ingredient_market import] ingredient_id=$ingId fehlt (Z${i + 1}).');
          continue;
        }

        final marketExists = await (appDb.select(appDb.markets)
              ..where((t) => t.id.equals(market)))
            .getSingleOrNull();

        if (marketExists == null) {
          print('[ingredient_market import] market_id=$market fehlt (Z${i + 1}).');
          continue;
        }

        if (unitCode != null && unitCode.isNotEmpty) {
          final unitExists = await (appDb.select(appDb.units)
                ..where((t) => t.code.equals(unitCode)))
              .getSingleOrNull();

          if (unitExists == null) {
            print('[ingredient_market import] unit_code=$unitCode fehlt (Z${i + 1}).');
            continue;
          }
        }

        if (packageUnitCode != null && packageUnitCode.isNotEmpty) {
          final unitExists = await (appDb.select(appDb.units)
                ..where((t) => t.code.equals(packageUnitCode)))
              .getSingleOrNull();

          if (unitExists == null) {
            print('[ingredient_market import] package_unit_code=$packageUnitCode fehlt (Z${i + 1}).');
            continue;
          }
        }

        // --------------------------------------------------
        // INSERT / UPSERT
        // --------------------------------------------------
        await appDb.into(appDb.ingredientMarket).insertOnConflictUpdate(
          IngredientMarketCompanion(
            id: d.Value(id),
            ingredientId: d.Value(ingId),
            marketId: d.Value(market),
            name: d.Value(name),
            bio: d.Value(bio),
            unitCode:
                d.Value(unitCode?.isEmpty == true ? null : unitCode),
            unitAmount: d.Value(unitAmount),
            price: d.Value(price),
            packageUnitCode: d.Value(
                packageUnitCode?.isEmpty == true ? null : packageUnitCode),
            favorite: d.Value(favorite),
          ),
        );

        affected++;
      }
    });

    print('[ingredient_market import] Fertig: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[ingredient_market import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// ProductCountry-Import
/// CSV: assets/data/product_country.csv
/// Header: products_id;countries_id
/// Upsert via (products_id, countries_id)
/// ----------------------------------------------------------
Future<int> importProductCountryFromCsv({
  String assetPath = 'assets/data/product_country.csv',
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

    final header =
        _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    final idxProd = header.indexOf('products_id');
    final idxCountry = header.indexOf('countries_id');

    if (idxProd < 0 || idxCountry < 0) {
      print('[product_country import] Ungültiger Header, erwartet: products_id;countries_id');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        while (raw.length < header.length) raw.add('');

        final productId = int.tryParse(raw[idxProd].trim());
        final countryId = int.tryParse(raw[idxCountry].trim());

        if (productId == null || countryId == null) continue;

        // FK prüfen: Produkt
        final prod = await (appDb.select(appDb.products)
              ..where((t) => t.id.equals(productId)))
            .getSingleOrNull();
        if (prod == null) {
          print('[product_country import] Produkt fehlt: $productId (Z${i + 1})');
          continue;
        }

        // FK prüfen: Country
        final country = await (appDb.select(appDb.countries)
              ..where((t) => t.id.equals(countryId)))
            .getSingleOrNull();
        if (country == null) {
          print('[product_country import] Country fehlt: $countryId (Z${i + 1})');
          continue;
        }

        await appDb.into(appDb.productCountry).insertOnConflictUpdate(
          ProductCountryCompanion(
            productsId: d.Value(productId),
            countriesId: d.Value(countryId),
          ),
        );

        affected++;
      }
    });

    print('[product_country import] Fertig: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[product_country import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// IngredientMarketCountry-Import
/// CSV: assets/data/ingredient_market_country.csv
/// Header: ingredient_market_id;countries_id
/// Upsert via (ingredient_market_id, countries_id)
/// ----------------------------------------------------------
Future<int> importIngredientMarketCountryFromCsv({
  String assetPath = 'assets/data/ingredient_market_country.csv',
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

    final header =
        _splitSmart(lines.first).map((s) => s.trim().toLowerCase()).toList();

    final idxIM = header.indexOf('ingredient_market_id');
    final idxCountry = header.indexOf('countries_id');

    if (idxIM < 0 || idxCountry < 0) {
      print('[ingredient_market_country import] Ungültiger Header, erwartet: ingredient_market_id;countries_id');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        while (raw.length < header.length) raw.add('');

        final ingredientMarketId = int.tryParse(raw[idxIM].trim());
        final countryId = int.tryParse(raw[idxCountry].trim());

        if (ingredientMarketId == null || countryId == null) continue;

        // FK prüfen: IngredientMarket
        final im = await (appDb.select(appDb.ingredientMarket)
              ..where((t) => t.id.equals(ingredientMarketId)))
            .getSingleOrNull();
        if (im == null) {
          print('[ingredient_market_country import] IngredientMarket fehlt: $ingredientMarketId (Z${i + 1})');
          continue;
        }

        // FK prüfen: Country
        final country = await (appDb.select(appDb.countries)
              ..where((t) => t.id.equals(countryId)))
            .getSingleOrNull();
        if (country == null) {
          print('[ingredient_market_country import] Country fehlt: $countryId (Z${i + 1})');
          continue;
        }

        await appDb.into(appDb.ingredientMarketCountry).insertOnConflictUpdate(
          IngredientMarketCountryCompanion(
            ingredientMarketId: d.Value(ingredientMarketId),
            countriesId: d.Value(countryId),
          ),
        );

        affected++;
      }
    });

    print('[ingredient_market_country import] Fertig: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[ingredient_market_country import] Fehler: $e\n$st');
    return 0;
  }
}



/// ----------------------------------------------------------
/// Shopping-List-Import
/// CSV: assets/data/shopping_list.csv
/// Header: id;name;date_shopping;date_created;market_id;last_edited;done;recipt_image
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importShoppingListFromCsv({
  String assetPath = 'assets/data/shopping_list.csv',
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

    final header = _splitSmart(lines.first)
        .map((s) => s.trim().toLowerCase())
        .toList();

    // ---------- Index-Mapping ----------
    final idxId           = header.indexOf('id');
    final idxName         = header.indexOf('name');
    final idxDateShopping = header.indexOf('date_shopping');
    final idxDateCreated  = header.indexOf('date_created');
    final idxMarketId     = header.indexOf('market_id');
    final idxLastEdited   = header.indexOf('last_edited');
    final idxDone         = header.indexOf('done');
    final idxReciptImage  = header.indexOf('recipt_image');  // NEU

    bool _parseBool(String s) {
      final v = s.trim().toLowerCase();
      return v == '1' || v == 'true' || v == 'yes' || v == 'ja';
    }

    // ------------ DATUMS-Parser ------------
    DateTime? _parseDate(String? s) {
      if (s == null || s.trim().isEmpty) return null;

      final v = s.trim();

      // FALL 1 – ISO8601
      try {
        return DateTime.parse(v);
      } catch (_) {}

      // FALL 2 – deutsches Format dd.MM.yyyy
      try {
        final parts = v.split('.');
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) {
            return DateTime(y, m, d);
          }
        }
      } catch (_) {}

      print("[CSV] WARNUNG: Datum konnte nicht geparst werden: $v");
      return null;
    }

    // ------------ Import ------------
    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;
        while (raw.length < header.length) raw.add('');

        final id   = int.tryParse(raw[idxId].trim());
        final name = raw[idxName].trim();
        final done = _parseBool(idxDone >= 0 ? raw[idxDone].trim() : '0');

        final dateShopping =
            idxDateShopping >= 0 ? _parseDate(raw[idxDateShopping]) : null;

        final dateCreated =
            idxDateCreated >= 0 ? _parseDate(raw[idxDateCreated]) : null;

        final lastEdited =
            idxLastEdited >= 0 ? _parseDate(raw[idxLastEdited]) : null;

        // NEU: Bildpfad aus CSV
        final reciptImage =
            idxReciptImage >= 0 ? raw[idxReciptImage].trim() : null;

        int? marketId;
        if (idxMarketId >= 0) {
          final rawMarket = raw[idxMarketId].trim();
          final parsed = int.tryParse(rawMarket);
          if (parsed != null && parsed > 0) marketId = parsed;
        }

        if (id == null || name.isEmpty) {
          print('[shopping_list import] Zeile ${i + 1} übersprungen: ungültig.');
          continue;
        }

        // ----------------------
        // INSERT / UPSERT
        // ----------------------
        await appDb.into(appDb.shoppingList).insertOnConflictUpdate(
          ShoppingListCompanion(
            id: d.Value(id),
            name: d.Value(name),
            dateShopping: d.Value(dateShopping),
            dateCreated: d.Value(dateCreated),
            lastEdited: d.Value(lastEdited),
            marketId: d.Value(marketId),
            done: d.Value(done),

            // NEU
            reciptImage: d.Value(reciptImage?.isEmpty == true ? null : reciptImage),
          ),
        );

        affected++;
      }
    });

    print('[shopping_list import] Fertig: $affected Zeilen importiert');
    return affected;

  } catch (e, st) {
    print('[shopping_list import] Fehler: $e\n$st');
    return 0;
  }
}


/// ----------------------------------------------------------
/// Shopping-List-Ingredient-Import
/// CSV: assets/data/shopping_list_ingredient.csv
/// ----------------------------------------------------------
Future<int> importShoppingListIngredientFromCsv({
  String assetPath = 'assets/data/shopping_list_ingredient.csv',
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

    final header = _splitSmart(lines.first)
        .map((s) => s.trim().toLowerCase())
        .toList();

    // Index-Mapping
    final idxId      = header.indexOf('id');
    final idxList    = header.indexOf('shopping_list_id');

    final idxRecipe  = header.indexOf('recipe_id');
    final idxPort    = header.indexOf('recipe_portion_number_id');

    final idxIngNom  = header.indexOf('ingredient_id_nominal');
    final idxAmtNom  = header.indexOf('ingredient_amount_nominal');
    final idxUnitNom = header.indexOf('ingredient_unit_code_nominal');

    final idxProdNom     = header.indexOf('product_id_nominal');
    final idxProdAmtNom  = header.indexOf('product_amount_nominal');

    final idxIngMarketNom     = header.indexOf('ingredient_market_id_nominal');
    final idxIngMarketAmtNom  = header.indexOf('ingredient_market_amount_nominal');

    final idxBasket = header.indexOf('basket');
    final idxBought = header.indexOf('bought');
    final idxPrice  = header.indexOf('price');
    final idxCountry = header.indexOf('country_id');

    final idxIngAct  = header.indexOf('ingredient_id_actual');
    final idxAmtAct  = header.indexOf('ingredient_amount_actual');
    final idxUnitAct = header.indexOf('ingredient_unit_code_actual');

    final idxProdAct     = header.indexOf('product_id_actual');
    final idxProdAmtAct  = header.indexOf('product_amount_actual');

    final idxIngMarketAct     = header.indexOf('ingredient_market_id_actual');
    final idxIngMarketAmtAct  = header.indexOf('ingredient_market_amount_actual');

    final idxPriceActual = header.indexOf('price_actual');


    if (idxId < 0 || idxList < 0) {
      print('[shopping_list_ingredient import] Ungültiger Header.');
      return 0;
    }

    bool _parseBool(String s) {
      final v = s.trim().toLowerCase();
      return v == '1' || v == 'true' || v == 'yes' || v == 'ja';
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

        // Basiskeys
        final id     = int.tryParse(raw[idxId].trim());
        final listId = int.tryParse(raw[idxList].trim());

        final recipeId =
            idxRecipe >= 0 ? int.tryParse(raw[idxRecipe].trim()) : null;

        final recipePortionNumberId =
            idxPort >= 0 ? int.tryParse(raw[idxPort].trim()) : null;

        // Nominal Ingredient
        final ingNom  = idxIngNom >= 0 ? int.tryParse(raw[idxIngNom].trim()) : null;
        final amtNom  = idxAmtNom >= 0 ? _parseNum(raw[idxAmtNom]) : null;
        final unitNom = idxUnitNom >= 0 ? raw[idxUnitNom].trim() : null;

        // Nominal Product
        final prodNom =
            idxProdNom >= 0 ? int.tryParse(raw[idxProdNom].trim()) : null;
        final prodAmtNom =
            idxProdAmtNom >= 0 ? _parseNum(raw[idxProdAmtNom]) : null;

        // Nominal Ingredient-Market
        final ingMarketNom =
            idxIngMarketNom >= 0 ? int.tryParse(raw[idxIngMarketNom].trim()) : null;
        final ingMarketAmtNom =
            idxIngMarketAmtNom >= 0 ? _parseNum(raw[idxIngMarketAmtNom]) : null;

        // Status
        final basket  = idxBasket >= 0 ? _parseBool(raw[idxBasket]) : false;
        final bought  = idxBought >= 0 ? _parseBool(raw[idxBought]) : false;

        final price = idxPrice >= 0 ? _parseNum(raw[idxPrice]) : null;
        final countryId =
            idxCountry >= 0 ? int.tryParse(raw[idxCountry].trim()) : null;

        // Actual Ingredient
        final ingAct =
            idxIngAct >= 0 ? int.tryParse(raw[idxIngAct].trim()) : null;
        final amtAct =
            idxAmtAct >= 0 ? _parseNum(raw[idxAmtAct]) : null;
        final unitAct =
            idxUnitAct >= 0 ? raw[idxUnitAct].trim() : null;

        // Actual Product
        final prodAct =
            idxProdAct >= 0 ? int.tryParse(raw[idxProdAct].trim()) : null;
        final prodAmtAct =
            idxProdAmtAct >= 0 ? _parseNum(raw[idxProdAmtAct]) : null;

        // Actual Ingredient-Market
        final ingMarketAct =
            idxIngMarketAct >= 0 ? int.tryParse(raw[idxIngMarketAct].trim()) : null;
        final ingMarketAmtAct =
            idxIngMarketAmtAct >= 0 ? _parseNum(raw[idxIngMarketAmtAct]) : null;

        // Actual Price
        final priceActual =
            idxPriceActual >= 0 ? _parseNum(raw[idxPriceActual]) : null;


        if (id == null || listId == null) continue;

        // FK Prüfen
        final listExists = await (appDb.select(appDb.shoppingList)
              ..where((t) => t.id.equals(listId)))
            .getSingleOrNull();
        if (listExists == null) continue;

        if (ingNom != null) {
          final e = await (appDb.select(appDb.ingredients)
                ..where((t) => t.id.equals(ingNom)))
              .getSingleOrNull();
          if (e == null) continue;
        }

        if (unitNom != null && unitNom.isNotEmpty) {
          final e = await (appDb.select(appDb.units)
                ..where((t) => t.code.equals(unitNom)))
              .getSingleOrNull();
          if (e == null) continue;
        }

        if (prodNom != null) {
          final e = await (appDb.select(appDb.products)
                ..where((t) => t.id.equals(prodNom)))
              .getSingleOrNull();
          if (e == null) continue;
        }

        if (ingMarketNom != null) {
          final e = await (appDb.select(appDb.ingredientMarket)
                ..where((t) => t.id.equals(ingMarketNom)))
              .getSingleOrNull();
          if (e == null) continue;
        }

        if (countryId != null) {
          final e = await (appDb.select(appDb.countries)
                ..where((t) => t.id.equals(countryId)))
              .getSingleOrNull();
          if (e == null) continue;
        }

        if (ingAct != null) {
          final e = await (appDb.select(appDb.ingredients)
                ..where((t) => t.id.equals(ingAct)))
              .getSingleOrNull();
          if (e == null) continue;
        }

        if (unitAct != null && unitAct.isNotEmpty) {
          final e = await (appDb.select(appDb.units)
                ..where((t) => t.code.equals(unitAct)))
              .getSingleOrNull();
          if (e == null) continue;
        }

        if (prodAct != null) {
          final e = await (appDb.select(appDb.products)
                ..where((t) => t.id.equals(prodAct)))
              .getSingleOrNull();
          if (e == null) continue;
        }

        if (ingMarketAct != null) {
          final e = await (appDb.select(appDb.ingredientMarket)
                ..where((t) => t.id.equals(ingMarketAct)))
              .getSingleOrNull();
          if (e == null) continue;
        }

        // UPSERT
        await appDb.into(appDb.shoppingListIngredient).insertOnConflictUpdate(
          ShoppingListIngredientCompanion(
            id: d.Value(id),
            shoppingListId: d.Value(listId),

            recipeId: d.Value(recipeId),
            recipePortionNumberId: d.Value(recipePortionNumberId),

            ingredientIdNominal: d.Value(ingNom),
            ingredientAmountNominal: d.Value(amtNom),
            ingredientUnitCodeNominal:
                d.Value(unitNom?.isEmpty == true ? null : unitNom),

            productIdNominal: d.Value(prodNom),
            productAmountNominal: d.Value(prodAmtNom),

            ingredientMarketIdNominal: d.Value(ingMarketNom),
            ingredientMarketAmountNominal: d.Value(ingMarketAmtNom),

            basket: d.Value(basket),
            bought: d.Value(bought),
            price: d.Value(price),
            countryId: d.Value(countryId),

            ingredientIdActual: d.Value(ingAct),
            ingredientAmountActual: d.Value(amtAct),
            ingredientUnitCodeActual:
                d.Value(unitAct?.isEmpty == true ? null : unitAct),

            productIdActual: d.Value(prodAct),
            productAmountActual: d.Value(prodAmtAct),

            ingredientMarketIdActual: d.Value(ingMarketAct),
            ingredientMarketAmountActual: d.Value(ingMarketAmtAct),

            priceActual: d.Value(priceActual),
          ),
        );

        affected++;
      }
    });

    print('[shopping_list_ingredient import] Fertig: $affected Zeilen');
    return affected;
  } catch (e, st) {
    print('[shopping_list_ingredient import] Fehler: $e\n$st');
    return 0;
  }
}

/// ----------------------------------------------------------
/// Storage-Import
/// CSV: assets/data/storage.csv
/// Header: id;name;icon;availability
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importStorageFromCsv({
  String assetPath = 'assets/data/storage.csv',
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

    // ------------------------------
    // Header lesen
    // ------------------------------
    final header = _splitSmart(lines.first)
        .map((s) => s.trim().toLowerCase())
        .toList();

    final idxId     = header.indexOf('id');
    final idxName   = header.indexOf('name');
    final idxIcon   = header.indexOf('icon');
    final idxAvail  = header.indexOf('availability');

    if (idxId < 0 || idxName < 0 || idxAvail < 0) {
      print('[storage import] Ungültiger Header, erwartet: id;name;icon;availability');
      return 0;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;

        while (raw.length < header.length) raw.add('');

        final id    = int.tryParse(raw[idxId].trim());
        final name  = raw[idxName].trim();
        final icon  = idxIcon >= 0 ? raw[idxIcon].trim() : null;

        // availability (CSV: 0/1)
        final availRaw = raw[idxAvail].trim();
        final availability = (availRaw == '1');

        if (id == null || name.isEmpty) continue;

        await appDb.into(appDb.storage).insertOnConflictUpdate(
          StorageCompanion(
            id: d.Value(id),
            name: d.Value(name),
            icon: d.Value(icon?.isEmpty == true ? null : icon),
            availability: d.Value(availability),
          ),
        );

        affected++;
      }
    });

    print('[storage import] Fertig, verarbeitet: $affected Zeilen');
    return affected;

  } catch (e, st) {
    print('[storage import] Fehler: $e\n$st');
    return 0;
  }
}


/// ----------------------------------------------------------
/// IngredientStorage-Import
/// CSV: assets/data/ingredient_storage.csv
/// Header: ingredient_id;storage_id;amount;unit_code
/// Upsert via (ingredient_id, storage_id)
/// ----------------------------------------------------------
Future<int> importIngredientStorageFromCsv({
  String assetPath = 'assets/data/ingredient_storage.csv',
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

    final header = _splitSmart(lines.first)
        .map((s) => s.trim().toLowerCase())
        .toList();

    final idxIngId   = header.indexOf('ingredient_id');
    final idxStorId  = header.indexOf('storage_id');
    final idxAmount  = header.indexOf('amount');
    final idxUnit    = header.indexOf('unit_code');

    if (idxIngId < 0 || idxStorId < 0 || idxAmount < 0 || idxUnit < 0) {
      print('[ingredient_storage import] Ungültiger Header, erwartet: ingredient_id;storage_id;amount;unit_code');
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

        final ingId  = int.tryParse(raw[idxIngId].trim());
        final storId = int.tryParse(raw[idxStorId].trim());
        final amount = _parseNum(raw[idxAmount]);
        final unit   = raw[idxUnit].trim();

        if (ingId == null || storId == null || amount == null || unit.isEmpty) {
          print('[ingredient_storage import] Zeile ${i + 1} übersprungen');
          continue;
        }

        // FK: ingredient
        final ingExists = await (appDb.select(appDb.ingredients)
              ..where((t) => t.id.equals(ingId)))
            .getSingleOrNull();

        if (ingExists == null) {
          print('[ingredient_storage import] ingredient_id=$ingId fehlt (Z${i + 1})');
          continue;
        }

        // FK: storage
        final storExists = await (appDb.select(appDb.storage)
              ..where((t) => t.id.equals(storId)))
            .getSingleOrNull();

        if (storExists == null) {
          print('[ingredient_storage import] storage_id=$storId fehlt (Z${i + 1})');
          continue;
        }

        // FK: unit_code
        final unitExists = await (appDb.select(appDb.units)
              ..where((t) => t.code.equals(unit)))
            .getSingleOrNull();

        if (unitExists == null) {
          print('[ingredient_storage import] unit_code="$unit" fehlt (Z${i + 1})');
          continue;
        }

        await appDb.into(appDb.ingredientStorage).insertOnConflictUpdate(
          IngredientStorageCompanion(
            ingredientId: d.Value(ingId),
            storageId: d.Value(storId),
            amount: d.Value(amount),
            unitCode: d.Value(unit),
          ),
        );

        affected++;
      }
    });

    print('[ingredient_storage import] Fertig: $affected Zeilen');
    return affected;

  } catch (e, st) {
    print('[ingredient_storage import] Fehler: $e\n$st');
    return 0;
  }
}


/// ----------------------------------------------------------
/// Stock-Import
/// CSV: assets/data/stock.csv
/// Header:
/// id;ingredient_id;storage_id;shopping_list_id;date_entry;amount;unit_code
/// Upsert via id
/// ----------------------------------------------------------
Future<int> importStockFromCsv({
  String assetPath = 'assets/data/stock.csv',
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
        .where(
          (l) => l.trim().isNotEmpty && !l.trimLeft().startsWith('#'),
        )
        .toList();
    if (lines.isEmpty) return 0;

    final header = _splitSmart(lines.first)
        .map((s) => s.trim().toLowerCase())
        .toList();

    final idxId           = header.indexOf('id');
    final idxIng          = header.indexOf('ingredient_id');
    final idxStorage      = header.indexOf('storage_id');
    final idxShoppingList = header.indexOf('shopping_list_id');   // NEU
    final idxDate         = header.indexOf('date_entry');
    final idxAmount       = header.indexOf('amount');
    final idxUnitCode     = header.indexOf('unit_code');

    if (idxId < 0 || idxIng < 0 || idxStorage < 0 || idxDate < 0) {
      print('[stock import] Ungültiger Header, erwartet: id;ingredient_id;storage_id;shopping_list_id;date_entry;amount;unit_code');
      return 0;
    }

    double? _parseNum(String s) {
      final t = s.trim().replaceAll(',', '.');
      return double.tryParse(t);
    }

    DateTime? _parseDate(String v) {
      v = v.trim();
      if (v.isEmpty) return null;

      try {
        return DateTime.parse(v);
      } catch (_) {}

      final parts = v.split('.');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          return DateTime(y, m, d);
        }
      }

      print('[stock import] Ungültiges Datum: "$v"');
      return null;
    }

    await appDb.transaction(() async {
      for (int i = 1; i < lines.length; i++) {
        final raw = _splitSmart(lines[i]);
        if (raw.isEmpty) continue;

        while (raw.length < header.length) raw.add('');

        final id            = int.tryParse(raw[idxId].trim());
        final ingId         = int.tryParse(raw[idxIng].trim());
        final storageId     = int.tryParse(raw[idxStorage].trim());
        final shoppingListId = idxShoppingList >= 0
            ? int.tryParse(raw[idxShoppingList].trim())
            : null;
        final dateEntry     = _parseDate(raw[idxDate].trim());
        final amount        = idxAmount >= 0 ? _parseNum(raw[idxAmount]) : null;
        final unitCode      = idxUnitCode >= 0 ? raw[idxUnitCode].trim() : null;

        if (id == null || ingId == null || storageId == null || dateEntry == null) {
          print('[stock import] Zeile ${i + 1} übersprungen');
          continue;
        }

        // FK: ingredient
        final ingExists = await (appDb.select(appDb.ingredients)
              ..where((t) => t.id.equals(ingId)))
            .getSingleOrNull();
        if (ingExists == null) {
          print('[stock import] ingredient_id=$ingId fehlt (Z${i + 1})');
          continue;
        }

        // FK: storage
        final storageExists = await (appDb.select(appDb.storage)
              ..where((t) => t.id.equals(storageId)))
            .getSingleOrNull();
        if (storageExists == null) {
          print('[stock import] storage_id=$storageId fehlt (Z${i + 1})');
          continue;
        }

        // NEU: FK: shopping_list_id
        if (shoppingListId != null) {
          final slExists = await (appDb.select(appDb.shoppingList)
                ..where((t) => t.id.equals(shoppingListId)))
              .getSingleOrNull();
          if (slExists == null) {
            print('[stock import] shopping_list_id=$shoppingListId fehlt (Z${i + 1})');
            continue;
          }
        }

        // FK: unit_code
        if (unitCode != null && unitCode.isNotEmpty) {
          final unitExists = await (appDb.select(appDb.units)
                ..where((t) => t.code.equals(unitCode)))
              .getSingleOrNull();
          if (unitExists == null) {
            print('[stock import] unit_code=$unitCode fehlt (Z${i + 1})');
            continue;
          }
        }

        await appDb.into(appDb.stock).insertOnConflictUpdate(
          StockCompanion(
            id: d.Value(id),
            ingredientId: d.Value(ingId),
            storageId: d.Value(storageId),
            shoppingListId: d.Value(shoppingListId),
            dateEntry: d.Value(dateEntry),
            amount: d.Value(amount),
            unitCode: d.Value(unitCode?.isEmpty == true ? null : unitCode),
          ),
        );

        affected++;
      }
    });

    print('[stock import] Fertig: $affected Zeilen');
    return affected;

  } catch (e, st) {
    print('[stock import] Fehler: $e\n$st');
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
  final countryCount = await appDb.customSelect('SELECT COUNT(*) c FROM countries').getSingle();
  final unitCount = await appDb.customSelect('SELECT COUNT(*) c FROM units').getSingle();
  final nutCatCount = await appDb.customSelect('SELECT COUNT(*) c FROM nutrients_categorie').getSingle();
  final nutCount = await appDb.customSelect('SELECT COUNT(*) c FROM nutrient').getSingle();
  final trafficlightCount = await appDb.customSelect('SELECT COUNT(*) c FROM trafficlight').getSingle();
  final shopshelfCount = await appDb.customSelect('SELECT COUNT(*) c FROM shopshelf').getSingle();
  final storageCatCount = await appDb.customSelect('SELECT COUNT(*) c FROM storage_categories').getSingle();
  final ingCatCount = await appDb.customSelect('SELECT COUNT(*) c FROM ingredient_categories').getSingle();
  final ingCount = await appDb.customSelect('SELECT COUNT(*) c FROM ingredients').getSingle();
  final ingNutCount = await appDb.customSelect('SELECT COUNT(*) c FROM ingredient_nutrients').getSingle();
  final ingUnitCount = await appDb.customSelect('SELECT COUNT(*) c FROM ingredient_units').getSingle();
  final seasonCount = await appDb.customSelect('SELECT COUNT(*) c FROM seasonality').getSingle();
  final ingseasonCount = await appDb.customSelect('SELECT COUNT(*) c FROM ingredient_seasonality').getSingle();
  final altCount = await appDb.customSelect('SELECT COUNT(*) AS c FROM alternatives').getSingle();
  final ingAltCount = await appDb.customSelect('SELECT COUNT(*) AS c FROM ingredient_alternatives').getSingle();
  final recCatCount = await appDb.customSelect('SELECT COUNT(*) c FROM recipe_categories').getSingle();
  final recCount = await appDb.customSelect('SELECT COUNT(*) c FROM recipes').getSingle();
  final recIngCount = await appDb.customSelect('SELECT COUNT(*) c FROM recipe_ingredients').getSingle();
  final tagCatCount = await appDb.customSelect('SELECT COUNT(*) c FROM tag_categories').getSingle();
  final tagCount = await appDb.customSelect('SELECT COUNT(*) c FROM tags').getSingle();
  final recTagCount = await appDb.customSelect('SELECT COUNT(*) c FROM recipe_tags').getSingle();
  final ingTagCount = await appDb.customSelect('SELECT COUNT(*) c FROM ingredient_tags').getSingle();
  final marketsCount = await appDb.customSelect('SELECT COUNT(*) c FROM markets').getSingle();
  final producersCount = await appDb.customSelect('SELECT COUNT(*) c FROM producers').getSingle();
  final productsCount = await appDb.customSelect('SELECT COUNT(*) c FROM products').getSingle();
  final productMarketsCount = await appDb.customSelect('SELECT COUNT(*) c FROM product_markets').getSingle();
  final ingredientMarketsCount = await appDb.customSelect('SELECT COUNT(*) c FROM ingredient_market').getSingle();
  final productcountriesCount = await appDb.customSelect('SELECT COUNT(*) c FROM product_country').getSingle();
  final ingmarcountriesCount = await appDb.customSelect('SELECT COUNT(*) c FROM ingredient_market_country').getSingle();
  final shoppingListCount = await appDb.customSelect('SELECT COUNT(*) c FROM shopping_list').getSingle();
  final shoppingListIngCount = await appDb.customSelect('SELECT COUNT(*) c FROM shopping_list_ingredient').getSingle();
  final storageCount = await appDb.customSelect('SELECT COUNT(*) c FROM storage').getSingle();
  final ingredientStorageCount = await appDb.customSelect('SELECT COUNT(*) c FROM ingredient_storage').getSingle();
  final stockCount = await appDb.customSelect('SELECT COUNT(*) c FROM stock').getSingle();





  int parseCount(row) => (row.data['c'] as int?) ?? (row.data['c'] as num?)?.toInt() ?? 0;

  final hasMonths = parseCount(MonthCount) > 0;
  final hasCountries = parseCount(countryCount) > 0;
  final hasUnits = parseCount(unitCount) > 0;
  final hasNutCats = parseCount(nutCatCount) > 0;
  final hasNuts = parseCount(nutCount) > 0;
  final hasTrafficlight = parseCount(trafficlightCount) > 0;
  final hasshopshelf = parseCount(shopshelfCount) > 0;
  final hasstorageCat = parseCount(storageCatCount) > 0;
  final hasIngCats = parseCount(ingCatCount) > 0;
  final hasIngs = parseCount(ingCount) > 0;
  final hasIngNuts = parseCount(ingNutCount) > 0;
  final hasIngUnits = parseCount(ingUnitCount) > 0;
  final hasSeasons = parseCount(seasonCount) > 0;
  final hasIngSeason = parseCount(ingseasonCount) > 0;
  final hasAlts = parseCount(altCount) > 0;
  final hasIngAlts = parseCount(ingAltCount) > 0;
  final hasRecCats = parseCount(recCatCount) > 0;
  final hasRecs = parseCount(recCount) > 0;
  final hasRecIngs = parseCount(recIngCount) > 0;
  final hasTagCats = parseCount(tagCatCount) > 0;
  final hasTags = parseCount(tagCount) > 0;
  final hasRecTags = parseCount(recTagCount) > 0;
  final hasIngTags = parseCount(ingTagCount) > 0;
  final hasmarkets = parseCount(marketsCount) > 0;
  final hasProducers = parseCount(producersCount) > 0;
  final hasProducts = parseCount(productsCount) > 0;
  final hasProductMarkets = parseCount(productMarketsCount) > 0;
  final hasIngredientMarkets = parseCount(ingredientMarketsCount) > 0;
  final hasProductCountries = parseCount(productcountriesCount) > 0;
  final hasIngMarCountries = parseCount(ingmarcountriesCount) > 0;
  final hasShoppingList = parseCount(shoppingListCount) > 0;
  final hasShoppingListIngredients = parseCount(shoppingListIngCount) > 0;
  final hasStorage = parseCount(storageCount) > 0;
  final hasIngredientStorage = parseCount(ingredientStorageCount) > 0;
  final hasStock = parseCount(stockCount) > 0;
  





  // Import-Chain (nur fehlende Teile)
  if (!hasMonths)    await seedMonthsIfEmpty();
  if (!hasCountries) await importCountriesFromCsv();
  if (!hasUnits) await importUnitsFromCsv();
  if (!hasNutCats) await importNutrientCategoriesFromCsv();
  if (!hasNuts) await importNutrientsFromCsv();
  if (!hasTrafficlight) await importTrafficlightFromCsv();
  if (!hasshopshelf) await importShopshelfFromCsv();
  if (!hasstorageCat) await importStorageCategoriesFromCsv();
  if (!hasIngCats) await importIngredientCategoriesFromCsv();
  if (!hasIngs) await importIngredientsFromCsv();
  if (!hasIngNuts) await importIngredientNutrientsFromCsv();
  if (!hasIngUnits) await importIngredientUnitsFromCsv();
  if (!hasSeasons)   await importSeasonalityFromCsv();
  if (!hasIngSeason) await importIngredientSeasonalityFromCsv();
  if (!hasAlts) await importAlternativesFromCsv();
  if (!hasIngAlts) await importIngredientAlternativesFromCsv();
  if (!hasRecCats) await importRecipeCategoriesFromCsv();
  if (!hasRecs) await importRecipesFromCsv();  
  if (!hasRecIngs) await importRecipeIngredientsFromCsv();
  if (!hasTagCats) await importTagCategoriesFromCsv();
  if (!hasTags) await importTagsFromCsv();
  if (!hasRecTags) await importRecipeTagsFromCsv();
  if (!hasIngTags) await importIngredientTagsFromCsv();
  if (!hasmarkets) await importMarketsFromCsv();
  if (!hasProducers) await importProducersFromCsv();
  if (!hasProducts) await importProductsFromCsv();
  if (!hasProductMarkets) await importProductMarketsFromCsv();
  if (!hasIngredientMarkets) await importIngredientMarketFromCsv();
  if (!hasProductCountries) await importProductCountryFromCsv();
  if (!hasIngMarCountries) await importIngredientMarketCountryFromCsv();
  if (!hasShoppingList) await importShoppingListFromCsv();
  if (!hasShoppingListIngredients) await importShoppingListIngredientFromCsv();
  if (!hasStorage) await importStorageFromCsv();
  if (!hasIngredientStorage) await importIngredientStorageFromCsv();
  if (!hasStock) await importStockFromCsv();



  await prefs.setBool(flag, true);
}

/// Re-Import: Upsert aller CSVs in sinnvoller Reihenfolge.
/// Löscht nichts; aktualisiert/füllt nur auf.
Future<void> reimportAllCsvs() async {
  await seedMonthsIfEmpty();
  await importCountriesFromCsv();
  await importUnitsFromCsv();
  await importNutrientCategoriesFromCsv();
  await importNutrientsFromCsv();
  await importTrafficlightFromCsv();
  await importStorageCategoriesFromCsv();
  await importShopshelfFromCsv();
  await importIngredientCategoriesFromCsv();
  await importIngredientsFromCsv();
  await importIngredientNutrientsFromCsv();
  await importIngredientUnitsFromCsv();
  await importSeasonalityFromCsv();
  await importIngredientSeasonalityFromCsv();
  await importAlternativesFromCsv();
  await importIngredientAlternativesFromCsv();
  await importRecipeCategoriesFromCsv();
  await importRecipesFromCsv();  
  await importRecipeIngredientsFromCsv();
  await importTagCategoriesFromCsv();
  await importTagsFromCsv();
  await importRecipeTagsFromCsv();
  await importIngredientTagsFromCsv();
  await importMarketsFromCsv();
  await importProducersFromCsv();
  await importProductsFromCsv();
  await importProductMarketsFromCsv();
  await importIngredientMarketFromCsv();
  await importProductCountryFromCsv();
  await importIngredientMarketCountryFromCsv();
  await importShoppingListFromCsv();
  await importShoppingListIngredientFromCsv();
  await importStorageFromCsv();
  await importIngredientStorageFromCsv();
  await importStockFromCsv();

}
