import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
      },
    );

    // Start listening to booking request updates
    _listenToBookingUpdates();
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required int id,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'booking_channel',
      'Booking Notifications',
      channelDescription:
          'Notifications for vehicle booking requests and responses',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // Listen for booking updates where the current user is involved
  void _listenToBookingUpdates() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

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

    String title, body;
    if (status == 'approved') {
      title = 'Booking Approved!';
      body =
          'Your booking request for $vehicleName has been approved. You can now proceed to payment.';
    } else {
      title = 'Booking Declined';
      body = 'Your booking request for $vehicleName was declined by the owner.';
    }

    await showNotification(
      id: doc.id.hashCode,
      title: title,
      body: body,
    );

    // Update the notified flag
    await doc.reference.update({'notified': true});
  }

  // Handle notifications for owners (new booking requests)
  Future<void> _handleOwnerNotification(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final userName = data['userName'] as String;
    final vehicleInfo = data['vehicleInfo'] as Map<String, dynamic>;
    final vehicleName = '${vehicleInfo['make']} ${vehicleInfo['model']}';

    await showNotification(
      id: doc.id.hashCode,
      title: 'New Booking Request',
      body: '$userName would like to book your $vehicleName. Tap to respond.',
    );

    // Update the owner notified flag
    await doc.reference.update({'ownerNotified': true});
  }
}
