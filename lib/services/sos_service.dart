import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class SOSService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _locationUpdateTimer;
  String? _currentAlertId;

  Future<void> sendSOSAlert() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get user's emergency contacts
      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .get();

      // Get user's name
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Unknown User';

      // Calculate end time (12 hours from now)
      final endTime = DateTime.now().add(const Duration(hours: 12));

      // Create SOS alert document
      final sosRef = await _firestore.collection('sos_alerts').add({
        'userId': user.uid,
        'userName': userName,
        'location': GeoPoint(position.latitude, position.longitude),
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'I need help',
        'status': 'active',
        'endTime': endTime,
        'notifiedContacts': contactsSnapshot.docs.map((doc) => doc.id).toList(),
      });

      _currentAlertId = sosRef.id;

      // Notify each emergency contact
      for (var contact in contactsSnapshot.docs) {
        final contactData = contact.data();
        await _firestore
            .collection('emergency_notifications')
            .add({
              'sosAlertId': sosRef.id,
              'userId': user.uid,
              'userName': userName,
              'contactName': contactData['name'],
              'contactPhone': contactData['phone'],
              'message': 'I need help',
              'location': GeoPoint(position.latitude, position.longitude),
              'timestamp': FieldValue.serverTimestamp(),
              'endTime': endTime,
              'status': 'sent',
            });
      }

      // Start periodic location updates
      _startLocationUpdates();

      // Schedule alert deactivation after 12 hours
      Timer(const Duration(hours: 12), () {
        if (_currentAlertId == sosRef.id) {
          cancelSOSAlert(sosRef.id);
        }
      });

    } catch (e) {
      print('Error sending SOS alert: $e');
      rethrow;
    }
  }

  void _startLocationUpdates() {
    // Cancel any existing timer
    _locationUpdateTimer?.cancel();

    // Update location every 1 minute
    _locationUpdateTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (_currentAlertId == null) {
        timer.cancel();
        return;
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        await _firestore
            .collection('sos_alerts')
            .doc(_currentAlertId)
            .update({
              'location': GeoPoint(position.latitude, position.longitude),
              'lastLocationUpdate': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        print('Error updating location: $e');
      }
    });
  }

  Future<void> cancelSOSAlert(String alertId) async {
    try {
      await _firestore
          .collection('sos_alerts')
          .doc(alertId)
          .update({
            'status': 'canceled',
            'endTime': FieldValue.serverTimestamp(),
          });

      if (_currentAlertId == alertId) {
        _currentAlertId = null;
        _locationUpdateTimer?.cancel();
      }
    } catch (e) {
      print('Error canceling SOS alert: $e');
      rethrow;
    }
  }

  void dispose() {
    _locationUpdateTimer?.cancel();
  }

  Future<void> shareLocationWithEmergencyContacts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get user's emergency contacts
      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .get();

      // Get user's name
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Unknown User';

      // Create location sharing session
      await _firestore.collection('location_sharing').add({
        'userId': user.uid,
        'userName': userName,
        'lastLocation': GeoPoint(position.latitude, position.longitude),
        'startTime': FieldValue.serverTimestamp(),
        'lastUpdate': FieldValue.serverTimestamp(),
        'duration': 12, // 12 hours
        'active': true,
        'isEmergency': true,
        'sharedWith': contactsSnapshot.docs.map((doc) => doc.id).toList(),
      });

    } catch (e) {
      print('Error sharing location with emergency contacts: $e');
      rethrow;
    }
  }
} 