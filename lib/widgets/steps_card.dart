// widgets/steps_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../utils/theme.dart';

class StepsCard extends StatelessWidget {
  const StepsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, health, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Steps info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Steps",
                        style: RivlTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        health.todayStepsFormatted,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.flag,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Goal: ${health.formatSteps(health.dailyGoal)}',
                            style: RivlTextStyles.caption,
                          ),
                          if (health.goalReached) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: RivlColors.success,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Progress ring
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: health.goalProgress,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          RivlColors.primary,
                        ),
                      ),
                      Text(
                        '${(health.goalProgress * 100).toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
