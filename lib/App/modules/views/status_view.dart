import 'package:flutter/material.dart';

class Status_view extends StatelessWidget {
  final int totalAwarenessChecks;
  final int successfulAwarenessChecks;
  final int partialAwarenessChecks;
  final int failedAwarenessChecks;
  final int totalJourneySteps;
  final int totalRewardsEarned;

  const Status_view({
    Key? key,
    required this.totalAwarenessChecks,
    required this.successfulAwarenessChecks,
    required this.partialAwarenessChecks,
    required this.failedAwarenessChecks,
    required this.totalJourneySteps,
    required this.totalRewardsEarned,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Make the dialog bigger by reducing its padding from screen edges
      insetPadding: const EdgeInsets.all(16),
      // Round the corners a bit (optional)
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // Remove default title spacing so we can place the close button at top-right
      titlePadding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      // Title: "Journey Statistics" on the left, X (close) icon on the right
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Journey Statistics"),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(), // Close the dialog
          ),
        ],
      ),
      // Constrain the dialog so it won't exceed 70% of screen height
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: three stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatRow("Total Awareness", totalAwarenessChecks),
                _buildStatRow("Successful Checks", successfulAwarenessChecks),
                _buildStatRow("Partial Checks", partialAwarenessChecks),
              ],
            ),
            const SizedBox(height: 16),
            // Row 2: three stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatRow("Failed Checks", failedAwarenessChecks),
                _buildStatRow("Total Steps", totalJourneySteps),
                _buildStatRow("Total Rewards", totalRewardsEarned),
              ],
            ),
          ],
        ),
      ),
      // No bottom actions, because we have the close button at the top right
    );
  }

  // Keep the same function name, just use a smaller card layout
  Widget _buildStatRow(String label, int value) {
    final iconData = _getIconForLabel(label);

    return SizedBox(
      width: 110, // Make each card small so it fits easily
      height: 110,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconData, size: 20, color: Colors.green),
              const SizedBox(height: 4),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // You can adjust these icons as you like
  IconData _getIconForLabel(String label) {
    switch (label) {
      case "Total Awareness":
        return Icons.visibility;
      case "Successful Checks":
        return Icons.check_circle;
      case "Partial Checks":
        return Icons.timelapse;
      case "Failed Checks":
        return Icons.cancel;
      case "Total Steps":
        return Icons.directions_walk;
      case "Total Rewards":
        return Icons.card_giftcard;
      default:
        return Icons.info;
    }
  }
}
