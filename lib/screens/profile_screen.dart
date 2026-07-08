import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kusinai01_app/screens/edit_profile_screen.dart';
import 'package:kusinai01_app/screens/edit_allergens_screen.dart';
import 'package:kusinai01_app/screens/my_cookbook_screen.dart';
import '../widgets/custom_app_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final snapshot =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (snapshot.exists) {
        setState(() {
          userData = snapshot.data();
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Widget _profileInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 16),
          children: [
            TextSpan(
                text: '$label ',
                style: const TextStyle(
                    fontWeight: FontWeight.w500, color: Colors.white70)),
            TextSpan(
                text: value, style: const TextStyle(color: Color(0xFFFBBC05))),
          ],
        ),
      ),
    );
  }

  Widget _buildAllergenChips(List<dynamic> allergens) {
    if (allergens.isEmpty) {
      return const Text(
        "No allergens specified",
        style: TextStyle(color: Colors.white54),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allergens.map((allergen) {
        return Chip(
          label: Text(
            allergen,
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: const Color(0xFFFBBC05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3B7A57),
      appBar: const CustomAppBar(title: 'Profile'),
      body: userData == null
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFBBC05)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                  const SizedBox(height: 10),

              // Profile Picture
              Stack(
                children: [
                  CircleAvatar(
                    radius: 65,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : const AssetImage('assets/default_avatar.png')
                    as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 35,
                        width: 35,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFBBC05),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.black, size: 18),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // User Name
              Text(
                userData!['firstName'] != null || userData!['lastName'] != null
                    ? "${userData!['firstName'] ?? ''} ${userData!['lastName'] ?? ''}".trim()
                    : 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),
              Text(
                FirebaseAuth.instance.currentUser?.email ?? '',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),

              const SizedBox(height: 20),

              const Text(
                'About Me',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1C2C),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _profileInfo('Gender:', '${userData!['gender']}'),
                    _profileInfo('Age:', '${userData!['age']}'),
                    _profileInfo('Weight:', '${userData!['weight']} kg'),
                    _profileInfo('Height:', '${userData!['height']} cm'),
                    _profileInfo(
                        'BMI:',
                        userData!['bmi'] != null
                            ? '${userData!['bmi'].toStringAsFixed(1)}'
                            : 'N/A'),
                    _profileInfo('Cooking Skill:',
                        '${userData!['cookingSkill'] ?? 'Unknown'}'),

                    const SizedBox(height: 10),

                    const Text(
                      'Allergens:',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),

                    _buildAllergenChips(
                        List<String>.from(userData!['allergens'] ?? [])),

                    const SizedBox(height: 16),

                    // Edit buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                  const EditProfileScreen()),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text("Edit Profile"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBBC05),
                            foregroundColor: Colors.black,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                  const EditAllergensScreen()),
                            ).then((_) => fetchUserData());
                          },
                          icon: const Icon(Icons.local_hospital),
                          label: const Text("Edit Allergens"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBBC05),
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // New Section: Culinary Contributions
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Culinary Portfolio',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyCookbookScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBC05), Color(0xFFE0A800)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBC05).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.kitchen_rounded, color: Color(0xFF3C2F2F), size: 28),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Cookbook',
                              style: TextStyle(
                                color: Color(0xFF3C2F2F),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Manage your private recipes',
                              style: TextStyle(
                                color: const Color(0xFF3C2F2F).withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF3C2F2F), size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
    );
  }
}
