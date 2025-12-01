import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/face_detection_service.dart';
import 'dart:io';

class FaceTestScreen extends StatefulWidget {
  @override
  State<FaceTestScreen> createState() => _FaceTestScreenState();
}

class _FaceTestScreenState extends State<FaceTestScreen> {
  final FaceDetectionService _faceService = FaceDetectionService();
  final ImagePicker _picker = ImagePicker();
  String _status = 'Take a photo to detect face';
  File? _image;

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
    );

    if (photo != null) {
      setState(() {
        _image = File(photo.path);
        _status = 'Detecting...';
      });

      try {
        final faces = await _faceService.detectFacesFromFile(photo.path);
        setState(() {
          _status = faces.isEmpty 
            ? 'No face detected' 
            : '${faces.length} face(s) detected!';
        });
      } catch (e) {
        setState(() => _status = 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Face Detection Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_image != null)
              Image.file(_image!, height: 300),
            SizedBox(height: 20),
            Text(_status, style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _takePicture,
              child: Text('Take Photo'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _faceService.dispose();
    super.dispose();
  }
}