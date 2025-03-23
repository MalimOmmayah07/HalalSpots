import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:halal_spots/views/seeker/shop_details.dart'; // Import the Shop Details Page

class ListFollow extends StatefulWidget {
  const ListFollow({super.key});

  @override
  State<ListFollow> createState() => _ListFollowState();
}

class _ListFollowState extends State<ListFollow> {
  User? currentUser;
  bool isLoading = true;
  bool isFollowed = false;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = []; // List to hold filtered users
  Map<String, bool> followedStores = {}; // To keep track of followed stores
  TextEditingController searchController = TextEditingController(); // Controller for the search input
  
  @override
  void initState() {
    super.initState();
    fetchAllUsers();
    searchController.addListener(_filterUsers); // Listen for search input changes
  }

  void fetchAllUsers() async {
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("No user logged in");
    }
      final usersCollection = FirebaseFirestore.instance.collection('Users');
      final querySnapshot = await usersCollection.get();

      Map<String, int> followingCount = {};

      // Pre-fetch 'Following' counts for all users
      await Future.forEach(querySnapshot.docs, (userDoc) async {
        if (userDoc.id != currentUser!.email) {
          QuerySnapshot followingDocs = await usersCollection
              .doc(userDoc.id)
              .collection('Following')
              .get();
          for (var doc in followingDocs.docs) {
            followingCount[doc.id] = (followingCount[doc.id] ?? 0) + 1;
          }
        }
      });

      List<Map<String, dynamic>> fetchedUsers = [];
      DateTime currentDate = DateTime.now().toLocal();
      currentDate = DateTime(currentDate.year, currentDate.month, currentDate.day);

      // Process each user document
      await Future.forEach(querySnapshot.docs, (userDoc) async {
        var data = userDoc.data();
        String? halalCertificateExpiry = data['halal_certificate_expiry'];

        DateTime? expiryDate;
        if (halalCertificateExpiry != null && halalCertificateExpiry.isNotEmpty) {
          try {
            expiryDate = DateTime.parse(halalCertificateExpiry).toLocal();
            expiryDate = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
          } catch (e) {
            expiryDate = null;
          }
        }

        if (userDoc.id != currentUser!.email &&
            data['store_name'] != null &&
            data['store_name'].isNotEmpty &&
            data['halal_certificate_verified'] == true &&
            expiryDate != null &&
            (expiryDate.isAfter(currentDate) || expiryDate.isAtSameMomentAs(currentDate))) {
          String storeName = data['store_name'] ?? 'N/A';
          String email = data['email'] ?? 'N/A';
          double longitude = (data['longitude'] != null) ? data['longitude'].toDouble() : 0.0; // Ensure it's a double
          double latitude = (data['latitude'] != null) ? data['latitude'].toDouble() : 0.0; // Ensure it's a double
          String storeAddress = data['store_address'] ?? 'N/A';
          bool halalCertificateVerified = data['halal_certificate_verified'] ?? false;
          bool validIdVerified = data['valid_id_verified'] ?? false;
          String storeProfileImage = data['shop_logo'] ?? 
              'https://image.similarpng.com/very-thumbnail/2021/09/Online-shopping-logo-design-template-on-transparent-background-PNG.png';
          double averageRating = await calculateAverageRating(storeName);
          bool isFollowed = await checkIfFollowed(userDoc.id);

          if (isFollowed) {
            fetchedUsers.add({
              'storeName': storeName,
              'storeAddress': storeAddress,
              'averageRating': averageRating,
              'halalCertificateVerified': halalCertificateVerified,
              'validIdVerified': validIdVerified,
              'storeProfileImage': storeProfileImage,
              'longitude': longitude,
              'latitude': latitude,
              'userId': userDoc.id,
              'email': email,
              'isFollowed': isFollowed,
              'followers': followingCount[email] ?? 0, // Fixed to correctly fallback to 0
            });
          }
        }
      });

      if (mounted) {
        setState(() {
          users = fetchedUsers;
          filteredUsers = fetchedUsers;
          isLoading = false;
        });
      }
  }

  // Filter the users based on the search input
  void _filterUsers() {
    setState(() {
      filteredUsers = users.where((user) {
        return user['storeName'].toLowerCase().contains(searchController.text.toLowerCase()) ||
               user['storeAddress'].toLowerCase().contains(searchController.text.toLowerCase());
      }).toList();
    });
  }

  Future<double> calculateAverageRating(String storeName) async {
    // Get the reviews collection for the specific store
    final reviewsCollection = FirebaseFirestore.instance
        .collection('Reviews')
        .doc(storeName) // Access the document for the store
        .collection('userReviews'); // Get the user reviews sub-collection

    // Fetch all the reviews for the store
    final reviewsSnapshot = await reviewsCollection.get();

    if (reviewsSnapshot.docs.isEmpty) {
      return 0.0; // No reviews, return 0
    }

    double totalRating = 0;
    int reviewCount = reviewsSnapshot.docs.length;

    // Sum up all the ratings
    for (var reviewDoc in reviewsSnapshot.docs) {
      totalRating += reviewDoc.data()['rating'] ?? 0;
    }

    // Calculate and return the average rating
    return totalRating / reviewCount;
  }

  Future<bool> checkIfFollowed(String userId) async {
    try {
      final followCollection = FirebaseFirestore.instance.collection('Users').doc(currentUser!.email).collection('Following');
      final docSnapshot = await followCollection.doc(userId).get();
      return docSnapshot.exists; 
    } catch (e) {
      return false;
    }
  }

