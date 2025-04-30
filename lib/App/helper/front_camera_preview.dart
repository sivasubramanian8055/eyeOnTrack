import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http; // <-- Import http for API calls
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

/// A simple Debouncer to prevent too-frequent actions.
class Debouncer {
  final Duration delay;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({required this.delay});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }
}

/// ------------------------------
/// FrontCameraPreview: Face Detection, Eye Extraction & Gaze
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
  final debouncer = Debouncer(delay: Duration(milliseconds: 500));
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

  // -- ADDED: We'll store the results from the API in this array.
  final List<String> _apiResults = [];
  final List<Future> _pendingApiCalls = [];
  // We'll ensure we only call the API once every X seconds:
  DateTime? _lastStraightCallTime;
  final Duration _straightCooldown = const Duration(seconds: 1);

  @override
  void initState() {
    super.initState();
    debugPrint("FrontCameraPreview initState called.");
    _text = widget.overlayText;
    final HomeController homeController = Get.find<HomeController>();
    homeController.onTriggerRewardFromCamera = _triggerReward;
  }

  @override
  void dispose() {
    debugPrint("FrontCameraPreview dispose called.");
    _rewardTimer?.cancel();
    _faceDetector.close();
    super.dispose();
  }

  /// Optionally start a reward timer if you want an auto trigger. Disabled by default.
  void _startRewardTimer() {
    debugPrint("Starting reward timer.");
    _rewardTimer?.cancel();
    _rewardTimer = Timer(const Duration(seconds: 6), () {
      debugPrint("Reward timer expired, mounted = $mounted");
      if (mounted && !_rewardTriggered) {
        _triggerReward();
      }
    });
  }

  /// Convert NV21 bytes to RGB using the image package.
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

  /// Convert NV21 to JPEG bytes
  Uint8List nv21ToJpeg(Uint8List nv21Bytes, int width, int height) {
    final rgbImage = convertNV21ToRGB(nv21Bytes, width, height);
    return Uint8List.fromList(img.encodeJpg(rgbImage, quality: 80));
  }

  /// Make the API call with the base64 of the JPEG image
  Future<void> _callApiWithFrame(
      Uint8List nv21Bytes, int width, int height) async {
    try {
      // 1) Convert to JPEG.
      final jpegBytes = nv21ToJpeg(nv21Bytes, width, height);
      final imgDecoded = img.decodeImage(jpegBytes);
      if (imgDecoded != null) {
        final rotated = img.copyRotate(imgDecoded, angle: 270);
        final rotatedJpegBytes = Uint8List.fromList(img.encodeJpg(rotated));
        final base64Image = base64Encode(rotatedJpegBytes);

        // 2) POST to your endpoint.
        final url =
            Uri.parse("https://persuasive.research.cs.dal.ca/eyesontrack/api");

        // Wrap the post call in a Future and add it to _pendingApiCalls.
        final apiCall = http
            .post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "image_data": base64Image,
          }),
        )
            .then((response) {
          if (response.statusCode == 200) {
            // Suppose your server returns JSON like: { "result": "left" }
            final data = jsonDecode(response.body);
            final String result = data["result"]?.toString() ?? "unknown";
            _apiResults.add(result);
            debugPrint("API call success: $result");
          } else {
            debugPrint("API call failed. status=${response.statusCode}");
          }
        }).catchError((e) {
          debugPrint("Error calling API: $e");
        });

        _pendingApiCalls.add(apiCall);
        // Remove the call from pending when done.
        apiCall.whenComplete(() {
          _pendingApiCalls.remove(apiCall);
        });
      }
    } catch (e) {
      debugPrint("Error calling API: $e");
    }
  }

  /// Detect face & determine gaze
  Future<void> _processImage(InputImage inputImage, Uint8List nv21Bytes) async {
    final now = DateTime.now();
    // Skip if we processed too recently
    if (_lastProcessTime != null &&
        now.difference(_lastProcessTime!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastProcessTime = now;

    final faces = await _faceDetector.processImage(inputImage);
    setState(() {
      _text = faces.isNotEmpty ? 'Face detected' : 'No face detected';
    });

    if (faces.isNotEmpty) {
      final face = faces.first;
      final eulerY = face.headEulerAngleY;
      if (eulerY != null) {
        String gaze;
        if (eulerY > 10) {
          gaze = 'left';
          _lookedLeft = true;
        } else if (eulerY < -10) {
          gaze = 'right';
          _lookedRight = true;
        } else {
          gaze = 'straight';
        }
        setState(() => _text = 'Looking $gaze');

        // If user is looking straight, we do the API call every _straightCooldown
        if (gaze == 'straight') {
          if (_lastStraightCallTime == null ||
              now.difference(_lastStraightCallTime!) >= _straightCooldown) {
            _lastStraightCallTime = now;
            _callApiWithFrame(
              nv21Bytes,
              inputImage.metadata!.size.width.toInt(),
              inputImage.metadata!.size.height.toInt(),
            );
          }
        }
      }
    }
  }

  /// Decide when to trigger reward
  void _triggerReward() async {
    if (_rewardTriggered) {
      debugPrint("Reward has already been triggered.");
      return;
    }
    _rewardTriggered = true;
    debugPrint("Triggering reward...");

    // // Wait until all pending API calls complete.
    // if (_pendingApiCalls.isNotEmpty) {
    //   debugPrint(
    //       "Waiting for pending API calls to complete before triggering reward.");
    //   await Future.wait(_pendingApiCalls);
    // }
    // debugPrint("All pending API calls completed. Now handling reward.");
    _handleReward();
  }

  /// Evaluate results
  void _handleReward() async {
    final HomeController homeController = Get.find<HomeController>();

    // Determine API detection results.
    // (Note: In your code, "Gaze: right" is used to set apiSawLeft and vice versa.
    // Adjust these as needed for your actual API response.)
    bool apiSawLeft = _apiResults.contains("Gaze: right");
    bool apiSawRight = _apiResults.contains("Gaze: left");
    debugPrint(
        "API results: $_apiResults, apiSawLeft: $apiSawLeft, apiSawRight: $apiSawRight");

    await homeController.handleCameraReward(
      context,
      lookedLeft: apiSawLeft || _lookedLeft,
      lookedRight: apiSawRight || _lookedRight,
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
                _triggerReward();
                widget.onClose();
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
