import 'package:flutter/material.dart';
import 'package:kusinai01_app/screens/survey_screen/survey_page1.dart';
import 'package:kusinai01_app/screens/survey_screen/survey_page3.dart';
import 'user_survey_model.dart';

class SurveyScreen2 extends StatefulWidget {
  final UserSurvey userSurvey;

  const SurveyScreen2({super.key, required this.userSurvey});

  @override
  State<SurveyScreen2> createState() => _SurveyScreen2State();
}

class _SurveyScreen2State extends State<SurveyScreen2> {
  String selectedGender = '';

  Widget buildGenderOption(String label, IconData icon, String value) {
    final isSelected = selectedGender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGender = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.grey,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Basic info",
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          const Text("Let's get to know you!",
                              style: TextStyle(color: Colors.amber)),
                          const SizedBox(height: 24),
                          const Text(
                            "Gender",
                            style: TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 25),
                          ),
                          const SizedBox(height: 4),
                          const Text("What is your gender?",
                              style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 20),
                          buildGenderOption("Male", Icons.male, "Male"),
                          buildGenderOption("Female", Icons.female, "Female"),
                          buildGenderOption("Prefer not to say", Icons.circle,
                              "Prefer not to say"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom button row
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SurveyScreen1()));
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white10,
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedGender.isNotEmpty
                              ? () {
                                  widget.userSurvey.gender = selectedGender;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SurveyScreen3(
                                          userSurvey: widget.userSurvey),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Proceed",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
