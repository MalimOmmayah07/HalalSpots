import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  User? currentUser;
  String username = '';
  String userType = '';
  String profilePic =
      'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';
  bool isLoading = true;
  List<Map<String, dynamic>> highlights = [];
  List<Map<String, dynamic>> announcements = [];
  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      fetchHalalAwarenessPosts();
      fetchAnnouncements();
      fetchUserData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated. Please log in.')),
      );
    }
  }



  void fetchUserData() async {

      final data = await FirebaseFirestore.instance
          .collection("Users")
          .doc(currentUser!.email)
          .get();

      setState(() {
        username = data.get("username") ?? '';
        userType = data.get("type") ?? '';
      });
        final profilePicRef = FirebaseStorage.instance
            .ref()
            .child('users/${currentUser!.email}/profile_picture.jpg');
        final profilePicUrl = await profilePicRef.getDownloadURL();

        setState(() {
          profilePic = profilePicUrl;
        });
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate(); // Convert Timestamp to DateTime
    return timeago.format(dateTime);
  }

  void fetchHalalAwarenessPosts() async {
      final querySnapshot = await FirebaseFirestore.instance
          .collection("Settings")
          .doc("halalAwareness")
          .collection("posts")
          .get();

      highlights = querySnapshot.docs.map((doc) {
        return {
          "posts": doc.get("content") ?? 'No content available',
        };
      }).toList();

      setState(() {
        isLoading = false;
      });
  }

