import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'track_me_screen.dart';
import '../widgets/sos_button.dart';
import '../widgets/bottom_nav_bar.dart';

class ShareLocationScreen extends StatefulWidget {
  const ShareLocationScreen({Key? key}) : super(key: key);

  @override
  State<ShareLocationScreen> createState() => _ShareLocationScreenState();
}

class _ShareLocationScreenState extends State<ShareLocationScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedContacts = {};
  int _selectedDuration = 8; // Default to 8 hours
  List<Map<String, dynamic>> _contacts = [];
  List<Map<String, dynamic>> _filteredContacts = [];
  bool _isLoading = true;
  List<Map<String, dynamic>> _contactGroups = []; // Add state variable for groups
  Set<String> _selectedGroups = {}; // Add state variable for selected groups

  @override
  void initState() {
    super.initState();
    _loadContactsAndGroups(); // Call the new loading method
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
        return contact['name'].toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _loadContactsAndGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load Contacts
        final contactsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('emergency_contacts')
            .get();

        // Load Groups (fetch from existing sos_groups)
        final groupsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('sos_groups') // **Fetch from sos_groups**
            .get();

        setState(() {
          _contacts = contactsSnapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    'name': doc['name'] as String,
                    // Include other contact fields if needed
                  })
              .toList();
          _filteredContacts = _contacts; // Initialize filtered contacts

          _contactGroups = groupsSnapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    'name': doc['name'] as String,
                    'members': List<String>.from(doc['members'] ?? []), // List of contact IDs
                  })
              .toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading contacts and groups: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleContact(String contactId) {
    setState(() {
      if (_selectedContacts.contains(contactId)) {
        _selectedContacts.remove(contactId);
        // If contact is deselected, also deselect any groups that were fully selected and contained this contact
        _selectedGroups.removeWhere((groupId) {
          final group = _contactGroups.firstWhere((g) => g['id'] == groupId);
          // Only deselect the group if the removed contact was the last selected member from that group
          // This part of the logic can become complex if contacts can be in multiple groups.
          // For simplicity now, we'll just check if the contact is in the group.
          return (group['members'] as List<String>).contains(contactId);
        });
      } else {
        _selectedContacts.add(contactId);
        // When a contact is selected, we don't automatically select its groups.
      }
    });
  }

  void _toggleGroup(String groupId) {
    setState(() {
      final group = _contactGroups.firstWhere((g) => g['id'] == groupId);
      final members = List<String>.from(group['members'] ?? []); // Ensure members is a List<String>

      if (_selectedGroups.contains(groupId)) {
        _selectedGroups.remove(groupId);
        // Deselect all contacts in this group
        _selectedContacts.removeAll(members);
      } else {
        _selectedGroups.add(groupId);
        // Select all contacts in this group
        _selectedContacts.addAll(members);
      }
    });
  }

  void _startSharing() async {
    if (_selectedContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one contact')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Create a new location sharing session
        final sessionRef = await FirebaseFirestore.instance
            .collection('location_sharing')
            .add({
          'userId': user.uid,
          'sharedWith': _selectedContacts.toList(),
          'startTime': FieldValue.serverTimestamp(),
          'duration': _selectedDuration,
          'active': true,
        });

        if (!mounted) return;
        Navigator.pop(context, {
          'sessionId': sessionRef.id,
          'sharedWith': _selectedContacts.toList(),
          'duration': _selectedDuration,
        });
      }
    } catch (e) {
      print('Error starting location sharing: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error starting location sharing')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Share Location',
          style: TextStyle(
            color: Color(0xFFFF69B4),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Select ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'friends & ',
                      style: TextStyle(
                        color: Color(0xFFFF69B4),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: '\nshare your ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'live\n',
                      style: TextStyle(
                        color: Color(0xFFFF69B4),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: 'location.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type to search',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Contact Groups',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
                )
              else if (_contactGroups.isEmpty)
                const Text(
                  'No contact groups found',
                  style: TextStyle(color: Colors.grey),
                )
              else
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _contactGroups.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final group = _contactGroups[index];
                      final isSelected = _selectedGroups.contains(group['id']);
                      return GestureDetector(
                        onTap: () => _toggleGroup(group['id']),
                        child: Chip(
                          label: Text(group['name'], style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0))),
                          backgroundColor: isSelected ? const Color(0xFFFF69B4) : Colors.white.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFFFF69B4) : Colors.transparent,
                              width: 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Emergency Contacts',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
                )
              else if (_filteredContacts.isEmpty)
                const Center(
                  child: Text(
                    'No contacts found',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filteredContacts.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      final isSelected = _selectedContacts.contains(contact['id']);
                      return GestureDetector(
                        onTap: () => _toggleContact(contact['id']),
                        child: _buildContactAvatar(contact, isSelected),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Live location duration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDurationOption(1, '1 hr'),
                  _buildDurationOption(8, '8 hr'),
                  _buildDurationOption(12, '12 hr'),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startSharing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildDurationOption(int hours, String label) {
    final isSelected = _selectedDuration == hours;
    return GestureDetector(
      onTap: () => setState(() => _selectedDuration = hours),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFFFF69B4) : Colors.grey,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFF69B4) : Colors.grey,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildContactAvatar(Map<String, dynamic> contact, bool isSelected) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFFF69B4),
              child: Text(
                contact['name'][0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF69B4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          contact['name'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 