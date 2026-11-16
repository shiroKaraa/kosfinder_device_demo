// ignore_for_file: unnecessary_const
class CloudConfig {
  static const url = const String.fromEnvironment('SUPABASE_URL');
  static const publishableKey =
      const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static bool get enabled => url.isNotEmpty && publishableKey.isNotEmpty;
}