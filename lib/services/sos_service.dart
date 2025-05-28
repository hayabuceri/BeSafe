import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class SOSService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _locationUpdateTimer;
  String? _currentAlertId;

  Future<void> sendSOSAlert({
    required String groupId,
    required String message,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Cancel any existing active SOS alerts for this user
      final activeAlerts = await _firestore
          .collection('sos_alerts')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .get();
      for (var doc in activeAlerts.docs) {
        await doc.reference.update({
          'status': 'canceled',
          'endTime': FieldValue.serverTimestamp(),
        });
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get SOS group members
      final groupDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('sos_groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        throw Exception('SOS group not found');
      }

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final memberIds = List<String>.from(groupData['members'] ?? []);

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
        'message': message,
        'status': 'active',
        'endTime': endTime,
        'groupId': groupId,
        'notifiedMembers': memberIds,
      });

      _currentAlertId = sosRef.id;

      // Get group members' data
      final membersSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('emergency_contacts')
          .where(FieldPath.documentId, whereIn: memberIds)
          .get();

      // Notify each group member
      for (var member in membersSnapshot.docs) {
        final memberData = member.data();
        await _firestore
            .collection('emergency_notifications')
            .add({
              'sosAlertId': sosRef.id,
              'userId': user.uid,
              'userName': userName,
              'contactName': memberData['name'],
              'contactPhone': memberData['phone'],
              'message': message,
              'location': GeoPoint(position.latitude, position.longitude),
              'timestamp': FieldValue.serverTimestamp(),
              'endTime': endTime,
              'status': 'sent',
              'groupId': groupId,
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
}