import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kusinai01_app/data/recipe_model.dart';
import 'individual_recipe_screen.dart';
import 'dart:async';
import '../utils/search_logic.dart';
import '../widgets/custom_app_bar.dart';

class SearchScreen extends StatefulWidget {
  final List<String>? initialIngredients;

  const SearchScreen({super.key, this.initialIngredients});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Recipe> allRecipes = []; // full list from Firestore
  List<Recipe> recipes = []; // filtered list
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _fetchAllRecipes();
    // Add listener for real-time search
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        final input = _searchController.text.trim();
        _searchRecipes(input);
      }
    });
  }

  Future<void> _fetchAllRecipes() async {
    setState(() => isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance.collection('recipes').get();

      final fetched = snapshot.docs
          .map((doc) => Recipe.fromMap(doc.data(), doc.id))
          .toList();

      setState(() {
        allRecipes = fetched;
        recipes = fetched; // default: show all
        isLoading = false;
      });

      // If ingredients were passed from AR scanner, search them immediately
      if (widget.initialIngredients != null &&
          widget.initialIngredients!.isNotEmpty) {
        _searchRecipes(widget.initialIngredients!.join(", "));
        _searchController.text = widget.initialIngredients!.join(", ");
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        // Handle error gracefully - recipes list will remain empty
      }
    }
  }

  void _searchRecipes(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        recipes = allRecipes;
      });
      return;
    }

    final lowerQuery = query.toLowerCase();
    final queryIngredients = lowerQuery
        .split(",")
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final results = allRecipes.where((recipe) {
      final titleMatch = recipe.title.toLowerCase().contains(lowerQuery);

      final ingredientMatch = recipe.ingredients.any((ing) =>
          queryIngredients.any((q) => ing.toLowerCase().contains(q)));

      return titleMatch || ingredientMatch;
    }).toList();

    // Sort results: title matches first, then ingredient matches
    results.sort((a, b) {
      final aTitleMatch = a.title.toLowerCase().contains(lowerQuery);
      final bTitleMatch = b.title.toLowerCase().contains(lowerQuery);

      if (aTitleMatch && !bTitleMatch) return -1;
      if (!aTitleMatch && bTitleMatch) return 1;
      return 0;
    });

    setState(() {
      recipes = results;
    });
  }

  void _onSearch() {
    final input = _searchController.text.trim();
    _searchRecipes(input);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Search Recipes',
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                      'Enter ingredients (e.g. chicken, garlic) or recipe name',
                      hintStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF222431),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          _searchRecipes('');
                        },
                      )
                          : null,
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.amber),
                  onPressed: _onSearch,
                ),
              ],
            ),
          ),

          // Recipe Results
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                : recipes.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _searchController.text.trim().isNotEmpty
                        ? Icons.search_off
                        : Icons.restaurant_menu,
                    color: Colors.white60,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.trim().isNotEmpty
                        ? "No recipes found."
                        : "Start searching for recipes",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (_searchController.text.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Try different ingredients or recipe names",
                        style: const TextStyle(color: Colors.white60, fontSize: 14),
                      ),
                    ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return Card(
                  color: const Color(0xFF222431),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: recipe.imageUrl.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        recipe.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.fastfood, color: Colors.amber),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[800],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.amber,
                              ),
                            ),
                          );
                        },
                      ),
                    )
                        : recipe.isAiGenerated 
                          ? Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1B3329),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.restaurant_rounded, color: Color(0xFFFBBC05), size: 24),
                            )
                          : const Icon(Icons.fastfood_rounded, color: Color(0xFFFBBC05)),
                    title: Text(
                      recipe.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${recipe.ingredients.take(3).join(", ")}...',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (recipe.isAiGenerated)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBC05).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFBBC05).withOpacity(0.3)),
                              ),
                              child: const Text(
                                "SELECTION",
                                style: TextStyle(
                                  color: Color(0xFFFBBC05),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        if (_searchController.text.trim().isNotEmpty && 
                            index < 3 && 
                            SearchLogic.calculateRelevanceScore(recipe, _searchController.text) >= 30)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBC05).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFBBC05).withOpacity(0.3), width: 0.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFFBBC05), size: 12),
                                  const SizedBox(width: 4),
                                  const Text(
                                    "TOP MATCH",
                                    style: TextStyle(
                                      color: Color(0xFFFBBC05),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: Colors.white70),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RecipeDetailScreen(recipe: recipe),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}