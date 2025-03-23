import 'package:halal_spots/views/seeker/shop.dart';
import 'package:halal_spots/views/shop/post.dart';
import 'package:halal_spots/views/seeker/map.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:halal_spots/views/shop/add.dart';
import 'package:halal_spots/views/home.dart';
import 'package:halal_spots/views/profile.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class Nav extends StatefulWidget {
  const Nav({super.key});

  @override
  _NavState createState() => _NavState();
}

class _NavState extends State<Nav> {
  int _selectedIndex = 1; // Default to Home page for Seeker
  late User currentUser;
  String? userType;

  final List<Widget> _widgetOptionsSeeker = <Widget>[
    const ProfilePage(),
    const ShopPage(),
    const HomePage(),
    const MapPage(),
    Container(), // Placeholder for Logout
  ];

  final List<Widget> _widgetOptionsShop = <Widget>[
    const ProfilePage(),
    const AddPostPage(),
    const HomePage(),
    const AddPage(),
    Container(), // Placeholder for Logout
  ];

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser!;
    fetchUserType();
  }

  // Fetch the user type initially and listen for changes in real-time
  void fetchUserType() async {
    FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser.email)
        .snapshots()
        .listen((userData) async {
      if (userData.exists) {
        setState(() {
          userType = userData.get("type");
        });
        await _loadSelectedIndex(); // Load selected index from SharedPreferences
      }
    });
  }

  // Fetch the stored index from SharedPreferences
  Future<void> _loadSelectedIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int storedIndex = prefs.getInt('selectedIndex') ?? 1; // Default to index 1
    setState(() {
      _selectedIndex = storedIndex;
    });
  }

  // Save the selected index to SharedPreferences
  Future<void> _saveSelectedIndex(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('selectedIndex', index);
  }

  void _onItemTap(int index) async {
    if ((userType == 'Seeker' && index == 4) || 
        (userType == 'Shop' && index == 4)) {
      _showLogoutConfirmationDialog();
    } else {
      setState(() {
        _selectedIndex = index;
      });
      await _saveSelectedIndex(index); // Save the selected index
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _showLogoutConfirmationDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text("Logout"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: userType == 'Seeker'
          ? _widgetOptionsSeeker.elementAt(_selectedIndex)
          : userType == 'Shop'
              ? _widgetOptionsShop.elementAt(_selectedIndex)
              : Container(), // Fallback if no user type matches
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFE57F).withOpacity(0.8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4.0,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: userType == 'Seeker'
              ? <BottomNavigationBarItem>[
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.shop),
                    label: 'Shop',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.map),
                    label: 'Map',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.exit_to_app),
                    label: 'Logout',
                  ),
                ]
              : userType == 'Shop'
                  ? <BottomNavigationBarItem>[
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.person),
                        label: 'Profile',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.announcement),
                        label: 'Announcement',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.add),
                        label: 'Add',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.exit_to_app),
                        label: 'Logout',
                      ),
                    ]
                  : <BottomNavigationBarItem>[
                      // Fallback to ensure at least 2 items
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.exit_to_app),
                        label: 'Logout',
                      ),
                    ],
          currentIndex: _selectedIndex,
          onTap: _onItemTap,
          selectedFontSize: 10.0,
          unselectedFontSize: 8.0,
          selectedItemColor: Color.fromARGB(255, 17, 12, 96),
          unselectedItemColor: const Color.fromARGB(255, 255, 202, 126),
        ),
      ),
    );
  }
}
