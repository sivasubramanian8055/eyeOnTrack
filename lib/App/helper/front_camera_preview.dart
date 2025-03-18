import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../modules/controllers/home_controller.dart';

// Create a global RouteObserver (if not already defined)
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      home: FrontCameraPreview(
        onClose: () {
          debugPrint("FrontCameraPreview closed via onClose callback.");
        },
      ),
    );
  }
}

/// ------------------------------
/// CameraView: Handles Camera Feed and Produces NV21 bytes
/// ------------------------------
class CameraView extends StatefulWidget {
  final String title;
  final String? text;

  /// Callback receives both InputImage (for ML Kit) and NV21 bytes.
  final Function(InputImage inputImage, Uint8List nv21Bytes) onImage;
  final CameraLensDirection initialCameraLensDirection;
  final VoidCallback? onClose;

  const CameraView({
    Key? key,
    required this.title,
    required this.onImage,
    this.text,
    this.initialCameraLensDirection = CameraLensDirection.back,
    this.onClose,
  }) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;

  // Map for rotation compensation.
  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _cameras = await availableCameras();
      for (int i = 0; i < _cameras.length; i++) {
        if (_cameras[i].lensDirection == widget.initialCameraLensDirection) {
          _cameraIndex = i;
          break;
        }
      }
      if (_cameraIndex != -1) {
        await _startLiveFeed();
      } else {
        print('No camera found with the specified lens direction.');
      }
    } catch (e) {
      print('Error during camera initialization: $e');
    }
  }

  Future<void> _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    // Using YUV420 format.
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    try {
      await _controller?.initialize();
      if (!mounted) return;
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    } catch (e) {
      print('Error starting live feed: $e');
    }
  }

  void _processCameraImage(CameraImage image) async {
    // Convert YUV_420_888 → NV21
    final nv21Bytes = _convertYUV420toNV21(image);

    // Compute rotation for ML Kit.
    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    final rotationCompensation =
        _orientations[_controller!.value.deviceOrientation];
    if (rotationCompensation == null) return;

    int finalRotation;
    if (camera.lensDirection == CameraLensDirection.front) {
      finalRotation = (sensorOrientation + rotationCompensation) % 360;
    } else {
      finalRotation = (sensorOrientation - rotationCompensation + 360) % 360;
    }

    final rotation = InputImageRotationValue.fromRawValue(finalRotation);
    if (rotation == null) return;

    final inputImage = InputImage.fromBytes(
      bytes: nv21Bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width, // For NV21, row length = width.
      ),
    );

    // Pass InputImage + NV21 bytes to the callback.
    widget.onImage(inputImage, nv21Bytes);
  }

  /// Converts a YUV_420_888 CameraImage into NV21 bytes.
  Uint8List _convertYUV420toNV21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final frameSize = width * height;
    final nv21 = Uint8List(frameSize + frameSize ~/ 2);

    // Copy Y plane.
    nv21.setRange(0, frameSize, image.planes[0].bytes);

    // Interleave U & V.
    final planeU = image.planes[1];
    final planeV = image.planes[2];
    final uvRowStride = planeV.bytesPerRow;
    final uvPixelStride = planeV.bytesPerPixel ?? 1;
    int uvIndex = frameSize;
    final uvHeight = height ~/ 2;
    final uvWidth = width ~/ 2;
    for (int row = 0; row < uvHeight; row++) {
      int rowOffset = row * uvRowStride;
      for (int col = 0; col < uvWidth; col++) {
        final vIndex = rowOffset + col * uvPixelStride;
        final uIndex = rowOffset + col * (planeU.bytesPerPixel ?? 1);
        // NV21 requires V first, then U.
        nv21[uvIndex++] = planeV.bytes[vIndex];
        nv21[uvIndex++] = planeU.bytes[uIndex];
      }
    }
    return nv21;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _controller != null && _controller!.value.isInitialized
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: CameraPreview(_controller!),
                    ),
                  )
                : Container(color: Colors.black),
            if (widget.text != null)
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black45,
                  child: Text(
                    widget.text!,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (widget.onClose != null)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: widget.onClose,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// ------------------------------
/// DetectorView: A Stateless Wrapper for CameraView
/// ------------------------------
class DetectorView extends StatelessWidget {
  final String title;
  final String? text;

  /// Callback with two parameters.
  final Function(InputImage inputImage, Uint8List nv21Bytes) onImage;
  final CameraLensDirection initialCameraLensDirection;
  final VoidCallback? onClose;

  const DetectorView({
    Key? key,
    required this.title,
    required this.onImage,
    this.text,
    this.initialCameraLensDirection = CameraLensDirection.back,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CameraView(
      title: title,
      text: text,
      onImage: onImage,
      initialCameraLensDirection: initialCameraLensDirection,
      onClose: onClose,
    );
  }
}

/// ------------------------------
/// EyeDisplayWidget: Displays Extracted Eye Images
/// ------------------------------
class EyeDisplayWidget extends StatelessWidget {
  final Uint8List? leftEye;
  final Uint8List? rightEye;

  const EyeDisplayWidget({Key? key, this.leftEye, this.rightEye})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Extracted Eyes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (leftEye != null)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.memory(leftEye!, fit: BoxFit.cover),
              )
            else
              const Text('No left eye'),
            if (rightEye != null)
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.memory(rightEye!, fit: BoxFit.cover),
              )
            else
              const Text('No right eye'),
          ],
        ),
      ],
    );
  }
}

