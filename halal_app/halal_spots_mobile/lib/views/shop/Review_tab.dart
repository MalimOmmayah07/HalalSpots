import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting

class ReviewTab extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ReviewTab({
    super.key,
    required this.userData,
  });

  @override
  _ReviewTabState createState() => _ReviewTabState();
}

class _ReviewTabState extends State<ReviewTab> {
  bool isLoading = true;
  final List<Map<String, dynamic>> _reviews = [];
  final int _reviewsPerPage = 10;
  DocumentSnapshot? _lastReviewDoc;
  String? storeName;
  double _averageRating = 0.0; // Store average rating

  @override
  void initState() {
    super.initState();
    _getStoreName();  // Fetch the store name on initialization
  }

  Future<void> _getStoreName() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    // Fetch the store name from the "Users" collection using currentUser.uid
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection("Users")
        .doc(currentUser.email)
        .get();

    if (userDoc.exists) {
      setState(() {
        storeName = userDoc['store_name'];  // Assuming the store name field is called 'store_name'
      });
      print("Store Name: $storeName");  // Debugging statement
      _fetchReviews(); // Fetch reviews once store name is fetched
    }
  }

  Future<void> _fetchReviews() async {
    if (storeName == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    print("Fetching reviews for store: $storeName");  // Debugging statement

    QuerySnapshot querySnapshot;
    if (_lastReviewDoc == null) {
      querySnapshot = await FirebaseFirestore.instance
          .collection('Reviews')
          .doc(storeName) // Use the fetched storeName
          .collection('userReviews')
          .orderBy('timestamp', descending: true)
          .limit(_reviewsPerPage)
          .get();
    } else {
      querySnapshot = await FirebaseFirestore.instance
          .collection('Reviews')
          .doc(storeName) // Use the fetched storeName
          .collection('userReviews')
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastReviewDoc!)
          .limit(_reviewsPerPage)
          .get();
    }

    if (querySnapshot.docs.isNotEmpty) {
      _lastReviewDoc = querySnapshot.docs.last;
      double totalRating = 0.0;
      int count = 0;

      setState(() {
        _reviews.addAll(querySnapshot.docs.map((doc) {
          double rating = doc['rating'].toDouble();
          totalRating += rating;
          count++;

          return {
            'rating': rating,
            'review': doc['review'],
            'timestamp': (doc['timestamp'] as Timestamp).toDate(),
            'userEmail': doc['userEmail'],
          };
        }).toList());

        if (count > 0) {
          _averageRating = totalRating / count; // Calculate average rating
        }

        isLoading = false;
      });
    } else {
      print("No reviews found for store: $storeName");  // Debugging statement
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('yyyy-MM-dd hh:mm a').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator()) // Show loading indicator while data is being fetched
        : SingleChildScrollView(  // Wrap the ListView in a scrollable container
            child: Column(
              children: [
                // Display the average rating score at the top, centered with the rating bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      children: [
                        // Rating bar for the average rating score
                        RatingBar.builder(
                          initialRating: _averageRating,
                          minRating: 1,
                          allowHalfRating: true,
                          itemCount: 5,
                          itemSize: 30.0,
                          itemBuilder: (context, _) => Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onRatingUpdate: (newRating) {
                            // Optionally handle the rating update if needed
                          },
                        ),
                        SizedBox(height: 8),
                        // Display the numerical average rating
                        Text(
                          'Average Rating: ${_averageRating.toStringAsFixed(1)}', // Display the average rating
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // List of reviews
                ListView.builder(
                  shrinkWrap: true,  // Prevents the ListView from growing too large
                  padding: const EdgeInsets.all(5.0),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    var review = _reviews[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal:20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12.0),
                        leading: const CircleAvatar(radius: 30, child: Icon(Icons.account_circle)),
                        title: Text(review['userEmail'] ?? 'Anonymous'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Rating bar with the rating number next to it
                            Row(
                              children: [
                                RatingBar.builder(
                                  initialRating: review['rating'].toDouble(),
                                  minRating: 1,
                                  allowHalfRating: true,
                                  itemCount: 5,
                                  itemSize: 15.0,
                                  itemBuilder: (context, _) => Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  onRatingUpdate: (newRating) {
                                    // Do something with the new rating if needed
                                  },
                                ),
                                SizedBox(width: 8), // Space between stars and rating number
                                Text('${review['rating']}'), // Display the rating number
                              ],
                            ),
                            Text('Review: ${review['review']}'),
                            Text(_formatTimestamp(review['timestamp'])), // Display formatted timestamp
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
  }
}
