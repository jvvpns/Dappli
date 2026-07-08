import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kusinai01_app/data/recipe_model.dart';
import 'package:kusinai01_app/screens/individual_recipe_screen.dart';
import '../widgets/custom_app_bar.dart';

class SavedRecipesScreen extends StatefulWidget {
  const SavedRecipesScreen({Key? key}) : super(key: key);

  @override
  State<SavedRecipesScreen> createState() => _SavedRecipesScreenState();
}

class _SavedRecipesScreenState extends State<SavedRecipesScreen> {
  Widget _buildAiPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFF1B3329),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Icon(Icons.restaurant_rounded, color: Color(0xFFFBBC05), size: 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF3B7A57),
        body: Center(
          child: Text(
            'You must be logged in to view saved recipes.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final savedRecipesRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_recipes')
        .orderBy('created_at', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFF3B7A57),
      appBar: const CustomAppBar(
        title: 'Saved Recipes',
        showBackButton: false,
        backgroundColor: Color(0xFF3B7A57),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: savedRecipesRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded, color: Colors.white54, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No saved recipes yet.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final recipes = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Recipe.fromMap(data, doc.id);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return Card(
                color: Colors.white.withOpacity(0.08),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  leading: recipe.imageUrl.isNotEmpty
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      recipe.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                      : const Icon(Icons.fastfood,
                      color: Colors.amber, size: 40),
                  title: Text(
                    recipe.title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    recipe.ingredients.take(3).join(", ") + "...",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('saved_recipes')
                          .doc(recipe.id)
                          .delete();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Recipe removed.')),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipe: recipe),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
