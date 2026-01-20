import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationService {
  /// 🔔 New order notification (Admin)
  static Future<void> addNewOrderNotification({
    required String orderId,
  }) async {
    await FirebaseFirestore.instance
        .collection('AdminNotifications')
        .add({
      'title': 'New Order Received',
      'body': 'A new order has been placed',
      'orderId': orderId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 📊 Unread notification count (for badge)
  static Stream<int> unreadCount() {
    return FirebaseFirestore.instance
        .collection('AdminNotifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// ✅ Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('AdminNotifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
}
