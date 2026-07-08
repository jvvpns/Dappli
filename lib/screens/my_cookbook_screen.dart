import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../data/recipe_model.dart';
import 'individual_recipe_screen.dart';
import 'upload_recipe_screen.dart';
import '../widgets/custom_app_bar.dart';

class MyCookbookScreen extends StatefulWidget {
  const MyCookbookScreen({Key? key}) : super(key: key);

  @override
  State<MyCookbookScreen> createState() => _MyCookbookScreenState();
}

class _MyCookbookScreenState extends State<MyCookbookScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Center(child: Text('Login to see your cookbook', style: TextStyle(color: Colors.white70)));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2C2222),
      appBar: CustomAppBar(
        title: 'My Cookbook',
        backgroundColor: const Color(0xFF2C2222),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UploadRecipeScreen()),
              );
            },
            icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFFBBC05), size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('recipes')
            .where('authorId', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFBBC05)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final recipes = snapshot.data!.docs
              .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: recipes.length,
            itemBuilder: (context, index) {
              return _buildRecipeCard(recipes[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildRecipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RecipeDetailScreen(recipe: recipe)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF3C2F2F),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: recipe.imageUrl.isNotEmpty
                    ? (recipe.imageUrl.startsWith('data:image')
                        ? Image.memory(
                            base64Decode(recipe.imageUrl.split(',')[1]),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Image.network(
                            recipe.imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ))
                    : Container(
                        color: Colors.white12,
                        child: const Center(child: Icon(Icons.restaurant, color: Colors.white24, size: 40)),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Color(0xFFFBBC05), size: 14),
                        const SizedBox(width: 4),
                        Text('${recipe.totalTime}m', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.kitchen_outlined, color: Colors.white10, size: 100),
          const SizedBox(height: 16),
          const Text(
            'Your Cookbook is empty',
            style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the + button to add your first recipe!',
            style: TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
