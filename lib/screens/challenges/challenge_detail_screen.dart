// screens/challenges/challenge_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/theme.dart';
import '../../utils/animations.dart';
import '../../models/challenge_model.dart';
import '../../widgets/confetti_celebration.dart';
import '../../widgets/add_funds_sheet.dart';
import '../main_screen.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final String challengeId;

  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  DateTime? _lastSyncTime;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Details'),
        elevation: 0,
      ),
      body: Consumer<ChallengeProvider>(
        builder: (context, provider, _) {
          final matches = provider.challenges.where(
            (c) => c.id == widget.challengeId,
          );
          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Challenge not found',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }
          final challenge = matches.first;

          final isCreator = challenge.creatorId == currentUserId;

          // For squad challenges, use team aggregate progress & names
          final int userProgress;
          final int rivalProgress;
          final String userName;
          final String rivalName;

          if (challenge.isTeamVsTeam) {
            final isOnTeamA = challenge.teamA?.memberIds.contains(currentUserId) ?? true;
            if (isOnTeamA) {
              userProgress = challenge.teamAProgress;
              rivalProgress = challenge.teamBProgress;
              userName = challenge.teamA?.name ?? 'Your Squad';
              rivalName = challenge.teamB?.name ?? 'Rival Squad';
            } else {
              userProgress = challenge.teamBProgress;
              rivalProgress = challenge.teamAProgress;
              userName = challenge.teamB?.name ?? 'Your Squad';
              rivalName = challenge.teamA?.name ?? 'Rival Squad';
            }
          } else {
            userProgress = isCreator
                ? challenge.creatorProgress
                : challenge.opponentProgress;
            rivalProgress = isCreator
                ? challenge.opponentProgress
                : challenge.creatorProgress;
            userName = isCreator ? challenge.creatorName : (challenge.opponentName ?? 'You');
            rivalName = isCreator ? (challenge.opponentName ?? 'Opponent') : challenge.creatorName;
          }

          final bool isWinning;
          final isTied = userProgress == rivalProgress;
          if (isTied) {
            isWinning = false;
          } else if (challenge.goalType.higherIsBetter) {
            isWinning = userProgress > rivalProgress;
          } else {
            // Pace: lower is better, 0 means no data
            if (userProgress == 0) {
              isWinning = false;
            } else if (rivalProgress == 0) {
              isWinning = true;
            } else {
              isWinning = userProgress < rivalProgress;
            }
          }
          final bool hasWon;
          if (challenge.isTeamVsTeam && challenge.status == ChallengeStatus.completed) {
            final teamAWon = challenge.winnerId == challenge.creatorId;
            final isOnTeamA = challenge.teamA?.memberIds.contains(currentUserId) ?? false;
            final isOnTeamB = challenge.teamB?.memberIds.contains(currentUserId) ?? false;
            hasWon = (teamAWon && isOnTeamA) || (!teamAWon && isOnTeamB && challenge.winnerId != null);
          } else {
            hasWon = challenge.status == ChallengeStatus.completed &&
                challenge.winnerId == currentUserId;
          }
          final showCelebration = hasWon;

          // Compute timeline progress (how far through the challenge period)
          double timelineProgress = 0.0;
          if (challenge.startDate != null && challenge.endDate != null) {
            final totalDuration =
                challenge.endDate!.difference(challenge.startDate!).inSeconds;
            final elapsed =
                DateTime.now().difference(challenge.startDate!).inSeconds;
            if (totalDuration > 0) {
              timelineProgress = (elapsed / totalDuration).clamp(0.0, 1.0);
            }
          }

          // Compute head-to-head bar fractions
          // For pace-based goals (lower = better), invert the bars
          final double userBarFraction;
          final double rivalBarFraction;
          if (challenge.goalType.higherIsBetter) {
            final maxProgress = (userProgress > rivalProgress)
                ? userProgress
                : rivalProgress;
            userBarFraction =
                maxProgress > 0 ? userProgress / maxProgress : 0.0;
            rivalBarFraction =
                maxProgress > 0 ? rivalProgress / maxProgress : 0.0;
          } else {
            // Pace: lower is better, so the lower value gets the longer bar
            if (userProgress == 0 && rivalProgress == 0) {
              userBarFraction = 0.0;
              rivalBarFraction = 0.0;
            } else {
              final maxVal = (userProgress > rivalProgress)
                  ? userProgress
                  : rivalProgress;
              // Invert: lower time = longer bar
              userBarFraction = userProgress > 0
                  ? (maxVal / userProgress).clamp(0.0, 1.0)
                  : 0.0;
              rivalBarFraction = rivalProgress > 0
                  ? (maxVal / rivalProgress).clamp(0.0, 1.0)
                  : 0.0;
            }
          }

          return ConfettiCelebration(
            celebrate: showCelebration,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // -- Status badge --
                  SlideIn(
                    delay: const Duration(milliseconds: 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: challenge.statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: challenge.statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        challenge.statusDisplayName,
                        style: TextStyle(
                          color: challenge.statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // -- Animated prize amount --
                  SlideIn(
                    delay: const Duration(milliseconds: 80),
                    child: AnimatedValue(
                      value: challenge.prizeAmount,
                      prefix: '\$',
                      decimals: 0,
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: RivlColors.primary,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                  Text(
                    'Prize Pool',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    challenge.timeRemaining,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // -- Timeline progress bar (challenge duration) --
                  if (challenge.status == ChallengeStatus.active &&
                      challenge.startDate != null)
                    SlideIn(
                      delay: const Duration(milliseconds: 120),
                      child: _TimelineBar(progress: timelineProgress),
                    ),
                  if (challenge.status == ChallengeStatus.active)
                    const SizedBox(height: 24),

                  // -- Head-to-head progress comparison --
                  SlideIn(
                    delay: const Duration(milliseconds: 160),
                    child: _HeadToHeadBars(
                      userName: userName,
                      rivalName: rivalName,
                      userProgress: userProgress,
                      rivalProgress: rivalProgress,
                      userFraction: userBarFraction,
                      rivalFraction: rivalBarFraction,
                      goalUnit: challenge.goalType.unit,
                      goalType: challenge.goalType,
                      sectionLabel: challenge.isTeamVsTeam ? 'Squad vs Squad' : 'Head to Head',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // -- VS display with avatars and status indicator --
                  SlideIn(
                    delay: const Duration(milliseconds: 240),
                    child: Card(
                      elevation: 3,
                      shadowColor: Colors.black.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 28),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Current user / team side
                                Expanded(
                                  child: _AvatarColumn(
                                    name: userName,
                                    progress: userProgress,
                                    goalUnit: challenge.goalType.unit,
                                    goalType: challenge.goalType,
                                    color: RivlColors.primary,
                                    gradientColors: const [
                                      RivlColors.primary,
                                      RivlColors.primaryLight,
                                    ],
                                    isLeading: isWinning && !isTied,
                                  ),
                                ),

                                // VS + status indicator
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.grey.shade700
                                                  : Colors.grey.shade300,
                                              Theme.of(context).brightness == Brightness.dark
                                                  ? Colors.grey.shade800
                                                  : Colors.grey.shade100,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'VS',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              color: context.textSecondary,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (challenge.status ==
                                          ChallengeStatus.active) ...[
                                        const SizedBox(height: 10),
                                        _StatusIndicator(
                                          isWinning: isWinning,
                                          isTied: isTied,
                                        ),
                                      ],
                                      if (hasWon) ...[
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: RivlColors.success
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Text(
                                            'You won!',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: RivlColors.success,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Rival / opponent team side
                                Expanded(
                                  child: _AvatarColumn(
                                    name: rivalName,
                                    progress: rivalProgress,
                                    goalUnit: challenge.goalType.unit,
                                    goalType: challenge.goalType,
                                    color: RivlColors.secondary,
                                    gradientColors: const [
                                      Color(0xFFFF6B5B),
                                      Color(0xFFFF9A8B),
                                    ],
                                    isLeading: !isWinning && !isTied &&
                                        rivalProgress > 0,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // -- Details card with colored sections --
                  SlideIn(
                    delay: const Duration(milliseconds: 320),
                    child: Card(
                      elevation: 2,
                      shadowColor: Colors.black.withOpacity(0.06),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          _DetailSection(
                            icon: challenge.goalType.icon,
                            iconColor: RivlColors.primary,
                            bgColor: RivlColors.primary.withOpacity(0.06),
                            label: 'Type',
                            value: challenge.goalType.displayName,
                            isFirst: true,
                          ),
                          _DetailSection(
                            icon: Icons.flag_outlined,
                            iconColor: RivlColors.success,
                            bgColor: RivlColors.success.withOpacity(0.06),
                            label: 'Goal',
                            value:
                                '${challenge.goalType.formatProgress(challenge.goalValue)} ${challenge.goalType.unit}',
                          ),
                          _DetailSection(
                            icon: Icons.schedule_outlined,
                            iconColor: RivlColors.warning,
                            bgColor: RivlColors.warning.withOpacity(0.06),
                            label: 'Duration',
                            value: challenge.duration.displayName,
                          ),
                          _DetailSection(
                            icon: Icons.attach_money,
                            iconColor: RivlColors.secondary,
                            bgColor: RivlColors.secondary.withOpacity(0.06),
                            label: 'Stake',
                            value:
                                '\$${challenge.stakeAmount.toInt()} each',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // -- Expiry countdown for pending challenges --
                  if (challenge.status == ChallengeStatus.pending)
                    SlideIn(
                      delay: const Duration(milliseconds: 380),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: (challenge.isExpired
                                    ? Colors.red
                                    : Colors.orange)
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: (challenge.isExpired
                                      ? Colors.red
                                      : Colors.orange)
                                  .withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 18,
                                color: challenge.isExpired
                                    ? Colors.red
                                    : Colors.orange[700],
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  challenge.expiryTimeRemaining,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: challenge.isExpired
                                        ? Colors.red
                                        : Colors.orange[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // -- Accept / Decline for pending challenges --
                  if (challenge.status == ChallengeStatus.pending &&
                      !challenge.isExpired)
                    SlideIn(
                      delay: const Duration(milliseconds: 400),
                      child: _PendingActions(
                        challenge: challenge,
                        provider: provider,
                      ),
                    ),

                  // -- Sync button --
                  if (challenge.status == ChallengeStatus.active)
                    SlideIn(
                      delay: const Duration(milliseconds: 400),
                      child: ScaleOnTap(
                        onTap: provider.isSyncing
                            ? null
                            : () async {
                                final success =
                                    await provider.syncSteps(challenge);
                                if (success && mounted) {
                                  setState(() {
                                    _lastSyncTime = DateTime.now();
                                  });
                                }
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: provider.isSyncing
                                ? null
                                : const LinearGradient(
                                    colors: [
                                      RivlColors.primary,
                                      RivlColors.primaryLight,
                                    ],
                                  ),
                            color: provider.isSyncing
                                ? context.surfaceVariant
                                : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (provider.isSyncing)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                const Icon(Icons.sync,
                                    color: Colors.white, size: 22),
                              const SizedBox(width: 10),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    provider.isSyncing
                                        ? 'Syncing...'
                                        : 'Sync ${challenge.goalType.displayName}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (_lastSyncTime != null &&
                                      !provider.isSyncing)
                                    Text(
                                      'Last synced ${_formatSyncTime(_lastSyncTime!)}',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.75),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // -- Quick Rematch (completed 1v1 challenges only) --
                  if (challenge.status == ChallengeStatus.completed &&
                      !challenge.isTeamVsTeam) ...[
                    const SizedBox(height: 16),
                    SlideIn(
                      delay: const Duration(milliseconds: 400),
                      child: _QuickRematchCard(challenge: challenge),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatSyncTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ---------------------------------------------------------------------------
// Head-to-head animated progress bars
// ---------------------------------------------------------------------------
class _HeadToHeadBars extends StatelessWidget {
  final String userName;
  final String rivalName;
  final int userProgress;
  final int rivalProgress;
  final double userFraction;
  final double rivalFraction;
  final String goalUnit;
  final GoalType goalType;
  final String sectionLabel;

  const _HeadToHeadBars({
    required this.userName,
    required this.rivalName,
    required this.userProgress,
    required this.rivalProgress,
    required this.userFraction,
    required this.rivalFraction,
    required this.goalUnit,
    required this.goalType,
    this.sectionLabel = 'Head to Head',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sectionLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 14),
            // User bar
            _ProgressBarRow(
              label: userName,
              value: userProgress,
              fraction: userFraction,
              color: RivlColors.primary,
              unit: goalUnit,
              goalType: goalType,
            ),
            const SizedBox(height: 10),
            // Rival bar
            _ProgressBarRow(
              label: rivalName,
              value: rivalProgress,
              fraction: rivalFraction,
              color: RivlColors.secondary,
              unit: goalUnit,
              goalType: goalType,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBarRow extends StatelessWidget {
  final String label;
  final int value;
  final double fraction;
  final Color color;
  final String unit;
  final GoalType goalType;

  const _ProgressBarRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
    required this.unit,
    required this.goalType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${goalType.formatProgress(value)} $unit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedProgress(
          value: fraction,
          color: color,
          backgroundColor: color.withOpacity(0.12),
          height: 10,
          borderRadius: 5,
          duration: const Duration(milliseconds: 900),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Timeline bar for challenge duration
// ---------------------------------------------------------------------------
class _TimelineBar extends StatelessWidget {
  final double progress;

  const _TimelineBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Challenge Timeline',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
            Text(
              '$pct% elapsed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedProgress(
          value: progress,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey.shade600
              : Colors.grey.shade400,
          backgroundColor: context.surfaceVariant,
          height: 6,
          borderRadius: 3,
          duration: const Duration(milliseconds: 800),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar column for the VS display
// ---------------------------------------------------------------------------
class _AvatarColumn extends StatelessWidget {
  final String name;
  final int progress;
  final String goalUnit;
  final GoalType goalType;
  final Color color;
  final List<Color> gradientColors;
  final bool isLeading;

  const _AvatarColumn({
    required this.name,
    required this.progress,
    required this.goalUnit,
    required this.goalType,
    required this.color,
    required this.gradientColors,
    required this.isLeading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Gradient background behind avatar
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                gradientColors[0].withOpacity(0.25),
                gradientColors[1].withOpacity(0.10),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CircleAvatar(
            radius: 36,
            backgroundColor: color.withOpacity(0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        const SizedBox(height: 2),
        Text(
          goalType.formatProgress(progress),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          goalUnit,
          style: TextStyle(
            fontSize: 12,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isLeading) ...[
          const SizedBox(height: 4),
          Icon(Icons.arrow_upward_rounded, size: 16, color: RivlColors.success),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "You're winning!" / "You're behind" status indicator
// ---------------------------------------------------------------------------
class _StatusIndicator extends StatelessWidget {
  final bool isWinning;
  final bool isTied;

  const _StatusIndicator({required this.isWinning, required this.isTied});

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;
    final IconData icon;

    if (isTied) {
      text = 'Tied!';
      color = RivlColors.warning;
      icon = Icons.balance;
    } else if (isWinning) {
      text = "You're winning!";
      color = RivlColors.success;
      icon = Icons.trending_up_rounded;
    } else {
      text = "You're behind";
      color = RivlColors.secondary;
      icon = Icons.trending_down_rounded;
    }

    return PulseAnimation(
      duration: const Duration(milliseconds: 1500),
      minScale: 0.97,
      maxScale: 1.03,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail section rows (replacing flat dividers with colored sections)
// ---------------------------------------------------------------------------
class _DetailSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  const _DetailSection({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(20) : Radius.zero,
          bottom: isLast ? const Radius.circular(20) : Radius.zero,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail row (kept for backward compatibility, styled better)
// ---------------------------------------------------------------------------
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Rematch Card (kept intact with improved styling)
// ---------------------------------------------------------------------------

/// Quick rematch card shown on completed challenges
class _QuickRematchCard extends StatelessWidget {
  final ChallengeModel challenge;

  const _QuickRematchCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id;
    final isCreator = challenge.creatorId == currentUserId;
    final opponentId = isCreator ? challenge.opponentId : challenge.creatorId;
    final opponentName = isCreator ? challenge.opponentName : challenge.creatorName;
    final didWin = challenge.winnerId == currentUserId;

    return Card(
      color: didWin
          ? RivlColors.success.withOpacity(0.05)
          : RivlColors.secondary.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              didWin ? Icons.emoji_events : Icons.replay,
              color: didWin ? Colors.amber : RivlColors.secondary,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              didWin ? 'You won! Run it back?' : 'Rematch?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Same settings vs ${opponentName ?? 'opponent'}',
              style: TextStyle(color: context.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Quick rematch — same settings
                Expanded(
                  child: ScaleOnTap(
                    onTap: () => _startRematch(context, challenge, opponentId, opponentName),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: RivlColors.secondary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.flash_on, size: 20, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Quick Rematch',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Modify & rematch
                Expanded(
                  child: ScaleOnTap(
                    onTap: () => _modifyRematch(context, challenge, opponentId, opponentName),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: RivlColors.primary,
                          width: 2,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.tune, size: 20, color: RivlColors.primary),
                          SizedBox(width: 6),
                          Text(
                            'Modify',
                            style: TextStyle(
                              color: RivlColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Double or nothing
            if (challenge.stakeAmount > 0)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () =>
                      _doubleOrNothing(context, challenge, opponentId, opponentName),
                  child: Text(
                    'Double or Nothing (\$${(challenge.stakeAmount * 2).toInt()})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _startRematch(BuildContext context, ChallengeModel challenge,
      String? opponentId, String? opponentName) async {
    if (opponentId == null) return;

    final provider = context.read<ChallengeProvider>();

    // Set up same challenge parameters
    final opponent = await _getOpponentAsUser(context, opponentId, opponentName);
    if (opponent == null) return;

    provider.setSelectedOpponent(opponent);
    provider.setSelectedGoalType(challenge.goalType);
    provider.setSelectedDuration(challenge.duration);

    // Find matching stake
    final stakeMatch = StakeOption.options.firstWhere(
      (s) => s.amount == challenge.stakeAmount,
      orElse: () => StakeOption.options[0],
    );
    provider.setSelectedStake(stakeMatch);

    // Create the challenge
    final walletBalance = context.read<WalletProvider>().balance;
    final challengeId = await provider.createChallenge(walletBalance: walletBalance);
    if (challengeId != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rematch sent to ${opponentName ?? 'opponent'}!'),
          backgroundColor: RivlColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _modifyRematch(BuildContext context, ChallengeModel challenge,
      String? opponentId, String? opponentName) async {
    if (opponentId == null) return;

    final provider = context.read<ChallengeProvider>();
    final opponent = await _getOpponentAsUser(context, opponentId, opponentName);
    if (opponent == null) return;

    // Pre-fill form with previous settings
    provider.setSelectedOpponent(opponent);
    provider.setSelectedGoalType(challenge.goalType);
    provider.setSelectedDuration(challenge.duration);

    final stakeMatch = StakeOption.options.firstWhere(
      (s) => s.amount == challenge.stakeAmount,
      orElse: () => StakeOption.options[0],
    );
    provider.setSelectedStake(stakeMatch);

    // Navigate to create screen (tab index 2)
    if (context.mounted) {
      Navigator.pop(context);
      MainScreen.onTabSelected?.call(2);
    }
  }

  void _doubleOrNothing(BuildContext context, ChallengeModel challenge,
      String? opponentId, String? opponentName) async {
    if (opponentId == null) return;

    final provider = context.read<ChallengeProvider>();
    final opponent = await _getOpponentAsUser(context, opponentId, opponentName);
    if (opponent == null) return;

    provider.setSelectedOpponent(opponent);
    provider.setSelectedGoalType(challenge.goalType);
    provider.setSelectedDuration(challenge.duration);

    // Double the stake
    final doubleStake = challenge.stakeAmount * 2;
    final stakeMatch = StakeOption.options.firstWhere(
      (s) => s.amount == doubleStake,
      orElse: () => StakeOption.options.last,
    );
    provider.setSelectedStake(stakeMatch);

    final walletBalance = context.read<WalletProvider>().balance;
    final challengeId = await provider.createChallenge(walletBalance: walletBalance);
    if (challengeId != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Double or nothing! \$${doubleStake.toInt()} challenge sent to ${opponentName ?? 'opponent'}!'),
          backgroundColor: RivlColors.secondary,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<dynamic> _getOpponentAsUser(
      BuildContext context, String opponentId, String? opponentName) async {
    // Search for opponent to get their UserModel
    final provider = context.read<ChallengeProvider>();
    if (opponentName != null) {
      await provider.searchUsers(opponentName);
      final results = provider.searchResults;
      final match = results.where((u) => u.id == opponentId).toList();
      if (match.isNotEmpty) return match.first;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Accept / Decline buttons for pending challenges on the detail screen
// ---------------------------------------------------------------------------
class _PendingActions extends StatefulWidget {
  final ChallengeModel challenge;
  final ChallengeProvider provider;

  const _PendingActions({required this.challenge, required this.provider});

  @override
  State<_PendingActions> createState() => _PendingActionsState();
}

class _PendingActionsState extends State<_PendingActions> {
  bool _accepting = false;
  bool _declining = false;

  Future<void> _accept() async {
    var walletBalance = context.read<WalletProvider>().balance;

    // Prompt to add funds if balance is insufficient
    if (widget.challenge.stakeAmount > 0 && walletBalance < widget.challenge.stakeAmount) {
      final funded = await showAddFundsSheet(
        context,
        stakeAmount: widget.challenge.stakeAmount,
        currentBalance: walletBalance,
      );
      if (!funded || !mounted) return;
      // Re-read balance after deposit
      walletBalance = context.read<WalletProvider>().balance;
    }

    setState(() => _accepting = true);
    final success = await widget.provider.acceptChallenge(
      widget.challenge.id,
      walletBalance: walletBalance,
    );
    if (!mounted) return;
    setState(() => _accepting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Challenge accepted! Good luck!'
            : widget.provider.errorMessage ?? 'Failed to accept challenge'),
        backgroundColor: success ? RivlColors.success : RivlColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    widget.provider.clearMessages();

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _decline() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Challenge?'),
        content: const Text('Are you sure you want to decline this challenge?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Decline', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _declining = true);
    final success = await widget.provider.declineChallenge(widget.challenge.id);
    if (!mounted) return;
    setState(() => _declining = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Challenge declined'
            : widget.provider.errorMessage ?? 'Failed to decline challenge'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    widget.provider.clearMessages();

    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Accept button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _accepting || _declining ? null : _accept,
            style: ElevatedButton.styleFrom(
              backgroundColor: RivlColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _accepting
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Accept Challenge',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        // Decline button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _accepting || _declining ? null : _decline,
            style: OutlinedButton.styleFrom(
              foregroundColor: context.textSecondary,
              side: BorderSide(color: context.textSecondary.withOpacity(0.3)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _declining
                ? SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                      color: context.textSecondary, strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Decline',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

