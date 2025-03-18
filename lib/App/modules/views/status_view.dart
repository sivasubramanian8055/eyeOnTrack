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
      title: const Text("Journey Statistics"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatRow("Total Awareness Checks", totalAwarenessChecks),
          _buildStatRow("Successful Checks", successfulAwarenessChecks),
          _buildStatRow("Partial Checks", partialAwarenessChecks),
          _buildStatRow("Failed Checks", failedAwarenessChecks),
          _buildStatRow("Total Steps", totalJourneySteps),
          _buildStatRow("Total Rewards Earned", totalRewardsEarned),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("OK"),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value.toString(),
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
