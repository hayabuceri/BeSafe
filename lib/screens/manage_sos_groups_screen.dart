import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';

class ManageSOSGroupsScreen extends StatefulWidget {
  const ManageSOSGroupsScreen({Key? key}) : super(key: key);

  @override
  State<ManageSOSGroupsScreen> createState() => _ManageSOSGroupsScreenState();
}

class _ManageSOSGroupsScreenState extends State<ManageSOSGroupsScreen> {
  final TextEditingController _groupNameController = TextEditingController();
  bool _isLoading = true;
  List<Map<String, dynamic>> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final groupsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('sos_groups')
            .get();

        setState(() {
          _groups = groupsSnapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading groups: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showCreateGroupDialog() async {
    _groupNameController.clear();
    final bool? create = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Create New SOS Group',
            style: TextStyle(
              color: Color(0xFFFF69B4),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _groupNameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Enter group name',
                  hintStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF69B4)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You will be able to select group members in the next step.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFF69B4),
              ),
              child: const Text(
                'NEXT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (create == true && _groupNameController.text.isNotEmpty) {
      await _createGroupAndSelectMembers(_groupNameController.text);
    }
  }

  Future<void> _createGroupAndSelectMembers(String name) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Create the group first
      final groupRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sos_groups')
          .add({
        'name': name,
        'members': [],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Load emergency contacts
      final contactsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .get();

      final contacts = contactsSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      if (!mounted) return;

      // Before showDialog
      final selectedIds = <String>{};

      final selectedMembers = await showDialog<List<String>>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async {
              Navigator.of(context).pop([]);
              return false;
            },
            child: StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: Colors.black,
                  title: const Text(
                    'Select Group Members',
                    style: TextStyle(
                      color: Color(0xFFFF69B4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Select contacts to add to this group:',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: contacts.length,
                            itemBuilder: (context, index) {
                              final contact = contacts[index];
                              return CheckboxListTile(
                                title: Text(
                                  contact['name'] ?? 'Unknown',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: contact['phone'] != null && contact['phone'].toString().isNotEmpty
                                    ? Text(
                                        contact['phone'],
                                        style: const TextStyle(color: Colors.white70),
                                      )
                                    : null,
                                value: selectedIds.contains(contact['id']),
                                activeColor: const Color(0xFFFF69B4),
                                checkColor: Colors.white,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedIds.add(contact['id']);
                                    } else {
                                      selectedIds.remove(contact['id']);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop([]),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(selectedIds.toList()),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFFF69B4),
                      ),
                      child: const Text(
                        'SAVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );

      if (selectedMembers != null) {
        // Update the group with selected members
        await groupRef.update({
          'members': selectedMembers,
        });

        await _loadGroups();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS group created successfully'),
            backgroundColor: Color(0xFFFF69B4),
          ),
        );
      } else {
        // If user cancels member selection, delete the group
        await groupRef.delete();
      }
    } catch (e) {
      print('Error creating group: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create SOS group'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteGroup(String groupId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Delete Group',
            style: TextStyle(
              color: Color(0xFFFF69B4),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this group?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'DELETE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('sos_groups')
            .doc(groupId)
            .delete();

        await _loadGroups();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group deleted successfully'),
            backgroundColor: Color(0xFFFF69B4),
          ),
        );
      } catch (e) {
        print('Error deleting group: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete group'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editGroupMembers(String groupId, List<dynamic> currentMembers) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Load emergency contacts
      final contactsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .get();

      final contacts = contactsSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      if (!mounted) return;

      // Pre-select current members
      final selectedIds = Set<String>.from(currentMembers);

      final updatedMembers = await showDialog<List<String>>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async {
              Navigator.of(context).pop(null);
              return false;
            },
            child: StatefulBuilder(
              builder: (context, setState) {
                return AlertDialog(
                  backgroundColor: Colors.black,
                  title: const Text(
                    'Edit Group Members',
                    style: TextStyle(
                      color: Color(0xFFFF69B4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Select contacts to add to this group:',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: contacts.length,
                            itemBuilder: (context, index) {
                              final contact = contacts[index];
                              return CheckboxListTile(
                                title: Text(
                                  contact['name'] ?? 'Unknown',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                subtitle: contact['phone'] != null && contact['phone'].toString().isNotEmpty
                                    ? Text(
                                        contact['phone'],
                                        style: const TextStyle(color: Colors.white70),
                                      )
                                    : null,
                                value: selectedIds.contains(contact['id']),
                                activeColor: const Color(0xFFFF69B4),
                                checkColor: Colors.white,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedIds.add(contact['id']);
                                    } else {
                                      selectedIds.remove(contact['id']);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(selectedIds.toList()),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFFF69B4),
                      ),
                      child: const Text(
                        'SAVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );

      if (updatedMembers != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('sos_groups')
            .doc(groupId)
            .update({'members': updatedMembers});
        await _loadGroups();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group members updated'),
            backgroundColor: Color(0xFFFF69B4),
          ),
        );
      }
    } catch (e) {
      print('Error editing group: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update group members'),
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
        title: 'Manage SOS Groups',
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: _showCreateGroupDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF69B4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Create New Group',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _groups.isEmpty
                      ? const Center(
                          child: Text(
                            'No SOS groups yet',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _groups.length,
                          itemBuilder: (context, index) {
                            final group = _groups[index];
                            return Card(
                              color: Colors.grey[900],
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                title: Text(
                                  group['name'] ?? 'Unnamed Group',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  '${(group['members'] as List?)?.length ?? 0} members',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Color(0xFFFF69B4),
                                      ),
                                      onPressed: () => _editGroupMembers(group['id'], group['members'] ?? []),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _deleteGroup(group['id']),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
} 