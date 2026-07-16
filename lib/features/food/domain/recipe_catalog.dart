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
  'protein_pancakes': MealRecipe('protein_pancakes', [_pan]),
  'veggie_scramble': MealRecipe('veggie_scramble', [_pan]),
  'chicken_pasta': MealRecipe('chicken_pasta', [_pan]),
  'lentil_soup': MealRecipe('lentil_soup', [_pot, _multicooker]),
  'beef_veg': MealRecipe('beef_veg', [_pan, _multicooker]),
  'shrimp_salad': MealRecipe('shrimp_salad', [_pan]),
  'cottage_berries': MealRecipe('cottage_berries', [_assembly]),
  'kefir_snack': MealRecipe('kefir_snack', [_assembly]),
  'eggs_toast': MealRecipe('eggs_toast', [_pan]),
  'rice_milk': MealRecipe('rice_milk', [_pot]),
  'fruit_yogurt': MealRecipe('fruit_yogurt', [_assembly]),
  'cheese_omelette': MealRecipe('cheese_omelette', [_pan]),
  'beef_buckwheat': MealRecipe('beef_buckwheat', [_pot]),
  'fish_potatoes': MealRecipe('fish_potatoes', [_oven]),
  'chicken_rice_veg': MealRecipe('chicken_rice_veg', [_pan]),
  'shrimp_pasta': MealRecipe('shrimp_pasta', [_pan]),
  'chicken_veg_stew': MealRecipe('chicken_veg_stew', [_pot]),
  'fish_fresh_salad': MealRecipe('fish_fresh_salad', [_pan]),
  'beef_lentils': MealRecipe('beef_lentils', [_pot]),
  'egg_potato_bake': MealRecipe('egg_potato_bake', [_oven]),
  'nuts_banana': MealRecipe('nuts_banana', [_assembly]),
  'bread_cheese': MealRecipe('bread_cheese', [_assembly]),
  'yogurt_berries': MealRecipe('yogurt_berries', [_assembly]),
  'mushroom_omelette': MealRecipe('mushroom_omelette', [_pan]),
  'cottage_oats': MealRecipe('cottage_oats', [_assembly]),
  'veggie_toast': MealRecipe('veggie_toast', [_pan]),
  'turkey_buckwheat': MealRecipe('turkey_buckwheat', [_pot]),
  'veggie_stew': MealRecipe('veggie_stew', [_pot]),
  'chicken_pasta_veg': MealRecipe('chicken_pasta_veg', [_pan]),
  'fish_rice_veg': MealRecipe('fish_rice_veg', [_pan]),
  'turkey_salad': MealRecipe('turkey_salad', [_pan]),
  'mushroom_chicken': MealRecipe('mushroom_chicken', [_pan]),
  'stuffed_peppers': MealRecipe('stuffed_peppers', [_oven]),
  'zucchini_eggs': MealRecipe('zucchini_eggs', [_pan]),
  'cottage_cucumber': MealRecipe('cottage_cucumber', [_assembly]),
  'apple_banana': MealRecipe('apple_banana', [_assembly]),
  'boiled_eggs': MealRecipe('boiled_eggs', [_pot]),
  'kefir_berries': MealRecipe('kefir_berries', [_assembly]),
  'spinach_eggs': MealRecipe('spinach_eggs', [_pan]),
  'berry_smoothie': MealRecipe('berry_smoothie', [_assembly]),
  'banana_pancakes': MealRecipe('banana_pancakes', [_pan]),
  'salmon_rice': MealRecipe('salmon_rice', [_oven]),
  'chickpea_stew': MealRecipe('chickpea_stew', [_pot]),
  'turkey_potatoes': MealRecipe('turkey_potatoes', [_oven]),
  'tuna_pasta': MealRecipe('tuna_pasta', [_pan]),
  'salmon_salad': MealRecipe('salmon_salad', [_pan]),
  'broccoli_chicken': MealRecipe('broccoli_chicken', [_pan]),
  'beef_veg_grill': MealRecipe('beef_veg_grill', [_grill]),
  'chickpea_salad': MealRecipe('chickpea_salad', [_assembly]),
  'tuna_snack': MealRecipe('tuna_snack', [_assembly]),
  'cheese_cubes': MealRecipe('cheese_cubes', [_assembly]),
  'berries_nuts': MealRecipe('berries_nuts', [_assembly]),
  'apple_nuts': MealRecipe('apple_nuts', [_assembly]),
  'avocado_toast': MealRecipe('avocado_toast', [_assembly]),
  'oat_berry_bowl': MealRecipe('oat_berry_bowl', [_pot]),
  'pepper_scramble': MealRecipe('pepper_scramble', [_pan]),
  'pork_buckwheat': MealRecipe('pork_buckwheat', [_pot]),
  'couscous_chicken': MealRecipe('couscous_chicken', [_pan]),
  'bean_soup': MealRecipe('bean_soup', [_pot]),
  'fish_couscous': MealRecipe('fish_couscous', [_pan]),
  'pork_veg': MealRecipe('pork_veg', [_pan]),
  'chicken_beans': MealRecipe('chicken_beans', [_pot]),
  'avocado_chicken_salad': MealRecipe('avocado_chicken_salad', [_pan]),
  'corn_tuna_salad': MealRecipe('corn_tuna_salad', [_assembly]),
  'avocado_egg': MealRecipe('avocado_egg', [_assembly]),
  'cottage_honey': MealRecipe('cottage_honey', [_assembly]),
  'yogurt_oats': MealRecipe('yogurt_oats', [_assembly]),
  'pepper_cheese': MealRecipe('pepper_cheese', [_assembly]),
  'peanut_banana_toast': MealRecipe('peanut_banana_toast', [_assembly]),
  'quinoa_porridge': MealRecipe('quinoa_porridge', [_pot]),
  'feta_veggie_eggs': MealRecipe('feta_veggie_eggs', [_pan]),
  'cottage_banana': MealRecipe('cottage_banana', [_assembly]),
  'mushroom_toast': MealRecipe('mushroom_toast', [_pan]),
  'chicken_quinoa': MealRecipe('chicken_quinoa', [_pan]),
  'beef_rice_veg': MealRecipe('beef_rice_veg', [_pot]),
  'salmon_potato': MealRecipe('salmon_potato', [_oven]),
  'turkey_pasta': MealRecipe('turkey_pasta', [_pan]),
  'veggie_quinoa_bowl': MealRecipe('veggie_quinoa_bowl', [_pot]),
  'baked_fish_veg': MealRecipe('baked_fish_veg', [_oven]),
  'chicken_sweet_potato': MealRecipe('chicken_sweet_potato', [_oven]),
  'pork_grill': MealRecipe('pork_grill', [_grill]),
  'greek_salad': MealRecipe('greek_salad', [_assembly]),
  'turkey_veg_stew': MealRecipe('turkey_veg_stew', [_pot]),
  'peanut_apple': MealRecipe('peanut_apple', [_assembly]),
  'feta_cucumber': MealRecipe('feta_cucumber', [_assembly]),
  'banana_milk': MealRecipe('banana_milk', [_assembly]),
  'cottage_nuts': MealRecipe('cottage_nuts', [_assembly]),
};

MealRecipe? recipeFor(String mealId) => kRecipes[mealId];
