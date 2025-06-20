import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final String notificationType; // 'booking_requests', 'messages', etc.

  const NotificationBadge({
    super.key,
    required this.child,
    required this.notificationType,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return child;

    return StreamBuilder<QuerySnapshot>(
      stream: _getNotificationStream(currentUser.uid),
      builder: (context, snapshot) {
        final unreadCount = _getUnreadCount(snapshot);

        if (unreadCount == 0) return child;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            Positioned(
              top: -5,
              right: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  unreadCount > 9 ? '9+' : '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _getNotificationStream(String userId) {
    switch (notificationType) {
      case 'booking_requests':
        return FirebaseFirestore.instance
            .collection('bookingRequests')
            .where('ownerId', isEqualTo: userId)
            .where('ownerNotified', isEqualTo: false)
            .where('status', isEqualTo: 'pending')
            .snapshots();
      case 'booking_responses':
        return FirebaseFirestore.instance
            .collection('bookingRequests')
            .where('userId', isEqualTo: userId)
            .where('notified', isEqualTo: false)
            .where('status', whereIn: ['approved', 'rejected']).snapshots();
      default:
        return const Stream.empty();
    }
  }

  int _getUnreadCount(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.hasData) {
      return snapshot.data!.docs.length;
    }
    return 0;
  }
}
