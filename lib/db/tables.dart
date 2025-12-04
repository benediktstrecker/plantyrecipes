// lib/db/tables.dart
part of 'package:planty_flutter_starter/db/app_db.dart';


// -------------------------------
// Monate (ohne csv)
// -------------------------------
class Months extends Table {
  IntColumn get id => integer().autoIncrement()(); // interne ID
  TextColumn get name => text()(); // Januar, Februar, ...
}

// -------------------------------
// Länder (aus countries.csv)
// -------------------------------
// CSV-Header: id;name;image;short;continent
class Countries extends Table {
  IntColumn get id => integer().autoIncrement()();     // interne ID
  TextColumn get name => text()();                     // Landesname
  TextColumn get image => text().nullable()();         // Pfad z.B. assets/images/flags/aegypten.webp
  TextColumn get short => text().nullable()();         // Kürzel (afg, ger, fra…)
  TextColumn get continent => text().nullable()();     // Kontinent (Asien, Afrika, Europa …)
}

// -------------------------------
// Einheiten (aus unit.csv)
// -------------------------------
class Units extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get code => text().unique()(); // z. B. g, kg, ml, l, pcs
  TextColumn get label => text()(); // Singular: Gramm, Liter, Stück
  TextColumn get plural => text().nullable()(); // Plural: Gramm, Liter, Stücke
  TextColumn get categorie =>
      text().withLength(min: 3, max: 20)(); // Kategorie: Masse, Anzahl, Energie
  RealColumn get baseFactor =>
      real()(); // Basisfaktor zur Grundeinheit (z. B. 1.0)
}

// -------------------------------
// Nährstoff-Kategorien (aus nutrient_categorie.csv)
// -------------------------------
// Entspricht CSV-Header: id;name;unit_code
class NutrientsCategorie extends Table {
  IntColumn get id => integer().autoIncrement()(); // interne ID
  TextColumn get name => text()(); // Name der Kategorie
  TextColumn get unitCode =>
      text().customConstraint('NOT NULL REFERENCES units(code)')(); // FK
}

// -------------------------------
// Nährstoffe (aus nutrient.csv)
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
// Tabelle: Trafficlight (aus trafficlight.csv)
// -------------------------------
// CSV-Header: id;name;color
class Trafficlight extends Table {
  IntColumn get id => integer()(); // feste ID laut CSV
  TextColumn get name => text()(); // z. B. "Unverarbeitet", "Verarbeitet", ...
  TextColumn get color => text().nullable()(); // optionale Farbe (#RRGGBB)

  @override
  Set<Column> get primaryKey => {id};
}

// -------------------------------
// Tabelle: Shopshelf (aus shopshelf.csv)
// -------------------------------
// CSV-Header: id;name;color;icon
class Shopshelf extends Table {
  IntColumn get id => integer()(); // feste ID laut CSV
  TextColumn get name => text()(); // Name des Regals (z. B. "Obst & Gemüse")
  TextColumn get color => text().nullable()(); // optionale Farbe (#RRGGBB)
  TextColumn get icon => text().nullable()(); // Pfad zum Icon (assets/images/icons/…)

  @override
  Set<Column> get primaryKey => {id};
}

// ----------------------------------------------------------
// StorageCategories
// ----------------------------------------------------------
class StorageCategories extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}


// -------------------------------
// Zutaten-Kategorien (aus ingredient_category.csv)
// -------------------------------
// Entspricht CSV-Header: id;title;image
class IngredientCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()(); // "Gemüse", "Obst", ...
  TextColumn get image => text().nullable()(); // z.B. assets/images/Gemuese.jpg
}

// -------------------------------
// Zutaten (aus ingredient.csv)
// -------------------------------
// CSV-Header:
// id;name;ingredient_category;picture;singular;favorite;bookmark;
// last_updated;trafficlight_id;storage_id;shelf_name;shelf_id;description;tip
class Ingredients extends Table {
  // feste ID aus CSV → kein autoIncrement()
  IntColumn get id => integer()();

  TextColumn get name => text()();

