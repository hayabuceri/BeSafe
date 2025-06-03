import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Search for users with matching phone number or name
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: query)
          .get();

      final nameQuerySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      // Combine and deduplicate results
      final Set<String> seenIds = {};
      final List<Map<String, dynamic>> combinedResults = [];

      for (var doc in querySnapshot.docs) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          combinedResults.add({
            'id': doc.id,
            'name': doc['name'] as String,
            'phone': doc['phone'] as String,
          });
        }
      }

      for (var doc in nameQuerySnapshot.docs) {
        if (!seenIds.contains(doc.id)) {
          seenIds.add(doc.id);
          combinedResults.add({
            'id': doc.id,
            'name': doc['name'] as String,
            'phone': doc['phone'] as String,
          });
        }
      }

      setState(() {
        _searchResults = combinedResults;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _addEmergencyContact(String contactId, String contactName) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Add to emergency_contacts collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('emergency_contacts')
          .doc(contactId)
          .set({
        'name': contactName,
        'added_at': FieldValue.serverTimestamp(),
      });

      // Clear search
      setState(() {
        _searchController.clear();
        _searchResults = [];
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency contact added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error adding emergency contact: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to add emergency contact'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteEmergencyContact(String contactId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('emergency_contacts')
          .doc(contactId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency contact removed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting emergency contact: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to remove emergency contact'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name or phone number',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: Colors.grey),
                  onPressed: () => _searchUsers(_searchController.text.trim()),
                ),
              ),
              onSubmitted: (value) => _searchUsers(value.trim()),
            ),
          ),

          // Search results
          if (_isSearching)
            const Center(child: CircularProgressIndicator())
          else if (_searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    title: Text(
                      user['name'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      user['phone'],
                      style: const TextStyle(color: Colors.grey),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add, color: Color(0xFFFF69B4)),
                      onPressed: () => _addEmergencyContact(
                        user['id'],
                        user['name'],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Existing emergency contacts
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUser?.uid)
                  .collection('emergency_contacts')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'Error loading contacts',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final contacts = snapshot.data?.docs ?? [];

                if (contacts.isEmpty && _searchResults.isEmpty) {
                  return const Center(
                    child: Text(
                      'No emergency contacts added yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF69B4),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            contact['name'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                            onPressed: () => _deleteEmergencyContact(contact.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 