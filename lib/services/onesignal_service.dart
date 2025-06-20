import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OneSignalService {
  // Singleton pattern
  static final OneSignalService _instance = OneSignalService._internal();
  factory OneSignalService() => _instance;
  OneSignalService._internal();

  // Your OneSignal App ID - replace with your actual App ID if needed
  final String oneSignalAppId = "a6f7512a-ede1-47b1-b48e-e7db720e20cc";

  // Your OneSignal REST API Key - Add your actual REST API key here
  final String restApiKey = "os_v2_app_u33vckxn4fd3dneo47nxedrazq7aocw3qqge6kfkazeu5nicyglvccsh7bt6o5mdcknofnvss3e3dpgwqtfjii4pnt4zwdmi5455sja";

  Future<void> initialize() async {
    try {
      debugPrint("Initializing OneSignal with App ID: $oneSignalAppId");

      // Set OneSignal log level
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

      // Initialize OneSignal
      OneSignal.initialize(oneSignalAppId);

      // Request permission for notifications
      final permission = await OneSignal.Notifications.requestPermission(true);
      debugPrint("OneSignal permission granted: $permission");

      // Set notification handlers
      _setNotificationHandlers();

      // Save player ID to user profile
      await _savePlayerIdToUserProfile();

      // Listen for booking updates
      _listenToBookingUpdates();

      debugPrint("OneSignal initialized successfully");
    } catch (e) {
      debugPrint("Error initializing OneSignal: $e");
    }
  }

  void _setNotificationHandlers() {
    // Handle notifications when app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      debugPrint(
          'NOTIFICATION WILL DISPLAY: ${event.notification.notificationId}');
      // Display the notification
      event.notification.display();
    });

    // Handle notification clicks
    OneSignal.Notifications.addClickListener((event) {
      debugPrint("NOTIFICATION CLICKED: ${event.notification.additionalData}");
      _handleNotificationOpened(event);
    });
  }

  Future<void> _savePlayerIdToUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint("No user logged in - can't save player ID");
      return;
    }

    try {
      // Get the device state to retrieve the player ID
      final userId = OneSignal.User.pushSubscription.id;
      debugPrint("OneSignal Player ID: $userId");

      if (userId != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'oneSignalPlayerId': userId,
        });
        debugPrint("OneSignal Player ID saved to user profile: $userId");
      }
    } catch (e) {
      debugPrint("Error saving OneSignal Player ID: $e");
    }
  }

  void _handleNotificationOpened(OSNotificationClickEvent event) {
    // Extract notification data
    final additionalData = event.notification.additionalData;
    if (additionalData == null) return;

    final notificationType = additionalData['notificationType'];
    final requestId = additionalData['requestId'];

    debugPrint(
        "Handling notification of type: $notificationType, requestId: $requestId");

    // Here you would implement navigation to the appropriate screen
    // based on notification type and ID
  }

  // Listen for booking updates where the current user is involved
  void _listenToBookingUpdates() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    debugPrint("Setting up Firestore listeners for notifications");

    // Listen to requests where user is the renter
    FirebaseFirestore.instance
        .collection('bookingRequests')
        .where('userId', isEqualTo: currentUser.uid)
        .where('notified', isEqualTo: false)
        .where('status', whereIn: ['approved', 'rejected'])
        .snapshots()
        .listen((snapshot) {
          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added ||
                change.type == DocumentChangeType.modified) {
              _handleRenterNotification(change.doc);
            }
          }
        });

    // Listen to requests where user is the owner
    FirebaseFirestore.instance
        .collection('bookingRequests')
        .where('ownerId', isEqualTo: currentUser.uid)
        .where('ownerNotified', isEqualTo: false)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          _handleOwnerNotification(change.doc);
        }
      }
    });
  }

  // Handle notifications for renters (responses from owners)
  Future<void> _handleRenterNotification(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] as String;
    final vehicleInfo = data['vehicleInfo'] as Map<String, dynamic>;
    final vehicleName = '${vehicleInfo['make']} ${vehicleInfo['model']}';
    final userId = data['userId'] as String;

    debugPrint("Handling renter notification for user $userId");

    String title, body;
    if (status == 'approved') {
      title = 'Booking Approved!';
      body =
          'Your booking request for $vehicleName has been approved. You can now proceed to payment.';
    } else {
      title = 'Booking Declined';
      body = 'Your booking request for $vehicleName was declined by the owner.';
    }

    // Get player ID from user document
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final oneSignalPlayerId = userDoc.data()?['oneSignalPlayerId'];

    if (oneSignalPlayerId != null) {
      await sendNotificationToUser(
        playerId: oneSignalPlayerId,
        title: title,
        content: body,
        notificationType: 'booking_response',
        data: {'requestId': doc.id},
      );

      // Update the notified flag
      await doc.reference.update({'notified': true});
    } else {
      debugPrint(
          "Could not send notification - OneSignal Player ID not found for user $userId");
    }
  }

  // Handle notifications for owners (new booking requests)
  Future<void> _handleOwnerNotification(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final userName = data['userName'] as String;
    final vehicleInfo = data['vehicleInfo'] as Map<String, dynamic>;
    final vehicleName = '${vehicleInfo['make']} ${vehicleInfo['model']}';
    final ownerId = data['ownerId'] as String;

    debugPrint("Handling owner notification for user $ownerId");

    // Get player ID from owner document
    final ownerDoc =
        await FirebaseFirestore.instance.collection('users').doc(ownerId).get();
    final oneSignalPlayerId = ownerDoc.data()?['oneSignalPlayerId'];

    if (oneSignalPlayerId != null) {
      await sendNotificationToUser(
        playerId: oneSignalPlayerId,
        title: 'New Booking Request',
        content:
            '$userName would like to book your $vehicleName. Tap to respond.',
        notificationType: 'booking_request',
        data: {'requestId': doc.id},
      );

      // Update the owner notified flag
      await doc.reference.update({'ownerNotified': true});
    } else {
      debugPrint(
          "Could not send notification - OneSignal Player ID not found for owner $ownerId");
    }
  }

  // Send notification using REST API
  Future<void> sendNotificationToUser({
    required String playerId,
    required String title,
    required String content,
    String? notificationType,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint("Sending notification to player ID: $playerId");
      debugPrint("Title: $title");
      debugPrint("Content: $content");
      
      // Combine notification data
      final Map<String, dynamic> notificationData = {
        'notificationType': notificationType,
        ...?data,
      };

      // Create notification payload using REST API format
      final Map<String, dynamic> notification = {
        'app_id': oneSignalAppId,
        'include_player_ids': [playerId],
        'contents': {'en': content},
        'headings': {'en': title},
        'data': notificationData,
      };

      debugPrint("Notification payload: ${notification.toString()}");

      // Send the notification using REST API
      final response = await http.post(
        Uri.parse('https://onesignal.com/api/v1/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $restApiKey',
        },
        body: jsonEncode(notification),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ Notification sent successfully to user with ID: $playerId');
        debugPrint('Response: ${response.body}');
      } else {
        debugPrint('❌ Failed to send notification. Status: ${response.statusCode}');
        debugPrint('Error: ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }
}
