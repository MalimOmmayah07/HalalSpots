import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AnnouncementPage extends StatefulWidget {
  const AnnouncementPage({super.key});

  @override
  State<AnnouncementPage> createState() => _AnnouncementPageState();
}

class _AnnouncementPageState extends State<AnnouncementPage> {
  User? currentUser;
  String username = '';
  String userType = '';
  String profilePic =
      'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';
  bool isLoading = true;
  List<Map<String, dynamic>> announcements = [];
  List<Map<String, dynamic>> filteredAnnouncements = []; // List for filtered announcements
  TextEditingController searchController = TextEditingController(); // Search controller

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      startListeningToLogs();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated. Please log in.')),
      );
    }
  }

  void startListeningToLogs() async {
    final data = await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser!.email)
        .get();
    setState(() {
      username = data.get("username") ?? '';
      userType = data.get("type") ?? '';
      isLoading = false; // Update loading state
    });

    final profilePicRef = FirebaseStorage.instance
        .ref()
        .child('users/${currentUser!.email}/profile_picture.jpg');
    final profilePicUrl = await profilePicRef.getDownloadURL();

    setState(() {
      profilePic = profilePicUrl;
    });

    // Fetch announcements
    fetchAnnouncements(userType);
  }

  void fetchAnnouncements(String currentUserType) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection("Announcement")
        .orderBy("timestamp", descending: true)
        .get();

    announcements.clear();

    for (var doc in querySnapshot.docs) {
      final announcementData = doc.data();

      List<dynamic> visibleToList = announcementData['visibleTo'] ?? [];
      if (!visibleToList.contains(currentUser!.email) &&
          !visibleToList.contains(currentUserType)) {
        continue;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(announcementData['postedby'])
          .get();

      String profilePicUrl =
          'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';
      String username = 'Unknown User';

      if (userDoc.exists) {
        profilePicUrl = userDoc.get('profilePicture') ?? profilePicUrl;
        username = userDoc.get('username') ?? username;
      }

      announcements.add({
        "title": announcementData['title'],
        "content": announcementData['content'],
        "postedBy": username,
        "profilePic": profilePicUrl,
        "timestamp": announcementData['timestamp'],
        "isSpecial": announcementData['isSpecial'],
        "imageUrl": announcementData['imageUrl'], // Add imageUrl
        "link": announcementData['link'],         // Add link
      });
    }

    setState(() {
      filteredAnnouncements = announcements;
    });
  }

  void searchAnnouncements(String query) {
    final filtered = announcements.where((announcement) {
      final titleLower = announcement['title'].toLowerCase();
      final contentLower = announcement['content'].toLowerCase();
      final searchLower = query.toLowerCase();
      return titleLower.contains(searchLower) ||
          contentLower.contains(searchLower);
    }).toList();

    setState(() {
      filteredAnnouncements = filtered; // Update filtered announcements
    });
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }

  void showAnnouncementDetails(Map<String, dynamic> announcement) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(announcement['title']),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(announcement['content']),
                const SizedBox(height: 10),
                Text(
                  'Posted by: ${announcement['postedBy']}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 10),
                Text(
                  formatTimestamp(announcement['timestamp']),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green,
              Colors.lightGreenAccent,
              Color(0xFFFFE57F),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            AppBar(
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
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
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: searchController,
                onChanged: searchAnnouncements,
                decoration: InputDecoration(
                  hintText: 'Search announcements...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      searchAnnouncements(''); // Reset the search
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Announcements Section
                  const Text(
                    'Announcements',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10.0),
                  ...filteredAnnouncements.map((announcement) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(announcement['profilePic']),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                announcement['title'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Add a star icon if isSpecial is true
                            if (announcement['isSpecial'] == true)
                              const Icon(
                                Icons.star,
                                color: Colors.amber, // You can change the color as needed
                                size: 20, // Adjust size if necessary
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              announcement['content'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              formatTimestamp(announcement['timestamp']), // Format the timestamp
                              style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                            ),
                          ],
                        ),
                        onTap: () => showAnnouncementDetails(announcement),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
