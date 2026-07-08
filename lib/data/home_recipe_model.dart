class HomeRecipe {
  final String recipeId;
  final String title;
  final String image;
  // Add other fields as needed

  HomeRecipe({
    required this.recipeId,
    required this.title,
    required this.image,
  });

  factory HomeRecipe.fromMap(Map<String, dynamic> map, String id) {
    return HomeRecipe(
      recipeId: id,
      title: map['title'] ?? '',
      image: map['image'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'image': image,
    };
  }
}

