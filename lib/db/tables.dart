// lib/db/tables.dart
part of 'package:planty_flutter_starter/db/app_db.dart';


// -------------------------------
// Tabelle: Months
// -------------------------------
class Months extends Table {
  IntColumn get id => integer().autoIncrement()(); // interne ID
  TextColumn get name => text()(); // Januar, Februar, ...
}

// -------------------------------
// Tabelle: Units
// -------------------------------
class Units extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()(); // g, kg, ml, l, tsp, tbsp, cup, pcs
  TextColumn get label => text()(); // Gramm, Liter, ...
  TextColumn get dimension =>
      text().withLength(min: 3, max: 10)(); // 'mass' | 'volume' | 'count'
  RealColumn get baseFactor =>
      real()(); // zur Basis (mass->g, volume->ml, count->pcs)
}

// -------------------------------
// Tabelle: Unit Conversions
// -------------------------------
class UnitConversions extends Table {
  IntColumn get fromUnitId => integer().references(Units, #id)();
  IntColumn get toUnitId => integer().references(Units, #id)();
  RealColumn get factor => real()(); // value_to = value_from * factor
  @override
  Set<Column> get primaryKey => {fromUnitId, toUnitId};
}

// -------------------------------
// Tabelle: Ingredient Unit Overrides
// -------------------------------
class IngredientUnitOverrides extends Table {
  IntColumn get ingredientId => integer()();
  IntColumn get unitId => integer().references(Units, #id)();
  RealColumn get gramsPerUnit => real().nullable()();
  RealColumn get mlPerUnit => real().nullable()();
  @override
  Set<Column> get primaryKey => {ingredientId, unitId};
}

// -------------------------------
// Tabelle: Nutrients Categories
// -------------------------------
// Entspricht CSV-Header: id;name;unit_code
class NutrientsCategorie extends Table {
  IntColumn get id => integer().autoIncrement()(); // interne ID
  TextColumn get name => text()(); // Name der Kategorie
  TextColumn get unitCode =>
      text().customConstraint('NOT NULL REFERENCES units(code)')(); // FK
}

// -------------------------------
// Tabelle: Nutrients
// -------------------------------
// Entspricht CSV-Header: id;name;nutrients_categorie_id;picture;color
class Nutrient extends Table {
  IntColumn get id => integer().autoIncrement()(); // interne ID
  TextColumn get name => text()(); // z.B. Kalorien, Zucker
  IntColumn get nutrientsCategorieId =>
      integer().references(NutrientsCategorie, #id)(); // FK
  TextColumn get unitCode =>
      text().customConstraint('NOT NULL REFERENCES units(code)')(); // FK
  TextColumn get picture => text().nullable()(); // optional
  TextColumn get color => text().nullable()(); // optional
}

// -------------------------------
// Zutaten-Kategorien
// -------------------------------
// Entspricht CSV-Header: id;title;image
class IngredientCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()(); // "Gemüse", "Obst", ...
  TextColumn get image => text().nullable()(); // z.B. assets/images/Gemuese.jpg
}

// -------------------------------
// Zutaten-Eigenschaften
// -------------------------------
class IngredientProperties extends Table {
  IntColumn get id => integer()(); // feste ID laut CSV
  TextColumn get name => text().unique()(); // Bezeichner
  @override
  Set<Column> get primaryKey => {id};
}

// -------------------------------
// Zutaten
// -------------------------------
// Entspricht CSV-Header: id;name;ingredient_category;unit_id;picture
class Ingredients extends Table {
  IntColumn get id => integer().autoIncrement()(); // interne ID
  TextColumn get name => text()();
  IntColumn get ingredientCategoryId =>
      integer().references(IngredientCategories, #id)(); // FK
  IntColumn get unitId => integer().nullable().references(Units, #id)(); // FK optional
  TextColumn get picture => text().nullable()(); // optional
}

// -------------------------------
// Tabelle: Ingredient Nutrients
// -------------------------------
// Entspricht CSV-Header: ingredient_id;nutrient_id;amount
class IngredientNutrients extends Table {
  IntColumn get id => integer().autoIncrement()();  // ← neue ID
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  IntColumn get nutrientId => integer().references(Nutrient, #id)();
  RealColumn get amount => real()();
}



// -------------------------------
// Tabelle: Seasonality
// -------------------------------
// CSV: id;name;color
class Seasonality extends Table {
  IntColumn get id => integer()();               // 1..n (feste IDs)
  TextColumn get name => text()();               // z.B. "Freiland"
  TextColumn get color => text().nullable()();   // optional: "#245225"

  @override
  Set<Column> get primaryKey => {id};
}

// -------------------------------
// Tabelle: Ingredient Seasonality
// -------------------------------
// CSV: ingredients_id;months_id;seasonality_id   (KEINE id-Spalte!)
// Primärschlüssel: (ingredients_id, months_id)
class IngredientSeasonality extends Table {
  IntColumn get ingredientsId => integer().references(Ingredients, #id)();
  IntColumn get monthsId => integer().references(Months, #id)();
  IntColumn get seasonalityId => integer().references(Seasonality, #id)();

  @override
  Set<Column> get primaryKey => {ingredientsId, monthsId};
}
