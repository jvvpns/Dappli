class UserSurvey {
  String gender;
  int weight;
  int height;
  int age;
  double bmi;
  String cookingSkill;
  List<String> allergens;

  UserSurvey({
    this.gender = '',
    this.weight = 60,
    this.height = 169,
    this.age = 23,
    this.bmi = 0.0,
    this.cookingSkill = '',
    this.allergens = const [],
  });
}
