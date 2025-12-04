// lib/db/app_db.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'tables.dart';
part 'app_db.g.dart';


LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
  
@DriftDatabase(
  tables: [
    Months,
    Units,
    Countries,
    NutrientsCategorie,
    Nutrient,
    Trafficlight,
    Shopshelf,
    StorageCategories,
    IngredientCategories,
    Ingredients,
    IngredientNutrients,
    IngredientUnits,
    Seasonality,
    IngredientSeasonality,
    Alternatives,
    IngredientAlternatives,
    RecipeCategories,
    Recipes,
    RecipeIngredients,
    TagCategories,
    Tags,
    RecipeTags,
    IngredientTags,
    Markets,
    Producers,
    Products,
    ProductMarkets,
    IngredientMarket,
    ProductCountry,
    IngredientMarketCountry,
    ShoppingList,
    ShoppingListIngredient,
    Storage,
    IngredientStorage,
    Stock,
  ],
)
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 1;
} 


//flutter pub run build_runner build --delete-conflicting-outputs