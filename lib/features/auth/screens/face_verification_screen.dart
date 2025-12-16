import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/aws_rekognition_service.dart';

class FaceVerificationScreen extends StatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  State<FaceVerificationScreen> createState() => _FaceVerificationScreenState();
}

class _FaceVerificationScreenState extends State<FaceVerificationScreen> 
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
  bool _isVerifying = false;
  
  late CameraDescription frontCamera;
  XFile? _capturedImage;
  final List<String> _successfulSteps = [];

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
    frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
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
      debugPrint('Error processing camera image: $e');
    }
  }

  void _handleFaceDetection(Face face) {
    if (!_isCaptured && !_isVerifying) {
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
            _captureAndVerifyImage();
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
      _addSuccessfulStep('Face Ready For Verification');
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
      if (rotationCompensation == null) {
        return null;
      }
      
      if (frontCamera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    
    if (rotation == null) {
      return null;
    }
    
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }
    
    if (image.planes.length != 1) {
      return null;
    }
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

  Future<void> _captureAndVerifyImage() async {
    if (_cameraController!.value.isTakingPicture || _isVerifying) return;
    
    setState(() => _isVerifying = true);
    
    try {
      // Stop image stream BEFORE taking picture
      await _cameraController!.stopImageStream();
      
      final XFile file = await _cameraController!.takePicture();
      setState(() {
        _isCaptured = true;
        _capturedImage = file;
      });
      
      // Verify face
      await _verifyFace(file);
    } catch (e) {
      debugPrint('Error capturing image: $e');
      setState(() => _isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e')),
        );
      }
    }
  }

  Future<void> _verifyFace(XFile image) async {
  try {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    final userData = await Supabase.instance.client
        .from('users')
        .select('face_id')
        .eq('id', userId)
        .single();

    final storedFaceId = userData['face_id'];
    if (storedFaceId == null) {
      throw Exception('No registered face found');
    }

    final awsService = AWSRekognitionService();
    const collectionId = 'billpay';

    // Search face in AWS collection
    final isMatch = await awsService.searchFaceByImage(
      imagePath: image.path,
      collectionId: collectionId,
      similarityThreshold: 90.0,
    );

    // Dispose camera BEFORE navigation
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }

    if (!mounted) return;

    if (isMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Face verified successfully!')),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Face does not match. Please try again.')),
      );
      Navigator.of(context).pop(false);
    }
  } catch (e) {
    debugPrint('Error verifying face: $e');
    
    if (_cameraController != null) {
      await _cameraController!.dispose();
      _cameraController = null;
    }
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Verification failed: $e')),
    );
    Navigator.of(context).pop(false);
  }
}

  String _getCurrentDirection() {
    if (_isVerifying) {
      return 'Verifying your face...';
    } else if (!_isFaceInFrame) {
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
      return 'Verifying...';
    }
  }

  @override
  void dispose() {
    _faceDetector.close();
    if (_cameraController != null) {
      _cameraController!.dispose();
    }
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Face')),
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
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          
          if (_capturedImage == null)
            SizedBox(
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
                  leading: const Icon(Icons.check_circle, color: Colors.green),
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