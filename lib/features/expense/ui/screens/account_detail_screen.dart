import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:expenseofflineapp/core/database/app_database.dart';
import 'package:expenseofflineapp/features/expense/providers/expense_provider.dart';

class AccountDetailScreen extends StatefulWidget {
  final Account account;

  const AccountDetailScreen({super.key, required this.account});

  @override
  State<AccountDetailScreen> createState() => _AccountDetailScreenState();
}

class _AccountDetailScreenState extends State<AccountDetailScreen> {
  late Future<dynamic> _metadataFuture;

  @override
  void initState() {
    super.initState();
    final db = Provider.of<AppDatabase>(context, listen: false);
    final provider = Provider.of<ExpenseProvider>(context, listen: false);

    if (widget.account.accountType == 'BANK') {
      _metadataFuture = provider.getBankAccount(db, widget.account.accountId);
    } else if (widget.account.accountType == 'UPI') {
      _metadataFuture = provider.getUpiAccount(db, widget.account.accountId);
    } else {
      _metadataFuture = Future.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    
    // Filter transactions specifically for this account
    final accountTransactions = provider.expenses
        .where((tx) => tx.accountId == widget.account.accountId)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAccountBalanceCard(),
                  const SizedBox(height: 32),
                  _buildMetadataSection(),
                  const SizedBox(height: 32),
                  const Text(
                    'Recent Account Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildTransactionsList(accountTransactions, provider),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF1E1E24),
      elevation: 0,
      pinned: true,
      expandedHeight: 120,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.account.accountName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        background: Container(color: const Color(0xFF0F0F13)),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _showDeleteDialog(context),
        ),
      ],
    );
  }

  Widget _buildAccountBalanceCard() {
    IconData iconData;
    Color iconColor;

    switch (widget.account.accountType) {
      case 'BANK':
        iconData = Icons.account_balance;
        iconColor = Colors.orangeAccent;
        break;
      case 'UPI':
        iconData = Icons.qr_code_scanner;
        iconColor = Colors.blueAccent;
        break;
      default:
        iconData = Icons.wallet;
        iconColor = Colors.greenAccent;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: iconColor.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: iconColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Balance',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
              ),
              Icon(iconData, color: iconColor),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹ ${widget.account.balance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Account Type: ${widget.account.accountType}',
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataSection() {
    return FutureBuilder<dynamic>(
      future: _metadataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final dynamic meta = snapshot.data;
        if (meta == null && widget.account.accountType != 'CASH') {
          return const SizedBox.shrink();
        }

        List<Widget> rows = [];
        
        if (meta is BankAccount) {
          rows = [
            _buildDetailRow('Bank Name', meta.bankName),
            _buildDetailRow('Account Number', meta.accountNumber),
            _buildDetailRow('IFSC Code', meta.ifscCode),
          ];
        } else if (meta is UpiAccount) {
          rows = [
            _buildDetailRow('UPI ID', meta.upiAddress),
            _buildDetailRow('UPI Name', meta.upiName ?? 'N/A'),
          ];
        } else {
           rows = [
             _buildDetailRow('Currency', widget.account.currency),
             _buildDetailRow('Status', 'Active'),
           ];
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E24).withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: rows,
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<TransactionModel> txs, ExpenseProvider provider) {
    if (txs.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(top: 40.0),
          child: Center(
            child: Text(
              'No account history found.',
              style: TextStyle(color: Colors.white24),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final transaction = txs[index];
          final isExpense = transaction.transactionType == 'EXPENSE';
          final formattedDate =
              DateFormat('dd MMM, yyyy • hh:mm a').format(transaction.transactionDate);
              
          return Container(
            margin: const EdgeInsets.only(bottom: 12, left: 24, right: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E24),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: isExpense 
                    ? Colors.redAccent.withOpacity(0.1)
                    : Colors.greenAccent.withOpacity(0.1),
                child: Icon(
                  isExpense ? Icons.north_east : Icons.south_west, 
                  color: isExpense ? Colors.redAccent : Colors.greenAccent,
                  size: 20,
                ),
              ),
              title: Text(
                transaction.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                formattedDate,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              trailing: Text(
                '${isExpense ? '-' : '+'} ₹ ${transaction.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  color: isExpense ? Colors.redAccent : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              onLongPress: () {
                final db = Provider.of<AppDatabase>(context, listen: false);
                provider.deleteExpense(db, transaction.transactionId);
              },
            ),
          );
        },
        childCount: txs.length,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A35),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to permanently delete this account? Transactions linked to this account will remain but might show as detached.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final db = Provider.of<AppDatabase>(context, listen: false);
              final provider = Provider.of<ExpenseProvider>(context, listen: false);
              await provider.deleteAccount(db, widget.account.accountId);
              if (mounted) {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Go back list
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
