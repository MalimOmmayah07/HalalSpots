import 'package:firebase_auth/firebase_auth.dart';  
import 'package:flutter/material.dart';  
import 'package:halal_spots/components/button.dart';  
import 'package:halal_spots/components/text_field.dart';  
import 'package:halal_spots/views/register.dart';  
import 'package:cloud_firestore/cloud_firestore.dart';  // Import Firestore package  
  
class LoginPage extends StatefulWidget {  
  const LoginPage({super.key});  
  
  @override  
  State<LoginPage> createState() => _LoginPageState();  
}  
  
class _LoginPageState extends State<LoginPage> {  
  final emailTextController = TextEditingController();  
  final passwordTextController = TextEditingController();  
  bool _obscurePassword = true;  // Variable to toggle password visibility  
  bool _isSigningIn = false; // Flag to prevent multiple sign in attempts  
  
  @override  
  void dispose() {  
   emailTextController.dispose();  
   passwordTextController.dispose();  
   super.dispose();  
  }  
  
  void signIn() async {  
   if (_isSigningIn) return; // Prevent multiple sign in attempts  
   setState(() => _isSigningIn = true);  
  
   try {  
    // First, check the Firestore Users collection for the email and status  
    DocumentSnapshot userDoc = await FirebaseFirestore.instance  
       .collection('Users')  
       .doc(emailTextController.text.trim()) // Use the email entered  
       .get();  
  
    if (userDoc.exists) {  
      // If the document exists, check the status  
      bool status = userDoc['status'] ?? false; // Default to false if status is not found  
      if (status) {  
       // If status is true, proceed with Firebase authentication  
       UserCredential user = await FirebaseAuth.instance.signInWithEmailAndPassword(  
        email: emailTextController.text,  
        password: passwordTextController.text,  
       );  
  
       if (user.user != null && !user.user!.emailVerified) {  
        await _handleEmailVerification();  
        return;  
       }  
  
       // Proceed with app flow after successful login  
      } else {  
       // If status is false, show a message and don't proceed with login  
       displayMessage('Your account is not active. Please contact support.');  
      }  
    } else {  
      // If no document exists for the email, show an error  
      displayMessage('No account found with that email.');  
    }  
   } on FirebaseAuthException catch (e) {  
    displayMessage(_getErrorMessage(e));  
   } finally {  
    setState(() => _isSigningIn = false);  
   }  
  }  
  
  Future<void> _handleEmailVerification() async {  
   displayMessage('Please verify your email before logging in.');  
   await FirebaseAuth.instance.signOut();  
  }  
  
  String _getErrorMessage(FirebaseAuthException e) {  
   switch (e.code) {  
    case 'user-not-found':  
      return 'No user found for that email.';  
    case 'wrong-password':  
      return 'Wrong password provided for that user.';  
    case 'invalid-email':  
      return 'The email address is not valid.';  
    default:  
      return 'An error occurred. Please try again.';  
   }  
  }  
  
  void displayMessage(String message) {  
   showDialog(  
    context: context,  
    builder: (context) => AlertDialog(  
      title: Text(message),  
      actions: [  
       TextButton(  
        onPressed: () => Navigator.of(context).pop(),  
        child: const Text('OK'),  
       ),  
      ],  
    ),  
   );  
  }  
  
  void navigateToRegisterPage() {  
   Navigator.push(  
    context,  
    MaterialPageRoute(builder: (context) => const RegisterPage()),  
   );  
  }  
  
  // Method to send password reset email  
  void sendPasswordResetEmail(String email) async {  
   try {  
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);  
    displayMessage('Password reset email sent! Check your inbox.');  
   } on FirebaseAuthException catch (e) {  
    displayMessage(_getErrorMessage(e));  
   }  
  }  
  
  // Show Forgot Password modal  
  void showForgotPasswordModal() {  
   showDialog(  
    context: context,  
    builder: (context) {  
      final resetEmailController = TextEditingController();  
      return AlertDialog(  
       title: const Text('Reset Password'),  
       content: Column(  
        mainAxisSize: MainAxisSize.min,  
        children: [  
          const Text('Enter your email address to reset your password.'),  
          TextField(  
           controller: resetEmailController,  
           decoration: const InputDecoration(  
            labelText: 'Email',  
            hintText: 'Enter your email',  
           ),  
          ),  
        ],  
       ),  
       actions: [  
        TextButton(  
          onPressed: () {  
           String email = resetEmailController.text.trim();  
           if (email.isNotEmpty) {  
            sendPasswordResetEmail(email);  
            Navigator.pop(context); // Close the modal after sending email  
           } else {  
            displayMessage('Please enter a valid email.');  
           }  
          },  
          child: const Text('Send Reset Email'),  
        ),  
        TextButton(  
          onPressed: () => Navigator.pop(context),  
          child: const Text('Cancel'),  
        ),  
       ],  
      );  
    },  
   );  
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
          _buildLogo(width),  
          _buildEmailTextField(),  
          _buildPasswordTextField(),  
          _buildLoginButton(),  
          _buildForgotPasswordText(),  // Forgot Password link  
          _buildSignUpText(),  
        ],  
       ),  
      ),  
    ),  
   );  
  }  
  
  Widget _buildLogo(double width) {  
   return Padding(  
    padding: const EdgeInsets.only(top: 20, bottom: 50),  
    child: Image.asset(  
      "images/whole_logo.png",  
      height: width * 0.4,  
      width: width * 0.4,  
    ),  
   );  
  }  
  
  Widget _buildEmailTextField() {  
   return Padding(  
    padding: const EdgeInsets.only(top: 0.50, bottom: 10),  
    child: MyTextField(  
      controller: emailTextController,  
      hintText: 'Email',  
      obscureText: false,  
      icon: Icons.email_outlined,  
      text: "Enter Email",  
    ),  
   );  
  }  
  
  Widget _buildPasswordTextField() {  
   return Padding(  
    padding: const EdgeInsets.only(top: 15, bottom: 10),  
    child: MyTextField(  
      controller: passwordTextController,  
      hintText: 'Password',  
      obscureText: _obscurePassword,  // Use the variable to control password visibility  
      icon: Icons.lock_outlined,  
      text: "Enter Password",  
      suffixIcon: IconButton(  
       icon: Icon(  
        _obscurePassword ? Icons.visibility_off : Icons.visibility,  
        color: Colors.black,  
       ),  
       onPressed: () {  
        setState(() {  
          _obscurePassword = !_obscurePassword;  // Toggle the password visibility  
        });  
       },  
      ),  
    ),  
   );  
  }  
  
  Widget _buildLoginButton() {  
   return Padding(  
    padding: const EdgeInsets.only(top: 10),  
    child: MyButton(  
      onTap: _isSigningIn ? null : signIn,  
      text: _isSigningIn ? 'Signing in...' : 'LOG IN',  
    ),  
   );  
  }  
  
  Widget _buildForgotPasswordText() {  
   return Padding(  
    padding: const EdgeInsets.only(top: 10),  
    child: TextButton(  
      onPressed: showForgotPasswordModal, // Show Forgot Password Modal  
      child: const Text(  
       'Forgot Password?',  
       style: TextStyle(color: Colors.blue),  
      ),  
    ),  
   );  
  }  
  
  Widget _buildSignUpText() {  
   return Row(  
    mainAxisAlignment: MainAxisAlignment.center,  
    children: [  
      const Text("Don't have an account? "),  
      TextButton(  
       onPressed: navigateToRegisterPage,  
       child: const Text('Sign Up'),  
      ),  
    ],  
   );  
  }  
}
