//// filepath: /C:/Users/yosiv/OneDrive/Desktop/2024-summer-research-project-main/DemoTracker/lib/App/helper/eye_gaze_model.dart
import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';

class EyeGazeModel {
  Interpreter? _interpreter;

  // Class labels: 0: 'down', 1: 'left', 2: 'right', 3: 'straight', 4: 'up'
  final List<String> classLabels = ['down', 'left', 'right', 'straight', 'up'];

  EyeGazeModel() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('models/eye_gaze_model.tflite');
      print("Model loaded successfully");
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  /// Preprocess your eye image here.
  /// Replace the following with your proper preprocessing – for example,
  /// resize, normalize, and reshape the image to the expected input shape.
  List<double> preprocessEye(/*Your image parameter*/) {
    // Dummy preprocessing – replace with real code.
    return List.filled(224 * 224 * 3, 0.0); // Example for a 224x224 RGB image.
  }

  /// Predict gaze direction for a given eye image input.
  /// Replace the parameter type with what you use (e.g., Image, Uint8List, etc.)
  Future<Map<String, dynamic>> predictEyeGaze(/*Your image parameter*/) async {
    // Preprocess the eye image.
    List<double> processedEye = preprocessEye();

    // Reshape input to [1, height, width, channels]
    // For this example assume input shape is [1, 224, 224, 3].
    var input = [processedEye];

    // Allocate output: adjust output size if your model differs.
    var output = List.generate(1, (_) => List.filled(5, 0.0));

    if (_interpreter == null) {
      return {'label': 'unknown', 'raw': null};
    }

    _interpreter!.run(input, output);

    // Find predicted label.
    int maxIndex = 0;
    for (int i = 1; i < output[0].length; i++) {
      if (output[0][i] > output[0][maxIndex]) maxIndex = i;
    }
    String predictedLabel = classLabels[maxIndex];
    return {'label': predictedLabel, 'raw': output};
  }
}
