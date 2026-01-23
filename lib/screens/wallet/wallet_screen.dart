// screens/wallet/wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wallet_provider.dart';
import '../../utils/theme.dart';
import '../../models/transaction_model.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/transaction-history');
            },
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance Card
                Card(
                  color: RivlColors.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Balance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '\$${provider.balance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _showDepositDialog(context),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Funds'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: RivlColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: provider.balance > 0
                                    ? () => _showWithdrawDialog(context)
                                    : null,
                                icon: const Icon(Icons.arrow_upward),
                                label: const Text('Withdraw'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Recent Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Transactions', style: RivlTextStyles.heading3),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/transaction-history');
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (provider.transactions.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text(
                              'No transactions yet',
                              style: RivlTextStyles.bodySecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...provider.transactions.take(5).map((transaction) {
                    return _TransactionListItem(transaction: transaction);
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDepositDialog(BuildContext context) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter amount to deposit:'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '\$',
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0) {
                context.read<WalletProvider>().deposit(amount);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Deposited \$${amount.toStringAsFixed(2)}')),
                );
              }
            },
            child: const Text('Deposit'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    final amountController = TextEditingController();
    final provider = context.read<WalletProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available: \$${provider.balance.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '\$',
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text);
              if (amount != null && amount > 0 && amount <= provider.balance) {
                provider.withdraw(amount);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Withdrawn \$${amount.toStringAsFixed(2)}')),
                );
              }
            },
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
  }
}

class _TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;

  const _TransactionListItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.amountColor.withOpacity(0.1),
          child: Icon(
            transaction.isCredit ? Icons.add : Icons.remove,
            color: transaction.amountColor,
          ),
        ),
        title: Text(transaction.typeDisplayName),
        subtitle: Text(
          DateFormat('MMM d, yyyy h:mm a').format(transaction.createdAt),
          style: RivlTextStyles.caption,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              transaction.displayAmount,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: transaction.amountColor,
              ),
            ),
            Text(
              transaction.statusDisplayName,
              style: RivlTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
