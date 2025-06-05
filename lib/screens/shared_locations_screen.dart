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
import '../widgets/custom_app_bar.dart';
import '../widgets/sos_button.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_menu.dart';

class SharedLocationsScreen extends StatefulWidget {
  const SharedLocationsScreen({Key? key}) : super(key: key);

  @override
  State<SharedLocationsScreen> createState() => _SharedLocationsScreenState();
}

class _SharedLocationsScreenState extends State<SharedLocationsScreen> {
  final MapController _mapController = MapController();
  String? _selectedUserId;
  final AuthService _authService = AuthService();
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      initialIndex: _selectedTab,
      child: Scaffold(
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
            AppMenu(),
          ],
          bottom: TabBar(
            indicatorColor: const Color(0xFFFF69B4),
            labelColor: const Color(0xFFFF69B4),
            unselectedLabelColor: Colors.white,
            tabs: const [
              Tab(text: 'Location Sharing'),
              Tab(text: 'SOS'),
            ],
            onTap: (index) {
              setState(() {
                _selectedTab = index;
              });
            },
          ),
        ),
        body: currentUser == null
            ? const Center(child: Text('Please sign in'))
            : TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Location Sharing Tab
                  StreamBuilder<QuerySnapshot>(
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
                  // SOS Tab
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('sos_alerts')
                        .where('status', isEqualTo: 'active')
                        .where('notifiedMembers', arrayContains: currentUser.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFFFF69B4))
                        );
                      }
                      final sosAlerts = snapshot.data!.docs;
                      if (sosAlerts.isEmpty) {
                        return const Center(
                          child: Text(
                            'No active SOS alerts',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }
                      return ListView.builder(
                        itemCount: sosAlerts.length,
                        itemBuilder: (context, index) {
                          final alert = sosAlerts[index];
                          final alertId = alert.id;
                          return StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('sos_alerts')
                                .doc(alertId)
                                .snapshots(),
                            builder: (context, alertSnapshot) {
                              if (!alertSnapshot.hasData || !alertSnapshot.data!.exists) {
                                return const SizedBox.shrink();
                              }
                              final data = alertSnapshot.data!.data() as Map<String, dynamic>;
                              final senderName = data['userName'] ?? 'Unknown';
                              final message = data['message'] ?? '';
                              final endTime = (data['endTime'] as Timestamp).toDate();
                              final location = data['location'] as GeoPoint?;
                              return Card(
                                color: Colors.white.withOpacity(0.08),
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.warning, color: Colors.red, size: 20),
                                          const SizedBox(width: 8),
                                          Text(
                                            'SOS from $senderName',
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const Spacer(),
                                          _SOSCountdownLabel(endTime: endTime, alertId: alertId),
                                          if (location != null)
                                            IconButton(
                                              icon: const Icon(Icons.navigation, color: Color(0xFFFF69B4)),
                                              onPressed: () {
                                                final url = 'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}';
                                                launchUrl(Uri.parse(url));
                                              },
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (message.isNotEmpty)
                                        Text(
                                          message,
                                          style: const TextStyle(color: Colors.white, fontSize: 15),
                                        ),
                                      if (location != null) ...[
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          height: 180,
                                          child: FlutterMap(
                                            options: MapOptions(
                                              initialCenter: LatLng(location.latitude, location.longitude),
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
                                                    point: LatLng(location.latitude, location.longitude),
                                                    width: 40,
                                                    height: 40,
                                                    child: Container(
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
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      ),
    );
  }
}

class _SOSCountdownLabel extends StatefulWidget {
  final DateTime endTime;
  final String alertId;
  const _SOSCountdownLabel({Key? key, required this.endTime, required this.alertId}) : super(key: key);

  @override
  State<_SOSCountdownLabel> createState() => _SOSCountdownLabelState();
}

class _SOSCountdownLabelState extends State<_SOSCountdownLabel> {
  Timer? _timer;
  String _remaining = '';

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final now = DateTime.now();
    final diff = widget.endTime.difference(now);
    if (diff.isNegative) {
      setState(() {
        _remaining = '00:00:00';
      });
      _timer?.cancel();

      FirebaseFirestore.instance
          .collection('sos_alerts')
          .doc(widget.alertId)
          .update({'status': 'expired', 'endTime': FieldValue.serverTimestamp()})
          .catchError((error) {
            print('Error updating SOS status: $error');
          });

      return;
    }
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    setState(() {
      _remaining = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer, color: Colors.red, size: 14),
          const SizedBox(width: 2),
          Text(
            _remaining,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
} 