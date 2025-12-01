import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FaceRegistrationScreen extends StatefulWidget {
  @override
  State<FaceRegistrationScreen> createState() => _FaceRegistrationScreenState();
}

class _FaceRegistrationScreenState extends State<FaceRegistrationScreen> 
    with WidgetsBindingObserver {
  
  CameraController? _cameraController;
  late FaceDetector _faceDetector;
  
  // Liveness check states
  bool _isFaceInFrame = false;
  bool _isFaceLeft = false;
  bool _isFaceRight = false;
  bool _isSmiled = false;
  bool _isEyeOpen = false;
  bool _isFaceReadyForPhoto = false;
  bool _isNoFace = false;
  bool _isMultiFace = false;
  bool _isCaptured = false;
  
  var frontCamera;
  XFile? _capturedImage;
  List<String> _successfulSteps = [];

  final orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    
    final options = FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableLandmarks: true,
      enableTracking: true,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCameras = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    setState(() {
      frontCamera = frontCameras;
    });

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    
    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {});
    
    _cameraController!.startImageStream((CameraImage img) {
      _processCameraImage(img);
    });
  }

  Future<void> _processCameraImage(CameraImage img) async {
    try {
      final inputImage = _getInputImageFromCameraImage(img);
      if (inputImage == null) return;

      final List<Face> faces = await _faceDetector.processImage(inputImage);

      if (faces.length > 1) {
        setState(() {
          _isMultiFace = true;
          _successfulSteps.clear();
          _resetFaceDetectionStatus();
        });
      } else if (faces.isEmpty) {
        setState(() {
          _isNoFace = true;
          _successfulSteps.clear();
          _resetFaceDetectionStatus();
        });
      } else if (faces.isNotEmpty) {
        _isMultiFace = false;
        _isNoFace = false;
        final Face face = faces.first;
        _handleFaceDetection(face);
      }
    } catch (e) {
      print('Error processing camera image: $e');
    }
  }

  void _handleFaceDetection(Face face) {
    if (!_isCaptured) {
      final double? rotY = face.headEulerAngleY;
      final double leftEyeOpen = face.leftEyeOpenProbability ?? -1.0;
      final double rightEyeOpen = face.rightEyeOpenProbability ?? -1.0;
      final double smileProb = face.smilingProbability ?? -1.0;

      setState(() {
        _updateFaceInFrameStatus();
        _updateHeadRotationStatus(rotY);
        _updateSmilingStatus(smileProb);
        _updateEyeOpenStatus(leftEyeOpen, rightEyeOpen);
        _updateFaceReadyForPhotoStatus(rotY, smileProb);
        
        if (_isFaceInFrame && _isFaceLeft && _isFaceRight && 
            _isSmiled && _isFaceReadyForPhoto && _isEyeOpen) {
          if (!_isCaptured) {
            _captureImage();
          }
        }
      });
    }
  }

  void _updateFaceInFrameStatus() {
    if (!_isFaceInFrame) {
      _isFaceInFrame = true;
      _addSuccessfulStep('Face in frame');
    }
  }

  void _updateFaceReadyForPhotoStatus(double? rotY, double? smileProb) {
    if (_isFaceRight && _isFaceLeft && rotY != null && 
        rotY > -2 && rotY < 2 && smileProb! < 0.2) {
      _isFaceReadyForPhoto = true;
      _addSuccessfulStep('Face Ready For Photo');
    } else {
      _isFaceReadyForPhoto = false;
    }
  }

  void _updateHeadRotationStatus(double? rotY) {
    if (_isFaceInFrame && !_isFaceLeft && rotY != null && rotY < -7) {
      _isFaceLeft = true;
      _addSuccessfulStep('Face rotated left');
    }

    if (_isFaceLeft && !_isFaceRight && rotY != null && rotY > 7) {
      _isFaceRight = true;
      _addSuccessfulStep('Face rotated right');
    }
  }

  void _updateEyeOpenStatus(double leftEyeOpen, double rightEyeOpen) {
    if (_isFaceInFrame && _isFaceLeft && _isFaceRight && 
        _isSmiled && !_isEyeOpen) {
      if (leftEyeOpen > 0.3 && rightEyeOpen > 0.3) {
        _isEyeOpen = true;
        _addSuccessfulStep('Eyes Open');
      }
    }
  }

  void _updateSmilingStatus(double smileProb) {
    if (_isFaceInFrame && _isFaceLeft && _isFaceRight && 
        !_isSmiled && smileProb > 0.3) {
      _isSmiled = true;
      _addSuccessfulStep('Smiling');
    }
  }

  void _resetFaceDetectionStatus() {
    _isFaceInFrame = false;
    _isFaceLeft = false;
    _isFaceRight = false;
    _isEyeOpen = false;
    _isNoFace = false;
    _isMultiFace = false;
    _isSmiled = false;
  }

  void _addSuccessfulStep(String step) {
    if (!_successfulSteps.contains(step)) {
      _successfulSteps.add(step);
    }
  }

  InputImage? _getInputImageFromCameraImage(CameraImage image) {
    final sensorOrientation = frontCamera.sensorOrientation;
    InputImageRotation? rotation;
    
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          orientations[_cameraController!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      
      if (frontCamera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
rotation = InputImageRotationValue.fromRawValue(rotationCompensation!);    }
    
    if (rotation == null) return null;
    
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;
    
    if (image.planes.length != 1) return null;
    final plane = image.planes.first;
    
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _captureImage() async {
    if (_cameraController!.value.isTakingPicture) return;
    
    try {
      final XFile file = await _cameraController!.takePicture();
      setState(() {
        _isCaptured = true;
        _capturedImage = file;
      });
      
      // Upload to Supabase
      await _uploadFaceToSupabase(file);
    } catch (e) {
      print('Error capturing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture image: $e')),
      );
    }
  }

  Future<void> _uploadFaceToSupabase(XFile image) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // Upload image to storage
      final bytes = await File(image.path).readAsBytes();
      final fileName = '$userId-face.jpg';
      
      await Supabase.instance.client.storage
          .from('face-images')
          .uploadBinary(fileName, bytes);

      // Get public URL
      final imageUrl = Supabase.instance.client.storage
          .from('face-images')
          .getPublicUrl(fileName);

      // Store URL in users table
      await Supabase.instance.client
          .from('users')
          .update({'face_image_url': imageUrl})
          .eq('id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Face registered successfully!')),
      );
      
      Navigator.pop(context);
    } catch (e) {
      print('Error uploading to Supabase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload: $e')),
      );
    }
  }

  String _getCurrentDirection() {
    if (!_isFaceInFrame) {
      return 'Enter your face in the frame';
    } else if (_isNoFace) {
      return 'No face detected';
    } else if (_isMultiFace) {
      return 'Multiple faces detected';
    } else if (!_isFaceLeft) {
      return 'Rotate your face to the left';
    } else if (!_isFaceRight) {
      return 'Rotate your face to the right';
    } else if (!_isSmiled) {
      return 'Smile please';
    } else if (!_isEyeOpen) {
      return 'Open your eyes';
    } else if (!_isFaceReadyForPhoto) {
      return 'Keep your face straight';
    } else {
      return 'Capturing...';
    }
  }

  @override
  void dispose() {
    _faceDetector.close();
    if (_cameraController != null) _cameraController!.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Register Face')),
      body: Column(
        children: [
          if (_capturedImage != null)
            Expanded(
              child: Image.file(File(_capturedImage!.path)),
            ),
          
          if (_capturedImage == null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _getCurrentDirection(),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          
          if (_capturedImage == null)
            Container(
              width: 300,
              height: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(150),
                child: CameraPreview(_cameraController!),
              ),
            ),
          
          Expanded(
            child: ListView.builder(
              itemCount: _successfulSteps.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text(_successfulSteps[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}