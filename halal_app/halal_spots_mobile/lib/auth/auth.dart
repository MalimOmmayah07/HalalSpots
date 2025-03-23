import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:halal_spots/components/nav.dart';
import 'package:halal_spots/views/login.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Check if the user is logged in
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Return a loading indicator or any placeholder widget
            return const CircularProgressIndicator();
          } else if (snapshot.hasData) {
            // User is logged in, navigate to Nav widget
            return const Nav();
          } else {
            // User is not logged in, navigate to LoginPage widget
            return const LoginPage();
          }
        },
      ),
    );
  }
}
