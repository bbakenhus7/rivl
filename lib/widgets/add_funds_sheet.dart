// widgets/add_funds_sheet.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/theme.dart';

/// Shows an "Add Funds" bottom sheet when the user doesn't have enough balance.
///
/// Returns `true` if the deposit was successful and balance should now be
/// sufficient, `false` if the user cancelled or the deposit failed.
Future<bool> showAddFundsSheet(
  BuildContext context, {
  required double stakeAmount,
  required double currentBalance,
}) async {
  final walletProvider = context.read<WalletProvider>();
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ChangeNotifierProvider.value(
      value: walletProvider,
      child: _AddFundsSheet(
        stakeAmount: stakeAmount,
        currentBalance: currentBalance,
      ),
    ),
  );
  return result == true;
}

class _AddFundsSheet extends StatefulWidget {
  final double stakeAmount;
  final double currentBalance;

  const _AddFundsSheet({
    required this.stakeAmount,
    required this.currentBalance,
  });

  @override
  State<_AddFundsSheet> createState() => _AddFundsSheetState();
}

class _AddFundsSheetState extends State<_AddFundsSheet> {
  final _amountController = TextEditingController();
  bool _depositSucceeded = false;

  double get _shortfall => (widget.stakeAmount - widget.currentBalance).ceilToDouble();

  List<double> get _suggestedAmounts {
    // Always include the exact shortfall (rounded up to nearest dollar),
    // plus standard tiers that cover the shortfall.
    final amounts = <double>{};
    final minNeeded = _shortfall.clamp(10.0, double.infinity);
    amounts.add(minNeeded);
    for (final tier in [25.0, 50.0, 100.0, 200.0]) {
      if (tier >= minNeeded) amounts.add(tier);
    }
    return amounts.toList()..sort();
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill with the minimum needed
    final minNeeded = _shortfall.clamp(10.0, double.infinity);
    _amountController.text = minNeeded.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Icon + Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: RivlColors.warning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: RivlColors.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Insufficient Funds',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add funds to continue',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Balance breakdown card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _BalanceRow(
                    label: 'Entry stake',
                    value: '\$${widget.stakeAmount.toStringAsFixed(0)}',
                    color: context.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  _BalanceRow(
                    label: 'Your balance',
                    value: '\$${widget.currentBalance.toStringAsFixed(2)}',
                    color: RivlColors.error,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _BalanceRow(
                    label: 'Amount needed',
                    value: '\$${_shortfall.toStringAsFixed(0)}',
                    color: RivlColors.primary,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick amount chips
            Text(
              'Deposit Amount',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: _suggestedAmounts.take(4).map((amount) {
                final isSelected =
                    _amountController.text == amount.toStringAsFixed(0);
                final isMinNeeded = amount == _shortfall.clamp(10.0, double.infinity);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _amountController.text = amount.toStringAsFixed(0);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? RivlColors.primary
                          : RivlColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? RivlColors.primary
                            : RivlColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      isMinNeeded
                          ? '\$${amount.toStringAsFixed(0)} (min)'
                          : '\$${amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isSelected ? Colors.white : RivlColors.primary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Custom amount field
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Custom amount',
                prefixText: '\$ ',
                hintText: 'Enter amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Add Funds button
            Consumer<WalletProvider>(
              builder: (context, provider, _) {
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: provider.isProcessing
                        ? null
                        : () => _handleDeposit(provider),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RivlColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: provider.isProcessing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Add \$${_amountController.text.isEmpty ? '0' : _amountController.text}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // Cancel
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeposit(WalletProvider provider) async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Minimum deposit is \$10'),
          backgroundColor: RivlColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final tx = await provider.initiateDeposit(amount);
    if (!mounted) return;

    if (tx != null) {
      _depositSucceeded = true;
      Navigator.pop(context, true);
    } else if (provider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage!),
          backgroundColor: RivlColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      provider.clearMessages();
    }
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool bold;

  const _BalanceRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: context.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
