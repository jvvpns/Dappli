import 'package:flutter/material.dart';
import 'package:kusinai01_app/app_colors.dart';

class LoadingSkeletonScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header skeleton
              Padding(
                padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                child: Center(
                  child: Container(
                    height: 36,
                    width: 100,
                    color: Colors.grey[300],
                  ),
                ),
              ),
              // Search bar skeleton
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              // Sections skeleton
              _buildSkeletonSection(),
              _buildSkeletonSection(),
              _buildSkeletonSection(),
              _buildSkeletonSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Container(
            height: 24,
            width: 150,
            color: Colors.grey[300],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemCount: 5,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: _buildSkeletonCard(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 20,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}