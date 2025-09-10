import 'package:flutter/material.dart';

class StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> stepTitles;
  final Color? activeColor;
  final Color? inactiveColor;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.stepTitles,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeStepColor = activeColor ?? theme.colorScheme.primary;
    final inactiveStepColor = inactiveColor ?? Colors.grey[400]!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: stepTitles.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isActive = index <= currentStep;
          final isCurrent = index == currentStep;

          return Row(
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        isActive ? activeStepColor : inactiveStepColor,
                    child: isCurrent
                        ? Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 16,
                          )
                        : index < currentStep
                            ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? activeStepColor : inactiveStepColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (index < stepTitles.length - 1)
                Container(
                  margin: const EdgeInsets.only(bottom: 28),
                  width: 40,
                  height: 2,
                  color:
                      index < currentStep ? activeStepColor : inactiveStepColor,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class ProgressStepsWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color? progressColor;

  const ProgressStepsWidget({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = progressColor ?? theme.colorScheme.primary;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step ${currentStep + 1} of $totalSteps',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              '${(((currentStep + 1) / totalSteps) * 100).round()}%',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (currentStep + 1) / totalSteps,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}
