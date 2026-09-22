import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';

/// Wraps the application-user auth flow (the `users` collection) — never
/// the PocketBase superuser API. Notifies listeners on login/logout so the
/// root widget can switch between the login screen and a role's shell.
class AuthService extends ChangeNotifier {
  AuthService(this._pb) {
    _subscription = _pb.authStore.onChange.listen((_) => notifyListeners());
  }

  final PocketBase _pb;
  late final StreamSubscription _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  bool get isAuthenticated => _pb.authStore.isValid;

  RecordModel? get currentUser =>
      _pb.authStore.record?.collectionName == 'users' ? _pb.authStore.record : null;

  String? get role => currentUser?.getStringValue('role');

  String get displayName {
    final user = currentUser;
    if (user == null) return '';
    final name = user.getStringValue('name');
    return name.isNotEmpty ? name : user.getStringValue('email');
  }

  Future<void> login(String email, String password) async {
    await _pb.collection('users').authWithPassword(email, password);
  }

  void logout() {
    _pb.authStore.clear();
  }
}
