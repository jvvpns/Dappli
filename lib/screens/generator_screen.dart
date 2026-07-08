import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kusinai01_app/data/recipe_model.dart';
import 'package:kusinai01_app/screens/individual_recipe_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import '../app_colors.dart';
import '../services/openai_service.dart';

import '../widgets/custom_app_bar.dart';

class GeneratorScreen extends StatefulWidget {
  final List<String> initialIngredients; // ✅ Added field

  const GeneratorScreen({
    super.key,
    required this.initialIngredients,
  });

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final TextEditingController _controller = TextEditingController();
  final OpenAIService _openAIService = OpenAIService();
  bool _isLoading = false;
  List<Recipe> _generatedRecipes = [];
  int _statusIndex = 0;
  Timer? _statusTimer;

  // Static to persist across screen transitions
  static DateTime? _lastGenerationTime;
  int _cooldownRemaining = 0;
  Timer? _cooldownTimer;
  static const int _cooldownDuration = 60; // seconds

  final List<String> _loadingMessages = [
    "Analyzing ingredients...",
    "Curating culinary suggestions...",
    "Balancing flavors...",
    "Refining your gourmet selection...",
    "Finalizing the presentation...",
  ];

  // 🔹 Custom SVGs for Recipe Styles (Genres)
  static const String _svgStew = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M4 8H20V12C20 16.4183 16.4183 20 12 20C7.58172 20 4 16.4183 4 12V8Z" stroke="#FBBC05" stroke-width="2"/><path d="M12 4V8M8 5V8M16 5V8" stroke="#FBBC05" stroke-width="2" stroke-linecap="round"/></svg>''';
  static const String _svgGrill = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 11V21M8 11V19M16 11V19M19 11V16M5 11V16M3 7H21" stroke="#FBBC05" stroke-width="2" stroke-linecap="round"/></svg>''';
  static const String _svgStirFly = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M4 11C4 11 4 16 12 16C20 16 20 11 20 11H4Z" stroke="#FBBC05" stroke-width="2"/><path d="M20 11L22 9" stroke="#FBBC05" stroke-width="2" stroke-linecap="round"/></svg>''';
  static const String _svgFresh = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M12 20C12 20 19 16 19 12C19 8 16 4 12 4C8 4 5 8 5 12C5 16 12 20 12 20Z" stroke="#FBBC05" stroke-width="1.5"/><path d="M12 4V20" stroke="#FBBC05" stroke-width="1.5" stroke-dasharray="2 2"/></svg>''';
  static const String _svgPot = '''<svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M3 8H21V10H3V8Z" fill="#FBBC05"/><path d="M5 10V18C5 19.1046 5.89543 20 7 20H17C18.1046 20 19 19.1046 19 18V10" stroke="#FBBC05" stroke-width="2"/></svg>''';

  bool _isGeneratingDetailed = false;
  String _detailStepMessage = "Preparing Ingredients...";

