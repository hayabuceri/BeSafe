import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'dart:math' show min, max;
import 'home_screen.dart';
import 'track_me_screen.dart';
import 'edit_profile_screen.dart';
import 'emergency_contacts_screen.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SharedLocationsScreen extends StatefulWidget {
  const SharedLocationsScreen({Key? key}) : super(key: key);

  @override
  State<SharedLocationsScreen> createState() => _SharedLocationsScreenState();
}

class _SharedLocationsScreenState extends State<SharedLocationsScreen> {
  final MapController _mapController = MapController();
  String? _selectedUserId;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Shared Locations',
          style: TextStyle(
            color: Color(0xFFFF69B4),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              showMenu(
                context: context,
                position: const RelativeRect.fromLTRB(100, 80, 0, 0),
                items: [
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
                      if (result == true) {
                        setState(() {}); // Refresh the screen
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
            },
          ),
        ],
      ),
      body: currentUser == null
          ? const Center(child: Text('Please sign in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('location_sharing')
                  .where('active', isEqualTo: true)
                  .where('sharedWith', arrayContains: currentUser.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF69B4))
                  );
                }

                final sessions = snapshot.data!.docs;
                if (sessions.isEmpty) {
                  return const Center(
                    child: Text(
                      'No active location sharing',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                if (_selectedUserId == null) {
                  // Show list of friends sharing location
                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final data = session.data() as Map<String, dynamic>;
                      final userId = data['userId'] as String;
                      
                      // Add null check for location
                      final locationData = data['lastLocation'];
                      if (locationData == null) {
                        return ListTile(
                          title: FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .get(),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData) {
                                return const Text('Loading...', style: TextStyle(color: Colors.white));
                              }
                              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                              final userName = userData?['name'] ?? 'Unknown User';
                              return Text(
                                '$userName (Location not available)',
                                style: const TextStyle(color: Colors.white),
                              );
                            },
                          ),
                          tileColor: Colors.white.withOpacity(0.1),
                        );
                      }
                      
                      final location = locationData as GeoPoint;
                      
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(userId)
                            .get(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          final userName = userData['name'] ?? 'Unknown User';

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedUserId = userId;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF69B4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Tap to view location',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.7),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                } else {
                  // Show selected friend's map
                  final selectedSession = sessions.firstWhere(
                    (session) => session['userId'] == _selectedUserId,
                  );
                  
                  // Add null check for location
                  final locationData = selectedSession['lastLocation'];
                  if (locationData == null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_off, color: Colors.white, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Location data is not available',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedUserId = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF69B4),
                            ),
                            child: const Text('Go Back', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final location = locationData as GeoPoint;
                  final position = LatLng(location.latitude, location.longitude);

                  return Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: position,
                          initialZoom: 15,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.besafe_app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: position,
                                width: 80,
                                height: 80,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 35,
                                      height: 35,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFF69B4),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.location_on,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Back button to return to friends list
                      Positioned(
                        top: 16,
                        left: 16,
                        child: FloatingActionButton.small(
                          backgroundColor: Colors.black87,
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _selectedUserId = null;
                            });
                          },
                        ),
                      ),
                      // Navigation button
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          backgroundColor: const Color(0xFFFF69B4),
                          onPressed: () {
                            final url = 'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}';
                            launchUrl(Uri.parse(url));
                          },
                          child: const Icon(Icons.directions, color: Colors.white),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFFFF69B4),
        unselectedItemColor: Colors.white,
        currentIndex: 2, // Track Me tab
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (index == 1) {
            // SOS button - keep on current screen
          } else if (index == 2) {
            // Already on Track Me screen
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency),
            label: 'SOS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Track Me',
          ),
        ],
      ),
    );
  }
} 