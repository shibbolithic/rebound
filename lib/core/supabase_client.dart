import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://geexguusxuelasylkvlh.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdlZXhndXVzeHVlbGFzeWxrdmxoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU4MTkzNDUsImV4cCI6MjA4MTM5NTM0NX0.17vCUfYfko96infelgwWzpoBOjlABBL0Lvu00zmEg8Q',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

}