  // ingredient_category → FK
  IntColumn get ingredientCategoryId =>
      integer().references(IngredientCategories, #id)();

  TextColumn get picture => text().nullable()();

  TextColumn get singular => text().nullable()();

  // favorite (0/1)
  BoolColumn get favorite =>
      boolean().withDefault(const Constant(false))();

  // bookmark (0/1)
  BoolColumn get bookmark =>
      boolean().withDefault(const Constant(false))();

  // last_updated (Text, ISO oder leer)
  TextColumn get lastUpdated => text().nullable()();

  // trafficlight_id → FK
  IntColumn get trafficlightId =>
      integer().nullable().references(Trafficlight, #id)();

  // storage_id → FK
  IntColumn get storagecatId =>
      integer().nullable().references(StorageCategories, #id)();

  // shelf_name (kein FK)
  TextColumn get shelfName => text().nullable()();

  // shelf_id → FK
  IntColumn get shelfId =>
      integer().nullable().references(Shopshelf, #id)();

  TextColumn get description => text().nullable()();

  TextColumn get tip => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}


// -------------------------------
// Tabelle: Zutaten-Nährstoffe (aus ingredient_nutrient.csv)
// -------------------------------
// Entspricht CSV-Header: ingredient_id;nutrient_id;amount
class IngredientNutrients extends Table {
  IntColumn get id => integer().autoIncrement()();  // ← neue ID
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  IntColumn get nutrientId => integer().references(Nutrient, #id)();
  RealColumn get amount => real()();
}

// -------------------------------
// Tabelle: Zutaten-Einheiten (aus ingredient_unit.csv)
// -------------------------------
// CSV-Header: id;ingredient_id;unit_code;amount
class IngredientUnits extends Table {
  IntColumn get id => integer().autoIncrement()(); // interne ID
  IntColumn get ingredientId => integer().references(Ingredients, #id)(); // FK
  TextColumn get unitCode =>
      text().customConstraint('NOT NULL REFERENCES units(code)')(); // FK
  RealColumn get amount => real()(); // Menge, z. B. 1.3 oder 1500
}


// -------------------------------
// Tabelle: Saisonalität (aus seasonality.csv)
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
// Tabelle: Zutaten-Saisonalität (aus ingredient_seasonality.csv)
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

// -------------------------------
// Alternatives (aus alternatives.csv)
// -------------------------------
// CSV-Header: id;name;show
class Alternatives extends Table {
  IntColumn get id => integer()();  // feste ID aus CSV
  TextColumn get name => text()();  // Name des Beziehungstyps
  BoolColumn get show =>
      boolean().withDefault(const Constant(false))(); // 0 oder 1

  @override
  Set<Column> get primaryKey => {id};
}

// -------------------------------
// IngredientAlternatives (aus ingredient_alternatives.csv)
// -------------------------------
// CSV-Header:
// ingredient_id;related_ingredient_id;alternatives_id;share
class IngredientAlternatives extends Table {
  IntColumn get id => integer().autoIncrement()();  

  IntColumn get ingredientId =>
      integer().references(Ingredients, #id)();        

  IntColumn get relatedIngredientId =>
      integer().references(Ingredients, #id)();        

  IntColumn get alternativesId =>
      integer().references(Alternatives, #id)();       

  RealColumn get share => real().nullable()();        

  @override
  Set<Column> get primaryKey => {id};
}


// -------------------------------
// NEU: Rezept-Kategorien (CSV recipe_category.csv)
// -------------------------------
// CSV-Header: id;title;image
class RecipeCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get image => text().nullable()();
}

// -------------------------------
// Rezepte (aus recipe.csv)
// -------------------------------
// CSV-Header:
// id;name;recipe_category;picture;portion_number;portion_unit;cook_counter;
// favorite;bookmark;last_cooked;last_updated;inspired_by;description;tip

class Recipes extends Table {
  IntColumn get id => integer().autoIncrement()(); // interne ID

  TextColumn get name => text()(); // Rezeptname

  IntColumn get recipeCategory =>
      integer().references(RecipeCategories, #id)(); // FK zu Kategorie

  TextColumn get picture => text().nullable()(); // optionales Bild

  // --- neue Felder ---
  IntColumn get portionNumber => integer().nullable()(); // z. B. 3

  // neu: Foreign Key auf Units.code
  TextColumn get portionUnit =>
      text().nullable().references(Units, #code)(); // z. B. "pcs", "g", "ml"

  IntColumn get cookCounter => integer().withDefault(const Constant(0))(); // gekocht wie oft
  IntColumn get favorite => integer().withDefault(const Constant(0))(); // 0/1
  IntColumn get bookmark => integer().withDefault(const Constant(0))(); // 0/1

  TextColumn get lastCooked => text().nullable()(); // ISO-Datum oder leer
  TextColumn get lastUpdated => text().nullable()();

  TextColumn get inspiredBy => text().nullable()();
  TextColumn get description => text().nullable()();
  TextColumn get tip => text().nullable()();
}


// -------------------------------
// Tabelle: Rezept-Zutaten (aus recipe_ingredients.csv)
// -------------------------------
// CSV-Header: id;recipe_id;ingredient_id;unit_code;amount
class RecipeIngredients extends Table {
  IntColumn get id => integer().autoIncrement()(); // interne ID
  IntColumn get recipeId => integer().references(Recipes, #id)(); // FK
  IntColumn get ingredientId => integer().references(Ingredients, #id)(); // FK
  TextColumn get unitCode =>
      text().customConstraint('NOT NULL REFERENCES units(code)')(); // FK
  RealColumn get amount => real()(); // z. B. 900, 3, 5, 1
}

// -------------------------------
// Tag-Kategorien (aus tag_categorie.csv)
// -------------------------------
// CSV-Header: id;name;color
class TagCategories extends Table {
  IntColumn get id => integer().autoIncrement()(); // interne ID
  TextColumn get name => text()(); // z. B. Ernährungsform, Geschmacksrichtung, Küchenstil
  TextColumn get color => text().nullable()(); // optionale Farbe (#RRGGBB)
}

// -------------------------------
// Tags (aus tags.csv)
// -------------------------------
// CSV-Header: id;name;tag_categorie_id;image;color
class Tags extends Table {
  IntColumn get id => integer().autoIncrement()(); // interne ID
  TextColumn get name => text()(); // z. B. Vegan, Vegetarisch
  IntColumn get tagCategorieId =>
      integer().references(TagCategories, #id)(); // FK zu Tag-Kategorie
  TextColumn get image => text().nullable()(); // Pfad zu Icon-Datei
  TextColumn get color => text().nullable()(); // optionale Farbe (#RRGGBB)
}

// -------------------------------
// Tabelle: Rezept-Tags (aus recipe_tag.csv)
// -------------------------------
// CSV-Header: id;recipe_id;tags_id
class RecipeTags extends Table {
  IntColumn get recipeId => integer().references(Recipes, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {recipeId, tagId};
}

// -------------------------------
// Tabelle: Zutaten-Tags (aus ingredient_tag.csv)
// -------------------------------
// CSV-Header: ingredient_id;tags_id
class IngredientTags extends Table {
  IntColumn get ingredientId => integer().references(Ingredients, #id)(); // FK
  IntColumn get tagsId => integer().references(Tags, #id)(); // FK

  @override
  Set<Column> get primaryKey => {ingredientId, tagsId};
}


// -------------------------------
// Tabelle: Markets (aus markets.csv)
// -------------------------------
// CSV-Header: id;name;picture;color;favorite
class Markets extends Table {
  IntColumn get id => integer()(); // feste ID laut CSV

  TextColumn get name => text()(); // Name des Markts (z. B. "Rewe", "Aldi")

  TextColumn get picture => text().nullable()(); 
  // z. B. assets/images/shop/rewe.webp

  TextColumn get color => text().nullable()(); 
  // optionale Farbe als Hex (#RRGGBB)

  // NEU: Favoriten-Markierung (0/1)
  BoolColumn get favorite =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}


// -------------------------------
// Tabelle: Producers (aus producers.csv)
// -------------------------------
// CSV-Header: id;name;picture;color
class Producers extends Table {
  IntColumn get id => integer()(); // feste ID laut CSV
  TextColumn get name => text()(); // Herstellername
  TextColumn get picture => text().nullable()(); // Pfad zum Bild
  TextColumn get color => text().nullable()(); // optionale Farbe (#RRGGBB)

  @override
  Set<Column> get primaryKey => {id};
}

// -------------------------------
// Tabelle: Products (aus products.csv)
// -------------------------------
// CSV-Header:
// id; name; ingredient_name;   // wird ignoriert (reine Info-Spalte)
// ingredient_id; producer_name;      // wird ignoriert (reine Info-Spalte)
// producer_id; image; favorite; EAN; bio;
// size_number; size_unit_code; yield_unit_code; yield_amount

class Products extends Table {
  IntColumn get id => integer()(); // feste ID laut CSV

  TextColumn get name => text()(); // Produktname

  IntColumn get ingredientId =>
      integer().references(Ingredients, #id)();

  IntColumn get producerId =>
      integer().references(Producers, #id)();

  TextColumn get image => text().nullable()();

  BoolColumn get favorite =>
      boolean().withDefault(const Constant(false))();

  IntColumn get EAN => integer().nullable()();

  BoolColumn get bio =>
      boolean().withDefault(const Constant(false))();

  RealColumn get sizeNumber => real().nullable()();

  @ReferenceName('sizeUnit')
  TextColumn get sizeUnitCode =>
      text().nullable().customConstraint('NULL REFERENCES units(code)')();

  @ReferenceName('yieldUnit')
  TextColumn get yieldUnitCode =>
      text().nullable().customConstraint('NULL REFERENCES units(code)')();

  RealColumn get yieldAmount => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}


// -------------------------------
// Tabelle: ProductMarkets (aus product_markets.csv)
// Neuer CSV-Header:
// id;products_id;market_id;price;date
// -------------------------------
class ProductMarkets extends Table {

  // Neue autarke PK-ID
  IntColumn get id => integer().autoIncrement()();

  // FK: Produkt
  IntColumn get productsId =>
      integer().references(Products, #id)();

  // FK: Markt
  IntColumn get marketId =>
      integer().references(Markets, #id)();

  // Preis
  RealColumn get price => real().nullable()();

  // Datum
  // CSV: Zahl / Timestamp / Text → als DateTime speichern
  DateTimeColumn get date => dateTime().nullable()();
}

// -------------------------------------------------------------
// Tabelle: IngredientMarket
// Neuer CSV-Header:
// id;ingredient_name;ingredient_id;market_name;market_id;
// name;bio;unit_code;unit_amount;price;package_unit_code;favorite
// -------------------------------------------------------------
class IngredientMarket extends Table {
  IntColumn get id => integer().autoIncrement()();

  // FK: Ingredient
  IntColumn get ingredientId =>
      integer().references(Ingredients, #id)();

  // FK: Market
  IntColumn get marketId =>
      integer().references(Markets, #id)();

  // Produktname im Markt
  TextColumn get name => text().nullable()();

  // Bio-Flag
  BoolColumn get bio =>
      boolean().withDefault(const Constant(false))();

  // Einheit (FK auf Units.code)
  TextColumn get unitCode =>
      text().nullable().customConstraint('NULL REFERENCES units(code)')();

  // Mengenangabe
  RealColumn get unitAmount => real().nullable()();

  // Preis
  RealColumn get price => real().nullable()();

  // Verpackungseinheit (FK auf Units.code)
  TextColumn get packageUnitCode =>
      text().nullable().customConstraint('NULL REFERENCES units(code)')();

  // Favorit-Flag
  BoolColumn get favorite =>
      boolean().withDefault(const Constant(false))();
}

// -------------------------------
// Tabelle: ProductCountry (aus product_country.csv)
// CSV: products_id;countries_id
// Primärschlüssel: (products_id, countries_id)
// -------------------------------
class ProductCountry extends Table {
  IntColumn get productsId =>
      integer().references(Products, #id)(); // FK → Product

  IntColumn get countriesId =>
      integer().references(Countries, #id)(); // FK → Country

  @override
  Set<Column> get primaryKey => {productsId, countriesId};
}


// -------------------------------
// Tabelle: IngredientMarketCountry (aus ingredient_market_country.csv)
// CSV: ingredient_market_id;countries_id
// Primärschlüssel: (ingredient_market_id, countries_id)
// -------------------------------
class IngredientMarketCountry extends Table {
  IntColumn get ingredientMarketId =>
      integer().references(IngredientMarket, #id)(); // FK → IngredientMarket

  IntColumn get countriesId =>
      integer().references(Countries, #id)(); // FK → Country

  @override
  Set<Column> get primaryKey => {ingredientMarketId, countriesId};
}




// -------------------------------
// Tabelle: ShoppingList (aus shopping_list.csv)
// -------------------------------
// CSV-Header: id;name;date_shopping;date_created;market_id;last_edited;done
class ShoppingList extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  // echtes Datum (optional)
  DateTimeColumn get dateShopping => dateTime().nullable()();

  // Erstelldatum = aktuelles Datum
  DateTimeColumn get dateCreated => dateTime().nullable()();

  // Bearbeitet am = aktuelles Datum
  DateTimeColumn get lastEdited => dateTime().nullable()();

  IntColumn get marketId =>
      integer().nullable().references(Markets, #id)();

  BoolColumn get done =>
      boolean().withDefault(const Constant(false))();

  TextColumn get reciptImage => text().nullable()();    
}



// -------------------------------------------------------------
// Tabelle: ShoppingListIngredient
// -------------------------------------------------------------
// CSV-Felder (erweitert):
// id;shopping_list_id;recipe_id;recipe_portion_number_id;
// ingredient_id_nominal;ingredient_amount_nominal;
// ingredient_unit_code_nominal;
// product_id_nominal;product_amount_nominal;
// ingredient_market_id_nominal;ingredient_market_amount_nominal;
// basket;bought;price;country_id;
// ingredient_id_actual;ingredient_amount_actual;
// ingredient_unit_code_actual;
// product_id_actual;product_amount_actual;
// ingredient_market_id_actual;ingredient_market_amount_actual;
// price_actual
// -------------------------------------------------------------

class ShoppingListIngredient extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Basis
  IntColumn get shoppingListId =>
      integer().references(ShoppingList, #id)();

  IntColumn get recipeId =>
      integer().nullable().references(Recipes, #id)();

  IntColumn get recipePortionNumberId => integer().nullable()();

  // Nominale Ingredient-Daten
  IntColumn get ingredientIdNominal =>
      integer().nullable().references(Ingredients, #id)();

  RealColumn get ingredientAmountNominal => real().nullable()();

  TextColumn get ingredientUnitCodeNominal =>
      text().nullable().customConstraint('NULL REFERENCES units(code)')();

  // Nominale Produkt-Daten
  IntColumn get productIdNominal =>
      integer().nullable().references(Products, #id)();

  RealColumn get productAmountNominal => real().nullable()();

  // Nominaler Ingredient-Market
  IntColumn get ingredientMarketIdNominal =>
      integer().nullable().references(IngredientMarket, #id)();

  RealColumn get ingredientMarketAmountNominal => real().nullable()();

  // Status / Einkauf
  BoolColumn get basket =>
      boolean().withDefault(const Constant(false))();

  BoolColumn get bought =>
      boolean().withDefault(const Constant(false))();

  RealColumn get price => real().nullable()();

  IntColumn get countryId =>
      integer().nullable().references(Countries, #id)();

  // Tatsächliche Ingredient-Daten
  IntColumn get ingredientIdActual =>
      integer().nullable().references(Ingredients, #id)();

  RealColumn get ingredientAmountActual => real().nullable()();

  TextColumn get ingredientUnitCodeActual =>
      text().nullable().customConstraint('NULL REFERENCES units(code)')();

  // Tatsächliche Produkt-Daten
  IntColumn get productIdActual =>
      integer().nullable().references(Products, #id)();

  RealColumn get productAmountActual => real().nullable()();

  // Tatsächlicher Ingredient-Market
  IntColumn get ingredientMarketIdActual =>
      integer().nullable().references(IngredientMarket, #id)();

  RealColumn get ingredientMarketAmountActual => real().nullable()();

  // -------------------------------------------------------------
  // NEU: price_actual
  // -------------------------------------------------------------
  RealColumn get priceActual => real().nullable()();
}


// -------------------------------
// Tabelle: Storage (aus storage.csv)
// CSV-Felder: id;name;icon;availability
// -------------------------------
class Storage extends Table {
  IntColumn get id => integer()();

  TextColumn get name => text()();

  TextColumn get icon => text().nullable()();

  // NEU: availability (0/1)
  BoolColumn get availability =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}


// -------------------------------
// IngredientStorage (aus ingredient_storage.csv)
// CSV-Header: ingredient_id;storage_id;amount;unit_code
// -------------------------------
class IngredientStorage extends Table {
  IntColumn get ingredientId =>
      integer().references(Ingredients, #id)();   // FK → Zutat

  IntColumn get storageId =>
      integer().references(Storage, #id)();      // FK → Lagerort

  RealColumn get amount => real()();            // Lagerdauer (numerisch)

  // NEU: Einheit für amount – FK zu units(code)
  TextColumn get unitCode =>
      text().customConstraint('NOT NULL REFERENCES units(code)')();

  @override
  Set<Column> get primaryKey => {ingredientId, storageId};
}


// -------------------------------
// Tabelle: Stock (aus stock.csv)
// CSV: id;ingredient_id;storage_id;shopping_list_id;date_entry;amount;unit_code
// -------------------------------
class Stock extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Ingredient → FK
  IntColumn get ingredientId =>
      integer().references(Ingredients, #id)();

  // Storage → FK
  IntColumn get storageId =>
      integer().references(Storage, #id)();

  // Shopping-List → FK
  IntColumn get shoppingListId =>
      integer().nullable().references(ShoppingList, #id)();

  // Datum des Einlagerns
  DateTimeColumn get dateEntry => dateTime().nullable()();

  // Menge
  RealColumn get amount => real().nullable()();

  // Einheit → FK zu Units.code
  TextColumn get unitCode =>
      text().nullable().customConstraint('NULL REFERENCES units(code)')();

  @override
  Set<Column> get primaryKey => {id};
}


