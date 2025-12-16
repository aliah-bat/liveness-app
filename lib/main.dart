import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'core/services/supabase_service.dart';
import 'core/services/aws_rekognition_service.dart'; 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file FIRST
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ .env file loaded successfully');
  } catch (e) {
    debugPrint('❌ Failed to load .env file: $e');
  }

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

  // Create AWS Rekognition collection (run once)
  try {
    final awsService = AWSRekognitionService();
    await awsService.createCollection('billpay');
    debugPrint('✅ AWS Rekognition collection created');
  } catch (e) {
    debugPrint('⚠️ AWS collection might already exist: $e');
  }

  runApp(const MyApp());
}