/// ------------------------------
/// FrontCameraPreview: Face Detection, Eye Extraction & Gaze via Face Orientation
/// ------------------------------
class FrontCameraPreview extends StatefulWidget {
  final VoidCallback onClose;
  final String overlayText;

  const FrontCameraPreview({
    Key? key,
    required this.onClose,
    this.overlayText = 'Awaiting detection...',
  }) : super(key: key);

  @override
  State<FrontCameraPreview> createState() => _FrontCameraPreviewState();
}

class _FrontCameraPreviewState extends State<FrontCameraPreview> {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );
  String _text = '';
  final _cameraLensDirection = CameraLensDirection.front;
  Uint8List? _leftEyeBytes;
  Uint8List? _rightEyeBytes;
  bool _lookedLeft = false;
  bool _lookedRight = false;
  bool _rewardTriggered = false; // ensure reward is triggered only once
  Timer? _rewardTimer;
  DateTime? _lastProcessTime;

  @override
  void initState() {
    super.initState();
    debugPrint("FrontCameraPreview initState called.");
    _text = widget.overlayText;
    final HomeController homeController = Get.find<HomeController>();
    homeController.onTriggerRewardFromCamera = _triggerReward;
    // _startRewardTimer();
  }

  @override
  void dispose() {
    debugPrint("FrontCameraPreview dispose called.");
    _rewardTimer?.cancel();
    _faceDetector.close();
    super.dispose();
  }

  /// Starts a timer that triggers reward after 10 seconds.
  void _startRewardTimer() {
    debugPrint("Starting reward timer.");
    _rewardTimer?.cancel();
    _rewardTimer = Timer(const Duration(seconds: 10), () {
      debugPrint("Reward timer expired, mounted = $mounted");
      if (mounted && !_rewardTriggered) {
        _triggerReward();
      }
    });
  }

  /// Triggers the reward by calling HomeController.handleCameraReward
  /// and then pops this view to destroy the widget instance.
  void _triggerReward() {
    try {
      // Ensure HomeController is registered with GetX (via Get.put(HomeController()) etc.)
      HomeController controller = Get.find<HomeController>();
      controller.handleCameraReward(
        context,
        lookedLeft: _lookedLeft,
        lookedRight: _lookedRight,
      );
    } catch (e) {
      debugPrint("Error triggering reward: $e");
    }
  }

  // Convert NV21 bytes to RGB image using the image package.
  img.Image convertNV21ToRGB(Uint8List nv21Bytes, int width, int height) {
    final frameSize = width * height;
    final outImg = img.Image(width: width, height: height);

    int yp = 0;
    for (int j = 0; j < height; j++) {
      int uvp = frameSize + (j >> 1) * width;
      int u = 0, v = 0;
      for (int i = 0; i < width; i++, yp++) {
        int y = (0xff & nv21Bytes[yp]) - 16;
        if (y < 0) y = 0;
        if ((i & 1) == 0) {
          v = (0xff & nv21Bytes[uvp++]) - 128;
          u = (0xff & nv21Bytes[uvp++]) - 128;
        }
        int y1192 = 1192 * y;
        int r = y1192 + 1634 * v;
        int g = y1192 - 833 * v - 400 * u;
        int b = y1192 + 2066 * u;
        r = r.clamp(0, 262143);
        g = g.clamp(0, 262143);
        b = b.clamp(0, 262143);
        int red = ((r << 6) & 0xff0000) >> 16;
        int green = ((g >> 2) & 0xff00) >> 8;
        int blue = (b >> 10) & 0xff;
        outImg.setPixelRgb(i, j, red, green, blue);
      }
    }
    return outImg;
  }

  // Crop a 150x150 region centered at the given eye position.
  img.Image cropEye(img.Image rgbImage, Point<double> eyePosition) {
    final centerX = eyePosition.x.round();
    final centerY = eyePosition.y.round();
    int cropX = centerX - 75;
    int cropY = centerY - 75;
    cropX = cropX.clamp(0, rgbImage.width - 150);
    cropY = cropY.clamp(0, rgbImage.height - 150);
    return img.copyCrop(rgbImage, x: cropX, y: cropY, width: 150, height: 150);
  }

  // Face detection & gaze determination using face orientation (Euler Y).
  Future<void> _processImage(InputImage inputImage, Uint8List nv21Bytes) async {
    final now = DateTime.now();
    if (_lastProcessTime != null &&
        now.difference(_lastProcessTime!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastProcessTime = now;

    print('Starting face detection...');
    final faces = await _faceDetector.processImage(inputImage);
    setState(() {
      _text = faces.isNotEmpty ? 'Face detected' : 'No face detected';
    });

    // If a face is detected, use its headEulerAngleY to decide gaze direction.
    if (faces.isNotEmpty) {
      // For simplicity, use the first detected face.
      final face = faces.first;
      // headEulerAngleY returns the rotation (in degrees) around the Y axis.
      final eulerY = face.headEulerAngleY;
      // You can adjust thresholds as needed.
      String gaze;
      if (eulerY != null) {
        if (eulerY > 10) {
          gaze = 'left';
          _lookedLeft = true;
        } else if (eulerY < -10) {
          gaze = 'right';
          _lookedRight = true;
        } else {
          gaze = 'straight';
        }
        setState(() {
          _text = 'Looking $gaze';
        });
      }
    }
    setState(() {});
  }

  // This function determines the reward based on whether the user has looked left and/or right.
  void _handleReward() async {
    int reward = 0;
    String finalMessage = "";
    if (_lookedLeft && _lookedRight) {
      reward = 10;
      finalMessage =
          "You looked both left and right. You have been rewarded 10 points!";
    } else if (_lookedLeft) {
      reward = 5;
      finalMessage =
          "You looked left to see for vehicles. You have been partially rewarded 5 points!";
    } else if (_lookedRight) {
      reward = 5;
      finalMessage =
          "You looked right for incoming vehicles. You have been partially rewarded 5 points!";
    } else {
      finalMessage = "You haven't looked left or right. No reward generated.";
    }

    // Show a dialog saying "Calculating rewards..." until the reward is updated.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const AlertDialog(
          title: Text("Reward"),
          content: Text("Calculating rewards..."),
        );
      },
    );

    // --- Backend functionality disabled ---
    // String userId = userLoginModel?.id.toString() ?? "defaultUserId";
    // await FirebaseFirestore.instance.collection('reword').doc(userId).set({
    //   "reward": reward,
    //   "timestamp": DateTime.now().toIso8601String(),
    // });
    // ------------------------------------------

    // Dismiss the "Calculating rewards..." dialog.
    Navigator.of(context).pop();

    // Show the final reward message.
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reward"),
          content: Text(finalMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset the gaze flags.
                setState(() {
                  _lookedLeft = false;
                  _lookedRight = false;
                });
              },
              child: const Text("OK"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Upper portion: Camera preview & face detection.
          Expanded(
            flex: 2,
            child: DetectorView(
              title: 'Face Detector',
              onImage: _processImage,
              initialCameraLensDirection: _cameraLensDirection,
              onClose: () {
                if (!_rewardTriggered) {
                  _triggerReward();
                }
              },
              text: _text,
            ),
          ),
          // Lower portion: Display extracted eye images.
          Expanded(
            flex: 1,
            child: EyeDisplayWidget(
              leftEye: _leftEyeBytes,
              rightEye: _rightEyeBytes,
            ),
          ),
        ],
      ),
    );
  }
}
