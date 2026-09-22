/// Environment-based configuration, supplied at build/run time via
/// `--dart-define-from-file=env/local.json` (or `env/prod.json`, once the
/// production VPS is available). Never hard-code environment URLs here —
/// see the `pms-project` skill / DEV_SETUP for the run commands.
class AppConfig {
  AppConfig._();

  static const String pocketbaseUrl = String.fromEnvironment(
    'POCKETBASE_URL',
    defaultValue: 'http://127.0.0.1:8090',
  );

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'local',
  );

  static bool get isProd => appEnv == 'prod';
}
