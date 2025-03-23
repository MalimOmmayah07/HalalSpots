import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:google_fonts/google_fonts.dart';

class ShopDetailsPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const ShopDetailsPage({super.key, required this.user});

  @override
  _ShopDetailsPageState createState() => _ShopDetailsPageState();
}

class _ShopDetailsPageState extends State<ShopDetailsPage> {
  // Firestore pagination variables
  final int _reviewsPerPage = 5;
  bool _hasMoreReviews = true;
  DocumentSnapshot? _lastReviewDoc;
  final List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _items = [];
  String _sortOption = 'Lowest to Highest'; // Default sort option
  String _availabilityFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchReviews();
    _fetchItems();
  }
  Future<void> _fetchReviews() async {
      QuerySnapshot querySnapshot;
      if (_lastReviewDoc == null) {
        querySnapshot = await FirebaseFirestore.instance
            .collection('Reviews')
            .doc(widget.user['storeName'])
            .collection('userReviews')
            .orderBy('timestamp', descending: true)
            .limit(_reviewsPerPage)
            .get();
      } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('Reviews')
            .doc(widget.user['storeName'])
            .collection('userReviews')
            .orderBy('timestamp', descending: true)
            .startAfterDocument(_lastReviewDoc!)
            .limit(_reviewsPerPage)
            .get();
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastReviewDoc = querySnapshot.docs.last;
        setState(() {
          _reviews.addAll(querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
          _hasMoreReviews = querySnapshot.docs.length == _reviewsPerPage;
        });
      }
  }

