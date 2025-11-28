class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://buopmpcbdbwqpvmjdvmi.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1b3BtcGNiZGJ3cXB2bWpkdm1pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI0NDIxMjIsImV4cCI6MjA3ODAxODEyMn0.bJgiza1Pi8gr33j03r_mUQwW_ISgOMXw37uMcyXrt0Y';

  // App Information
  static const String appName = 'BillPay';
  
  // Debug Settings
  static const bool isProduction = false;
  static bool get isDebugMode => !isProduction;
}