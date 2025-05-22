import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/emergency_contacts_screen.dart';
import '../screens/login_screen.dart';

class AppMenu extends StatelessWidget {
  final Function(String)? onNameUpdate;
  final AuthService _authService = AuthService();

  AppMenu({Key? key, this.onNameUpdate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.menu, color: Colors.white),
      color: Colors.white,
      itemBuilder: (context) => [
        PopupMenuItem(
          child: const Text(
            'Profile',
            style: TextStyle(color: Colors.black),
          ),
          onTap: () async {
            await Future.delayed(Duration.zero);
            if (!context.mounted) return;
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const EditProfileScreen()),
            );
            if (result == true && onNameUpdate != null) {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                final userData = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .get();
                if (userData.exists) {
                  onNameUpdate!(userData['name'] ?? 'User');
                }
              }
            }
          },
        ),
        PopupMenuItem(
          child: const Text(
            'Emergency Contacts',
            style: TextStyle(color: Colors.black),
          ),
          onTap: () async {
            await Future.delayed(Duration.zero);
            if (!context.mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EmergencyContactsScreen(),
              ),
            );
          },
        ),
        PopupMenuItem(
          child: const Text(
            'About',
            style: TextStyle(color: Colors.black),
          ),
          onTap: () async {
            await Future.delayed(Duration.zero);
            if (!context.mounted) return;
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.black,
                  title: const Text(
                    'About BeSafe',
                    style: TextStyle(
                      color: Color(0xFFFF69B4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BeSafe is your personal safety companion, designed to provide quick access to emergency services and safety features.',
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Version: 1.0.0',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Color(0xFFFF69B4)),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        PopupMenuItem(
          child: const Text(
            'Logout',
            style: TextStyle(color: Colors.black),
          ),
          onTap: () async {
            await _authService.signOut();
            if (!context.mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
      ],
    );
  }
} 