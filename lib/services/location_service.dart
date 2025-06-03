import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<Position>? _positionSubscription;
  String? _activeSharingSessionId;
  bool _isTracking = false;

  bool get isTracking => _isTracking;

  Future<void> startBackgroundTracking(String sessionId) async {
    if (_isTracking) return;

    try {
      // Request necessary permissions
      await Permission.locationWhenInUse.request();
      await Permission.locationAlways.request();

      _activeSharingSessionId = sessionId;
      _isTracking = true;

      // Start location updates
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Update every 5 meters
          timeLimit: Duration(seconds: 10), // Force update every 10 seconds
        ),
      ).listen((Position position) {
        _updateLocationInFirestore(position);
      });

    } catch (e) {
      print('Error starting background tracking: $e');
      _isTracking = false;
      rethrow;
    }
  }

  Future<void> stopBackgroundTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _activeSharingSessionId = null;
    _isTracking = false;
  }

  Future<void> _updateLocationInFirestore(Position position) async {
    try {
      final user = _auth.currentUser;
      if (user != null && _activeSharingSessionId != null) {
        await _firestore
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

  void dispose() {
    _positionSubscription?.cancel();
    _isTracking = false;
  }
} 