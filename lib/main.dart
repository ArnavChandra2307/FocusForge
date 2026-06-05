import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/session_foreground_service.dart';
import 'core/app_export.dart';
import 'core/services/supabase_service.dart';
import 'widgets/custom_error_widget.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'services/session_foreground_service.dart';
import 'services/session_task_handler.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(SessionTaskHandler());
}
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  final action = response.actionId;
  debugPrint('🔔 Notification action: $action');
}
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Supabase
  try {
    await SupabaseService.init();
    await SessionForegroundService.init();
  } catch (e) {
    debugPrint('❌ Failed to initialize Supabase: $e');
  }

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  bool hasShownError = false;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;
      Future.delayed(const Duration(seconds: 5), () {
        hasShownError = false;
      });
      return CustomErrorWidget(errorDetails: details);
    }
    return const SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(const MyApp());
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.focusforge.audio',
    androidNotificationChannelName: 'FocusForge Music',
    androidNotificationOngoing: true,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
        child: Sizer(
          builder: (context, orientation, screenType) {
            return MaterialApp(
          title: 'FocusForge',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          debugShowCheckedModeBanner: false,

          // 🚨 CRITICAL: Lock text scale - DO NOT REMOVE
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(1.0),
              ),
              child: child!,
            );
          },

          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
        );
      },
    ));
  }
}