import 'package:flutter/material.dart';
import 'package:kusinai01_app/screens/survey_screen/survey_page5.dart';
import 'user_survey_model.dart';

class SurveyScreen4 extends StatelessWidget {
  final UserSurvey userSurvey;

  const SurveyScreen4({super.key, required this.userSurvey});

  double calculateBMI() {
    final heightInMeters = userSurvey.height / 100;
    return userSurvey.weight / (heightInMeters * heightInMeters);
  }

  String getBMICategory(double bmi) {
    if (bmi < 18.5) return "Underweight";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Overweight";
    return "Obese";
  }

  Color getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final bmi = calculateBMI();
    final category = getBMICategory(bmi);
    final color = getBMIColor(bmi);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
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

                          // BMI Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 24, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: [
                                Text("Your BMI",
                                    style: TextStyle(color: Colors.grey[700])),
                                const SizedBox(height: 8),
                                Text(
                                  bmi.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                Text(
                                  category,
                                  style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _infoColumn(
                                        "${userSurvey.weight} kg", "Weight"),
                                    _infoColumn(
                                        "${userSurvey.height} cm", "Height"),
                                    _infoColumn("${userSurvey.age}", "Age"),
                                    _infoColumn(userSurvey.gender, "Gender"),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 80), // Space before button
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
                        onPressed: () => Navigator.pop(context),
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
                          onPressed: () {
                            final bmi = calculateBMI();
                            userSurvey.bmi = bmi;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SurveyScreen5(userSurvey: userSurvey),
                              ),
                            );
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
                            "Proceed",
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

  Widget _infoColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
