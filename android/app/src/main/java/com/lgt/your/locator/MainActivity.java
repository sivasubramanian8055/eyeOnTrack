package com.lgt.your.locator;

import io.flutter.embedding.android.FlutterFragmentActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import com.chaquo.python.Python;
import com.chaquo.python.android.AndroidPlatform;

public class MainActivity extends FlutterFragmentActivity {
    // This channel name must match what you use on the Flutter side.
    private static final String CHANNEL = "gazeDetectionChannel";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // Initialize Chaquopy's Python environment if not already started.
        if (!Python.isStarted()) {
            Python.start(new AndroidPlatform(this));
        }

        // Set up the MethodChannel to listen for calls from Flutter.
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler((call, result) -> {
                if (call.method.equals("processStraightFrame")) {
                    // Retrieve the JPEG bytes sent from Flutter.
                    byte[] imageBytes = call.argument("jpegBytes");
                    if (imageBytes == null) {
                        result.error("NO_BYTES", "No image bytes received", null);
                        return;
                    }
                    try {
                        // Get the Python instance and load your module (process_image.py)
                        Python py = Python.getInstance();
                        Object pyResult = py.getModule("process_image")
                            .callAttr("process_straight_frame", imageBytes);
                        // Return the processed eye image (as Base64 string, for example)
                        result.success(pyResult);
                    } catch (Exception e) {
                        result.error("PYTHON_ERROR", e.getLocalizedMessage(), null);
                    }
                } else {
                    result.notImplemented();
                }
            });
    }
}
