import 'package:flutter/material.dart';
import 'package:kusinai01_app/screens/survey_screen/survey_page6.dart';
import 'user_survey_model.dart';

class SurveyScreen5 extends StatefulWidget {
  final UserSurvey userSurvey;

  const SurveyScreen5({super.key, required this.userSurvey});

  @override
  State<SurveyScreen5> createState() => _SurveyScreen5State();
}

class _SurveyScreen5State extends State<SurveyScreen5> {
  String selectedSkill = '';

  Widget buildSkillOption(String label, IconData icon, String value) {
    final isSelected = selectedSkill == value;
    return GestureDetector(
      onTap: () => setState(() => selectedSkill = value),
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
            Icon(icon, color: isSelected ? Colors.black : Colors.grey),
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
                          const Text(
                            "Basic info",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Let's get to know you!",
                            style: TextStyle(color: Colors.amber),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Cooking Skill Level",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "How would you describe your cooking skills?",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 20),
                          buildSkillOption(
                              "Basic", Icons.fastfood_rounded, "Basic"),
                          buildSkillOption("Intermediate", Icons.ramen_dining,
                              "Intermediate"),
                          buildSkillOption(
                              "Advanced", Icons.local_dining, "Advanced"),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white10,
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: selectedSkill.isNotEmpty
                              ? () {
                                  final updatedSurvey = widget.userSurvey;
                                  updatedSurvey.cookingSkill = selectedSkill;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SurveyScreen6(
                                          userSurvey: updatedSurvey),
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
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
