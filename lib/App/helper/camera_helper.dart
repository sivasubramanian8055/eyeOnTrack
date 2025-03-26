import 'package:flutter/material.dart';
import 'front_camera_preview.dart';
import '../modules/controllers/home_controller.dart';

class CameraHelper {
  /// Instead of showing a dialog (which used to set dialogCameraApproved),
  /// simply return the camera preview.
  static Widget buildCameraPreview(HomeController homeController) {
    // Directly return the front camera preview widget.
    return FrontCameraPreview(
      onClose: () {
        homeController.isCameraActive.value = false;
      },
      overlayText: 'Awaiting detection...', // initial overlay text
    );
  }
}
