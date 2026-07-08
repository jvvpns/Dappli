import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kusinai01_app/screens/signin_screen.dart';
import 'package:kusinai01_app/screens/home_screen.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {

  try {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: ".env");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print(' Firebase initialized successfully');

    print('Starting app...');
    runApp(const DappliApp());
    print('App started');

  } catch (e, stackTrace) {
    print('Error in main: $e');
    print('Stack trace: $stackTrace');

    // Run a fallback app to show the error
    runApp(ErrorApp(error: e.toString()));
  }
}

class DappliApp extends StatelessWidget {
  const DappliApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building DappliApp...');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF3B7A57), // Banana Leaf Green
        // Global AppBar defaults — CustomAppBar inherits these automatically
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3B7A57), // matches scaffold
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      title: 'Dappli',
      home: const AuthGate(),
    );
  }
}

/// Routes authenticated users directly to [HomeScreen],
/// and unauthenticated users to [SignInPage].
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still waiting for the auth state to resolve
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is signed in — go straight to the app
        if (snapshot.hasData && snapshot.data != null) {
          return HomeScreen();
        }

        // No session — show sign-in page
        return const SignInPage();
      },
    );
  }
}



// Error app for showing initialization errors
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ErrorScreen(error: error),
    );
  }
}

// Error screen widget
class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0F8FF),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'Initialization Error',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                error,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  print('Restart requested');
                  // You could implement app restart logic here
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}