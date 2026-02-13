// screens/wallet/wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../models/wallet_model.dart';
import '../../utils/theme.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  TransactionType? _filterType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showTransactionHistory(context),
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.refreshTransactions(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Balance Card
                  _BalanceCard(
                    balance: provider.balance,
                    pendingBalance: provider.pendingBalance,
                    isVerified: provider.isVerified,
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.add,
                          label: 'Deposit',
                          color: RivlColors.success,
                          onPressed: () => _showDepositSheet(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.arrow_upward,
                          label: 'Withdraw',
                          color: RivlColors.primary,
                          onPressed: provider.canWithdraw
                              ? () => _showWithdrawSheet(context)
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Card
                  _StatsCard(
                    lifetimeWinnings: provider.lifetimeWinnings,
                    lifetimeLosses: provider.lifetimeLosses,
                    netProfit: provider.netProfit,
                  ),
                  const SizedBox(height: 24),

                  // Recent Transactions
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (provider.transactions.isEmpty)
                    const _EmptyTransactions()
                  else
                    ...provider.transactions.take(5).map(
                          (tx) => _TransactionTile(transaction: tx),
                        ),

                  if (provider.transactions.length > 5)
                    TextButton(
                      onPressed: () => _showTransactionHistory(context),
                      child: const Text('View All Transactions'),
                    ),

                  // Bank Account Status
                  const SizedBox(height: 24),
                  _BankAccountCard(isVerified: provider.isVerified),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDepositSheet(BuildContext context) {
    final walletProvider = context.read<WalletProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: walletProvider,
        child: const _DepositSheet(),
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context) {
    final walletProvider = context.read<WalletProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: walletProvider,
        child: const _WithdrawSheet(),
      ),
    );
  }

  void _showTransactionHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const _TransactionHistoryScreen(),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double pendingBalance;
  final bool isVerified;

  const _BalanceCard({
    required this.balance,
    required this.pendingBalance,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [RivlColors.primary, RivlColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: RivlColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (pendingBalance > 0) ...[
            const SizedBox(height: 8),
            Text(
              '+ \$${pendingBalance.toStringAsFixed(2)} pending',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed != null ? color : Colors.grey,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final double lifetimeWinnings;
  final double lifetimeLosses;
  final double netProfit;

  const _StatsCard({
    required this.lifetimeWinnings,
    required this.lifetimeLosses,
    required this.netProfit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.surface, RivlColors.primary.withOpacity(0.03)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lifetime Stats',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Winnings',
                    value: '\$${lifetimeWinnings.toStringAsFixed(0)}',
                    color: RivlColors.success,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Losses',
                    value: '\$${lifetimeLosses.toStringAsFixed(0)}',
                    color: RivlColors.error,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Net Profit',
                    value: '${netProfit >= 0 ? '+' : ''}\$${netProfit.toStringAsFixed(0)}',
                    color: netProfit >= 0 ? RivlColors.success : RivlColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: (isCredit ? RivlColors.success : RivlColors.error)
              .withOpacity(0.1),
          child: Icon(
            _getIcon(),
            color: isCredit ? RivlColors.success : RivlColors.error,
            size: 20,
          ),
        ),
        title: Text(transaction.displayType),
        subtitle: Text(
          _formatDate(transaction.createdAt),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              transaction.displayAmount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isCredit ? RivlColors.success : RivlColors.error,
              ),
            ),
            if (transaction.isPending)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: RivlColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 10,
                    color: RivlColors.warning,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (transaction.type) {
      case TransactionType.deposit:
        return Icons.add_circle_outline;
      case TransactionType.withdrawal:
        return Icons.arrow_upward;
      case TransactionType.stakeDebit:
        return Icons.sports_score;
      case TransactionType.winnings:
        return Icons.emoji_events;
      case TransactionType.refund:
        return Icons.undo;
      case TransactionType.bonus:
        return Icons.card_giftcard;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Deposit funds to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _BankAccountCard extends StatelessWidget {
  final bool isVerified;

  const _BankAccountCard({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isVerified
              ? RivlColors.success.withOpacity(0.1)
              : RivlColors.warning.withOpacity(0.1),
          child: Icon(
            isVerified ? Icons.account_balance : Icons.account_balance_outlined,
            color: isVerified ? RivlColors.success : RivlColors.warning,
          ),
        ),
        title: Text(isVerified ? 'Bank Account Linked' : 'Link Bank Account'),
        subtitle: Text(
          isVerified
              ? 'Ready for deposits and withdrawals'
              : 'Required for withdrawals',
        ),
        trailing: isVerified
            ? const Icon(Icons.check_circle, color: RivlColors.success)
            : TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bank linking coming soon!'),
                    ),
                  );
                },
                child: const Text('Link'),
              ),
      ),
    );
  }
}

class _DepositSheet extends StatefulWidget {
  const _DepositSheet();

  @override
  State<_DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<_DepositSheet> {
  final _amountController = TextEditingController();
  final _amounts = [25.0, 50.0, 100.0, 200.0];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deposit Funds',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add money to your wallet via bank transfer (ACH)',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Quick amounts
            Wrap(
              spacing: 12,
              children: _amounts.map((amount) {
                return ChoiceChip(
                  label: Text('\$${amount.toInt()}'),
                  selected: _amountController.text == amount.toString(),
                  onSelected: (_) {
                    setState(() {
                      _amountController.text = amount.toString();
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Custom amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '\$ ',
                hintText: 'Enter amount',
              ),
            ),
            const SizedBox(height: 24),

            // Deposit button
            Consumer<WalletProvider>(
              builder: (context, provider, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isProcessing
                        ? null
                        : () async {
                            final amount = double.tryParse(_amountController.text);
                            if (amount == null || amount < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Minimum deposit is \$10'),
                                ),
                              );
                              return;
                            }

                            final tx = await provider.initiateDeposit(amount);
                            if (tx != null && context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(provider.successMessage ?? 'Deposit initiated'),
                                ),
                              );
                            } else if (provider.errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(provider.errorMessage!),
                                  backgroundColor: RivlColors.error,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RivlColors.success,
                    ),
                    child: provider.isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Deposit'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet();

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amountController = TextEditingController();
  WithdrawalMethod _method = WithdrawalMethod.ach;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Consumer<WalletProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Withdraw Funds',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Available: \$${provider.balance.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Amount input
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$ ',
                    hintText: 'Enter amount',
                    suffixIcon: TextButton(
                      onPressed: () {
                        _amountController.text = provider.balance.toStringAsFixed(2);
                      },
                      child: const Text('MAX'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Withdrawal method
                const Text(
                  'Transfer Speed',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                RadioListTile<WithdrawalMethod>(
                  title: const Text('Standard (1-3 business days)'),
                  subtitle: const Text('Free'),
                  value: WithdrawalMethod.ach,
                  groupValue: _method,
                  onChanged: (value) {
                    setState(() => _method = value!);
                  },
                ),
                RadioListTile<WithdrawalMethod>(
                  title: const Text('Instant'),
                  subtitle: const Text('1.5% fee'),
                  value: WithdrawalMethod.instantAch,
                  groupValue: _method,
                  onChanged: (value) {
                    setState(() => _method = value!);
                  },
                ),
                const SizedBox(height: 16),

                // Withdraw button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isProcessing
                        ? null
                        : () async {
                            final amount = double.tryParse(_amountController.text);
                            if (amount == null || amount < 10) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Minimum withdrawal is \$10'),
                                ),
                              );
                              return;
                            }

                            final tx = await provider.initiateWithdrawal(
                              amount,
                              method: _method,
                            );
                            if (tx != null && context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(provider.successMessage ?? 'Withdrawal initiated'),
                                ),
                              );
                            } else if (provider.errorMessage != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(provider.errorMessage!),
                                  backgroundColor: RivlColors.error,
                                ),
                              );
                            }
                          },
                    child: provider.isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Withdraw'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TransactionHistoryScreen extends StatelessWidget {
  const _TransactionHistoryScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, _) {
          if (provider.transactions.isEmpty) {
            return const Center(child: _EmptyTransactions());
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.transactions.length,
            itemBuilder: (context, index) {
              return _TransactionTile(
                transaction: provider.transactions[index],
              );
            },
          );
        },
      ),
    );
  }
}
