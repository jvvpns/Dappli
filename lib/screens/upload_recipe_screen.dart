import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/storage_service.dart';
import '../services/image_helper.dart';
import '../data/recipe_model.dart';
import '../widgets/custom_app_bar.dart';

class UploadRecipeScreen extends StatefulWidget {
  const UploadRecipeScreen({Key? key}) : super(key: key);

  @override
  State<UploadRecipeScreen> createState() => _UploadRecipeScreenState();
}

class _UploadRecipeScreenState extends State<UploadRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isUploading = false;
  bool _isAiRefining = false;
  bool _hasUsedAi = false; // AI Limiter

  // Form Fields
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _prepTimeController = TextEditingController();
  final List<TextEditingController> _ingredientControllers = [TextEditingController()];
  final List<TextEditingController> _instructionControllers = [TextEditingController()];
  File? _selectedImage;
  final List<String> _selectedAllergenTags = [];

  final List<String> _commonAllergens = [
    'Peanut', 'Dairy', 'Egg', 'Gluten', 'Soy', 'Shellfish', 'Fish', 'Tree Nuts'
  ];

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF3C2F2F),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose Photo Source', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(Icons.camera_alt_rounded, 'Camera', () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                }),
                _buildSourceOption(Icons.photo_library_rounded, 'Gallery', () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFBBC05), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: const Color(0xFF3C2F2F), size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _refineWithAi() async {
    if (_hasUsedAi) return;

    final rawInstructions = _instructionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).join('\n');
    if (rawInstructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add some steps first!')));
      return;
    }

    setState(() => _isAiRefining = true);

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) throw Exception('API key not found');

      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final prompt = "You are a professional Filipino Chef. Refine the following recipe steps into a numbered, clear, and professional format. Keep it concise. Do not include a title or ingredients. Steps:\n$rawInstructions";
      
      final response = await model.generateContent([Content.text(prompt)]);
      final refinedText = response.text ?? "";

      if (refinedText.isNotEmpty) {
        final newSteps = refinedText.split('\n').where((s) => s.trim().isNotEmpty).toList();
        setState(() {
          _instructionControllers.clear();
          for (var step in newSteps) {
            _instructionControllers.add(TextEditingController(text: step.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim()));
          }
          _hasUsedAi = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFFFBBC05),
            content: Text('The Chef has polished your recipe! 👨‍🍳✨', style: TextStyle(color: Color(0xFF3C2F2F), fontWeight: FontWeight.bold)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chef is busy: $e')));
    } finally {
      setState(() => _isAiRefining = false);
    }
  }

  void _addCustomAllergen() {
    final TextEditingController customController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3C2F2F),
        title: const Text('Add Other Allergen', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: customController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g., Honey',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFBBC05))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () {
            if (customController.text.trim().isNotEmpty) {
              setState(() => _selectedAllergenTags.add(customController.text.trim()));
            }
            Navigator.pop(context);
          }, child: const Text('ADD', style: TextStyle(color: Color(0xFFFBBC05)))),
        ],
      ),
    );
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      // PRO LOGIC: Automatically jump to the first step with an error
      if (_titleController.text.isEmpty || _prepTimeController.text.isEmpty) {
        setState(() => _currentStep = 0);
      } else if (_ingredientControllers.any((c) => c.text.isEmpty)) {
        setState(() => _currentStep = 1);
      } else if (_instructionControllers.any((c) => c.text.isEmpty)) {
        setState(() => _currentStep = 2);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wait! Some recipe details are missing.'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }
    
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isUploading = true);

    try {
      String imageBase64 = '';
      if (_selectedImage != null) {
        final compressedFile = await ImageHelper.compressImage(_selectedImage!);
        imageBase64 = await StorageService().convertToBase64(compressedFile);
      }

      final recipe = Recipe(
        imageUrl: imageBase64,
        id: '',
        title: _titleController.text.trim(),
        ingredients: _ingredientControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList(),
        instructions: _instructionControllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).join('\n'),
        totalTime: int.tryParse(_prepTimeController.text.trim()) ?? 0,
        allergens: _selectedAllergenTags,
        authorId: uid,
        isPublic: false,
      );

      await FirebaseFirestore.instance.collection('recipes').add(recipe.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recipe added to your Cookbook!')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C2222),
      appBar: const CustomAppBar(
        title: 'Chef\'s Creation',
        backgroundColor: Color(0xFF2C2222),
      ),
      body: _isUploading 
        ? _buildLoadingState() 
        : Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: Color(0xFFFBBC05), onSurface: Colors.white),
            ),
            child: Form(
              key: _formKey,
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 3) {
                    setState(() => _currentStep += 1);
                  } else {
                    _saveRecipe();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep -= 1);
                  }
                },
                controlsBuilder: (context, details) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      children: [
                        ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFBBC05),
                            foregroundColor: const Color(0xFF3C2F2F),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(_currentStep == 3 ? 'PUBLISH' : 'NEXT'),
                        ),
                        if (_currentStep > 0)
                          TextButton(onPressed: details.onStepCancel, child: const Text('BACK', style: TextStyle(color: Colors.white70))),
                      ],
                    ),
                  );
                },
                steps: [
                  _buildBasicInfoStep(),
                  _buildIngredientsStep(),
                  _buildInstructionsStep(),
                  _buildReviewStep(),
                ],
              ),
            ),
          ),
    );
  }

  Step _buildBasicInfoStep() {
    return Step(
      title: const Text('Basic Information', style: TextStyle(color: Colors.white)),
      isActive: _currentStep >= 0,
      content: Column(
        children: [
          _buildTextField('Recipe Title', _titleController),
          const SizedBox(height: 16), // Added breathing room
          _buildTextField('Prep Time (minutes)', _prepTimeController, isNumber: true),
          const SizedBox(height: 20), // Added breathing room
          GestureDetector(
            onTap: _showImageSourcePicker,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(color: const Color(0xFF3C2F2F), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
              child: _selectedImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add_a_photo_rounded, color: Color(0xFFFBBC05), size: 40),
                        SizedBox(height: 8),
                        Text('Add Photo (Optional)', style: TextStyle(color: Colors.white70)),
                      ],
                    )
                  : ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_selectedImage!, fit: BoxFit.cover)),
            ),
          ),
        ],
      ),
    );
  }

  Step _buildIngredientsStep() {
    return Step(
      title: const Text('Ingredients', style: TextStyle(color: Colors.white)),
      isActive: _currentStep >= 1,
      content: Column(
        children: [
          ..._ingredientControllers.map((controller) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildTextField('e.g., 2 tbsp Soy Sauce', controller),
          )),
          TextButton.icon(
            onPressed: () => setState(() => _ingredientControllers.add(TextEditingController())),
            icon: const Icon(Icons.add, color: Color(0xFFFBBC05)),
            label: const Text('ADD INGREDIENT', style: TextStyle(color: Color(0xFFFBBC05))),
          ),
        ],
      ),
    );
  }

  Step _buildInstructionsStep() {
    return Step(
      title: const Text('Cooking Instructions', style: TextStyle(color: Colors.white)),
      isActive: _currentStep >= 2,
      content: Column(
        children: [
          if (!_hasUsedAi)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFFBBC05).withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFBBC05).withOpacity(0.3))),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded, color: Color(0xFFFBBC05), size: 20),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('The Chef can polish your recipe steps once per session to get the flavors just right!', style: TextStyle(color: Color(0xFFFBBC05), fontSize: 13, height: 1.4))),
                  ],
                ),
              ),
            ),
          ..._instructionControllers.asMap().entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildTextField('Step ${entry.key + 1}', entry.value, maxLines: 2),
          )),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _instructionControllers.add(TextEditingController())),
                icon: const Icon(Icons.add, color: Color(0xFFFBBC05)),
                label: const Text('ADD STEP', style: TextStyle(color: Color(0xFFFBBC05))),
              ),
              const Spacer(),
              if (!_hasUsedAi)
                ElevatedButton.icon(
                  onPressed: _isAiRefining ? null : _refineWithAi,
                  icon: _isAiRefining 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Color(0xFF3C2F2F), strokeWidth: 2))
                    : const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('REFINE WITH AI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBBC05), foregroundColor: const Color(0xFF3C2F2F), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Step _buildReviewStep() {
    return Step(
      title: const Text('Allergens & Review', style: TextStyle(color: Colors.white)),
      isActive: _currentStep >= 3,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select any allergens included:', style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              ..._commonAllergens.map((allergen) {
                final isSelected = _selectedAllergenTags.contains(allergen);
                return FilterChip(
                  label: Text(allergen),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFBBC05),
                  checkmarkColor: const Color(0xFF3C2F2F),
                  backgroundColor: const Color(0xFF3C2F2F),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) _selectedAllergenTags.add(allergen);
                      else _selectedAllergenTags.remove(allergen);
                    });
                  },
                );
              }),
              ..._selectedAllergenTags.where((a) => !_commonAllergens.contains(a)).map((allergen) => FilterChip(
                  label: Text(allergen),
                  selected: true,
                  selectedColor: const Color(0xFFFBBC05).withOpacity(0.5),
                  checkmarkColor: const Color(0xFF3C2F2F),
                  backgroundColor: const Color(0xFF3C2F2F),
                  onSelected: (selected) => setState(() => _selectedAllergenTags.remove(allergen)),
                )),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16, color: Color(0xFF3C2F2F)),
                label: const Text('OTHERS', style: TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: const Color(0xFFFBBC05),
                onPressed: _addCustomAllergen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF3C2F2F),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: (v) => v!.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: Color(0xFFFBBC05)),
          SizedBox(height: 20),
          Text('Simmering your creation...', style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
