import 'package:flutter_test/flutter_test.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:pms_vbis/core/auth/auth_service.dart';
import '../support/pocketbase_test_helper.dart';

/// Real login against the local dev PocketBase (127.0.0.1:8090). Plain
/// test(), not testWidgets() — see login_view_test.dart for why.
void main() {
  setUpAll(() async {
    final superuserPb = await authenticatedSuperuserClient();
    await ensureTestTelecaller(superuserPb, testTelecallerAEmail);
  });

  test('login() with correct telecaller credentials authenticates via the users collection', () async {
    final pb = PocketBase(testPocketBaseUrl);
    final auth = AuthService(pb);

    await auth.login(testTelecallerAEmail, testAccountPassword);

    expect(auth.isAuthenticated, isTrue);
    expect(auth.role, 'telecaller');
    expect(pb.authStore.record?.collectionName, 'users'); // never _superusers
  });

  test('login() with a wrong password throws and leaves the session unauthenticated', () async {
    final pb = PocketBase(testPocketBaseUrl);
    final auth = AuthService(pb);

    await expectLater(
      auth.login(testTelecallerAEmail, 'DefinitelyWrongPassword!'),
      throwsA(anything),
    );
    expect(auth.isAuthenticated, isFalse);
  });

  test('logout() clears the session', () async {
    final pb = PocketBase(testPocketBaseUrl);
    final auth = AuthService(pb);
    await auth.login(testTelecallerAEmail, testAccountPassword);
    expect(auth.isAuthenticated, isTrue);

    auth.logout();

    expect(auth.isAuthenticated, isFalse);
    expect(auth.currentUser, isNull);
  });

  test('AuthService notifies listeners on login and logout', () async {
    final pb = PocketBase(testPocketBaseUrl);
    final auth = AuthService(pb);
    var notifications = 0;
    auth.addListener(() => notifications++);

    await auth.login(testTelecallerAEmail, testAccountPassword);
    // AuthStore.onChange is a plain (non-sync) broadcast stream, so
    // delivery happens on a later event-loop turn rather than
    // synchronously inside save()/clear() — give it one.
    await Future.delayed(Duration.zero);
    auth.logout();
    await Future.delayed(Duration.zero);

    expect(notifications, greaterThanOrEqualTo(2));
  });
}
