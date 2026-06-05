import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://bfdyboyemesaayntuylm.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJmZHlib3llbWVzYWF5bnR1eWxtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc2MTA1OTcsImV4cCI6MjA5MzE4NjU5N30._4SVTLIadYZZZkAVIYAYTtSbkePMXeB4L8povMJJP-I',
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit, // ← BAS YEH ADD KAR
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}