import 'package:cloud_firestore/cloud_firestore.dart';
import 'recipe_model.dart';

Future<List<Recipe>> fetchRecipes() async {
  final snapshot = await FirebaseFirestore.instance.collection('recipes').get();
  return snapshot.docs.map((doc) => Recipe.fromMap(doc.data(), doc.id)).toList();
}
