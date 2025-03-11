//// filepath: /C:/Users/yosiv/OneDrive/Desktop/2024-summer-research-project-main/DemoTracker/lib/App/helper/camera_helper.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'front_camera_preview.dart';
import '../modules/controllers/home_controller.dart';

class CameraHelper {
  /// Shows a dialog asking the user if they want to check their awareness.
  /// On “Yes” (for Android), it activates the camera preview.
  static void showAwarenessDialog(
      BuildContext context, HomeController homeController) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Awareness Check"),
          content:
              const Text("Do you want to check your awareness while crossing?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (Platform.isAndroid) {
                  homeController.dialogCameraApproved.value = true;
                }
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  /// Builds the front camera preview widget.
  static Widget buildCameraPreview(HomeController homeController) {
    return FrontCameraPreview(
      onClose: () {
        homeController.isCameraActive.value = false;
        homeController.dialogCameraApproved.value = false;
      },
      overlayText: 'Awaiting detection...', // initial overlay text
    );
  }
}
