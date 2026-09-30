/// Reads environment variables injected via `--dart-define`.
abstract final class AppEnv {
  static const String supabaseUrl = String.fromEnvironment(
    'https://fzlzmfefnpmayudzxhnk.supabase.co/rest/v1/',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ6bHptZmVmbnBtYXl1ZHp4aG5rIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA2NzQ5ODYsImV4cCI6MjEwNjI1MDk4Nn0.hJsQMPe9lQk-qcTBTK_lX7HQIZwogrhQg1Fd5CTqP9M',
    defaultValue: '',
  );

  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isDev => environment == 'dev';
  static bool get isProd => environment == 'prod';
}
