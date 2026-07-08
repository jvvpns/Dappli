import 'package:flutter/material.dart';
import 'package:kusinai01_app/app_colors.dart';
import 'package:kusinai01_app/data/recipe_model.dart';
import 'package:kusinai01_app/widgets/recipe_card.dart';
import 'package:kusinai01_app/screens/individual_recipe_screen.dart';
import '../widgets/custom_app_bar.dart';

class RecipeDiscoveryScreen extends StatelessWidget {
  final List<Recipe> recipes;

  const RecipeDiscoveryScreen({Key? key, required this.recipes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Discovered Recipes',
        backgroundColor: AppColors.background,
        titleColor: AppColors.text,
      ),
      body: recipes.isEmpty
          ? Center(
        child: Text(
          'No recipes discovered',
          style: TextStyle(color: AppColors.text),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(20.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          return RecipeCard(recipe: recipes[index]);
        },
      ),
    );
  }
}