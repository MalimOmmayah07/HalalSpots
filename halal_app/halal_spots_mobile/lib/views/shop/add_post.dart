import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this import for url_launcher
import 'package:halal_spots/components/text_field.dart';
import 'package:halal_spots/components/button.dart';

class AddPost extends StatefulWidget {
  const AddPost({super.key});

  @override
  _AddPostState createState() => _AddPostState();
}

class _AddPostState extends State<AddPost> {
  late User? currentUser;
  final _formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final detailsController = TextEditingController();
  final linkController = TextEditingController(); // Controller for the URL link
  bool isLoading = false;

  XFile? _selectedImage; // Image file selected by the user

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _selectedImage = pickedImage;
      });
    }
  }

  Future<String?> uploadImage(XFile image) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('posts/${DateTime.now().toString()}.jpg');
      await ref.putFile(File(image.path));
      return await ref.getDownloadURL();
    } catch (error) {
      displayMessage("Error uploading image: $error");
      return null;
    }
  }

  Future<void> addPost(String title, String details, String? link) async {
    if (!_formKey.currentState!.validate()) {
      return; // Prevent submission if validation fails
    }

    setState(() {
      isLoading = true; // Show the loading indicator
    });

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await uploadImage(_selectedImage!);
      if (imageUrl == null) {
        setState(() {
          isLoading = false; // Hide the loading indicator
        });
        return; // Stop the process if image upload fails
      }
    }

    try {
      await FirebaseFirestore.instance.collection('Posts').doc().set({
        'title': title,
        'details': details,
        'postedBy': currentUser!.email,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl, // Save image URL
        'link': link, // Save the URL link
      });

      setState(() {
        isLoading = false; // Hide the loading indicator
      });

      titleController.clear();
      detailsController.clear();
      linkController.clear(); // Clear the link
      _selectedImage = null; // Clear selected image

      displayMessage("Post added successfully!");
    } catch (error) {
      setState(() {
        isLoading = false; // Hide the loading indicator
      });
      displayMessage("Error adding post: $error");
    }
  }

  void displayMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // Method to launch any URL
  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      displayMessage("Could not open the link");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                primaryTextField(
                  controller: titleController,
                  hintText: 'Enter Post Title',
                  obscureText: false,
                  text: "Title",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the post title';
                    }
                    return null;
                  },
                ),
                primaryTextField(
                  controller: detailsController,
                  hintText: 'Enter Details',
                  obscureText: false,
                  text: "Details",
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the post details';
                    }
                    return null;
                  },
                ),
                primaryTextField(
                  controller: linkController,
                  hintText: 'Enter URL Link (Optional)',
                  obscureText: false,
                  text: "Link",
                  validator: (value) {
                    // Allow the link to be optional
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    height: 200, // Fixed height for uniformity
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey.shade200,
                      border: Border.all(color: Colors.grey, width: 1.0),
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        File(_selectedImage!.path),
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Center(
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const CircularProgressIndicator()
                    : MyButton1(
                  onTap: () {
                    addPost(
                      titleController.text,
                      detailsController.text,
                      linkController.text.isNotEmpty
                          ? linkController.text
                          : null, // Only add the link if it's provided
                    );
                  },
                  text: 'Add Post',
                ),
                // Link button
                if (linkController.text.isNotEmpty)
                  TextButton(
                    onPressed: () => _launchURL(linkController.text),
                    child: const Text("Open Link"),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
