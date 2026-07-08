import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kusinai01_app/data/recipe_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({Key? key, required this.recipe}) : super(key: key);

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  List<String> userAllergens = [];
  bool _isSaving = false;
  bool _isSaved = false;
  bool _hasShownWarning = false;

  @override
  void initState() {
    super.initState();
    _checkForAllergens();
    _checkIfSaved();
  }

  /// 🔸 Read user's allergen list from Firestore (users/{uid}.allergens)
  Future<void> _checkForAllergens() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists || doc.data()?['allergens'] == null) return;

      final List<dynamic> allergenList = doc.data()?['allergens'] ?? [];
      userAllergens =
          allergenList.map((a) => a.toString().toLowerCase()).toList();

      final recipeAllergens =
      widget.recipe.allergens.map((a) => a.toLowerCase()).toList();

      final matched = userAllergens
          .where((a) => recipeAllergens.contains(a))
          .toList();

      if (matched.isNotEmpty && !_hasShownWarning) {
        _hasShownWarning = true;
        _showAllergenWarning(matched);
      }
    } catch (e) {
      debugPrint("Error checking allergens: $e");
    }
  }

  /// ⚠️ Show allergen warning popup
  void _showAllergenWarning(List<String> matchedAllergens) {
    showDialog(
      context: context,
      barrierDismissible: false, // force user to choose
      builder: (context) => AlertDialog(
        title: const Text(
          "⚠️ Allergen Warning",
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "This recipe contains your allergen(s):\n\n${matchedAllergens.join(', ')}.\n\nDo you want to proceed?",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Proceed Anyway"),
          ),
        ],
      ),
    );
  }

  /// 🔸 Check if recipe already saved
  Future<void> _checkIfSaved() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_recipes')
        .where('title', isEqualTo: widget.recipe.title)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() => _isSaved = true);
    }
  }

  /// 🔸 Save recipe to Firestore
  Future<void> _saveRecipe() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save recipes.')),
      );
      return;
    }

    if (_isSaved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe already saved!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final recipeId =
          FirebaseFirestore.instance.collection('recipes').doc().id;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saved_recipes')
          .doc(recipeId)
          .set({
        ...widget.recipe.toMap(),
        'created_at': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSaved = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recipe saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving recipe: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// 🟨 Optional helper: Save or update allergens in Firestore
  Future<void> updateUserAllergens(List<String> allergens) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'allergens': allergens},
      SetOptions(merge: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveRecipe,
        backgroundColor: _isSaved ? Colors.green : const Color(0xFFFBBC05),
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
              )
            : Icon(_isSaved ? Icons.check_rounded : Icons.bookmark_add_outlined,
                color: Colors.black),
        label: Text(
          _isSaved ? 'Saved' : 'Save Recipe',
          style: const TextStyle(color: Color(0xFF3C2F2F), fontWeight: FontWeight.bold),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280.0,
            pinned: true,
            backgroundColor: const Color(0xFF3B7A57),
            // Title only shows in the collapsed/pinned state — no duplicate
            title: Text(
              recipe.displayTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            // ✅ Consistent back button matching app-wide navigation pattern
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              // No title here — prevents the double-header issue
              background: recipe.imageUrl.isNotEmpty
                  ? (recipe.imageUrl.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(recipe.imageUrl.split(',')[1]),
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          recipe.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: const Color(0xFF3C2F2F),
                              child: const Center(
                                child: CircularProgressIndicator(color: Color(0xFFFBBC05)),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => _buildGourmetPlaceholder(recipe),
                        ))
                  : recipe.isAiGenerated 
                      ? _buildGourmetPlaceholder(recipe)
                      : Image.asset('assets/placeholder.jpg', fit: BoxFit.cover),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic Allergen Alert (Color changes based on match)
                  if (recipe.allergens.isNotEmpty)
                    Builder(builder: (context) {
                      final matchesUser = userAllergens.any((ua) => recipe
                          .allergens
                          .any((ra) => ra.toLowerCase() == ua.toLowerCase()));

                      final bgColor = matchesUser
                          ? const Color(0xFF3B1818) // Deep red (Alarm)
                          : const Color(0xFF1E3329); // Deep teal/green (Info)
                      final accentColor = matchesUser
                          ? Colors.redAccent // Red accent (Alarm)
                          : const Color(0xFFFBBC05); // Amber (Info)

                      return Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: bgColor,
                          border: Border.all(color: accentColor, width: 1.5),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.25),
                              blurRadius: 16,
                              spreadRadius: 2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              matchesUser
                                  ? Icons.warning_amber_rounded
                                  : Icons.info_outline_rounded,
                              color: accentColor,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    matchesUser
                                        ? "Personal Allergen Warning"
                                        : "General Food Info",
                                    style: TextStyle(
                                      color: accentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Contains: ${recipe.allergens.join(', ')}",
                                    style: TextStyle(
                                        color: accentColor,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                  // Quick Info Row
                  Row(
                    children: [
                      const Icon(Icons.restaurant_menu_rounded, color: Colors.white54, size: 20),
                      const SizedBox(width: 6),
                      Text("${recipe.ingredients.length} Ingredients", style: const TextStyle(color: Colors.white70)),
                      const SizedBox(width: 16),
                      const Icon(Icons.list_alt_rounded, color: Colors.white54, size: 20),
                      const SizedBox(width: 6),
                      Text("${recipe.instructions.split('\n').where((s) => s.trim().isNotEmpty).length} Steps", style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Ingredients",
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFBBC05)),
                  ),
                  const SizedBox(height: 16),
                  ...recipe.ingredients.map(
                        (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("• ", style: TextStyle(color: Color(0xFFFBBC05), fontSize: 20, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              i.trim(),
                              style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  const Text(
                    "Instructions",
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFBBC05)),
                  ),
                  const SizedBox(height: 16),
                  ...recipe.instructions
                      .split('\n')
                      .where((step) => step.trim().isNotEmpty)
                      .map(
                        (step) => Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFFFBBC05), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              step.trim(),
                              style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 80), // Keep room for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGourmetPlaceholder(Recipe recipe) {
    return Container(
      color: const Color(0xFF1B3329), // Deep Mono Green
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_rounded, color: Color(0xFFFBBC05), size: 64),
            const SizedBox(height: 16),
            const Text(
              "DAPPLI SELECTION",
              style: TextStyle(
                color: Color(0xFFFBBC05),
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
