import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class AddRecipeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(
        title: 'Add Recipe',
        backgroundColor: Color(0xFF3B7A57),
      ),
      body: Center(
        child: Text('Add Recipe Feature Coming Soon!'),
      ),
    );
  }
}