void fetchAnnouncements() async {
  setState(() {
    isLoading = true;
  });

    // Fetch the "Following" subcollection for the current user
    final userFollowSnapshot = await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser!.email)
        .collection("Following") // Correctly reference the "Following" subcollection
        .get();

    // Extract the list of following users (their emails or user IDs)
    final List<String> followingList = userFollowSnapshot.docs
        .map((doc) => doc.id) // The document ID represents the followed user
        .toList();

    // Print the following list to the console
    print('Following List for ${currentUser!.email}: $followingList');

    if (followingList.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return; // No users to follow, exit early
    }

    // Fetch all posts where 'postedBy' is in the list of followed users
    final querySnapshot = await FirebaseFirestore.instance
        .collection("Posts")
        .where("postedBy", whereIn: followingList)
        .get();

    // List to store announcements with user details
    final List<Map<String, dynamic>> announcements = [];

    for (var doc in querySnapshot.docs) {
      final postedBy = doc.get("postedBy") ?? '';

      // Fetch user details using the "postedBy" field
      final userDoc = await FirebaseFirestore.instance
          .collection("Users")
          .doc(postedBy)
          .get();

      if (!userDoc.exists) {
        continue; // Skip if user doesn't exist
      }

      // Extract user details or use default values
      final profileUser = userDoc.data()?["username"] ?? 'Unknown';
      final storeName = userDoc.data()?["store_name"] ?? 'Unknown';
      final profilePicture = userDoc.data()?["profile_picture"] ?? 
          'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';
      final shopLogo = userDoc.data()?["shop_logo"] ?? 
          'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_1280.png';

      // Add the combined data to the announcements list
      announcements.add({
        "title": doc.get("title") ?? 'No title available',
        "details": doc.get("details") ?? 'No details available',
        "timestamp": doc.get("timestamp"),
        "postedBy": postedBy,
        "storeName": storeName,
        "profile_picture": profilePicture,
        "shop_logo": shopLogo,
        "profile_user": profileUser,
      });
    }

    // Update state after fetching data
    setState(() {
      isLoading = false;
      this.announcements = announcements; // Assuming `announcements` is a list in your state
    });

}





  void showFullPostDialog(String fullPost) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Full Post'),
        content: SingleChildScrollView(
          child: Text(
            fullPost,
            style: GoogleFonts.poppins(fontSize: 12.0),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  bool isPostLong(String post) {
    final textSpan = TextSpan(
      text: post,
      style: GoogleFonts.poppins(fontSize: 10.0),
    );

    final textPainter = TextPainter(
      text: textSpan,
      maxLines: 3,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: MediaQuery.of(context).size.width - 32);
    return textPainter.didExceedMaxLines;
  }

void showFullAnnouncementDialog(Map<String, dynamic> announcement) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 6,
      title: Text(
        announcement["title"] ?? 'No title',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      content: SingleChildScrollView(  // Allow content to scroll if it's too long
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile picture as the background image for the dialog
              Container(
                height: 300,  // You can adjust this height as per your design
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      announcement["shop_logo"] ?? 'https://via.placeholder.com/150',
                    ),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(16.0), // Matches the AlertDialog border
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "${announcement["storeName"] ?? 'Unknown'}",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                "Posted by: ${announcement["profile_user"] ?? 'Unknown'}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                announcement["details"] ?? 'No details available',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                formatTimestamp(announcement["timestamp"]),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}



@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        color: Colors.white12,
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
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      CarouselSlider(
                        options: CarouselOptions(
                          height: 150, // Increased height for better space
                          autoPlay: true,
                          enlargeCenterPage: true,
                          aspectRatio: 16 / 9,
                          viewportFraction: 0.9,
                        ),
                        items: highlights.map((highlight) {
                          String post = highlight["posts"] ?? 'No content available';
                          bool showReadMore = isPostLong(post);

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16.0), // Added more margin for spacing
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10.0), // Slightly more rounded corners for a modern look
                              color: Colors.white.withOpacity(0.95), // Slightly more opaque for a cleaner look
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromARGB(172, 17, 12, 96),
                                  blurRadius: 11.0, // Softer shadow for a smoother effect
                                  offset: Offset(0, 4), // Slight vertical shadow offset
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), // Balanced padding
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start, // Align items at the top for better structure
                                crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                                children: [
                                  // Text container with justified alignment
                                  Expanded(
                                    child: Container(
                                      constraints: BoxConstraints(maxHeight: 100), // Controls text overflow
                                      child: Text(
                                        post,
                                        maxLines: 4, // Allow more lines if the post is long
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.justify, // Justify the text for cleaner alignment
                                        style: TextStyle(
                                          fontSize: 10, // Slightly larger font for better readability
                                          fontWeight: FontWeight.w700, // Regular weight for a clean look
                                          color: Colors.black87, // Darker text for better contrast
                                        ),
                                      ),

                                    ),
                                  ),
                                  if (showReadMore)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2.0), // Add spacing above the "Read More" button
                                      child: Center( // Centering the "Read More" button horizontally
                                        child: GestureDetector(
                                          onTap: () {
                                            showFullPostDialog(post);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0), // Padding for button
                                            decoration: BoxDecoration(
                                              color: Color.fromARGB(255, 17, 12, 96), // Blue background for the "Read More" button
                                              borderRadius: BorderRadius.circular(5.0), // Rounded corners for the button
                                            ),
                                            child: const Text(
                                              'More',
                                              style: TextStyle(
                                                color: Colors.white, // White text for contrast
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                decoration: TextDecoration.none, // Removed underline for cleaner design
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),


// Announcements List
const SizedBox(height: 30),
Column(
  children: [
    // Halal Announcements Header
    Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16.0),
      width: double.infinity,
      child: Text(
        'Shop Announcements',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 17, 12, 96),
        ),
      ),
    ),
    ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 0),
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: announcements.length,
  itemBuilder: (context, index) {
    final announcement = announcements[index];
    final screenWidth = MediaQuery.of(context).size.width;

    double responsiveFontSize(double baseFontSize) {
      return baseFontSize * (screenWidth / 375); // 375 is a standard width for scaling (e.g., iPhone 11 Pro)
    }

    return GestureDetector(
      onTap: () {
        showFullAnnouncementDialog(announcement);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 3.0, horizontal: 14.0),
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        color: const Color(0xFFF9F9F9),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile picture on the left
              Container(
                width: 65,
                height: 70,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(
                      announcement["shop_logo"] ?? 'https://via.placeholder.com/150',
                    ),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              const SizedBox(width: 10),
              // Details on the right
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      announcement["title"] ?? 'No title',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: responsiveFontSize(11),
                        color: const Color(0xFF1D1D1D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "Posted by: ${announcement["profile_user"] ?? 'Unknown'}",
                      style: TextStyle(
                        fontSize: responsiveFontSize(7),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF757575),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      announcement["details"] ?? 'No details available',
                      style: TextStyle(
                        fontSize: responsiveFontSize(8),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF616161),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      formatTimestamp(announcement["timestamp"]),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: responsiveFontSize(7),
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9E9E9E),
              ),
            ],
          ),
        ),
      ),
    );
  },
),

  ],
),

                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

}
