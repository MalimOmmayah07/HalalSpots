import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart'; // For opening the link
import 'package:halal_spots/components/text_field.dart';

class PostList extends StatefulWidget {
  const PostList({super.key});

  @override
  _PostListState createState() => _PostListState();
}

class _PostListState extends State<PostList> {
  late User? currentUser;
  bool isLoading = true;
  List<Map<String, dynamic>> filteredPosts = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    searchController.addListener(_filterPosts);
  }

  void _filterPosts() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredPosts = filteredPosts.where((post) {
        return post['title'].toLowerCase().contains(query) ||
            post['details'].toLowerCase().contains(query);
      }).toList();
    });
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return timeago.format(dateTime);
  }

  void showDeleteConfirmation(String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              deletePost(postId);
              Navigator.of(ctx).pop();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> deletePost(String postId) async {
    try {
      await FirebaseFirestore.instance.collection('Posts').doc(postId).delete();
      displayMessage("Post deleted successfully");
    } catch (error) {
      displayMessage("Error deleting post: $error");
    }
  }

  void displayMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void showPostDetailsModal(Map<String, dynamic> post) {
    TextEditingController titleController = TextEditingController(text: post['title']);
    TextEditingController detailsController = TextEditingController(text: post['details']);
    TextEditingController imageUrlController = TextEditingController(text: post['imageUrl']);
    TextEditingController linkController = TextEditingController(text: post['link']);
    String? currentImageUrl = post['imageUrl'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Post"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Displaying the current image if available
              currentImageUrl != null && currentImageUrl.isNotEmpty
                  ? Column(
                children: [
                  Image.network(
                    currentImageUrl,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 10),
                ],
              )
                  : const SizedBox.shrink(),

              Text("Title", style: TextStyle(fontWeight: FontWeight.bold)),
              primaryTextField(
                controller: titleController,
                hintText: 'Enter Post Title',
                obscureText: false,
                text: "Title",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the post title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              Text("Details", style: TextStyle(fontWeight: FontWeight.bold)),
              primaryTextField(
                controller: detailsController,
                hintText: 'Enter Details',
                obscureText: false,
                text: "Details",
                maxLines: 10,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the post details';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10),
              Text("Link", style: TextStyle(fontWeight: FontWeight.bold)),
              primaryTextField(
                controller: linkController,
                hintText: 'Enter Link',
                obscureText: false,
                text: "Link",
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the link';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () {
              updatePost(
                post['id'],
                titleController.text,
                detailsController.text,
                imageUrlController.text,
                linkController.text,
              );
              Navigator.of(ctx).pop();
            },
            child: Text(
              "Update",
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> updatePost(String postId, String newTitle, String newDetails, String newImageUrl, String newLink) async {
    try {
      await FirebaseFirestore.instance.collection('Posts').doc(postId).update({
        'title': newTitle,
        'details': newDetails,
        'timestamp': Timestamp.now(),
        'imageUrl': newImageUrl,
        'link': newLink,
      });

      displayMessage("Post updated successfully");
    } catch (error) {
      displayMessage("Error updating post: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.orangeAccent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search posts...',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: const Color.fromARGB(255, 255, 168, 68)),
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Posts')
            .where('postedBy', isEqualTo: currentUser!.email)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final posts = snapshot.data?.docs ?? [];
          filteredPosts = posts.map((doc) {
            return {
              'id': doc.id,
              'title': doc['title'],
              'details': doc['details'],
              'timestamp': doc['timestamp'],
              'imageUrl': doc['imageUrl'],
              'link': doc['link'],
            };
          }).toList();

          return filteredPosts.isEmpty
              ? const Center(child: Text("No posts found"))
              : ListView.builder(
            itemCount: filteredPosts.length,
            itemBuilder: (context, index) {
              final post = filteredPosts[index];
              return GestureDetector(
                onTap: () {
                  showPostDetailsModal(post);
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 10,
                  color: Colors.white,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            post['imageUrl'] != null
                                ? Image.network(post['imageUrl'], height: 150, fit: BoxFit.cover)
                                : SizedBox.shrink(),
                            const SizedBox(height: 10),
                            Text(
                              post['title'],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              post['details'],
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              formatTimestamp(post['timestamp']),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            post['link'] != null
                                ? GestureDetector(
                              onTap: () async {
                                final url = post['link'];
                                if (await canLaunch(url)) {
                                  await launch(url);
                                } else {
                                  throw 'Could not launch $url';
                                }
                              },
                              child: Text(
                                'Link: ${post['link']}',
                                style: TextStyle(color: Colors.blue, fontSize: 12),
                              ),
                            )
                                : SizedBox.shrink(),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDeleteConfirmation(post['id']);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