  void _startStatusTimer() {
    _statusTimer?.cancel();
    _statusIndex = 0;
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _isLoading) {
        setState(() {
          _statusIndex = (_statusIndex + 1) % _loadingMessages.length;
        });
      } else {
        timer.cancel();
      }
    });
  }



  @override
  void initState() {
    super.initState();

    // Pre-fill the text field, but wait for manual "Generate" click
    if (widget.initialIngredients.isNotEmpty) {
      _controller.text = widget.initialIngredients.join(', ');
    }
  }

  void _checkInitialCooldown() {
    if (_lastGenerationTime != null) {
      final diff =
          DateTime.now().difference(_lastGenerationTime!).inSeconds;
      if (diff < _cooldownDuration) {
        setState(() {
          _cooldownRemaining = _cooldownDuration - diff;
        });
        _startCooldownTimer();
      }
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _cooldownRemaining > 0) {
        setState(() {
          _cooldownRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _cooldownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generateRecipes(String ingredientsInput) async {
    if (ingredientsInput.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _generatedRecipes = [];
    });
    _startStatusTimer();

    final prompt = '''
You are a master Filipino chef. Given the ingredients below, suggest 5 unique Filipino dishes that could be prepared. 

Return only a **valid JSON array** of objects. Each object must contain:
- "title": The name of the dish.
- "description": A short, appetizing 1-sentence description.
- "style": A single category from this list: [Stew, Grill, Stir-fry, Fresh, Soup].

Rank suggestions by relevance to the given ingredients.
Ingredients: $ingredientsInput
''';

    try {
      final content = await _openAIService.chat(
        prompt: prompt,
        temperature: 0.8,
        maxTokens: 2000,
      );

      final jsonStart = content.indexOf('[');
      final jsonEnd = content.lastIndexOf(']');
      if (jsonStart == -1 || jsonEnd == -1) {
        throw Exception('No JSON array found in response.');
      }

      final jsonString = content.substring(jsonStart, jsonEnd + 1);
      final parsed = jsonDecode(jsonString);

      if (parsed is! List) throw Exception('Response JSON is not a list.');

      final recipes = parsed.map<Recipe>((r) {
        return Recipe.suggestion(
          title: r['title']?.toString() ?? 'Untitled Suggestion',
          description: r['description']?.toString() ?? '',
          style: r['style']?.toString() ?? 'Stew',
        );
      }).toList();

      // Update last generation time on success
      _lastGenerationTime = DateTime.now();
      setState(() {
        _generatedRecipes = recipes;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
  Future<void> _fetchDetailedRecipe(Recipe suggestion) async {
    setState(() {
      _isGeneratingDetailed = true;
      _detailStepMessage = "Chef is analyzing '${suggestion.title}'...";
    });

    final prompt = '''
You are a Filipino Chef. Provide the full details for the recipe: "${suggestion.title}".
Description: ${suggestion.description}
Initial Ingredients provided by user: ${_controller.text}

Return only a **valid JSON object** with:
- "ingredients": (array of strings)
- "instructions": (array of strings)
- "total_time": (integer in minutes)
- "allergens": (array of strings)

Ensure the instructions are professional and easy to follow.
''';

    try {
      final content = await _openAIService.chat(
        prompt: prompt,
        temperature: 0.7,
      );

      final jsonStart = content.indexOf('{');
      final jsonEnd = content.lastIndexOf('}');
      final detailParsed = jsonDecode(content.substring(jsonStart, jsonEnd + 1));

      final fullRecipe = Recipe(
        id: UniqueKey().toString(),
        title: suggestion.title,
        description: suggestion.description,
        imageUrl: '',
        ingredients: List<String>.from(detailParsed['ingredients'] ?? []),
        instructions: (detailParsed['instructions'] as List)
            .asMap()
            .entries
            .map((e) => '${e.key + 1}. ${e.value}')
            .join('\n'),
        totalTime: detailParsed['total_time'] ?? 0,
        allergens: List<String>.from(detailParsed['allergens'] ?? []),
        isAiGenerated: true,
      );

      if (!mounted) return;
      setState(() => _isGeneratingDetailed = false);

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: fullRecipe)),
      );
    } catch (e) {
      if (mounted) setState(() => _isGeneratingDetailed = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to detail recipe: $e')));
    }
  }

  Future<void> _saveGeneratedRecipe(Recipe recipe) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to save recipes.')),
      );
      return;
    }

    final recipeId = FirebaseFirestore.instance.collection('recipes').doc().id;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('saved_recipes')
        .doc(recipeId)
        .set({
      ...recipe.toMap(),
      'created_at': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recipe saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: const CustomAppBar(),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Premium Header (from HomeScreen style)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gourmet',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFBBC05), // Brand Yellow
                          ),
                        ),
                        Container(
                          height: 3,
                          width: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBC05),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                const SizedBox(height: 12),
                Text(
                  'What are we cooking today?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                // 🔹 Themed Input (Glassmorphism)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'e.g. Chicken, garlic, ginger...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔹 Generate Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _cooldownRemaining > 0) ? null : () => _generateRecipes(_controller.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFBBC05),
                      foregroundColor: const Color(0xFF3C2F2F),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3C2F2F)),
                          )
                        else
                          Icon(_cooldownRemaining > 0 ? Icons.timer_outlined : Icons.auto_awesome_rounded),
                        const SizedBox(width: 12),
                        Text(
                          _isLoading
                              ? 'PREPARING...'
                              : (_cooldownRemaining > 0 ? 'COOLDOWN (${_cooldownRemaining}s)' : 'GENERATE RECIPES'),
                          style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 🔹 Results Area
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _generatedRecipes.isEmpty
                          ? _buildEmptyState()
                          : _buildSuggestionsGrid(),
                ),
              ],
            ),
          ),

          // 🔹 Preparation Overlay (Premium Detail Generation)
          if (_isGeneratingDetailed) _buildPreparingOverlay(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.restaurant_rounded, color: Color(0xFFFBBC05), size: 48),
        const SizedBox(height: 16),
        Text(
          _loadingMessages[_statusIndex],
          style: const TextStyle(
            color: Color(0xFFFBBC05),
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Expanded(
          child: ListView.builder(
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 150,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 250,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu_rounded, color: Colors.white.withOpacity(0.1), size: 64),
          const SizedBox(height: 16),
          Text(
            "Ready to craft your feast?",
            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsGrid() {
    return ListView.builder(
      itemCount: _generatedRecipes.length,
      padding: const EdgeInsets.only(bottom: 40),
      itemBuilder: (context, index) {
        final suggestion = _generatedRecipes[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _fetchDetailedRecipe(suggestion),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    // Style Icon (Custom SVG)
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBBC05).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: SvgPicture.string(
                        _getSvgForStyle(suggestion.description), // Helper logic later or style
                        colorFilter: const ColorFilter.mode(Color(0xFFFBBC05), BlendMode.srcIn),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion.displayTitle.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            suggestion.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.2), size: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getSvgForStyle(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('soup') || d.contains('stew') || d.contains('liquid')) return _svgStew;
    if (d.contains('grill') || d.contains('roast') || d.contains('smoke')) return _svgGrill;
    if (d.contains('fry') || d.contains('stir')) return _svgStirFly;
    if (d.contains('salad') || d.contains('fresh') || d.contains('cold')) return _svgFresh;
    return _svgPot;
  }

  Widget _buildPreparingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pulsing Ring
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFBBC05).withOpacity(0.3), width: 8),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFFBBC05)),
                      strokeWidth: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  "DAPPLI SELECTION",
                  style: TextStyle(
                    color: Color(0xFFFBBC05),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _detailStepMessage,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
