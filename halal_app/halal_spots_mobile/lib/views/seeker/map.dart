import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // For location coordinates
import 'package:location/location.dart'; // For getting real-time location

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  LocationData? _currentLocation; // Make it nullable
  late Location _location;
  List<Marker> _shopMarkers = []; // List to store shop markers

  @override
  void initState() {
    super.initState();
    _location = Location();
    _getLocation();
    _loadShops(); // Load shop markers from Firestore

    // Enable location updates in real-time
    _location.onLocationChanged.listen((LocationData newLocation) {
      setState(() {
        _currentLocation = newLocation;
      });
    });
  }

  // Get the user's current location
  void _getLocation() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    // Check if the location service is enabled
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return; // If location services are not enabled, return
      }
    }

    // Check for permission to access the location
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return; // If permission is not granted, return
      }
    }

    // Get the current location
    _currentLocation = await _location.getLocation();
    setState(() {});
  }

  

  Future<void> _loadShops() async {
    final usersCollection = FirebaseFirestore.instance.collection('Users');

    final querySnapshot = await usersCollection.get();

    List<Marker> markers = [];

    for (var userDoc in querySnapshot.docs) {
      var data = userDoc.data();
      var latitude = data['latitude'];
      var longitude = data['longitude'];
      var shopName = data['store_name'] ?? 'Unnamed Store'; // Default if store_name is null
      var halal = data['halal_certificate_verified'];

      if (latitude != null && longitude != null && halal == true) {
          markers.add(
            Marker(
              width: 60.0,
              height: 60.0,
              point: LatLng(latitude, longitude),
              child: Column(
                
        children: [
          // Icon at the top
          Icon(
            Icons.pin_drop,
            color: Colors.red,
            size: 24.0,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2.0,
                ),
              ],
            ),
            child: Text(
              shopName ?? 'Unnamed Store',
              style: const TextStyle(
                fontSize: 8.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
              ),
            ),
          );
        }
      }
      setState(() {
        _shopMarkers = markers;
      });
  }

  @override
  Widget build(BuildContext context) {
    // If the current location is not available, show a loading indicator
    if (_currentLocation == null) {
      return Center(child: CircularProgressIndicator());
    }

    final LatLng currentPosition =
        LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!);

    return Scaffold(
      body: FlutterMap(
        options: MapOptions(
          initialCenter: currentPosition,
          initialZoom: 15,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.halal_spots',
          ),
          MarkerLayer(
            markers: [
              // Add the user's current location marker
              Marker(
                width: 40.0,
                height: 40.0,
                point: currentPosition,
                child: Stack(
                  children: [
                    // The main shadow effect without the flashlight
                    Positioned(
                      child: Container(
                        width: 20.0,
                        height: 20.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withOpacity(0.1), // Blue shadow with opacity
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.5), // Shadow color
                              offset: Offset(3.0, 3.0), // Shadow position
                              blurRadius: 8.0, // How blurred the shadow is
                              spreadRadius: 2.0, // How much the shadow spreads
                            ),
                          ],
                        ),
                      ),
                    ),
                    // The main marker icon (circle)
                    Positioned(
                      top: 0.0,
                      left: 0.0,
                      child: Icon(
                        Icons.circle_rounded,
                        color: Colors.blue,
                        size: 20.0,
                      ),
                    ),
                  ],
                ),
              ),
              // Add the shop markers fetched from Firestore
              ..._shopMarkers,
            ],
          ),
        ],
      ),
    );
  }
}
