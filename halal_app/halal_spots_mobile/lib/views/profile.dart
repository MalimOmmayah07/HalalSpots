import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:halal_spots/views/shop/Follower_tab.dart';
import 'package:halal_spots/views/shop/Review_tab.dart';
import 'shop/informations_tab.dart';
import 'shop/shop_details_tab.dart';
import 'shop/shop_docs_tab.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser!;
  final usersCollection = FirebaseFirestore.instance.collection("Users");
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    // Implement your image picking functionality
    print('Image Picker triggered');
  }

  Future<void> _onUpdateLocationPressed() async {
    // Implement location update functionality
    print('Update location triggered');
  }

  Future<void> _updateExpiryDate(String expiryDate) async {
  try {
    await usersCollection.doc(currentUser.email).update({
      'halal_certificate_expiry': expiryDate,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Expiry date updated successfully')),
    );
  } catch (e) {
    print('Error updating expiry date: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to update expiry date')),
    );
  }
}

  // Build each Tab widget with dynamic font size
  Widget _buildTab(String label, int index) {
    // Calculate responsive font size based on screen width and selected state
    double fontSize = _getResponsiveFontSize(index);

    return Tab(
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Calculate font size dynamically based on screen width and selected tab
  double _getResponsiveFontSize(int index) {
    double screenWidth = MediaQuery.of(context).size.width;
    double baseFontSize = screenWidth * 0.025; // Font size as 5% of screen width

    // If the tab is selected, increase the font size
    if (_tabController.index == index) {
      return baseFontSize; // Increase size for selected tab
    } else {
      return baseFontSize; // Default size for unselected tabs
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'images/whole_logo.png',
          fit: BoxFit.contain,
          height: 50,
        ),
        backgroundColor: const Color.fromARGB(8, 0, 0, 0),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: usersCollection.doc(currentUser.email).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            bool isShop = userData['type'] == 'Shop';

            return Column(
              children: [
                Padding(
  padding: EdgeInsets.zero, // Remove all padding here
  child:  TabBar(
              controller: _tabController,
              indicatorPadding: EdgeInsets.zero,  // Remove padding for indicator
              labelPadding: EdgeInsets.symmetric(horizontal: 5.0), // Reduce space between tabs
              tabs: [
                _buildTab('Informations', 0),
                if (isShop) _buildTab('Shop Details', 1),
                if (isShop) _buildTab('Shop Docs', 2),
                if (isShop) _buildTab('Followers', 3),
                if (isShop) _buildTab('Reviews', 4),
              ],
            ),
),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      InformationsTab(
                        userData: userData,
                        pickImage: pickImage,
                      ),
                      if (isShop)
                        ShopDetailsTab(
                          userData: userData,
                          updateLocation: _onUpdateLocationPressed,
                        ),
                      if (isShop)
                        ShopDocsTab(
                          userData: userData,
                          pickImage: pickImage,
                          updateExpiryDate: _updateExpiryDate,
                        ),
                      if (isShop)
                        FollowerTab(
                          userData: userData,
                          ),
                      if (isShop)
                        ReviewTab(
                          userData: userData,
                          ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
