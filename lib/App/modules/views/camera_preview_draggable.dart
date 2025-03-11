//// filepath: /C:/Users/yosiv/OneDrive/Desktop/2024-summer-research-project-main/DemoTracker/lib/App/helper/camera_preview_draggable.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../modules/controllers/home_controller.dart';
import '../../helper/camera_helper.dart';

class CameraPreviewDraggable extends StatefulWidget {
  final HomeController controller;
  const CameraPreviewDraggable({Key? key, required this.controller})
      : super(key: key);

  @override
  _CameraPreviewDraggableState createState() => _CameraPreviewDraggableState();
}

class _CameraPreviewDraggableState extends State<CameraPreviewDraggable> {
  // Initial position within the Stack.
  Offset position = const Offset(10, 120);
  // Dimensions for the preview widget.
  static const double previewWidth = 150;
  static const double previewHeight = 400;

  @override
  Widget build(BuildContext context) {
    // Get screen size to clamp the widget within visible boundaries.
    final Size screenSize = MediaQuery.of(context).size;
    return Obx(() {
      // Only render the camera preview when isCameraActive is true.
      if (!widget.controller.isCameraActive.value) {
        return const SizedBox.shrink();
      }
      return Positioned(
        left: position.dx,
        top: position.dy,
        child: GestureDetector(
          onPanUpdate: (DragUpdateDetails details) {
            // Update position with the delta of the drag.
            setState(() {
              position += details.delta;
              // Clamp X in range [0, screen width - previewWidth].
              if (position.dx < 0) {
                position = Offset(0, position.dy);
              } else if (position.dx > screenSize.width - previewWidth) {
                position = Offset(screenSize.width - previewWidth, position.dy);
              }
              // Clamp Y in range [0, screen height - previewHeight].
              if (position.dy < 0) {
                position = Offset(position.dx, 0);
              } else if (position.dy > screenSize.height - previewHeight) {
                position =
                    Offset(position.dx, screenSize.height - previewHeight);
              }
            });
          },
          child: SizedBox(
            width: previewWidth,
            height: previewHeight,
            child: CameraHelper.buildCameraPreview(widget.controller),
          ),
        ),
      );
    });
  }
}
