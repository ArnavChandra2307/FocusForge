import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  final action = response.actionId ?? '';
  debugPrint('🔔 Background action: $action');
  SessionForegroundService._actionCallback?.call(action);
}
class SessionForegroundService {
  static final FlutterLocalNotificationsPlugin _notif =
  FlutterLocalNotificationsPlugin();

  static const int _notifId = 777;

  static Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notif.initialize(
      InitializationSettings(android: android),
      onDidReceiveNotificationResponse: _onAction,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
  }

  static void _onAction(NotificationResponse response) {
    final action = response.actionId;
    debugPrint('🔔 Action received: $action');
    _actionCallback?.call(action ?? '');
  }

  static void Function(String)? _actionCallback;

  static void setActionCallback(void Function(String action) callback) {
    _actionCallback = callback;
  }

  static Future<void> start(String timeText) async {
    await _show(timeText, paused: false);
    debugPrint('🚀 Session notification shown');
  }

  static Future<void> update(String timeText, {bool paused = false}) async {
    await _show(timeText, paused: paused);
  }

  static Future<void> stop() async {
    await _notif.cancel(_notifId);
    debugPrint('🛑 Session notification cancelled');
  }

  static Future<void> _show(String timeText, {required bool paused}) async {
    final androidDetails = AndroidNotificationDetails(
      'focusforge_session',
      'Study Session',
      channelDescription: 'Active study session timer',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
      // actions: [
      //   AndroidNotificationAction(
      //     'pause',
      //     paused ? '▶ Resume' : '⏸ Pause',
      //   ),
      //   const AndroidNotificationAction('end', '⏹ End'),
      // ],
    );

    final String title = paused
        ? '⏸ Arre ruk gaye kya? Resume karo!'
        : '🔥 Padhai chal rahi hai — keep going!';

    final String body = paused
        ? 'Timer ruka hua hai • $timeText'
        : '⏱ $timeText • Focus mode ON 💪';

    await _notif.show(
      _notifId,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }
}