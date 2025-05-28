import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';

class CreateSOSGroupScreen extends StatefulWidget {
  const CreateSOSGroupScreen({Key? key}) : super(key: key);

  @override
  State<CreateSOSGroupScreen> createState() => _CreateSOSGroupScreenState();
}

class _CreateSOSGroupScreenState extends State<CreateSOSGroupScreen> {
  final Set<String> _selectedContacts = {};
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContacts);
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        return contact['name'].toLowerCase().contains(query) ||
            contact['phone'].toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final contactsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('emergency_contacts')
            .get();

        setState(() {
          _contacts = contactsSnapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();
          _filteredContacts = List.from(_contacts);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading contacts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createSOSGroup() async {
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one contact'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Create SOS group
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sos_groups')
          .doc('sos_members')
          .set({
        'name': 'SOS Members',
        'members': _selectedContacts.toList(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS group created successfully'),
          backgroundColor: Color(0xFFFF69B4),
        ),
      );
    } catch (e) {
      print('Error creating SOS group: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create SOS group'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: 'Create SOS Group',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search contacts',
                hintStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
                  )
                : _filteredContacts.isEmpty
                    ? const Center(
                        child: Text(
                          'No contacts found',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _filteredContacts[index];
                          return CheckboxListTile(
                            title: Text(
                              contact['name'] ?? 'Unknown',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              contact['phone'] ?? '',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            value: _selectedContacts.contains(contact['id']),
                            activeColor: const Color(0xFFFF69B4),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedContacts.add(contact['id']);
                                } else {
                                  _selectedContacts.remove(contact['id']);
                                }
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSOSGroup,
        backgroundColor: const Color(0xFFFF69B4),
        icon: const Icon(Icons.save),
        label: const Text('Create Group'),
      ),
    );
  }
}