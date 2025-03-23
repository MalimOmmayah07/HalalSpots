import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:halal_spots/components/button.dart';
import 'package:halal_spots/components/text_field.dart';
import 'package:halal_spots/views/login.dart'; // Assuming you have a LoginPage

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailTextController = TextEditingController();
  final passwordTextController = TextEditingController();
  final confirmPasswordTextController = TextEditingController();
  String selectedUserType = 'Seeker';

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void signUp() async {
    // Validate user inputs
    if (emailTextController.text.isEmpty ||
        passwordTextController.text.isEmpty ||
        confirmPasswordTextController.text.isEmpty) {
      displayMessage('Please fill in all required fields');
      return;
    }

    if (passwordTextController.text != confirmPasswordTextController.text) {
      displayMessage("Passwords don't match!");
      return;
    }

    // Show a progress indicator
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailTextController.text,
        password: passwordTextController.text,
      );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      await FirebaseFirestore.instance
          .collection("Users")
          .doc(userCredential.user!.email)
          .set({
        'username': emailTextController.text.split('@')[0],
        'email': emailTextController.text,
        'fullName': '',
        'address': '',
        'phoneNo': '',
        'type': selectedUserType,
      });

      // Close the progress indicator
      Navigator.pop(context);

      // Navigate to LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      // Close the progress indicator and display the error message
      Navigator.pop(context);
      displayMessage(e.message ?? "An error occurred. Please try again.");
    }
  }

  void displayMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2), // Optional: Set duration for the message
    ));
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white12,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.asset(
                  "images/whole_logo.png",
                  height: width * 0.40,
                  width: width * 0.40,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: MyTextField(
                  controller: emailTextController,
                  hintText: 'Email',
                  obscureText: false,
                  icon: Icons.email_outlined,
                  text: "Enter Email",
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: MyTextField(
                  controller: passwordTextController,
                  hintText: 'Password',
                  obscureText: _obscurePassword,
                  icon: Icons.lock,
                  text: "Enter Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;  // Toggle password visibility
                      });
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: MyTextField(
                  controller: confirmPasswordTextController,
                  hintText: 'Confirm Password',
                  obscureText: _obscureConfirmPassword,
                  icon: Icons.lock_outlined,
                  text: "Confirm Password",
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;  // Toggle confirm password visibility
                      });
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: MyButton(onTap: signUp, text: 'SIGN UP'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text('Login here'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
