import 'package:pocketbase/pocketbase.dart';
import '../config/app_config.dart';

/// App-wide PocketBase client, pointed at LOCAL or PROD via [AppConfig].
/// One instance per app run — inject/pass this rather than constructing
/// `PocketBase(...)` again elsewhere, so auth state (the client's authStore)
/// stays consistent across the app.
class PocketBaseClient {
  PocketBaseClient._();

  static final PocketBase instance = PocketBase(AppConfig.pocketbaseUrl);
}
