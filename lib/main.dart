import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set portrait orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
    debugPrint('✅ App initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize app: $e');
  }

  runApp(const MyApp());
}