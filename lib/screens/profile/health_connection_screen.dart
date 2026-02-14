// screens/profile/health_connection_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/health_provider.dart';
import '../../utils/theme.dart';

class HealthConnectionScreen extends StatefulWidget {
  const HealthConnectionScreen({super.key});

  @override
  State<HealthConnectionScreen> createState() => _HealthConnectionScreenState();
}

class _HealthConnectionScreenState extends State<HealthConnectionScreen> {
  bool _isConnecting = false;

  String get _platformName {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'Apple Health';
    if (defaultTargetPlatform == TargetPlatform.android) return 'Google Fit';
    return 'Health App';
  }

  IconData get _platformIcon {
    if (defaultTargetPlatform == TargetPlatform.iOS) return Icons.apple;
    if (defaultTargetPlatform == TargetPlatform.android) return Icons.fitness_center;
    return Icons.health_and_safety;
  }

  Future<void> _toggleConnection(HealthProvider health) async {
    if (_isConnecting) return;
    setState(() => _isConnecting = true);

    if (health.isAuthorized) {
      // Show confirmation dialog before disconnecting
      final shouldDisconnect = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Disconnect Health App?'),
          content: Text(
            'You will no longer sync data from $_platformName. '
            'RIVL will use demo data instead.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (shouldDisconnect == true && mounted) {
        // Disconnect by refreshing with demo data
        health.stopAutoRefresh();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_platformName disconnected'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      // Connect
      final authorized = await health.requestAuthorization();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authorized
                  ? '$_platformName connected successfully'
                  : health.isHealthSupported
                      ? 'Could not connect to $_platformName'
                      : 'Health data is not supported on this platform. Using demo data.',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        if (authorized) {
          health.startAutoRefresh();
        }
      }
    }

    if (mounted) setState(() => _isConnecting = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? RivlColors.darkBackground : RivlColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Health App Connection'),
        centerTitle: true,
      ),
      body: Consumer<HealthProvider>(
        builder: (context, health, _) {
          final isConnected = health.isAuthorized;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // Connection status card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isConnected
                          ? [RivlColors.success.withOpacity(0.9), RivlColors.success.withOpacity(0.7)]
                          : [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.15)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (isConnected ? RivlColors.success : Colors.grey).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _platformIcon,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _platformName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isConnected ? Icons.check_circle : Icons.cancel_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isConnected ? 'Connected' : 'Not Connected',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Connect/Disconnect button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isConnecting ? null : () => _toggleConnection(health),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isConnected ? Colors.red.shade400 : RivlColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isConnecting
                        ? const SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            isConnected ? 'Disconnect' : 'Connect $_platformName',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Data types synced
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.surface,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data We Sync',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      _DataTypeRow(icon: Icons.directions_walk, label: 'Steps', isActive: isConnected),
                      _DataTypeRow(icon: Icons.favorite_rounded, label: 'Heart Rate', isActive: isConnected),
                      _DataTypeRow(icon: Icons.bedtime_outlined, label: 'Sleep', isActive: isConnected),
                      _DataTypeRow(icon: Icons.monitor_heart_outlined, label: 'HRV', isActive: isConnected),
                      _DataTypeRow(icon: Icons.local_fire_department, label: 'Active Calories', isActive: isConnected),
                      _DataTypeRow(icon: Icons.straighten, label: 'Distance', isActive: isConnected),
                      _DataTypeRow(icon: Icons.air, label: 'Blood Oxygen', isActive: isConnected),
                      _DataTypeRow(icon: Icons.speed, label: 'VO2 Max', isActive: isConnected),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Last synced info
                if (isConnected)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sync Info',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(label: 'Last synced', value: _formatLastUpdated(health.metrics.lastUpdated)),
                        const SizedBox(height: 8),
                        _InfoRow(label: 'Auto-refresh', value: 'Every 5 minutes'),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: health.isLoading ? null : () => health.refreshData(),
                            icon: const Icon(Icons.refresh, size: 18),
                            label: Text(health.isLoading ? 'Syncing...' : 'Sync Now'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Privacy note
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RivlColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lock_outline, color: RivlColors.info, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your health data stays on your device and is only used to power RIVL features like challenges, recovery scores, and your health dashboard. We never sell your data.',
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatLastUpdated(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _DataTypeRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _DataTypeRow({required this.icon, required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isActive ? RivlColors.success : context.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isActive ? null : context.textSecondary,
              ),
            ),
          ),
          Icon(
            isActive ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: isActive ? RivlColors.success : Colors.grey.withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: context.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
