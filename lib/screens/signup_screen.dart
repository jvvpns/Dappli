import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kusinai01_app/screens/signin_screen.dart';
import 'package:philippines_rpcmb/philippines_rpcmb.dart';
import 'package:kusinai01_app/screens/survey_screen/survey_page1.dart';
import 'package:kusinai01_app/utils/form_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  Region? selectedRegion;
  Province? selectedProvince;
  Municipality? selectedMunicipality;

  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<Region> regions = philippineRegions;
  List<Province> provinces = [];
  List<Municipality> municipalities = [];

  bool acceptedTerms = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create an account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          color: Colors.white,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Let's help you set up your account,\nit won't take long.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.yellow,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text("Name",
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _lastNameController,
                              decoration: buildInputDecoration("Last Name"),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: TextField(
                              controller: _firstNameController,
                              decoration: buildInputDecoration("First Name"),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text("Address",
                          style: TextStyle(color: Colors.white, fontSize: 18)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          DropdownButtonFormField<Region>(
                                                        decoration: buildInputDecoration('Region'),
                                                        value: selectedRegion,
                                                        items: regions.map((region) {
                          return DropdownMenuItem(
                            value: region,
                            child: Text(
                              region.regionName,
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                                                        }).toList(),
                                                        onChanged: (region) {
                          setState(() {
                            selectedRegion = region;
                            selectedProvince = null;
                            selectedMunicipality = null;
                            provinces = region?.provinces ?? [];
                            municipalities = [];
                          });
                                                        },
                                                        dropdownColor: Colors.black,
                                                      ),
                          SizedBox(height: 5),
                          DropdownButtonFormField<Province>(
                                                        decoration: buildInputDecoration('Province'),
                                                        value: selectedProvince,
                                                        items: provinces.map((province) {
                          return DropdownMenuItem(
                            value: province,
                            child: Text(
                              province.name,
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                                                        }).toList(),
                                                        onChanged: (province) {
                          setState(() {
                            selectedProvince = province;
                            selectedMunicipality = null;
                            municipalities =
                                province?.municipalities ?? [];
                          });
                                                        },
                                                        dropdownColor: Colors.black,
                                                      ),
                          SizedBox(height: 5),
                          DropdownButtonFormField<Municipality>(
                                                        decoration:
                            buildInputDecoration('City/Municipality'),
                                                        value: selectedMunicipality,
                                                        items: municipalities.map((municipality) {
                          return DropdownMenuItem(
                            value: municipality,
                            child: Text(
                              municipality.name,
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                                                        }).toList(),
                                                        onChanged: (municipality) {
                          setState(() {
                            selectedMunicipality = municipality;
                          });
                                                        },
                                                        dropdownColor: Colors.black,
                                                      )
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _emailController,
                        decoration: buildInputDecoration("Email"),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        decoration: buildInputDecoration("Password"),
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      CheckboxListTile(
                        activeColor: Colors.amber,
                        checkColor: Colors.black,
                        side: const BorderSide(color: Colors.white),
                        title: const Text(
                          "I accept the Terms and Conditions",
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                        value: acceptedTerms,
                        onChanged: (value) {
                          setState(() {
                            acceptedTerms = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: acceptedTerms
                            ? () async {
                                try {
                                  UserCredential userCredential =
                                      await FirebaseAuth.instance
                                          .createUserWithEmailAndPassword(
                                    email: _emailController.text.trim(),
                                    password: _passwordController.text.trim(),
                                  );

                                  // Get UID
                                  final uid = userCredential.user!.uid;

                                  // Save user info to Firestore
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(uid)
                                      .set({
                                    'firstName':
                                        _firstNameController.text.trim(),
                                    'lastName': _lastNameController.text.trim(),
                                    'email': _emailController.text.trim(),
                                    'region': selectedRegion?.regionName ?? '',
                                    'province': selectedProvince?.name ?? '',
                                    'municipality':
                                        selectedMunicipality?.name ?? '',
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SurveyScreen1()),
                                  );
                                } on FirebaseAuthException catch (e) {
                                  String message = '';
                                  if (e.code == 'email-already-in-use') {
                                    message = 'Email is already registered.';
                                  } else if (e.code == 'invalid-email') {
                                    message = 'Invalid email address.';
                                  } else if (e.code == 'weak-password') {
                                    message =
                                        'Password should be at least 6 characters.';
                                  } else {
                                    message =
                                        'Registration failed: ${e.message}';
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(width, 48),
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Expanded(
                            child:
                                Divider(color: Colors.yellow, thickness: 1.5),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Or Sign up with",
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child:
                                Divider(color: Colors.yellow, thickness: 1.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            margin: EdgeInsets.all(10.0),
                            width: 60.0,
                            height: 60.0,
                            child: IconButton(
                              icon: Image.asset('assets/google_icon.png'),
                              iconSize: 40,
                              onPressed: () {},
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.all(10.0),
                            width: 60.0,
                            height: 60.0,
                            child: IconButton(
                              icon: Image.asset('assets/facebook_icon.png'),
                              iconSize: 40,
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignInPage()),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                    text: "Already a member? ",
                                    style: TextStyle(color: Colors.white70)),
                                TextSpan(
                                    text: "Sign in",
                                    style:
                                        TextStyle(color: Colors.amberAccent)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
      ),
    );
  }
}
