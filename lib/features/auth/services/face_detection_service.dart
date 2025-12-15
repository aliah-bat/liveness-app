import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  late FaceDetector _faceDetector;

  FaceDetectionService() {
    final options = FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<List<Face>> detectFacesFromFile(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    return await _faceDetector.processImage(inputImage);
  }

  void dispose() {
    _faceDetector.close();
  }
}