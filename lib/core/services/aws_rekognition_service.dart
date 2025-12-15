import 'dart:io';
import 'dart:typed_data';
import 'package:aws_rekognition_api/rekognition-2016-06-27.dart' as aws;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AWSRekognitionService {
  late aws.Rekognition _rekognition;

  AWSRekognitionService() {
    _rekognition = aws.Rekognition(
      region: 'us-east-1',
      credentials: aws.AwsClientCredentials(
        accessKey: dotenv.env['AWS_ACCESS_KEY']!,
        secretKey: dotenv.env['AWS_SECRET_KEY']!,
      ),
    );
  }

  Future<bool> compareFaces({
    required String sourceImagePath,
    required String targetImagePath,
    double similarityThreshold = 70.0,
  }) async {
    try {
      final sourceBytes = await File(sourceImagePath).readAsBytes();
      final targetBytes = await File(targetImagePath).readAsBytes();

      final response = await _rekognition.compareFaces(
        sourceImage: aws.Image(bytes: Uint8List.fromList(sourceBytes)),
        targetImage: aws.Image(bytes: Uint8List.fromList(targetBytes)),
        similarityThreshold: similarityThreshold,
      );

      if (response.faceMatches != null && response.faceMatches!.isNotEmpty) {
        final similarity = response.faceMatches!.first.similarity ?? 0;
        debugPrint('Face similarity: $similarity%');
        return similarity >= similarityThreshold;
      }

      return false;
    } catch (e) {
      debugPrint('Error comparing faces: $e');
      return false;
    }
  }

  Future<bool> compareFaceWithUrl({
    required String sourceImagePath,
    required String targetImageUrl,
    double similarityThreshold = 70.0,
  }) async {
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(targetImageUrl));
      final response = await request.close();
      
      final BytesBuilder builder = await response.fold(
        BytesBuilder(),
        (BytesBuilder previous, List<int> element) => previous..add(element),
      );
      final targetBytes = builder.takeBytes();

      final sourceBytes = await File(sourceImagePath).readAsBytes();

      final rekognitionResponse = await _rekognition.compareFaces(
        sourceImage: aws.Image(bytes: Uint8List.fromList(sourceBytes)),
        targetImage: aws.Image(bytes: targetBytes),
        similarityThreshold: similarityThreshold,
      );

      if (rekognitionResponse.faceMatches != null && 
          rekognitionResponse.faceMatches!.isNotEmpty) {
        final similarity = rekognitionResponse.faceMatches!.first.similarity ?? 0;
        debugPrint('Face similarity: $similarity%');
        return similarity >= similarityThreshold;
      }

      return false;
    } catch (e) {
      debugPrint('Error comparing faces: $e');
      return false;
    }
  }
}