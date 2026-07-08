import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController cookingSkillController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
    await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        firstNameController.text = data['firstName'] ?? '';
        lastNameController.text = data['lastName'] ?? '';
        genderController.text = data['gender'] ?? '';
        ageController.text = data['age']?.toString() ?? '';
        weightController.text = data['weight']?.toString() ?? '';
        heightController.text = data['height']?.toString() ?? '';
        cookingSkillController.text = data['cookingSkill'] ?? '';
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'gender': genderController.text.trim(),
        'age': int.tryParse(ageController.text.trim()) ?? 0,
        'weight': double.tryParse(weightController.text.trim()) ?? 0,
        'height': double.tryParse(heightController.text.trim()) ?? 0,
        'cookingSkill': cookingSkillController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Edit Profile',
        backgroundColor: Color(0xFF101423),
      ),
      backgroundColor: const Color(0xFF2C2222),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildField('First Name', firstNameController),
                _buildField('Last Name', lastNameController),
                _buildDropdownField('Gender', genderController, ['Male', 'Female', 'Prefer not to say']),
                _buildField('Age', ageController, isNumber: true),
                _buildField('Weight (kg)', weightController, isNumber: true),
                _buildField('Height (cm)', heightController, isNumber: true),
                _buildDropdownField('Cooking Skill Level', cookingSkillController, ['Beginner', 'Intermediate', 'Pro']),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFBBC05),
                    foregroundColor: const Color(0xFF3C2F2F),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Color(0xFF3C2F2F), strokeWidth: 3),
                        )
                      : const Text(
                          'SAVE CHANGES',
                          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF222431),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) =>
        (value == null || value.isEmpty) ? 'Enter $label' : null,
      ),
    );
  }

  Widget _buildDropdownField(String label, TextEditingController controller, List<String> options) {
    String? currentValue = options.contains(controller.text) ? controller.text : null;
    if (currentValue == null && controller.text.isNotEmpty) {
      currentValue = options.firstWhere(
        (o) => o.toLowerCase() == controller.text.toLowerCase(),
        orElse: () => options.first,
      );
      controller.text = currentValue;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: currentValue,
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          setState(() {
            controller.text = newValue!;
          });
        },
        dropdownColor: const Color(0xFF222431),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: const Color(0xFF222431),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
