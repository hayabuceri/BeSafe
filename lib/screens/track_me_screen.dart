import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'share_location_screen.dart';
import 'home_screen.dart';
import 'edit_profile_screen.dart';
import 'emergency_contacts_screen.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/sos_button.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/app_menu.dart';

class TrackMeScreen extends StatefulWidget {
  const TrackMeScreen({Key? key}) : super(key: key);

  @override
  State<TrackMeScreen> createState() => _TrackMeScreenState();
}

class _TrackMeScreenState extends State<TrackMeScreen> with WidgetsBindingObserver {
  bool _isTracking = false;
  Position? _currentPosition;
  Stream<Position>? _positionStream;
  StreamSubscription<Position>? _positionSubscription;
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  String? _activeSharingSessionId;
  Set<String> _sharedWithContacts = {};
  int _selectedDuration = 8; // Default duration
  DateTime? _sessionStartTime;
  Timer? _timer;
  String _remainingTime = '';

  @override   
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getCurrentLocation();
    _checkActiveSharingSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_isTracking) {
      _stopTracking();
    }
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _activeSharingSessionId != null) {
      _resumeTracking();
    }
  }

  Future<void> _checkActiveSharingSession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final activeSession = await FirebaseFirestore.instance
            .collection('location_sharing')
            .where('userId', isEqualTo: user.uid)
            .where('active', isEqualTo: true)
            .get();

        if (activeSession.docs.isNotEmpty && mounted) {
          final session = activeSession.docs.first;
          final data = session.data();
          
          setState(() {
            _activeSharingSessionId = session.id;
            _sharedWithContacts = (data['sharedWith'] as List).map((e) => e.toString()).toSet();
            _selectedDuration = data['duration'] as int;
            _sessionStartTime = (data['startTime'] as Timestamp).toDate();
          });

          await _startTracking();
          _startTimer();
        }
      }
    } catch (e) {
      print('Error checking active session: $e');
    }
  }

  Future<void> _resumeTracking() async {
    if (_activeSharingSessionId != null && !_isTracking) {
      await _startTracking();
    }
  }

  Future<void> _getCurrentLocation() async {
    final status = await Permission.location.request();
    if (status.isDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required')),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _updateMarkers(position);
      });
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  void _updateMarkers(Position position) {
    setState(() {
      _markers = [
        Marker(
          point: LatLng(position.latitude, position.longitude),
          child: const Icon(
            Icons.location_on,
            color: Color(0xFFFF69B4),
            size: 40,
          ),
        ),
      ];
    });
  }

  Future<void> _startTracking() async {
    final status = await Permission.location.request();
    if (status.isDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission is required')),
      );
      return;
    }

    setState(() {
      _isTracking = true;
    });

    try {
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      _positionSubscription = _positionStream?.listen((Position position) {
        if (!mounted) return;
        setState(() {
          _currentPosition = position;
          _updateMarkers(position);
        });
        
        if (_mapController.camera.center != LatLng(position.latitude, position.longitude)) {
          _mapController.move(
            LatLng(position.latitude, position.longitude),
            _mapController.camera.zoom,
          );
        }
        
        _updateLocationInFirestore(position);
      });

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTracking = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error starting location tracking')),
      );
    }
  }

  void _startTimer() {
    if (_sessionStartTime == null) return;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final endTime = _sessionStartTime!.add(Duration(hours: _selectedDuration));
      final remaining = endTime.difference(now);

      if (remaining.isNegative) {
        _stopTracking();
        return;
      }

      setState(() {
        final hours = remaining.inHours;
        final minutes = remaining.inMinutes % 60;
        final seconds = remaining.inSeconds % 60;
        _remainingTime = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      });
    });
  }

  Future<void> _stopTracking() async {
    if (_positionSubscription != null) {
      await _positionSubscription?.cancel();
      _positionSubscription = null;
    }
    _timer?.cancel();
    
    // End the sharing session
    if (_activeSharingSessionId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('location_sharing')
            .doc(_activeSharingSessionId)
            .update({
          'active': false,
          'endTime': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        print('Error ending sharing session: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _isTracking = false;
      _activeSharingSessionId = null;
      _sharedWithContacts.clear();
      _sessionStartTime = null;
      _remainingTime = '';
    });
  }

  Future<void> _updateLocationInFirestore(Position position) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _activeSharingSessionId != null) {
        await FirebaseFirestore.instance
            .collection('location_sharing')
            .doc(_activeSharingSessionId)
            .update({
          'lastLocation': GeoPoint(position.latitude, position.longitude),
          'lastUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating location in Firestore: $e');
    }
  }

  Future<void> _onTrackMePressed() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ShareLocationScreen()),
    );

    if (result != null && mounted) {
      final sessionId = result['sessionId'] as String;
      final sharedWith = result['sharedWith'] as List<String>;
      final duration = result['duration'] as int;
      
      setState(() {
        _activeSharingSessionId = sessionId;
        _sharedWithContacts = sharedWith.toSet();
        _selectedDuration = duration;
        _sessionStartTime = DateTime.now();
      });

      // Start tracking with the selected contacts
      await _startTracking();
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Don't stop tracking when navigating back
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text(
            'Track Me',
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
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: Colors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Track me',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isTracking 
                        ? 'Sharing location with ${_sharedWithContacts.length} contacts'
                        : 'Share live location with your friends',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  if (_isTracking) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF69B4).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Color(0xFFFF69B4),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Time remaining: $_remainingTime',
                            style: const TextStyle(
                              color: Color(0xFFFF69B4),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: _currentPosition == null
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF69B4)))
                  : FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        initialZoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.besafe_app',
                        ),
                        MarkerLayer(markers: _markers),
                      ],
                    ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isTracking ? _stopTracking : _onTrackMePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isTracking ? Colors.red : const Color(0xFFFF69B4),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  _isTracking ? 'Stop Sharing' : 'Share Location',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      ),
    );
  }
} 