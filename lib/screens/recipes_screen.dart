import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class RecipePage extends StatelessWidget {
  const RecipePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Dappli',
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(onPressed: (){}, icon: const Icon(Icons.search)),
          IconButton(onPressed: (){}, icon: const Icon(Icons.add),)
        ],
      ),
    );
  }
}