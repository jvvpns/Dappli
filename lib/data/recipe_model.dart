class Recipe {
  final String imageUrl;
  final String id;
  final String title;
  final String description;
  final List<String> ingredients;
  final String instructions;
  final int totalTime;
  final List<String> allergens;
  final String? authorId; // ✅ Track who uploaded it
  final bool isPublic;  // ✅ For privacy
  final bool isAiGenerated; // ✅ NEW: Track AI vs User content
  bool isSaved; // for saving recipes

  String get displayTitle => title.replaceAll(RegExp(r'\s+Recipe$', caseSensitive: false), '').trim();

  Recipe({
    required this.imageUrl,
    required this.id,
    required this.title,
    this.description = '',
    required this.ingredients,
    required this.instructions,
    required this.totalTime,
    required this.allergens,
    this.authorId,
    this.isPublic = false,
    this.isAiGenerated = false,
    this.isSaved = false,
  });

  factory Recipe.fromMap(Map<String, dynamic> data, String documentId) {
    return Recipe(
      imageUrl: data['image'] ?? '',
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      instructions: data['instructions'] ?? '',
      totalTime: data['total_time'] ?? 0,
      allergens: List<String>.from(data['allergens'] ?? []),
      authorId: data['authorId'],
      isPublic: data['isPublic'] ?? false,
      isAiGenerated: data['isAiGenerated'] ?? false,
      isSaved: data['isSaved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'image': imageUrl,
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'instructions': instructions,
      'total_time': totalTime,
      'allergens': allergens,
      'authorId': authorId,
      'isPublic': isPublic,
      'isAiGenerated': isAiGenerated,
      'isSaved': isSaved,
    };
  }

  factory Recipe.fromGeneratedText(String rawText) {
    final lines = rawText.split('\n');

    String title = '';
    String description = '';
    List<String> ingredients = [];
    List<String> instructions = [];
    int totalTime = 0;
    List<String> allergens = [];

    int step = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.toLowerCase().startsWith('title:')) {
        title = line.replaceFirst(RegExp(r'(?i)title:'), '').trim();
      } else if (line.toLowerCase().startsWith('description:')) {
        description = line.replaceFirst(RegExp(r'(?i)description:'), '').trim();
      } else if (line.toLowerCase().startsWith('ingredients:')) {
        step = 1;
      } else if (line.toLowerCase().startsWith('instructions:')) {
        step = 2;
      } else if (line.toLowerCase().startsWith('total cooking time:')) {
        final timeText = line.replaceFirst(RegExp(r'(?i)total cooking time:'), '').trim();
        totalTime = int.tryParse(RegExp(r'\d+').stringMatch(timeText) ?? '0') ?? 0;
      } else if (line.toLowerCase().startsWith('allergens:')) {
        final allergenText = line.replaceFirst(RegExp(r'(?i)allergens:'), '').trim();
        allergens = allergenText.split(',').map((e) => e.trim()).toList();
      } else {
        if (step == 1 && line.isNotEmpty) {
          ingredients.add(line.replaceFirst(RegExp(r'^[-*]\s*'), '').trim());
        } else if (step == 2 && line.isNotEmpty) {
          instructions.add(line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim());
        }
      }
    }

    return Recipe(
      imageUrl: '',
      id: '',
      title: title.isNotEmpty ? title : 'Generated Recipe',
      description: description,
      ingredients: ingredients,
      instructions: instructions.join('\n'),
      totalTime: totalTime,
      allergens: allergens,
      isAiGenerated: true,
    );
  }

  factory Recipe.fromText(String rawText) => Recipe.fromGeneratedText(rawText);

  factory Recipe.suggestion({
    required String title,
    required String description,
    required String style,
  }) {
    return Recipe(
      imageUrl: '',
      id: '',
      title: title,
      description: description,
      ingredients: [],
      instructions: '',
      totalTime: 0,
      allergens: [],
      isPublic: false,
      isAiGenerated: true,
      isSaved: false,
    );
  }
}
