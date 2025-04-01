import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';

class PythonChannel {
  // This channel name must match the one in your MainActivity.java
  static const MethodChannel _channel = MethodChannel('gazeDetectionChannel');

  /// Calls the native (Java) side to process the straight frame.
  /// Expects [jpegBytes] as a Uint8List containing the JPEG image.
  /// Returns the Python script's result as a String.
  static Future<String> processStraightFrame(Uint8List jpegBytes) async {
    try {
      final String result =
          await _channel.invokeMethod('processStraightFrame', {
        'jpegBytes': jpegBytes,
      });
      return result;
    } on PlatformException catch (e) {
      return "Error: ${e.message}";
    }
  }
}