void followUser(String userId) async {
  final followCollection = FirebaseFirestore.instance
      .collection('Users')
      .doc(currentUser!.email)
      .collection('Following');

  bool isFollowed = followedStores[userId] ?? false;

  if (isFollowed) {
    await followCollection.doc(userId).delete();
    setState(() {
      followedStores[userId] = false;
      filteredUsers = filteredUsers.map((user) {
        if (user['userId'] == userId) {
          user['isFollowed'] = false;
        }
        return user;
      }).toList();
    });
  } else {
    await followCollection.doc(userId).set({
      'followedAt': FieldValue.serverTimestamp(),
    });
    setState(() {
      followedStores[userId] = true;
      filteredUsers = filteredUsers.map((user) {
        if (user['userId'] == userId) {
          user['isFollowed'] = true;
        }
        return user;
      }).toList();
    });
  }
}

@override
  Widget build(BuildContext context) {
  double screenWidth = MediaQuery.of(context).size.width;
  double fontSizeFactor = screenWidth * 0.01;  // Adjust this factor for better scaling.

  return Scaffold(
    appBar: AppBar(
      title: const Text(
        "Shop Lists",
        style: TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: Color.fromARGB(255, 17, 12, 96),
      elevation: 0,
      toolbarHeight: 40,
      centerTitle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
    ),
    body: Container(
      decoration: const BoxDecoration(
        color: Colors.white12,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Store',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          isLoading
              ? const Center(
                  child: Text(
                    'No Shop',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Expanded(
                  child: GridView.builder(
  padding: const EdgeInsets.all(8.0),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    childAspectRatio: 0.85,
  ),
  itemCount: filteredUsers.length,
  itemBuilder: (context, index) {
    final user = filteredUsers[index];
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShopDetailsPage(user: user),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        elevation: 2.0,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,  // Ensures the icon doesn't get clipped
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    user['storeProfileImage'],
                    fit: BoxFit.cover,
                    height: 120.0,
                    width: double.infinity,
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),  // Semi-transparent white background
                      shape: BoxShape.circle,  // Circular background
                    ),
                    width: fontSizeFactor * 10,  // Set width of the container
                    height: fontSizeFactor * 10,  // Set height of the container
                    padding: const EdgeInsets.all(0.5),  // Reduced padding for a smaller button

                                    child: IconButton(
  icon: Icon(
  user['isFollowed'] == true
      ? Icons.favorite
      : Icons.favorite_border,
  color: user['isFollowed'] == true
      ? Colors.red
      : Colors.grey,
),

  onPressed: () {
    followUser(user['userId']);
  },
),

                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            user['storeName'],
                            style: GoogleFonts.poppins(
                              fontSize: fontSizeFactor * 2.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user['storeAddress'],
                        style: GoogleFonts.poppins(
                          fontSize: fontSizeFactor * 1.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: fontSizeFactor * 2,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${user['followers']}',
                            style: GoogleFonts.poppins(
                              fontSize: fontSizeFactor * 1.8,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildRatingRow(user['averageRating'], fontSizeFactor),
                        ],
                      ),
                      const SizedBox(height: 1),
                      _buildVerificationRow(user['halalCertificateVerified'], "Muslim-Friendly Certificate", fontSizeFactor),
                      const SizedBox(height: 1),
                      _buildVerificationRow(user['validIdVerified'], "Business Permit", fontSizeFactor),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
)

                ),
        ],
      ),
    ),
  );
}

Widget _buildVerificationRow(bool isVerified, String label, double fontSizeFactor) {
  return Row(
    children: [
      Icon(
        isVerified ? Icons.check_circle : Icons.cancel,
        color: isVerified ? Colors.green : Colors.red,
        size: fontSizeFactor * 1.8,
      ),
      const SizedBox(width: 5),
      Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: fontSizeFactor * 1.8,
          color: Colors.black54,
        ),
      ),
    ],
  );
}

Widget _buildRatingRow(double rating, double fontSizeFactor) {
  int fullStars = rating.floor();
  int emptyStars = 5 - fullStars;
  double fractionalPart = rating - fullStars;

  List<Widget> stars = [];

  for (int i = 0; i < fullStars; i++) {
    stars.add(Icon(Icons.star, color: const Color.fromARGB(255, 218, 197, 8), size: fontSizeFactor * 1.8));
  }

  if (fractionalPart >= 0.5) {
    stars.add(Icon(Icons.star_half, color: const Color.fromARGB(255, 218, 197, 8), size: fontSizeFactor * 1.8));
  }

  for (int i = 0; i < emptyStars; i++) {
    stars.add(Icon(Icons.star_border, color: const Color.fromARGB(255, 218, 197, 8), size: fontSizeFactor * 1.8));
  }

  return Center(  // Center the entire row horizontally
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,  // Center contents within Row
      mainAxisSize: MainAxisSize.min,  // Make the row take only as much width as necessary
      children: [
        // Stars
        Row(
          children: stars,
        ),
        SizedBox(width: 5),  // Space between stars and rating text
        // Rating text with styled text
        Text(
          rating.toStringAsFixed(1), // Rating with 1 decimal place
          style: TextStyle(
            fontSize: fontSizeFactor * 1.8,
            fontWeight: FontWeight.w500, // Slightly lighter text
            color: Colors.black87, // Slightly muted black color
          ),
        ),
      ],
    ),
  );

  
}

} 