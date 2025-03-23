import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart'; // For image picking
import 'package:firebase_storage/firebase_storage.dart'; // For Firebase Storage
import 'package:halal_spots/components/text_field.dart'; 
import 'dart:io'; // For File

class ShopDetailsTab extends StatelessWidget {
  final Map<String, dynamic> userData;
  final VoidCallback updateLocation;

  final currentUser = FirebaseAuth.instance.currentUser!;
  final usersCollection = FirebaseFirestore.instance.collection("Users");

  // Image picker instance
  final ImagePicker _picker = ImagePicker();

 ShopDetailsTab({super.key,required this.userData,required this.updateLocation,});

  Future<void> _pickImage(String field) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _uploadImage(field, pickedFile.path);
    }
  }

  Future<void> _uploadImage(String field, String imagePath) async {
    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('shops/${currentUser.email}/$field.jpg');

    UploadTask uploadTask = storageReference.putFile(File(imagePath));

    await uploadTask.whenComplete(() async {
      String downloadURL = await storageReference.getDownloadURL();
      _updateFirestoreField(field, downloadURL);
    });
  }

  Future<void> _updateFirestoreField(String field, String downloadURL) async {
    try {
      await usersCollection.doc(currentUser.email).update({field: downloadURL});
      print('Image URL updated successfully');
    } catch (e) {
      print('Error updating Firestore: $e');
    }
  }

  Future<void> _getCurrentLocation(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permission denied");
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    double latitude = position.latitude;
    double longitude = position.longitude;

    await _updateLocationInFirestore(latitude, longitude);
  }

  Future<void> _updateLocationInFirestore(double latitude, double longitude) async {
    try {
      await usersCollection.doc(currentUser.email).update({
        'latitude': latitude,
        'longitude': longitude,
      });
      print("Location updated successfully!");
    } catch (e) {
      print("Error updating location: $e");
    }
  }

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
            return DropdownMenuItem<String>(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            newValue = value!;
          },
        ),
        onConfirm: () {
          if (newValue.isNotEmpty) updateFirestoreField(field, newValue);
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
          if (newValue.trim().isNotEmpty) updateFirestoreField(field, newValue);
        },
      );
    }
  }

  Future<void> updateFirestoreField(String field, String newValue) async {
    if (newValue.trim().isNotEmpty) {
      try {
        await usersCollection.doc(currentUser.email).update({field: newValue});
        print('Update successful');
      } catch (e) {
        print('Firestore Update Error: $e');
      }
    }
  }

  Future<void> showCustomDialog(
    BuildContext context,
    String title,
    Widget content, {
    required VoidCallback onConfirm,
  }) async {
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

  @override
  Widget build(BuildContext context) {
    String storeName = userData['store_name'] ?? '';
    String storeAddress = userData['store_address'] ?? '';
    double latitude = userData['latitude'] ?? 14.5826446; // Default latitude
    double longitude = userData['longitude'] ?? 120.9774978; // Default longitude

    LatLng initialLocation = LatLng(latitude, longitude);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      children: [
        Padding(
          padding: const EdgeInsets.all(5.0),

        ),
// Shop Logo Section
GestureDetector(
  onTap: () => _pickImage('shop_logo'), // Picking the logo image
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 50.0),
    width: 100.0, // Set the width of the logo container
    height: 300.0, // Set the height of the logo container
    child: Container(
      decoration: BoxDecoration(
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
      child: ClipRRect(
        borderRadius: BorderRadius.zero, // Removes circular clipping
        child: Image.network(
          userData['shop_logo'] ??
              'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png',
          fit: BoxFit.cover,
        ),
      ),
    ),
  ),
),

      MyTextBox(
        sectionName: "Store Name",
        text: storeName,
        onPressed: () => editField(context, "store_name"),
      ),
      MyTextBox(
        sectionName: "Store Address",
        text: storeAddress,
        onPressed: () => editField(context, "store_address"),
      ),
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          margin: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
            children: [
              const Text(
                "Store Location",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(
                height: 300,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: initialLocation,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.halal_spots',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          width: 50.0,
                          height: 50.0,
                          point: initialLocation,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.pin_drop_rounded,
                                color: Colors.blue,
                                size: 30.0,
                              ),
                              Text(
                                storeName,
                                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
    ElevatedButton(
    onPressed: () {
    _getCurrentLocation(context); // Fetch current location when the button is pressed
    },
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue, // Change button color here
    foregroundColor: Colors.white, // Text color
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20), // Rounded corners
    ),
    padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0), // Padding for button size
    ),
    child: const Text(
    'Update Location',
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Custom font size and weight
    ),
    ),
            ],
          ),
        ),
      ),
      ],
    );
  }
}
