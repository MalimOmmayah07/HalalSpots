import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:halal_spots/components/text_field.dart';
import 'dart:io';

class InformationsTab extends StatelessWidget {
  final Map<String, dynamic> userData;
   final VoidCallback pickImage;
  final currentUser = FirebaseAuth.instance.currentUser!;
  final usersCollection = FirebaseFirestore.instance.collection("Users");

  InformationsTab({super.key, required this.userData, required this.pickImage});

  final ImagePicker _picker = ImagePicker();

  // Method to pick and upload the image
  Future<void> _pickImage(String field) async {
      // Pick an image using ImagePicker
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Upload the image once selected
        _uploadImage(field, pickedFile.path);
      }
  }

  // Upload image to Firebase Storage
  Future<void> _uploadImage(String field, String imagePath) async {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }

      // Define the Firebase Storage reference
      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('users/${currentUser.email}/$field.jpg');

      // Upload the file to Firebase Storage
      UploadTask uploadTask = storageReference.putFile(File(imagePath));

      // Wait for the upload to complete and get the download URL
      await uploadTask.whenComplete(() async {
          String downloadURL = await storageReference.getDownloadURL();
          _updateFirestoreField(field, downloadURL);
      });
  }

  // Update Firestore field with the uploaded image URL
  Future<void> _updateFirestoreField(String field, String downloadURL) async {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.email)
            .update({field: downloadURL});
      }
  }
  // Edit field method
  Future<void> editField(BuildContext context, String field) async {
    String newValue = "";

    if (field == 'type') {
      List<String> accountTypes = ['Seeker', 'Shop'];

      await showCustomDialog(
        context,
        "Edit $field",
        DropdownButtonFormField<String>(
          value: accountTypes.contains(userData[field]) ? userData[field] : null,
          items: accountTypes.map((type) {
            return DropdownMenuItem<String>(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            newValue = value!;
          },
        ),
        onConfirm: () {
          if (newValue.isNotEmpty) _updateFirestoreField(field, newValue);
        },
      );
    } else {
      await showCustomDialog(
        context,
        "Edit $field",
        TextField(
          autofocus: true,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: "Enter new $field",
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          onChanged: (value) => newValue = value,
        ),
        onConfirm: () {
          if (newValue.trim().isNotEmpty) _updateFirestoreField(field, newValue);
        },
      );
    }
  }

  // Show custom dialog
  Future<void> showCustomDialog(
      BuildContext context, String title, Widget content,
      {required VoidCallback onConfirm}) async {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  content,
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Update'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Build widget
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      children: [
        GestureDetector(
          onTap: () => _pickImage('profile_picture'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 50.0),
            child: AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    userData['profile_picture'] ??
                        'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),
        Text(
          userData['username'] ?? 'Unknown User',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        MyTextBox(
          sectionName: "Full Name",
          text: userData['fullName'] ?? 'Not provided',
          onPressed: () => editField(context, 'fullName'),
        ),
        MyTextBox(
          sectionName: "Address",
          text: userData['address'] ?? 'Not provided',
          onPressed: () => editField(context, 'address'),
        ),
        MyTextBox(
          sectionName: "Phone No",
          text: userData['phoneNo'] ?? 'Not provided',
          onPressed: () => editField(context, 'phoneNo'),
        ),
        MyTextBox(
          sectionName: "Type",
          text: userData['type'] ?? 'Not provided',
          onPressed: () => editField(context, 'type'),
        ),
        MyTextBox(
          sectionName: "Username",
          text: userData['username'] ?? 'Not provided',
          onPressed: () => editField(context, 'username'),
        ),
      ],
    );
  }
}
