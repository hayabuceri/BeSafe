import 'package:flutter/material.dart';
import '../services/sos_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/manage_sos_groups_screen.dart';
import 'dart:async';

class SOSButton extends StatefulWidget {
  final bool isInNavigationBar;
  final VoidCallback? onPressed;

  const SOSButton({
    Key? key,
    this.isInNavigationBar = false,
    this.onPressed,
  }) : super(key: key);

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton> {
  final SOSService _sosService = SOSService();
  String _selectedMessage = 'I need help';
  final TextEditingController _customMessageController = TextEditingController();
  bool _isCustomMessage = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _customMessageController.dispose();
    super.dispose();
  }

  Future<void> _handleSOSTap() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get all SOS groups
    final groupsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('sos_groups')
        .get();

    if (groupsSnapshot.docs.isEmpty) {
      // Navigate to manage SOS groups screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ManageSOSGroupsScreen(),
        ),
      );
      return;
    }

    // Show group selection dialog
    final selectedGroup = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Select SOS Group',
            style: TextStyle(
              color: Color(0xFFFF69B4),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose a group to send SOS alert:',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: groupsSnapshot.docs.length,
                    itemBuilder: (context, index) {
                      final group = groupsSnapshot.docs[index];
                      final data = group.data();
                      return ListTile(
                        title: Text(
                          data['name'] ?? 'Unnamed Group',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          '${(data['members'] as List?)?.length ?? 0} members',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        onTap: () => Navigator.of(context).pop({
                          'id': group.id,
                          ...data,
                        }),
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
              onPressed: () {
                if (!mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageSOSGroupsScreen(),
                  ),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFF69B4),
              ),
              child: const Text(
                'MANAGE GROUPS',
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

    if (selectedGroup == null) return;

    // Show message selection dialog
    final bool? messageConfirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black,
              title: const Text(
                'SOS Message',
                style: TextStyle(
                  color: Color(0xFFFF69B4),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose or write your message:',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  RadioListTile<String>(
                    title: const Text(
                      'I need help',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: 'I need help',
                    groupValue: _selectedMessage,
                    activeColor: const Color(0xFFFF69B4),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedMessage = value!;
                        _isCustomMessage = false;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text(
                      'Custom message',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: 'custom',
                    groupValue: _isCustomMessage ? 'custom' : _selectedMessage,
                    activeColor: const Color(0xFFFF69B4),
                    onChanged: (String? value) {
                      setState(() {
                        _isCustomMessage = true;
                      });
                    },
                  ),
                  if (_isCustomMessage)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _customMessageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Enter your message',
                          hintStyle: TextStyle(color: Colors.white70),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white70),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFFFF69B4)),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedMessage = value;
                          });
                        },
                      ),
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
                    'SEND SOS',
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
      },
    );

    if (messageConfirmed != true || !mounted) return;

    try {
      final message = _isCustomMessage && _customMessageController.text.isNotEmpty
          ? _customMessageController.text
          : _selectedMessage;

      await _sosService.sendSOSAlert(
        groupId: selectedGroup['id'],
        message: message,
      );
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SOS alert sent to ${selectedGroup['name']}'),
          backgroundColor: const Color(0xFFFF69B4),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send SOS alert'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInNavigationBar) {
      return GestureDetector(
        onTap: _handleSOSTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFFF69B4), width: 2),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF69B4).withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'SOS',
            style: TextStyle(
              color: Color(0xFFFF69B4),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _handleSOSTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFFF69B4), width: 2),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF69B4).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'SOS',
          style: TextStyle(
            color: Color(0xFFFF69B4),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}