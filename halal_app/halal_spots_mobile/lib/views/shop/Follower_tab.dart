import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FollowerTab extends StatefulWidget {
  final Map<String, dynamic> userData;

  const FollowerTab({
    super.key,
    required this.userData,
  });

  @override
  _FollowerTabState createState() => _FollowerTabState();
}

class _FollowerTabState extends State<FollowerTab> {
  List<Map<String, dynamic>> followersList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    followers(); 
  }

  // Function to get the followers of the current user
  void followers() async {
    var currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception("No user logged in");
    }

    final usersCollection = FirebaseFirestore.instance.collection('Users');
    final querySnapshot = await usersCollection.get();

    List<Map<String, dynamic>> followersListTemp = [];

    // Loop through users to find the ones following the current user
    for (var userDoc in querySnapshot.docs) {
      if (userDoc.id != currentUser.email) {
        QuerySnapshot followingDocs = await usersCollection
            .doc(userDoc.id)
            .collection('Following')
            .get();

        for (var doc in followingDocs.docs) {
          if (doc.id == currentUser.email) {
            var followerDoc = await usersCollection.doc(userDoc.id).get();
            var followerData = followerDoc.data();

            if (followerData != null) {
              followersListTemp.add({
                'email': userDoc.id,
                'fullName': followerData['fullName'] ?? 'N/A',
                'phoneNo': followerData['phoneNo'] ?? 'N/A',
                'profile_picture': followerData['profile_picture'] ?? '',
                'username': followerData['username'] ?? 'N/A',
                'address': followerData['address'] ?? 'N/A',
              });
            }
          }
        }
      }
    }

    setState(() {
      followersList = followersListTemp;
      isLoading = false;  // Stop loading once data is fetched
    });
  }

@override
Widget build(BuildContext context) {
  return isLoading
      ? Center(child: CircularProgressIndicator()) // Show loading indicator while data is being fetched
      : ListView(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center( // Added Center widget to center the text
                child: Text(
                  'Total Followers: ${followersList.length}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ),
            ListView.builder(
              padding: const EdgeInsets.all(5.0),
              shrinkWrap: true, // Important to make the inner ListView not take up all space
              itemCount: followersList.length,
              itemBuilder: (context, index) {
                var follower = followersList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(7.0),
                    leading: follower['profile_picture'] != ''
                        ? CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(follower['profile_picture']),
                          )
                        : const CircleAvatar(
                            radius: 30, child: Icon(Icons.account_circle)),
                    title: Text(follower['fullName']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Username: ${follower['username']}'),
                        Text('Phone: ${follower['phoneNo']}'),
                        Text('Address: ${follower['address']}'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
}

}
