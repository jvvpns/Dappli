import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kusinai01_app/data/recipe_model.dart';
import 'package:kusinai01_app/screens/menu_screen.dart';
import 'package:kusinai01_app/screens/individual_recipe_screen.dart';
import 'package:kusinai01_app/screens/search_screen.dart';
import 'package:kusinai01_app/screens/ar_scanner_screen.dart';
import 'package:kusinai01_app/screens/savedrecipes_screen.dart';
import 'package:kusinai01_app/screens/upload_recipe_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Pagination State
  final ScrollController _scrollController = ScrollController();
  List<Recipe> _recipes = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoadingInitial = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  static const int _batchSize = 10;

  @override
  void initState() {
    super.initState();
    _fetchInitialRecipes();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialRecipes() async {
    setState(() => _isLoadingInitial = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .limit(_batchSize)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        _recipes = querySnapshot.docs
            .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        _hasMore = querySnapshot.docs.length == _batchSize;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Error fetching recipes: $e');
    }
    if (mounted) setState(() => _isLoadingInitial = false);
  }

  Future<void> _fetchMoreRecipes() async {
    if (_isLoadingMore || !_hasMore || _lastDocument == null) return;

    setState(() => _isLoadingMore = true);
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .startAfterDocument(_lastDocument!)
          .limit(_batchSize)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
        final newRecipes = querySnapshot.docs
            .map((doc) => Recipe.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        _recipes.addAll(newRecipes);
        _hasMore = querySnapshot.docs.length == _batchSize;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Error fetching more recipes: $e');
    }
    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _fetchMoreRecipes();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget recipeCard(Recipe recipe) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RecipeDetailScreen(recipe: recipe),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: recipe.imageUrl.isNotEmpty
                    ? Image.network(recipe.imageUrl, fit: BoxFit.cover)
                    : recipe.isAiGenerated
                        ? _buildGourmetPlaceholder(recipe, isSmall: true)
                        : Image.asset('assets/placeholder.jpg', fit: BoxFit.cover),
              ),
              // Bottom Gradient Scrim
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
              // Title
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Text(
                  recipe.displayTitle, // ✅ Using the auto-cleaning title
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KusinaAI',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SearchScreen()),
                  );
                },
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                iconSize: 30,
              ),
            ],
          ),
        ),
        // Section Header
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: const BoxDecoration(
                  color: Color(0xFFFBBC05),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                ),
                child: const Text(
                  'Recipes',
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3C2F2F),
                  ),
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
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Upload a recipe...',
                          style: TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFBBC05),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const UploadRecipeScreen()),
                            );
                          },
                          iconSize: 18,
                          icon: const Icon(Icons.add_rounded, color: Color(0xFF3C2F2F)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Paginated Grid View
        Expanded(
          child: _isLoadingInitial
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFBBC05)))
              : _recipes.isEmpty
                  ? const Center(child: Text('No recipes found', style: TextStyle(color: Colors.white70)))
                  : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 80),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _recipes.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _recipes.length) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFFFBBC05)));
                        }
                        return recipeCard(_recipes[index]);
                      },
                    ),
        ),
      ],
    );
  }

  /// Builds only the currently selected tab's widget.
  /// Using IndexedStack would eagerly build ALL tabs — including ARScannerScreen —
  /// causing the camera to initialize immediately on home screen entry.
  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const SavedRecipesScreen();
      case 2:
        return const ARScannerScreen();
      case 3:
        return MenuScreen();
      default:
        return _buildHomeTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _buildCurrentTab(),
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: const Color(0xFF0F1122)),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF3C2F2F),
          selectedItemColor: const Color(0xFFFBBC05),
          unselectedItemColor: const Color(0xFFFBBC05),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 0 ? Icons.home : Icons.home_outlined),
              label: 'Recipes',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 1 ? Icons.bookmarks : Icons.bookmarks_outlined),
              label: 'Saved',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 2 ? Icons.document_scanner : Icons.document_scanner_sharp),
              label: 'Scanner',
            ),
            BottomNavigationBarItem(
              icon: Icon(_selectedIndex == 3 ? Icons.menu : Icons.menu_rounded),
              label: 'Menu',
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildGourmetPlaceholder(Recipe recipe, {bool isSmall = false}) {
    return Container(
      color: const Color(0xFF1B3329), // Deep Mono Green
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_rounded,
              color: const Color(0xFFFBBC05),
              size: isSmall ? 32 : 64,
            ),
            if (!isSmall) ...[
              const SizedBox(height: 12),
              const Text(
                "DAPPLI SELECTION",
                style: TextStyle(
                  color: Color(0xFFFBBC05),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildNavItem({required IconData icon, required String label, required int index, required VoidCallback onTap}) {
    final isSelected = _selectedIndex == index;
    return MaterialButton(
      minWidth: 40,
      onPressed: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFFFBBC05) : Colors.white54,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFFFBBC05) : Colors.white54,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
