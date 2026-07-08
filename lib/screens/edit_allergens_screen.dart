import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';

class EditAllergensScreen extends StatefulWidget {
  const EditAllergensScreen({Key? key}) : super(key: key);

  @override
  State<EditAllergensScreen> createState() => _EditAllergensScreenState();
}

class _EditAllergensScreenState extends State<EditAllergensScreen> {
  List<String> allergens = [];
  final TextEditingController _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAllergens();
  }

  Future<void> _loadAllergens() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.exists) {
      setState(() {
        allergens = List<String>.from(doc['allergens'] ?? []);
      });
    }
  }

  Future<void> _saveAllergens() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'allergens': allergens});

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Allergens updated successfully!')),
    );
    Navigator.pop(context);
  }

  void _addAllergen() {
    final newAllergen = _controller.text.trim();
    if (newAllergen.isNotEmpty && !allergens.contains(newAllergen)) {
      setState(() {
        allergens.add(newAllergen);
      });
      _controller.clear();
    }
  }

  void _removeAllergen(String allergen) {
    setState(() {
      allergens.remove(allergen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Edit Allergens',
        backgroundColor: Color(0xFF101423),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add or remove allergens below:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),

            // Add allergen input field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter new allergen (e.g. peanuts)',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: const Color(0xFF1A1C2C),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: (_) => _addAllergen(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addAllergen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBBC05),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Allergen Chips
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allergens.map((allergen) {
                    return Chip(
                      label: Text(
                        allergen,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: const Color(0xFFFBBC05),
                      deleteIcon: const Icon(Icons.close, color: Colors.black),
                      onDeleted: () => _removeAllergen(allergen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAllergens,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBC05),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
