import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import '../widgets/custom_app_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:intl/intl.dart';

class MySOSAlertScreen extends StatefulWidget {
  const MySOSAlertScreen({Key? key}) : super(key: key);

  @override
  State<MySOSAlertScreen> createState() => _MySOSAlertScreenState();
}

class _MySOSAlertScreenState extends State<MySOSAlertScreen> {
  final MapController _mapController = MapController();
  GeoPoint? _sosLocation;
  DateTime? _sosEndTime;
  String _sosRemainingTime = '';
  Timer? _sosTimer;
  String? _sosAlertId;

  @override
  void initState() {
    super.initState();
    _fetchActiveSOSAlert();
  }

  @override
  void dispose() {
    _sosTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchActiveSOSAlert() async {
    print('MySOSAlertScreen: _fetchActiveSOSAlert starting...');
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('MySOSAlertScreen: _fetchActiveSOSAlert - User is null.');
      setState(() {
        _sosAlertId = null;
        _sosLocation = null;
        _sosEndTime = null;
        _sosRemainingTime = '';
      });
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sos_alerts')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      print('MySOSAlertScreen: _fetchActiveSOSAlert - Snapshot received. Docs found: ${snapshot.docs.length}');

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final endTime = (data['endTime'] as Timestamp).toDate();
        final GeoPoint location = data['location'] as GeoPoint;

        print('MySOSAlertScreen: _fetchActiveSOSAlert - Active SOS found. ID: ${doc.id}, EndTime: $endTime, Location: ${location.latitude}, ${location.longitude}');

        setState(() {
          _sosAlertId = doc.id;
          _sosLocation = location;
          _sosEndTime = endTime;
        });
        print('MySOSAlertScreen: _fetchActiveSOSAlert - State updated after finding active SOS.');
        _startSOSTimer();
      } else {
        print('MySOSAlertScreen: _fetchActiveSOSAlert - No active SOS found in snapshot.');
        setState(() {
          _sosAlertId = null;
          _sosLocation = null;
          _sosEndTime = null;
          _sosRemainingTime = '';
        });
        _sosTimer?.cancel();
        print('MySOSAlertScreen: _fetchActiveSOSAlert - State updated after no active SOS found.');
      }
    } catch (e) {
      print('MySOSAlertScreen: _fetchActiveSOSAlert - Error: $e');
      setState(() {
        _sosAlertId = null;
        _sosLocation = null;
        _sosEndTime = null;
        _sosRemainingTime = '';
      });
       _sosTimer?.cancel(); // Cancel timer on error
    }
     print('MySOSAlertScreen: _fetchActiveSOSAlert finished. State: _sosAlertId=$_sosAlertId, _sosLocation=$_sosLocation');
  }

  void _startSOSTimer() {
    print('MySOSAlertScreen: _startSOSTimer starting...');
    _sosTimer?.cancel();
    if (_sosEndTime == null) {
      print('MySOSAlertScreen: _startSOSTimer - _sosEndTime is null. Timer not started.');
      setState(() {
         _sosRemainingTime = ''; // Ensure remaining time is empty if end time is null
      });
      return;
    }

    _sosTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final remaining = _sosEndTime!.difference(now);

      if (remaining.isNegative) {
        print('MySOSAlertScreen: _startSOSTimer - Timer finished.');
        setState(() {
          _sosRemainingTime = '00:00:00';
          // We don't set _sosAlertId, _sosLocation, _sosEndTime to null here
          // because the screen should still show the last known location/details
          // until _fetchActiveSOSAlert runs again and finds no active alert.
        });
        timer.cancel();
        // Optionally trigger _fetchActiveSOSAlert here to update the UI to 'no active SOS'
        // or rely on the HomeScreen's StreamBuilder to eventually remove the button.
        return;
      }

      setState(() {
        final hours = remaining.inHours;
        final minutes = remaining.inMinutes % 60;
        final seconds = remaining.inSeconds % 60;
        _sosRemainingTime = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      });
      // print('MySOSAlertScreen: _startSOSTimer - Remaining time updated: $_sosRemainingTime');
    });
     print('MySOSAlertScreen: _startSOSTimer - Timer started.');
  }

  Future<void> _stopSOSAlert() async {
    if (_sosAlertId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('sos_alerts')
            .doc(_sosAlertId)
            .update({
              'status': 'canceled',
              'endTime': FieldValue.serverTimestamp(),
            });

        setState(() {
          _sosAlertId = null;
          _sosLocation = null;
          _sosEndTime = null;
          _sosRemainingTime = '';
        });
        _sosTimer?.cancel();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS alert stopped.')),
        );
        Navigator.pop(context); // Go back after stopping
      } catch (e) {
        print('Error stopping SOS alert: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to stop SOS alert.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('MySOSAlertScreen: build method called. State: _sosAlertId=$_sosAlertId, _sosLocation=$_sosLocation, _sosRemainingTime=$_sosRemainingTime');
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const CustomAppBar(title: 'My Active SOS'),
      body: _sosLocation == null && _sosAlertId == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'No active SOS alert.',
                    style: TextStyle(color: Colors.white70, fontSize: 18),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Timer Display
                if (_sosRemainingTime.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer, color: Colors.red, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Time Remaining: $_sosRemainingTime',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Map Display
                Expanded(
                  child: _sosLocation != null
                      ? FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(
                              _sosLocation!.latitude,
                              _sosLocation!.longitude,
                            ),
                            initialZoom: 15,
                            // interactiveFlags: InteractiveFlag.all - ~InteractiveFlag.rotate,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.besafe_app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(
                                    _sosLocation!.latitude,
                                    _sosLocation!.longitude,
                                  ),
                                  width: 80,
                                  height: 80,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : const Center(
                          child: CircularProgressIndicator(color: Color(0xFFFF69B4)),
                        ),
                ),

                // Stop Button
                if (_sosAlertId != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _stopSOSAlert,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Stop SOS',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1), // Assuming SOS is index 1
    );
  }
} 