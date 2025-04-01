# HalalSpots
HALAL SPOTS: A MOBILE PLATFORM FOR LOCATING HALAL FOOD ESTABLISHMENTS IN REGION 10

# Project Overview

HalalSpots is a Flutter-based mobile application with Firebase as its backend, designed to assist users in finding and verifying Halal food establishments in Region 10. Additionally, it includes a web-based login/register system using Python-Flask and Firebase for user authentication.

# Technologies Used

Flutter - Frontend development framework (mobile app)
Firebase - Backend services for authentication, database, and storage
Flask - Web framework for Python-based authentication
MySQL - Database for storing certified Halal shops

# Features (Mobile App)

User registration and login
Search for Halal food establishments
Add and verify food establishments
Firebase authentication and database integration

# Features (Web App)

Firebase-based login and signup
Fully responsive UI (Credits: CodePen)
Flask backend for authentication

# Software Installation Requirements

To set up the development environment for this project, ensure the following software is installed:

# Mobile App (Flutter)

VS Code - Recommended IDE for Flutter development.
Android Studio - Required for running and testing the Flutter app on an emulator.
Flutter SDK - Ensure Flutter is correctly installed and configured.
Firebase Setup - Connect the project to Firebase by following Flutter Firebase setup instructions.

# Web App (Python-Flask)

Install dependencies:
pip install pyrebase4
pip install flask

# Setup Instructions
# Mobile App

Clone the repository to your local machine.
Install Flutter and ensure it is correctly configured.
Open the project in VS Code or Android Studio.
Connect Firebase services.

# Run the app using:

flutter run

# Web App

Install dependencies as listed above.

# Set up Firebase:

Go to Firebase Console
Create a new project
Add a web app and copy API credentials (apiKey, authDomain, databaseURL, storageBucket)
Paste them into main.py
Enable Email/Password authentication in Firebase

# Set up Firebase Storage

Run the Flask server:
flask run
The server will start on http://127.0.0.1:5000/

# Admin Credentials

For accessing the admin side of the application, use the following credentials:

Email: halalspot05@gmail.com
Password: halalspotadmin123

# Additional Info

After a successful sign-up in the web app, user details (name, email, uid) are stored in a global dictionary called person.

For any further assistance, refer to the official documentation of Flutter and Firebase.
