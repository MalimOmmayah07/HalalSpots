import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListItem extends StatefulWidget {
  const ListItem({super.key});

  @override
  _ListItemState createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  late User? currentUser;
  bool isLoading = true;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    fetchItems();
    searchController.addListener(_filterItems); // Listen to search input changes
  }

  // Fetch items from Firestore where the current user posted them
  Future<void> fetchItems() async {
    try {
      // Fetching items from Firestore where the current user posted them
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('Items')
          .where('postedBy', isEqualTo: currentUser!.email)
          .get();

      List<Map<String, dynamic>> loadedItems = [];
      for (var doc in snapshot.docs) {
        loadedItems.add({
          'id': doc.id,
          'itemName': doc['itemName'],
          'description': doc['description'],
          'category': doc['category'],
          'available': doc['isAvailable'],  // Ensure Firestore uses 'isAvailable' for this field
          'price': doc['price'],
          'imageUrl': doc['imageUrl'],
        });
      }

      setState(() {
        items = loadedItems;
        filteredItems = loadedItems; // Initially, show all items
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      displayMessage("Error fetching items: $error");
    }
  }

  // Function to show SnackBar messages
  void displayMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void showItemDetails(Map<String, dynamic> item) {
    TextEditingController itemNameController = TextEditingController(text: item['itemName']);
    TextEditingController descriptionController = TextEditingController(text: item['description']);
    TextEditingController priceController = TextEditingController(text: item['price'].toString());
    String selectedCategory = item['category'] ?? 'Food';  // Default category to 'Food'
    bool isAvailable = item['available'] ?? false;

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 16.0,
            left: 16.0,
            right: 16.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image at the top of the modal
                  Image.network(item['imageUrl'], width: double.infinity, height: 200, fit: BoxFit.cover),
                  SizedBox(height: 16),
                  Text(
                    'Edit Item',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: itemNameController,
                    decoration: InputDecoration(labelText: 'Item Name'),
                    validator: (value) => value!.isEmpty ? 'Item name is required' : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  SizedBox(height: 10),
                  // Dropdown for Category
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(labelText: 'Category'),
                    items: ['Food', 'Beverage']
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                    validator: (value) => value == null || value.isEmpty
                        ? 'Category is required'
                        : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: priceController,
                    decoration: InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Price is required' : null,
                  ),
                  SizedBox(height: 10),
                  // Dropdown for Availability (instead of Toggle Switch)
                  DropdownButtonFormField<bool>(
                    value: isAvailable,
                    decoration: InputDecoration(labelText: 'Availability'),
                    items: [
                      DropdownMenuItem(
                        value: true,
                        child: Text('Available'),
                      ),
                      DropdownMenuItem(
                        value: false,
                        child: Text('Not Available'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        isAvailable = value!;
                      });
                    },
                    validator: (value) => value == null ? 'Availability is required' : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        try {
                          // Update Firestore document
                          await FirebaseFirestore.instance
                              .collection('Items')
                              .doc(item['id'])
                              .update({
                            'itemName': itemNameController.text,
                            'description': descriptionController.text,
                            'category': selectedCategory,  // Update the category
                            'price': double.tryParse(priceController.text) ?? 0.0,
                            'isAvailable': isAvailable,
                          });

                          displayMessage('Item updated successfully!');
                          fetchItems(); // Refresh the list
                          Navigator.of(context).pop(); // Close the modal
                        } catch (error) {
                          displayMessage('Error updating item: $error');
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Save'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Filter items based on search input
  void _filterItems() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredItems = items.where((item) {
        return item['itemName'].toLowerCase().contains(query) ||
            item['category'].toLowerCase().contains(query);
      }).toList();
    });
  }

  // Function to delete item
  Future<void> deleteItem(String itemId) async {
    try {
      await FirebaseFirestore.instance.collection('Items').doc(itemId).delete();
      displayMessage('Item deleted successfully!');
      fetchItems(); // Refresh the list after deletion
    } catch (error) {
      displayMessage('Error deleting item: $error');
    }
  }

  // Function to show delete confirmation dialog
  void showDeleteConfirmation(String itemId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                deleteItem(itemId); // Call delete function
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // Listen to the Firestore changes in real-time for each item's availability
  Stream<DocumentSnapshot> getItemStream(String itemId) {
    return FirebaseFirestore.instance
        .collection('Items')
        .doc(itemId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background for a modern feel
      appBar: AppBar(
        title: const Text('My Items'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by item name or category',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];

                        return StreamBuilder<DocumentSnapshot>(
                          stream: getItemStream(item['id']),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            final itemData = snapshot.data!;
                            final isAvailable = itemData['isAvailable'];

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Image.network(item['imageUrl'], width: 50, height: 50),
                                title: Text(
                                  item['itemName'],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['category']),
                                    Text('₱${item['price'].toString()}'),
                                    Text(isAvailable ? 'Available' : 'Not Available'),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDeleteConfirmation(item['id']);
                                  },
                                ),
                                onTap: () => showItemDetails(item),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
