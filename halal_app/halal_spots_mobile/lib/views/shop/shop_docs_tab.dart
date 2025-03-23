import 'dart:io'; // Import File class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ShopDocsTab extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Future<void> Function() pickImage; // Callback for picking an image
  final Future<void> Function(String) updateExpiryDate; // Callback for updating expiry date

  const ShopDocsTab({
    super.key,
    required this.userData,
    required this.pickImage,
    required this.updateExpiryDate,
  });

  @override
  _ShopDocsTabState createState() => _ShopDocsTabState();
}

class _ShopDocsTabState extends State<ShopDocsTab> {
  bool _isHalalCertificateUploaded = false;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _expiryDateController = TextEditingController(); // Expiry date controller
  late TextEditingController _certificateNumberController = TextEditingController();
  late TextEditingController _gcashNumberController = TextEditingController();

    @override
  void initState() {
    super.initState();
    // Initialize controller with existing value
    _certificateNumberController = TextEditingController(
      text: widget.userData['halal_certificate_number'],
    );
    _gcashNumberController = TextEditingController(
      text: widget.userData['gcash_number'],
    );
  }
  // Initialize the ImagePicker
  Future<void> _pickImage(String field) async {
    try {
      // Pick an image using ImagePicker
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        // Upload the image once selected
        await _uploadImage(field, pickedFile.path);
      }
    } catch (e) {
      print('Image Picker Error: $e');
    }
  }

  // Upload image to Firebase Storage
  Future<void> _uploadImage(String field, String imagePath) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No user is logged in');
        return;
      }

      Reference storageReference = FirebaseStorage.instance
          .ref()
          .child('users/${currentUser.email}/$field.jpg');

      UploadTask uploadTask = storageReference.putFile(File(imagePath));
      await uploadTask.whenComplete(() async {
        String downloadURL = await storageReference.getDownloadURL();
        _updateFirestoreField(field, downloadURL);
      });
    } catch (e) {
      print('Image Upload Error: $e');
    }
  }

  // Update Firestore with the uploaded image URL and set the verified status to false
  Future<void> _updateFirestoreField(String field, String downloadURL) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // Set the verification status to false when a new image is uploaded
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.email)
            .update({
          field: downloadURL,
          '${field}_verified': false, // Set verified status to false
        });

        // Check if the Halal Certificate was uploaded
        if (field == 'halal_certificate') {
          setState(() {
            _isHalalCertificateUploaded = true; // Set the flag to true when uploaded
            _expiryDateController.clear(); // Clear the expiry date input field after upload
          });
        }
      }
    } catch (e) {
      print('Firestore Update Error: $e');
    }
  }

  // Helper method to get the verification status label and color
  Widget _getVerificationStatus(String field) {
    bool isUploaded = widget.userData[field]?.isNotEmpty ?? false; // Check if image URL is uploaded
    bool isVerified = widget.userData['${field}_verified'] ?? false;
    String? expiryDate = widget.userData['${field}_expiry'];

    String statusText = isUploaded
        ? (isVerified
            ? 'Verified' : 'Not Verified')
        : 'No Upload';

    Color statusColor = isUploaded
        ? (isVerified
            ? Colors.green
            : (expiryDate != null && _isExpired(expiryDate)
                ? Colors.red
                : Colors.orange))
        : Colors.orange;

    return Row(
      children: [
        Text(
          statusText,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          isUploaded
              ? (isVerified
                  ? Icons.check_circle
                  : (expiryDate != null && _isExpired(expiryDate)
                      ? Icons.error
                      : Icons.warning))
              : Icons.info,
          color: statusColor,
        ),
        const SizedBox(width: 10),
        if (expiryDate != null && _isExpired(expiryDate))
          Text(
            'Expired',
            style: const TextStyle(fontSize: 14, color: Colors.red),
          ),
        if (expiryDate != null && !_isExpired(expiryDate)) 
          Text(
            'Expires in ${_getDaysUntilExpiry(expiryDate)} days',
            style: const TextStyle(fontSize: 14, color: Colors.green),
          ),
      ],
    );
  }

  // Helper method to check if the certificate is expired
  bool _isExpired(String expiryDateString) {
    try {
      DateTime expiryDate = DateFormat('yyyy-MM-dd').parse(expiryDateString);
      DateTime currentDate = DateTime.now();
      return expiryDate.isBefore(currentDate); // Check if expiry date is in the past
    } catch (e) {
      print('Date Parsing Error: $e');
      return false; // Default to not expired if there's an error
    }
  }

  // Helper method to get the number of days until expiry
  int _getDaysUntilExpiry(String expiryDateString) {
    try {
      DateTime expiryDate = DateFormat('yyyy-MM-dd').parse(expiryDateString);
      DateTime currentDate = DateTime.now();
      Duration difference = expiryDate.difference(currentDate);
      return difference.inDays; // Return the difference in days
    } catch (e) {
      print('Date Parsing Error: $e');
      return 0; // Default to 0 if there's an error
    }
  }


   // Save Halal Certificate number
  Future<void> _saveCertificateNumber(String certificateNumber) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(currentUser.email)
            .update({'halal_certificate_number': certificateNumber});
      }
    } catch (e) {
      print('Error saving certificate number: $e');
    }
  }




  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Halal Certificate Section
        Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Muslim-Friendly Certificate",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _getVerificationStatus('halal_certificate'), // Display verification status for Halal Certificate
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _pickImage('halal_certificate'),
                  child: _buildImageContainer(
                    widget.userData['halal_certificate'] ??
                        'https://www.super-garden.com/files/uploaded/Halal%20sertifiktas%202021%2009%2016_2022%2009%2015-1.jpg',
                    600, // Set custom height for Halal Certificate
                  ),
                ),
                const SizedBox(height: 8),
                if (_isHalalCertificateUploaded) // Show expiry input only after certificate upload
                  TextField(
                    controller: _expiryDateController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Expiry Date (yyyy-MM-dd)',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        widget.updateExpiryDate(value); // Call the update function passed in the constructor
                      }
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _certificateNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Certificate Number',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {}); // Update UI dynamically
                    },
                    onSubmitted: _saveCertificateNumber,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Valid ID Section
        Card(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Business Permit",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _getVerificationStatus('valid_id'), // Display verification status for Valid ID
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _pickImage('valid_id'),
                  child: _buildImageContainer(
                    widget.userData['valid_id'] ??
                        'https://blogger.googleusercontent.com/img/b/R29vZ2xl/AVvXsEhdFvKKFcnqGMGQ1g4Ef23rDMPl1AnZRD_0ueIAFrCVli_LH-o92cbCq6saQj13m-gcFsm7aUIBMl8ElAcCBEn1_jICiwZsDXOgGT6tD8jeBTNf0pGUIsuGlDYSdlXEjHx5heZxLwl3e4U/s1600/2016+Business+Permit+-+Retailer.jpg',
                    600, // Set custom height for Valid ID Image
                  ),
                ),
              ],
            ),
          ),
        ),


      ],
    );
  }

  // Helper method to build image container
  Widget _buildImageContainer(String imageUrl, double height) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
