import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

/// PocketBase client instance configured for local development on port 8090.
///
/// - Desktop / iOS / Web: http://127.0.0.1:8090
/// - Android Emulator:    http://10.0.2.2:8090
final PocketBase pb = PocketBase(
  !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8090'
      : 'http://127.0.0.1:8090',
);

