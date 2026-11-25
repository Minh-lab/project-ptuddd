import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static Future<SupabaseClient?> initialize() async {
    final url =
        dotenv.env['SUPABASE_URL']?.trim() ??
        dotenv.env['NEXT_PUBLIC_SUPABASE_URL']?.trim();
    final publishableKey =
        dotenv.env['SUPABASE_PUBLISHABLE_KEY']?.trim() ??
        dotenv.env['SUPABASE_ANON_KEY']?.trim() ??
        dotenv.env['NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY']?.trim();
    if (url == null ||
        url.isEmpty ||
        publishableKey == null ||
        publishableKey.isEmpty) {
      return null;
    }

    final parsedUrl = Uri.tryParse(url);
    if (parsedUrl == null ||
        !parsedUrl.hasAuthority ||
        (parsedUrl.scheme != 'https' && parsedUrl.scheme != 'http')) {
      throw const FormatException('SUPABASE_URL không hợp lệ.');
    }

    await Supabase.initialize(
      url: url,
      publishableKey: publishableKey,
      accessToken: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return null;
        return user.getIdToken();
      },
      debug: false,
    );
    return Supabase.instance.client;
  }
}