Future<void> _fetchItems() async {
    Query query = FirebaseFirestore.instance
        .collection('Items')
        .where('postedBy', isEqualTo: widget.user['email']);

    // Apply availability filter
    if (_availabilityFilter == 'Available') {
      query = query.where('isAvailable', isEqualTo: true);
    } else if (_availabilityFilter == 'Not Available') {
      query = query.where('isAvailable', isEqualTo: false);
    }

    QuerySnapshot querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        _items = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        _sortItems(); // Sort the items when they are fetched
      });
    }
  }

  // Function to sort items based on selected option
  void _sortItems() {
    if (_sortOption == 'Lowest to Highest') {
      _items.sort((a, b) => a['price'].compareTo(b['price']));
    } else if (_sortOption == 'Highest to Lowest') {
      _items.sort((a, b) => b['price'].compareTo(a['price']));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user['storeName']),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Cover Photo (Store Profile Image)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(widget.user['storeProfileImage']),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
              ),
            ),
            // Content below the cover photo
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 240), // Space for cover photo
                  Center(
                    child: Column(
                      children: [
                        Text(
                          widget.user['storeName'],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          widget.user['storeAddress'],
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                  // Verified Information in one row, centered
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Centering the row
                    children: [
                      _buildVerificationInfo(
                        title: 'Muslim-Friendly Certificate',
                        status: widget.user['halalCertificateVerified'],
                      ),
                      SizedBox(width: 15), // Space between items
                      _buildVerificationInfo(
                        title: 'Business Permit',
                        status: widget.user['validIdVerified'],
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                   
                  Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRatingRow(widget.user['averageRating']),
                  SizedBox(width: 5),
                          Icon(
                            Icons.people,
                            size: 15,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${widget.user['followers']}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.blueAccent,
                        size: 16,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Latitude: ${widget.user['latitude']} | Longitude: ${widget.user['longitude']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10.0,
                          offset: Offset(0, 4),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(widget.user['latitude'], widget.user['longitude']),
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
                              width: 60.0,
                              height: 60.0,
                              point: LatLng(widget.user['latitude'], widget.user['longitude']),
                              child: Column(
                                children: [
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
                                      widget.user['storeName'],
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
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  

                  Text(
                    'Foods and Beverages',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16, // Adjust font size based on screen width
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(height: 10),
                     Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between dropdowns
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4.0), // Add spacing between dropdowns
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 1), // Add border for dropdown
                              borderRadius: BorderRadius.circular(8), // Rounded corners for dropdown
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: DropdownButton<String>(
                                value: _sortOption,
                                items: [
                                  'Lowest to Highest',
                                  'Highest to Lowest',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width > 600 ? 14 : 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _sortOption = newValue!;
                                    _sortItems(); // Apply sorting when value changes
                                  });
                                },
                                isExpanded: true,
                                underline: SizedBox(),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4.0), // Add spacing between dropdowns
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey, width: 1), // Add border for dropdown
                              borderRadius: BorderRadius.circular(8), // Rounded corners for dropdown
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: DropdownButton<String>(
                                value: _availabilityFilter,
                                items: [
                                  'All',
                                  'Available',
                                  'Not Available',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width > 600 ? 14 : 12,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _availabilityFilter = newValue!;
                                    _fetchItems(); // Fetch items based on the new filter
                                  });
                                },
                                isExpanded: true,
                                underline: SizedBox(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),


                  
                  SizedBox(height: 10),
                  _items.isEmpty
                      ? Center(
                  child: Text(
                    'No available',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                )
                      : GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Two cards per row
                    crossAxisSpacing: 10, // Space between cards
                    mainAxisSpacing: 10, // Space between rows
                    childAspectRatio: 0.75, // Adjust the aspect ratio of the card
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return GestureDetector(
                      onTap: () {
                        // Show modal when card is tapped
                        showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image in the modal
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      item['imageUrl'],
                                      width: double.infinity,
                                      height: 200, // Adjust height as needed
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  // Item Name
                                  Text(
                                    item['itemName'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  // Price with color in the modal
                                  Text(
                                    '₱${item['price']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFFD4AF37),  // Gold color using hex code
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text('Description: ${item['description']}'),
                                  SizedBox(height: 16),
                                  // Optionally, add a button to close the modal
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context); // Close the modal
                                    },
                                    child: Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.all(1),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image on top, smaller size
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item['imageUrl'],
                                width: double.infinity,
                                height: 150, // Reduced height for the image
                                fit: BoxFit.fill,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Item Name
                                  Text(
                                    item['itemName'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                      color: Colors.black87,
                                    ),
                                    overflow: TextOverflow.ellipsis, // Truncate if too long
                                    maxLines: 1,
                                  ),
                                  SizedBox(height: 4),
                                  // Price and Quantity in one row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      // Price with pesos sign in gold
                                      Text(
                                        '₱${item['price']}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFFD4AF37),  // Gold color using hex code
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(width: 8), // Add some space between price and quantity
                                      // Quantity
                                      Text(
                                        item['isAvailable'] != null && item['isAvailable'] ? 'Available' : 'Not Available',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: item['isAvailable'] == null || !item['isAvailable'] ? Colors.red : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 2),
                                  // Description with overflow handling
                                  Text(
                                    '${item['description']}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.black45,
                                    ),
                                    maxLines: 2, // Show a max of two lines for description
                                    overflow: TextOverflow.ellipsis, // Truncate if needed
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 20),
                                  GestureDetector(
                                    onTap: () {
                                      _showReviewDialog(context);
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.blueAccent, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.comment,
                                            color: Colors.blueAccent,
                                            size: 20,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Leave a Review',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  // Display reviews
                                  _reviews.isEmpty
                                      ? Center(
                        child: Text(
                          'No reviews available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: _reviews.length,
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            return ListTile(
                              title: Text(review['review']),
                              subtitle: Row(
                                children: [
                                  RatingBar.builder(
                                    initialRating: review['rating'],
                                    minRating: 1,
                                    allowHalfRating: true,
                                    itemCount: 5,
                                    itemSize: 16.0,
                                    itemBuilder: (context, _) => Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    onRatingUpdate: (_) {},
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    review['userEmail'] ?? 'Anonymous',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  // Pagination controls

                 if (_hasMoreReviews)
  Padding(
    padding: const EdgeInsets.only(top: 2.0), // Add spacing above the "Read More" button
    child: Center(
      child: GestureDetector(
        onTap: () {
          _fetchReviews(); // Add parentheses to invoke the function
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
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationInfo({required String title, required bool status}) {
    return Row(
      children: [
        Icon(
          status ? Icons.check_circle : Icons.cancel,
          color: status ? Colors.green : Colors.red,
          size: 12,  // Smaller icon size
        ),
        SizedBox(width: 2),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,  // Smaller font size
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showReviewDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      double rating = 0; // Declare rating variable
      final TextEditingController reviewController = TextEditingController(); // Declare review controller

      return AlertDialog(
        title: Text('Leave a Review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: reviewController, // Set the controller
              decoration: InputDecoration(labelText: 'Your Review'),
            ),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              allowHalfRating: true,
              itemCount: 5,
              itemSize: 24.0,
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (newRating) {
                rating = newRating; // Update rating on change
              },
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reviewController.text.isNotEmpty && rating > 0) {
                final userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Anonymous';

                // Check if the user already has a review for this store
                final reviewSnapshot = await FirebaseFirestore.instance
                    .collection('Reviews')
                    .doc(widget.user['storeName'])
                    .collection('userReviews')
                    .where('userEmail', isEqualTo: userEmail)
                    .get();

                if (reviewSnapshot.docs.isNotEmpty) {
                  // Update the existing review
                  await FirebaseFirestore.instance
                      .collection('Reviews')
                      .doc(widget.user['storeName'])
                      .collection('userReviews')
                      .doc(reviewSnapshot.docs.first.id) // Get the existing review document ID
                      .update({
                        'review': reviewController.text,
                        'rating': rating,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                } else {
                  // Add a new review
                  await FirebaseFirestore.instance
                      .collection('Reviews')
                      .doc(widget.user['storeName'])
                      .collection('userReviews')
                      .add({
                        'review': reviewController.text,
                        'rating': rating,
                        'userEmail': userEmail,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                }

                // No loading indicator, just update the UI directly
                _reviews.clear(); // Assuming _reviews is your review list
                _fetchReviews(); // Assuming this is a function to fetch reviews

                Navigator.pop(context); // Close the dialog
              }
            },
            child: Text('Submit'),
          ),
        ],
      );
    },
  );
}

Widget _buildRatingRow(double rating) {
  int fullStars = rating.floor();
  int emptyStars = 5 - fullStars;
  double fractionalPart = rating - fullStars;

  List<Widget> stars = [];

  // Adding full stars
  for (int i = 0; i < fullStars; i++) {
    stars.add(Icon(Icons.star, color: const Color.fromARGB(255, 218, 197, 8), size: 15));
  }

  // Adding half star if fractional part is 0.5 or more
  if (fractionalPart >= 0.5) {
    stars.add(Icon(Icons.star_half, color: const Color.fromARGB(255, 218, 197, 8), size: 15));
  }

  // Adding empty stars
  for (int i = 0; i < emptyStars; i++) {
    stars.add(Icon(Icons.star_border, color: const Color.fromARGB(255, 218, 197, 8), size: 15));
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
            fontSize: 12,
            fontWeight: FontWeight.w500, // Slightly lighter text
            color: Colors.black87, // Slightly muted black color
          ),
        ),
      ],
    ),
  );
}
}
