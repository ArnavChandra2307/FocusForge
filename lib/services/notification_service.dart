import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ── INIT ────────────────────────────────────────────────
  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); // IST

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings);

    // Android 13+ permission request
    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('✅ NotificationService initialized');
  }

  // ── SCHEDULE ALL NOTIFICATIONS FOR TODAY ───────────────
  static Future<void> scheduleSessionReminders() async {
    await init();

    for (int i = 100; i < 200; i++) {
      await _plugin.cancel(i);
    }

    final now = tz.TZDateTime.now(tz.local);

    final List<Map<String, int>> slots = [
      {'hour': 10, 'minute': 0},
      {'hour': 12, 'minute': 0},
      {'hour': 14, 'minute': 0},
      {'hour': 16, 'minute': 0},
      {'hour': 18, 'minute': 0},
      {'hour': 20, 'minute': 0},
      {'hour': 22, 'minute': 0},
      {'hour': 23, 'minute': 0},
    ];

    int notifId = 100;

    for (final slot in slots) {
      int hour = slot['hour']!;
      int minute = slot['minute']!;

      if (minute >= 60) {
        hour += minute ~/ 60;
        minute = minute % 60;
      }

      final bool isNextDay = hour >= 24;
      if (isNextDay) hour = hour % 24;

      tz.TZDateTime scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        isNextDay ? now.day + 1 : now.day,
        hour,
        minute,
      );

      if (scheduledTime.isBefore(now)) {
        notifId++;
        continue;
      }

      final List<String> reminderMessages = [
        'Arre yaar! 😅 Aaj padhai shuru ki kya?',
        'Bhai streak toot jayega! ⚠️ Session start kar abhi.',
        'Chal uth! 🔥 Aaj ka goal abhi baaki hai.',
        'Focus mode on kar! ⏱ Padhai pending hai aaj ki.',
        'Yaar seriously? 😂 Abhi tak session start nahi kiya!',
      ];
      reminderMessages.shuffle();

      await _scheduleOneNotification(
        id: notifId,
        scheduledTime: scheduledTime,
        title: '📚 Padhai Pending Hai!',
        body: reminderMessages.first,
      );

      notifId++;
    }

    debugPrint('✅ Reminders scheduled');
  }

  // ── SCHEDULE ONE NOTIFICATION ───────────────────────────
  static Future<void> _scheduleOneNotification({
    required int id,
    required tz.TZDateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'session_reminders',
      'Session Reminders',
      channelDescription: 'Reminds you to complete your study session',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── SMART NOTIFICATION (call when app opens) ────────────
  static Future<void> updateNotificationsBasedOnProgress() async {
    await init();

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('today_minutes')
          .eq('id', user.id)
          .single();

      final int todayMinutes = (profile['today_minutes'] as int?) ?? 0;
      final bool isComplete = todayMinutes >= 120;

      if (isComplete) {
        await _plugin.cancelAll();

        final sessions = await Supabase.instance.client
            .from('study_sessions')
            .select('subject, duration_minutes')
            .eq('user_id', user.id)
            .gte(
            'created_at',
            DateTime(DateTime.now().year, DateTime.now().month,
                DateTime.now().day)
                .toUtc()
                .toIso8601String());

        final Map<String, int> subjectMap = {};
        for (final s in sessions) {
          final subject = (s['subject'] as String?) ?? 'Unknown';
          final mins = (s['duration_minutes'] as int?) ?? 0;
          subjectMap[subject] = (subjectMap[subject] ?? 0) + mins;
        }

        String topSubject = 'Padhai';
        if (subjectMap.isNotEmpty) {
          topSubject = subjectMap.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }

        final List<String> doneMessages = [
          'Aaj $topSubject mein beast mode on tha! 🔥 Streak secured!',
          'Bhai $topSubject toh tod diya aaj! 💪 Streak +1 ho gaya!',
          '$topSubject padh ke streak badha di — legend! 🏆',
          'Aaj ka $topSubject session fire tha 🔥 — streak safe hai!',
          'Goal complete! $topSubject mein aaj khoob mehnat ki! ✅',
        ];
        doneMessages.shuffle();

        await _showInstantNotification(
          id: 999,
          title: '🎉 Streak Secured!',
          body: doneMessages.first,
        );

        debugPrint('✅ Goal complete — streak notification sent');
      } else {
        await _rescheduleWithProgress(todayMinutes);
      }
    } catch (e) {
      debugPrint('❌ Notification update error: $e');
    }
  }

  // ── RESCHEDULE WITH REAL PROGRESS ──────────────────────
  static Future<void> _rescheduleWithProgress(int todayMinutes) async {
    for (int i = 100; i < 200; i++) {
      await _plugin.cancel(i);
    }

    final int remainingMinutes = 120 - todayMinutes;
    final double remainingHours = remainingMinutes / 60.0;
    final String hoursText = remainingHours >= 1
        ? '${remainingHours.toStringAsFixed(1)} hours'
        : '$remainingMinutes minutes';

    final now = tz.TZDateTime.now(tz.local);

    final List<Map<String, int>> slots = [
      {'hour': 11, 'minute': 0},
      {'hour': 13, 'minute': 0},
      {'hour': 15, 'minute': 0},
      {'hour': 17, 'minute': 0},
      {'hour': 19, 'minute': 0},
      {'hour': 21, 'minute': 0},
      {'hour': 23, 'minute': 0},
      {'hour': 1, 'minute': 0},
    ];
    int notifId = 100;

    for (final slot in slots) {
      int hour = slot['hour']!;
      int minute = slot['minute']!;

      if (minute >= 60) {
        hour += minute ~/ 60;
        minute = minute % 60;
      }

      final bool isNextDay = hour >= 24 || hour < 6;
      final int resolvedHour = hour >= 24 ? hour % 24 : hour;

      tz.TZDateTime scheduledTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        isNextDay ? now.day + 1 : now.day,
        resolvedHour,
        minute,
      );

      if (scheduledTime.isBefore(now)) {
        notifId++;
        continue;
      }

      final List<String> pendingMessages = [
        'Arre yaar! 😅 Abhi $hoursText baaki hai — padhai shuru kar!',
        'Bhai streak toot jayega! ⚠️ $hoursText aur padhna hai abhi.',
        'Chal uth! 🔥 $hoursText ki padhai pending hai aaj ki.',
        'Aaj ka goal adhoora hai 😤 — $hoursText aur baaki hai!',
        'Streak bachani hai toh $hoursText aur laga de! 💪',
        'Focus mode on kar! ⏱ Sirf $hoursText aur baaki hai aaj.',
        'Yaar seriously? 😂 $hoursText padhai abhi bhi pending hai!',
        'Ek aur push! 🚀 $hoursText mein streak secure ho jayegi!',
      ];
      pendingMessages.shuffle();

      await _scheduleOneNotification(
        id: notifId,
        scheduledTime: scheduledTime,
        title: '📚 Padhai Pending Hai!',
        body: pendingMessages.first,
      );

      notifId++;
    }

    debugPrint('✅ Reminders rescheduled with progress');
  }

  // ── MIDNIGHT RESET ──────────────────────────────────────
  // BUG FIX #3 — resetForNewDay now also reschedules deadline notifications.
  // Previously cancelAll() wiped deadline notifs (200–399) but
  // scheduleSessionReminders() only restored session notifs (100–199).
  // Pass tasks list from your task provider/state so deadline notifs are restored too.
  static Future<void> resetForNewDay({
    List<Map<String, dynamic>>? tasks,
  }) async {
    await _plugin.cancelAll();
    await scheduleSessionReminders();

    if (tasks != null && tasks.isNotEmpty) {
      await scheduleDeadlineNotifications(tasks: tasks);
    }

    debugPrint('✅ New day — all reminders reset');
  }

  // ── INSTANT NOTIFICATION ────────────────────────────────
  static Future<void> _showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'streak_complete',
      'Streak Complete',
      channelDescription: 'Notifies when daily streak goal is completed',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
    NotificationDetails(android: androidDetails);

    await _plugin.show(id, title, body, details);
  }

  // ── DEADLINE NOTIFICATIONS ──────────────────────────────
  static Future<void> scheduleDeadlineNotifications({
    required List<Map<String, dynamic>> tasks,
  }) async {
    await init();

    // Cancel existing deadline notifications (IDs 200–399)
    for (int i = 200; i < 400; i++) {
      await _plugin.cancel(i);
    }

    final importantPending = tasks
        .where((t) =>
    t['important'] == true &&
        t['completed'] != true &&
        t['deadline'] != null)
        .toList();

    int notifId = 200;
    final now = tz.TZDateTime.now(tz.local);

    for (final task in importantPending) {
      final String taskName = task['task'] ?? 'Task';
      DateTime deadline;
      try {
        deadline = DateTime.parse(task['deadline']);
      } catch (_) {
        continue;
      }

      final today = DateTime(now.year, now.month, now.day);
      final deadlineDay =
      DateTime(deadline.year, deadline.month, deadline.day);
      final int daysLeft = deadlineDay.difference(today).inDays;

      if (daysLeft < 0) continue; // Already past

      // BUG FIX #2 — Schedule notifications spread across upcoming days,
      // not just today/tomorrow. We notify on: today, tomorrow, and
      // every 2 days until deadline (capped at 5 notification days per task).
      final List<int> notifyOnDays = _buildNotifyDays(daysLeft);

      final List<int> hours = [10, 19];

      for (final dayOffset in notifyOnDays) {
        for (final hour in hours) {
          final int minute = (taskName.hashCode.abs() + hour) % 30;

          tz.TZDateTime scheduledTime = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day + dayOffset,
            hour,
            minute,
          );

          if (scheduledTime.isBefore(now)) continue;

          final int daysLeftAtNotif = daysLeft - dayOffset;

          String title;
          String body;

          if (daysLeftAtNotif == 0) {
            title = '🚨 AAJ DEADLINE HAI BHAI!';
            body =
            '"$taskName" — yaar aaj hi khatam karna hai! Kal ka kal pe mat chod! 😱';
          } else if (daysLeftAtNotif == 1) {
            title = '⚠️ Kal deadline hai!';
            body =
            '"$taskName" — kal tak khatam nahi kiya toh log haste rahenge! 😅 Jaldi kar!';
          } else if (daysLeftAtNotif <= 3) {
            title = '😬 Deadline aa rahi hai!';
            body =
            '"$taskName" — sirf $daysLeftAtNotif din bache hain! Abhi nahi toh kab? 🔥';
          } else if (daysLeftAtNotif <= 7) {
            title = '📅 Task reminder!';
            body =
            '"$taskName" — $daysLeftAtNotif din mein deadline hai. Thoda thoda karte raho! 💪';
          } else {
            title = '🗓️ Upcoming task!';
            body =
            '"$taskName" — $daysLeftAtNotif din baaki hain. Plan kar lo bhai! 😎';
          }

          await _scheduleOneNotification(
            id: notifId,
            scheduledTime: scheduledTime,
            title: title,
            body: body,
          );

          notifId++;
          if (notifId >= 400) break;
        }
        if (notifId >= 400) break;
      }
      if (notifId >= 400) break;
    }

    debugPrint(
        '✅ Deadline notifications scheduled for ${importantPending.length} tasks');
  }

  // Returns which day offsets (from today) to send notifications on,
  // spread smartly based on how far the deadline is.
  static List<int> _buildNotifyDays(int daysLeft) {
    if (daysLeft == 0) return [0];
    if (daysLeft == 1) return [0, 1];
    if (daysLeft <= 3) return [0, daysLeft];
    if (daysLeft <= 7) return [0, daysLeft - 2, daysLeft];

    // For longer deadlines: today, midpoint, 3 days before, deadline day
    final mid = daysLeft ~/ 2;
    return [0, mid, daysLeft - 3, daysLeft]..sort();
  }

}