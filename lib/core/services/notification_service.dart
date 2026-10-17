import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InAppNotification {
  const InAppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.route,
    required this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final String route;
  final DateTime createdAt;
  final bool isRead;

  InAppNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? route,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return InAppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      route: route ?? this.route,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationService {
  NotificationService() {
    // Seed initial welcome notification
    _notifications.add(
      InAppNotification(
        id: 'notif_welcome',
        title: 'Welcome to Campus Signal',
        body: 'Finders Keepers is active on your campus. Browse found items or file a report.',
        route: '/home',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    );
    _broadcast();
  }

  final List<InAppNotification> _notifications = [];
  final _controller = StreamController<List<InAppNotification>>.broadcast();

  Stream<List<InAppNotification>> get notificationsStream => _controller.stream;
  List<InAppNotification> get currentNotifications => List.unmodifiable(_notifications);

  void _broadcast() {
    _controller.add(List.unmodifiable(_notifications));
  }

  Future<void> sendMatchAlert({
    required String itemId,
    required String itemTitle,
    required int matchPercentage,
  }) async {
    final notif = InAppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Potential Match Found ($matchPercentage%)',
      body: 'A found item "$itemTitle" closely matches an item you reported.',
      route: '/items/$itemId',
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, notif);
    _broadcast();
  }

  Future<void> sendClaimStatusAlert({
    required String claimId,
    required String itemTitle,
    required String status,
  }) async {
    final notif = InAppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Claim Update: $status',
      body: 'Your claim for "$itemTitle" has been updated to $status.',
      route: '/activity',
      createdAt: DateTime.now(),
    );
    _notifications.insert(0, notif);
    _broadcast();
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _broadcast();
  }

  void dispose() {
    _controller.close();
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(service.dispose);
  return service;
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationServiceProvider).currentNotifications;
  return notifs.where((n) => !n.isRead).length;
});
