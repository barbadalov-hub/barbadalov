/// Cooking recipes for the dietitian's dishes: each dish can be cooked several
/// ways (pan, oven, multicooker, grill/mangal…), and every method has its own
/// timed, step-by-step instructions. The step text and per-ingredient flavour
/// notes live in the i18n table (`recipe.<mealId>.<method>` and
/// `recipe.<mealId>.flavor`), one newline-separated string per method so the
/// content stays translatable and the count of keys stays small.
class RecipeMethod {
  final String id; // pan | oven | pot | multicooker | airfryer | grill | ...
  const RecipeMethod(this.id);
  String get labelKey => 'recipe.method.$id';
}

const _pan = RecipeMethod('pan');
const _oven = RecipeMethod('oven');
const _pot = RecipeMethod('pot');
const _multicooker = RecipeMethod('multicooker');
const _airfryer = RecipeMethod('airfryer');
const _grill = RecipeMethod('grill'); // grill pan / BBQ (mangal)
const _microwave = RecipeMethod('microwave');
const _assembly = RecipeMethod('assembly'); // no cooking

class MealRecipe {
  final String mealId;
  final List<RecipeMethod> methods;
  const MealRecipe(this.mealId, this.methods);

  String stepsKey(String methodId) => 'recipe.$mealId.$methodId';
  String get flavorKey => 'recipe.$mealId.flavor';
}

/// mealId → recipe. Missing dishes simply show ingredients without steps.
const kRecipes = <String, MealRecipe>{
  'casserole': MealRecipe('casserole', [_oven, _multicooker]),
  'oatmeal': MealRecipe('oatmeal', [_pot, _microwave]),
  'syrnyky': MealRecipe('syrnyky', [_pan, _airfryer]),
  'omelette': MealRecipe('omelette', [_pan, _oven]),
  'borscht': MealRecipe('borscht', [_pot, _multicooker]),
  'buckwheat_chicken': MealRecipe('buckwheat_chicken', [_pot, _oven]),
  'rice_fish': MealRecipe('rice_fish', [_pan, _oven]),
  'baked_chicken': MealRecipe('baked_chicken', [_oven, _airfryer, _grill]),
  'stewed_fish': MealRecipe('stewed_fish', [_pot, _multicooker]),
  'cottage_bowl': MealRecipe('cottage_bowl', [_assembly]),
  'yogurt_nuts': MealRecipe('yogurt_nuts', [_assembly]),
  'apple_cheese': MealRecipe('apple_cheese', [_assembly]),
  'banana_snack': MealRecipe('banana_snack', [_assembly]),
};

MealRecipe? recipeFor(String mealId) => kRecipes[mealId];
