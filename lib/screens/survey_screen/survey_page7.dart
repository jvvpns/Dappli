import 'package:flutter/material.dart';
import 'package:kusinai01_app/screens/home_screen.dart';
import 'package:kusinai01_app/screens/survey_screen/survey_page2.dart';
import 'user_survey_model.dart';
import 'package:kusinai01_app/services/user_service.dart';

class SurveyScreen7 extends StatelessWidget {
  final UserSurvey userSurvey;

  const SurveyScreen7({super.key, required this.userSurvey});

  double calculateBMI() {
    final h = userSurvey.height / 100;
    return userSurvey.weight / (h * h);
  }

  String getBMICategory(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal Weight";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  @override
  Widget build(BuildContext context) {
    final bmi = calculateBMI();
    final bmiStatus = getBMICategory(bmi);

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
                          const SizedBox(height: 20),
                          const Text(
                            "You're all set! Here's a summary of your preferences:",
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 25),
                          summaryRow("Gender:", userSurvey.gender),
                          summaryRow("Age:", "${userSurvey.age}"),
                          summaryRow("BMI:", bmiStatus, color: Colors.green),
                          summaryRow(
                              "Allergens:", userSurvey.allergens.join(", "),
                              color: Colors.amber),
                          summaryRow(
                              "Cooking Skill level:", userSurvey.cookingSkill,
                              color: Colors.amberAccent),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.amber),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        SurveyScreen2(userSurvey: userSurvey),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 80),
                          // extra space before button
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
                          onPressed: () async {
                            try {
                              final userService = UserService();

                              await userService.updateSurveyData({
                                'gender': userSurvey.gender,
                                'age': userSurvey.age,
                                'weight': userSurvey.weight,
                                'height': userSurvey.height,
                                'bmi': calculateBMI(),
                                'allergens': userSurvey.allergens,
                                'cookingSkill': userSurvey.cookingSkill,
                              });

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomeScreen()),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("Error saving survey: $e")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Let's Start!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
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

  Widget summaryRow(String label, String value, {Color color = Colors.white}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: "$label ",
              style: const TextStyle(fontSize: 20, color: Colors.white),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                  fontSize: 20, color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
