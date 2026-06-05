import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../presentation/splash/splash_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/signup_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/session_screen/session_screen.dart'; // ✅ IMPORTANT ADD

class AppRoutes {
  static const String initial  = '/';
  static const String home     = '/home';
  static const String login    = '/login';
  static const String signup   = '/signup';
  static const String session  = '/session';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    home:    (context) => const HomeScreen(),
    login:   (context) => const LoginScreen(),
    signup:  (context) => const SignupScreen(),
    session: (context) => const SessionScreen(),
  };
}

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSession();
    });
  }

  Future<void> _checkSession() async {
    final session = Supabase.instance.client.auth.currentSession;

    // ← YEH CHANGE KARO
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (session != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF060410),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
      ),
    );
  }
}