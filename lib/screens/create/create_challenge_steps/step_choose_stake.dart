// Step 2: Choose Stake

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/challenge_model.dart';
import '../../../providers/challenge_provider.dart';
import '../../../providers/friend_provider.dart';
import '../../../providers/wallet_provider.dart';
import '../../../utils/theme.dart';
import '../../../utils/animations.dart';
import '../../../widgets/confetti_celebration.dart';
import 'step_group_members.dart';

class StepChooseStake extends StatelessWidget {
  final StakeOption selectedStake;
  final Function(StakeOption) onChanged;
  final bool isGroup;
  final int groupSize;
  final bool isCharity;

  const StepChooseStake({
    super.key,
    required this.selectedStake,
    required this.onChanged,
    this.isGroup = false,
    this.groupSize = 2,
    this.isCharity = false,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlideIn(
            delay: const Duration(milliseconds: 100),
            child: Text(
              'How much are\nyou putting up?',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          SlideIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              isCharity
                  ? 'Both players stake the same amount. Winner keeps their stake. Loser\'s stake goes to charity.'
                  : isGroup
                      ? 'Each player stakes the same amount. Top 3 split the prize pool.'
                      : 'Both players stake the same amount. Winner takes the prize pool.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.textSecondary,
                  ),
            ),
          ),
          if (isCharity && selectedStake.amount <= 0) ...[
            const SizedBox(height: 16),
            SlideIn(
              delay: const Duration(milliseconds: 220),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RivlColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RivlColors.warning.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: RivlColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Charity challenges require a stake amount.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: RivlColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),

          // Prize pool display
          SlideIn(
            delay: const Duration(milliseconds: 250),
            child: isCharity
                ? CharityPrizeDisplay(stake: selectedStake)
                : isGroup
                    ? GroupPrizePoolDisplay(stake: selectedStake, groupSize: groupSize)
                    : Builder(
                        builder: (context) {
                          final opponent = context.read<ChallengeProvider>().selectedOpponent;
                          final isFriend = opponent != null &&
                              context.read<FriendProvider>().isFriend(opponent.id);
                          return AnimatedPrizePool(stake: selectedStake, isFriendChallenge: isFriend);
                        },
                      ),
          ),
          const SizedBox(height: 32),

          // Wallet balance indicator
          SlideIn(
            delay: const Duration(milliseconds: 300),
            child: Consumer<WalletProvider>(
              builder: (context, wallet, _) {
                final insufficient =
                    selectedStake.amount > 0 && wallet.balance < selectedStake.amount;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: insufficient
                        ? RivlColors.warning.withOpacity(0.1)
                        : RivlColors.success.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: insufficient
                          ? RivlColors.warning.withOpacity(0.3)
                          : RivlColors.success.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        insufficient
                            ? Icons.warning_amber_rounded
                            : Icons.account_balance_wallet,
                        size: 18,
                        color: insufficient ? RivlColors.warning : RivlColors.success,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          insufficient
                              ? 'Balance: \$${wallet.balance.toStringAsFixed(0)} — need \$${selectedStake.amount.toStringAsFixed(0)}'
                              : 'Balance: \$${wallet.balance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: insufficient ? RivlColors.warning : RivlColors.success,
                          ),
                        ),
                      ),
                      if (insufficient)
                        Text(
                          'Add funds on next step',
                          style: TextStyle(
                            fontSize: 11,
                            color: RivlColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Stake options
          SlideIn(
            delay: const Duration(milliseconds: 350),
            child: StakeSelector(
              selectedStake: selectedStake,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedPrizePool extends StatelessWidget {
  final StakeOption stake;
  final bool isFriendChallenge;

  const AnimatedPrizePool({super.key, required this.stake, this.isFriendChallenge = false});

  @override
  Widget build(BuildContext context) {
    final isFree = stake.amount == 0;
    final displayPrize = isFriendChallenge ? stake.friendPrize : stake.prize;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RivlColors.primary.withOpacity(0.08),
            RivlColors.primary.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: RivlColors.primary.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Text(
            isFree ? 'Challenge Type' : 'Prize Pool',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          AnimatedValue(
            value: isFree ? 0 : displayPrize,
            prefix: isFree ? '' : '\$',
            decimals: isFree ? 0 : 0,
            duration: const Duration(milliseconds: 600),
            style: TextStyle(
              fontSize: isFree ? 36 : 48,
              fontWeight: FontWeight.bold,
              color: RivlColors.primary,
            ),
          ),
          if (isFree)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Free',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: RivlColors.primary,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            isFree ? 'Just for bragging rights!' : 'Winner takes all!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textSecondary,
                ),
          ),
          if (!isFree) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isFriendChallenge
                    ? RivlColors.success.withOpacity(0.1)
                    : RivlColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isFriendChallenge
                    ? 'You stake ${stake.displayAmount}  |  No fee (friend challenge)'
                    : 'You stake ${stake.displayAmount}  |  3% AI Anti-Cheat Referee fee',
                style: TextStyle(
                  fontSize: 12,
                  color: isFriendChallenge
                      ? RivlColors.success.withOpacity(0.8)
                      : RivlColors.primary.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CharityPrizeDisplay extends StatelessWidget {
  final StakeOption stake;

  const CharityPrizeDisplay({super.key, required this.stake});

  @override
  Widget build(BuildContext context) {
    final isFree = stake.amount <= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.pink.withOpacity(0.08),
            Colors.purple.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.pink.withOpacity(0.15),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Charity Stake',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            isFree ? '\$0' : '\$${stake.amount.toInt()}',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: isFree ? Colors.grey : Colors.pink[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFree
                ? 'Select a stake amount above'
                : 'Loser\'s stake goes to charity',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.textSecondary,
                ),
          ),
          if (!isFree) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: RivlColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Winner keeps their ${stake.displayAmount}  |  No platform fee',
                style: TextStyle(
                  fontSize: 12,
                  color: RivlColors.success.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class StakeSelector extends StatelessWidget {
  final StakeOption selectedStake;
  final Function(StakeOption) onChanged;

  const StakeSelector({super.key, required this.selectedStake, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isCustomSelected = !StakeOption.options
        .any((o) => o.amount == selectedStake.amount);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: StakeOption.options.map((option) {
        final bool isSelected;
        if (option.isCustom) {
          isSelected = isCustomSelected;
        } else {
          isSelected = selectedStake.amount == option.amount;
        }

        return GestureDetector(
          onTap: () {
            if (option.isCustom) {
              _showCustomStakeDialog(context);
            } else {
              onChanged(option);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: (MediaQuery.of(context).size.width - 72) / 3,
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? RivlColors.primary.withOpacity(0.1)
                  : context.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? RivlColors.primary
                    : Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  option.isCustom
                      ? (isCustomSelected
                          ? '\$${selectedStake.amount.toInt()}'
                          : 'Custom')
                      : option.displayAmount,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: isSelected ? RivlColors.primary : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.isCustom
                      ? (isCustomSelected
                          ? 'Win ${selectedStake.displayPrize}'
                          : 'Set amount')
                      : (option.amount == 0
                          ? 'For fun!'
                          : 'Win ${option.displayPrize}'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showCustomStakeDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom Stake'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            prefixText: '\$ ',
            hintText: 'Enter amount (5-500)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= 5 && value <= 500) {
                onChanged(StakeOption.custom(value));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }
}
