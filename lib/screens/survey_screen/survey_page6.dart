import 'package:flutter/material.dart';
import 'package:kusinai01_app/screens/survey_screen/survey_page7.dart';
import 'user_survey_model.dart';

class SurveyScreen6 extends StatefulWidget {
  final UserSurvey userSurvey;

  const SurveyScreen6({super.key, required this.userSurvey});

  @override
  State<SurveyScreen6> createState() => _SurveyScreen6State();
}

class _SurveyScreen6State extends State<SurveyScreen6> {
  final TextEditingController allergenController = TextEditingController();
  late List<String> allergens;

  @override
  void initState() {
    super.initState();
    allergens = List.from(widget.userSurvey.allergens);
  }

  void addAllergen() {
    final text = allergenController.text.trim();
    if (text.isNotEmpty && !allergens.contains(text)) {
      setState(() {
        allergens.add(text);
        allergenController.clear();
      });
    }
  }

  void removeAllergen(String allergen) {
    setState(() {
      allergens.remove(allergen);
    });
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
                            "Allergens:",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "We'll make sure to avoid these in your recipe suggestions",
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: allergenController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'e.g. Peanuts',
                                    filled: true,
                                    fillColor: Colors.white10,
                                    hintStyle:
                                        const TextStyle(color: Colors.white54),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onSubmitted: (_) => addAllergen(),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: addAllergen,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.all(12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('+'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: allergens
                                .map((item) => Chip(
                                      label: Text(item),
                                      backgroundColor: Colors.amber,
                                      deleteIconColor: Colors.black,
                                      onDeleted: () => removeAllergen(item),
                                    ))
                                .toList(),
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
                          onPressed: () {
                            final updatedSurvey = widget.userSurvey;
                            updatedSurvey.allergens = allergens;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SurveyScreen7(userSurvey: updatedSurvey),
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
