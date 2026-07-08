import 'package:flutter/material.dart';
import 'package:kusinai01_app/screens/signup_screen.dart';
import 'home_screen.dart';
import 'package:kusinai01_app/utils/form_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  State<SignInPage> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool rememberMe = false;
  bool _obscureText = true; // Fixed: Changed from false to true

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "Dappli",
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 105,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A1D3A), // Fallback background color
                        ),
                        child: Image.asset(
                          'assets/login_img.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 105,
                              color: const Color(0xFF1A1D3A),
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.amber,
                                size: 50,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Welcome back!",
                        style: TextStyle(
                            fontSize: 25,
                            color: Colors.amber,
                            fontWeight: FontWeight.w500),
                      ),
                      const Text(
                        'Log in to continue',
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your email'
                            : null,
                        decoration: buildInputDecoration('Email'),
                        style: TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 12),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your password'
                            : null,
                        decoration: buildInputDecoration('Password').copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.white54,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),

                      const SizedBox(height: 10),

                      // Remember me + Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    rememberMe = value ?? false;
                                  });
                                },
                                activeColor: Colors.amber,
                                checkColor: Colors.black,
                              ),
                              const Text("Remember Me",
                                  style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: Colors.amberAccent),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Sign In Button
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              await FirebaseAuth.instance
                                  .signInWithEmailAndPassword(
                                email: _emailController.text.trim(),
                                password: _passwordController.text.trim(),
                              );

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomeScreen()),
                              );
                            } on FirebaseAuthException catch (e) {
                              String message = '';
                              if (e.code == 'user-not-found') {
                                message = 'No user found for this email.';
                              } else if (e.code == 'wrong-password') {
                                message = 'Incorrect password.';
                              } else {
                                message = 'Login failed: ${e.message}';
                              }

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(message)),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(width, 48),
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Sign in",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Divider with text
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

                      // Social Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SocialLoginButton(
                              imagePath: 'assets/google_icon.png'),
                          SocialLoginButton(
                              imagePath: 'assets/facebook_icon.png'),
                        ],
                      ),

                      const SizedBox(height: 15),

                      // Sign up navigation
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => SignUpPage()),
                            );
                          },
                          child: RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                    text: "Don't you have an account? ",
                                    style: TextStyle(color: Colors.white70)),
                                TextSpan(
                                    text: "Sign up",
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
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable social login button
class SocialLoginButton extends StatelessWidget {
  final String imagePath;

  const SocialLoginButton({Key? key, required this.imagePath})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10.0),
      width: 60.0,
      height: 60.0,
      child: IconButton(
        icon: Image.asset(imagePath),
        iconSize: 40,
        onPressed: () {},
      ),
    );
  }
}