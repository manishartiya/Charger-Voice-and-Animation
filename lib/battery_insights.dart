import 'package:flutter/material.dart';
import 'preferences_panels.dart';

String formatRemaining(num? milliseconds) {
  if (milliseconds == null || milliseconds < 0) return 'Learning…';
  if (milliseconds == 0) return 'Complete';
  final minutes = (milliseconds / 60000).ceil();
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  return minutes % 60 == 0 ? '$hours hr' : '$hours hr ${minutes % 60} min';
}

class RemainingTimeCard extends StatelessWidget {
  const RemainingTimeCard({super.key, required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    final plugged = data['plugged'] == true;
    final energy = data['energy'] as Map? ?? {};
    final remaining = energy['remainingMs'] as num?;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D2D59), Color(0xFF27213E)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6C5384)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC5B0).withValues(alpha: .12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              plugged
                  ? Icons.electric_bolt_rounded
                  : Icons.hourglass_bottom_rounded,
              color: const Color(0xFFFFC5B0),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plugged ? 'UNTIL FULL' : 'BATTERY TIME LEFT',
                  style: const TextStyle(
                    color: Color(0xFFD1B8E9),
                    fontSize: 10,
                    letterSpacing: 1.7,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  !plugged && remaining == 0
                      ? 'Battery empty'
                      : formatRemaining(remaining),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  remaining == null
                      ? 'Waiting for enough battery readings'
                      : '${energy['estimateSource'] ?? 'Estimate'} · varies with use',
                  style: const TextStyle(
                    color: Color(0xFFBFB3D1),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BatteryInsights extends StatelessWidget {
  const BatteryInsights({
    super.key,
    required this.data,
    required this.onAction,
  });
  final Map<String, dynamic> data;
  final Future<void> Function(String, [Map<String, dynamic>?]) onAction;
  @override
  Widget build(BuildContext context) {
    final energy = data['energy'] as Map? ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RemainingTimeCard(data: data),
        const SizedBox(height: 16),
        SettingsCard(
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show time on Dashboard'),
              value: data['showTimeEstimate'] != false,
              onChanged: (value) =>
                  onAction('settings', {'showTimeEstimate': value}),
            ),
            const Text(
              'Time to full uses your phone’s estimate when available. Otherwise, estimates need at least a 2% change over two minutes. Battery time left reflects recent use and changes with your activity.',
              style: TextStyle(
                color: Color(0xFFABA4BF),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsCard(
          children: [
            const Icon(Icons.apps_rounded, color: Color(0xFFFFC5B0), size: 30),
            const SizedBox(height: 12),
            const Text(
              'Which apps used your battery?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'See each app’s battery consumption in your phone’s battery report. Android keeps those figures in system settings; Charge Voice cannot read them directly.',
              style: TextStyle(
                color: Color(0xFFABA4BF),
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => onAction('batteryUsage'),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('View app battery usage'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsCard(
          children: [
            const Text(
              'Recent battery trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              '${energy['observedChange'] ?? 0}% ${data['plugged'] == true ? 'gained' : 'used'} in ${energy['observedMinutes'] ?? 0} min',
              style: const TextStyle(color: Color(0xFFB8A4FF), fontSize: 22),
            ),
            const SizedBox(height: 8),
            const Text(
              'Whole-phone change during the current observation window. Keep monitoring enabled to gather readings in the background.',
              style: TextStyle(
                color: Color(0xFFABA4BF),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SettingsCard(
          children: [
            const Text(
              'A quieter notification shade',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              data['notifications'] == false
                  ? 'Notifications are hidden. Charging monitoring can keep running.'
                  : 'Turn off Charge Voice notifications in Android settings to hide the monitor card.',
              style: const TextStyle(
                color: Color(0xFFABA4BF),
                fontSize: 12,
                height: 1.5,
              ),
            ),
            TextButton.icon(
              onPressed: () => onAction('notificationSettings'),
              icon: const Icon(Icons.notifications_off_outlined),
              label: const Text('Notification visibility'),
            ),
            const Text(
              'Android may still show an Active apps entry for background monitoring.',
              style: TextStyle(color: Color(0xFFABA4BF), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
