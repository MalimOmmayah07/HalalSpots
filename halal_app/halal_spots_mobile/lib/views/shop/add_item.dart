import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:halal_spots/components/text_field.dart';
import 'package:halal_spots/components/button.dart';
import 'package:flutter/services.dart';

class AddItem extends StatefulWidget {
  const AddItem({super.key});

  @override
  _AddItemState createState() => _AddItemState();
}

class _AddItemState extends State<AddItem> {
  late User? currentUser;
  final _formKey = GlobalKey<FormState>();
  final itemNameController = TextEditingController();
  final descriptionController = TextEditingController();
  final categoryController = TextEditingController();
  final priceController = TextEditingController();
  File? _selectedImage;
  final picker = ImagePicker();
  bool isLoading = false;
  bool isAvailable = true; // Availability status

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> addItem(String name, String description, String category, String price, bool availability) async {
    if (!_formKey.currentState!.validate()) {
      return; // Prevent submission if validation fails
    }

    setState(() {
      isLoading = true; // Show the loading indicator
    });

    try {
      String imageUrl = '';
      if (_selectedImage != null) {
        final imageRef = FirebaseStorage.instance
            .ref()
            .child('items/${currentUser!.email}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await imageRef.putFile(_selectedImage!);
        imageUrl = await imageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('Items').doc().set({
        'itemName': name,
        'description': description,
        'category': category,
        'price': double.parse(price),
        'isAvailable': availability,
        'postedBy': currentUser!.email,
        'timestamp': FieldValue.serverTimestamp(),
        'imageUrl': imageUrl,
      });

      setState(() {
        isLoading = false; // Hide the loading indicator
      });

      itemNameController.clear();
      descriptionController.clear();
      categoryController.clear();
      priceController.clear();
      setState(() {
        _selectedImage = null;
        isAvailable = true; // Reset availability to default
      });

      displayMessage("added successfully!");
    } catch (error) {
      setState(() {
        isLoading = false; // Hide the loading indicator
      });
      displayMessage("Error adding item: $error");
    }
  }

  void displayMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
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
                  controller: itemNameController,
                  hintText: 'Enter Food & Beverage Name',
                  obscureText: false,
                  text: "Food & Beverage",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the food & beverage name';
                    }
                    return null;
                  },
                ),
                primaryTextField(
                  controller: descriptionController,
                  hintText: 'Enter Description',
                  obscureText: false,
                  text: "Description",
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                PrimaryDropdown(
                  controller: categoryController,
                  hintText: 'Select Category',
                  labelText: 'Category',
                  options: ['Food', 'Beverage', 'Combo'], // Updated options for the dropdown
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                primaryTextField(
                  controller: priceController,
                  hintText: 'Enter Price',
                  obscureText: false,
                  text: "Price",
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available:',
                      style: TextStyle(fontSize: 16),
                    ),
                    Switch(
                      value: isAvailable,
                      onChanged: (value) {
                        setState(() {
                          isAvailable = value;
                        });
                      },
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: pickImage,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10.0),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _selectedImage != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImage!,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Icon(
                      Icons.camera_alt,
                      size: 150,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(thickness: 1),
                isLoading
                    ? const CircularProgressIndicator()
                    : MyButton1(
                  onTap: () {
                    addItem(
                      itemNameController.text,
                      descriptionController.text,
                      categoryController.text,
                      priceController.text,
                      isAvailable,
                    );
                  },
                  text: 'Add',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}