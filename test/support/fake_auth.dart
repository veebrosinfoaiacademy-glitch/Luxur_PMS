import 'dart:convert';
import 'package:pocketbase/pocketbase.dart';

/// Builds a structurally-valid (but not server-issued) JWT purely so
/// AuthStore.isValid's local expiry check passes — no network call
/// involved. Used only to drive widget-tree/routing assertions where what
/// matters is "the app believes it's logged in as role X", not whether a
/// real server would accept the token. Server-side auth itself is verified
/// for real in test/auth/auth_service_test.dart and the repository tests.
String _fakeJwt() {
  String b64(Map<String, dynamic> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  final header = b64({'alg': 'none', 'typ': 'JWT'});
  final payload = b64({'exp': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000});
  return '$header.$payload.fakesignature';
}

/// Signs the given [pb] client's in-memory authStore into a "logged in as
/// [role]" state without any network call.
void fakeSignIn(PocketBase pb, {required String role, String name = 'Test User'}) {
  final record = RecordModel({
    'id': 'faketestid${role.hashCode}',
    'collectionId': '_pb_users_auth_',
    'collectionName': 'users',
    'email': '$role@test.local',
    'name': name,
    'role': role,
    'active': true,
  });
  pb.authStore.save(_fakeJwt(), record);
}
