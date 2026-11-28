import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Public application configuration for the team's development project.
class SharedClientConfig {
  SharedClientConfig._(this._values);

  static const assetPath = 'config/shared_client.json';
  final Map<String, dynamic> _values;

  static Future<SharedClientConfig> load() async {
    final json = await rootBundle.loadString(assetPath);
    return SharedClientConfig._(jsonDecode(json) as Map<String, dynamic>);
  }

  String get supabaseUrl => _values['supabaseUrl'] as String;
  String get supabasePublishableKey =>
      _values['supabasePublishableKey'] as String;
  String get aiEndpoint => _values['aiEndpoint'] as String;

  FirebaseOptions? firebaseOptionsFor(TargetPlatform platform) {
    if (kIsWeb) return null;
    final platformName = switch (platform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
    if (platformName == null) return null;
    final firebase = _values['firebase'] as Map<String, dynamic>;
    final app = firebase[platformName] as Map<String, dynamic>;
    return FirebaseOptions(
      apiKey: app['apiKey'] as String,
      appId: app['appId'] as String,
      messagingSenderId: firebase['messagingSenderId'] as String,
      projectId: firebase['projectId'] as String,
      iosBundleId: app['bundleId'] as String?,
    );
  }
}
