import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:halal_spots/views/seeker/list_follow.dart';
import 'package:halal_spots/views/seeker/list_shop.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with SingleTickerProviderStateMixin {
  final currentUser = FirebaseAuth.instance.currentUser!;
  late String username = '';
  late String userType = '';
  String profilePic =
      'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';
  late bool isShop = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Changed length to 2 for two tabs
    fetchUserData();
  }

  void fetchUserData() async {
      final data = await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUser.email)
          .get();
      setState(() {
        username = data.get("username") ?? '';
        userType = data.get("type") ?? '';
        isShop = userType == 'Shop';
      });

      // Fetch profile picture URL from Firebase Storage
      final profilePicRef = FirebaseStorage.instance
          .ref()
          .child('users/${currentUser.email}/profile_picture.jpg');
      final profilePicUrl = await profilePicRef.getDownloadURL();

      setState(() {
        profilePic = profilePicUrl;
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        elevation: 2,
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8.0),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromARGB(223, 0, 0, 0),
                        spreadRadius: 1,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 20.0,
                    backgroundImage: NetworkImage(profilePic),
                    backgroundColor: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: Color(0xFFD4AF37), // Color for the indicator (hover-like effect)
            indicatorWeight: 4.0, // Thickness of the indicator
            labelColor: Color(0xFFD4AF37), // Color for the selected tab text
            unselectedLabelColor: Colors.black, // Color for unselected tabs
            tabs: [
              const Tab(text: 'Shops'),
              const Tab(text: 'Followed'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListShop(),
                ListFollow()
              ],
            ),
          ),
        ],
      ),
    );
  }
}
