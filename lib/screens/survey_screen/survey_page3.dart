import 'package:flutter/material.dart';
import 'package:kusinai01_app/screens/survey_screen/survey_page2.dart';
import 'package:kusinai01_app/screens/survey_screen/survey_page4.dart';
import 'package:numberpicker/numberpicker.dart';
import 'user_survey_model.dart';

class SurveyScreen3 extends StatefulWidget {
  final UserSurvey userSurvey;

  const SurveyScreen3({super.key, required this.userSurvey});

  @override
  State<SurveyScreen3> createState() => _SurveyScreen3State();
}

class _SurveyScreen3State extends State<SurveyScreen3> {
  late int weight;
  late int age;
  late int height;

  @override
  void initState() {
    super.initState();
    weight = widget.userSurvey.weight;
    age = widget.userSurvey.age;
    height = widget.userSurvey.height;
  }

  Widget buildCounterBox(
      String label, int value, VoidCallback onAdd, VoidCallback onRemove) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle_outline)),
                Text(
                  "$value",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_circle_outline)),
              ],
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
                          const Text(
                            "Basic info",
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          const Text("Let's get to know you!",
                              style: TextStyle(color: Colors.amber)),
                          const SizedBox(height: 20),
                          const Text(
                            "What are your weight, height, and age?",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              buildCounterBox(
                                  "Weight (kg)",
                                  weight,
                                  () => setState(() => weight++),
                                  () => setState(
                                      () => weight > 30 ? weight-- : null)),
                              buildCounterBox(
                                  "Age",
                                  age,
                                  () => setState(() => age++),
                                  () => setState(() => age > 5 ? age-- : null)),
                            ],
                          ),
                          const SizedBox(height: 30),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                const Text("Height (cm)",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                NumberPicker(
                                  value: height,
                                  minValue: 100,
                                  maxValue: 220,
                                  onChanged: (value) =>
                                      setState(() => height = value),
                                  selectedTextStyle: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textStyle:
                                      const TextStyle(color: Colors.black26),
                                ),
                              ],
                            ),
                          ),
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
                                  builder: (context) => SurveyScreen2(
                                      userSurvey: widget.userSurvey)));
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white10,
                          padding: const EdgeInsets.all(12),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            widget.userSurvey.weight = weight;
                            widget.userSurvey.age = age;
                            widget.userSurvey.height = height;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SurveyScreen4(
                                    userSurvey: widget.userSurvey),
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
