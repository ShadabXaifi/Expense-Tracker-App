import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:expenseofflineapp/core/database/app_database.dart';
import 'package:expenseofflineapp/features/expense/providers/expense_provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  String _selectedType = 'ALL'; // ALL, INCOME, EXPENSE
  int? _selectedAccountId; // null means ALL

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text('Transaction History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(context),
            const SizedBox(height: 16),
            Expanded(
              child: _buildTransactionList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'ALL', Icons.list),
                const SizedBox(width: 8),
                _buildFilterChip('Income', 'INCOME', Icons.arrow_downward, iconColor: Colors.greenAccent),
                const SizedBox(width: 8),
                _buildFilterChip('Expense', 'EXPENSE', Icons.arrow_upward, iconColor: Colors.redAccent),
                
                const SizedBox(width: 16),
                Container(width: 1, height: 30, color: Colors.white24), // Divider
                const SizedBox(width: 16),
                
                // Account Filter Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _selectedAccountId != null ? const Color(0xFF6C63FF).withOpacity(0.2) : const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedAccountId != null ? const Color(0xFF6C63FF) : Colors.white10,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedAccountId,
                      dropdownColor: const Color(0xFF2A2A35),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                      isDense: true,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      onChanged: (int? newValue) {
                        setState(() {
                          _selectedAccountId = newValue;
                        });
                      },
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('All Accounts'),
                        ),
                        ...provider.accounts.map((acc) {
                          return DropdownMenuItem<int?>(
                            value: acc.accountId,
                            child: Text(acc.accountName),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon, {Color? iconColor}) {
    final isSelected = _selectedType == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C63FF).withOpacity(0.2) : const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? const Color(0xFF6C63FF) : (iconColor ?? Colors.white54)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF6C63FF) : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        // Filter logic
        var filteredList = provider.expenses.where((tx) {
          bool passType = _selectedType == 'ALL' ? true : tx.transactionType == _selectedType;
          bool passAccount = _selectedAccountId == null ? true : tx.accountId == _selectedAccountId;
          return passType && passAccount;
        }).toList();

        if (filteredList.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.white24),
                SizedBox(height: 16),
                Text(
                  'No transactions found',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final transaction = filteredList[index];
            final isExpense = transaction.transactionType == 'EXPENSE';
            final formattedDate = DateFormat('dd MMM, yyyy • hh:mm a').format(transaction.transactionDate);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12, left: 20, right: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: isExpense 
                      ? Colors.redAccent.withOpacity(0.2)
                      : Colors.greenAccent.withOpacity(0.2),
                  child: Icon(
                    isExpense ? Icons.fastfood : Icons.attach_money, 
                    color: isExpense ? Colors.redAccent : Colors.greenAccent,
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
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isExpense ? '-' : '+'} ₹ ${transaction.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isExpense ? Colors.redAccent : Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction.transactionType, 
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
                onLongPress: () {
                    _showDeleteDialog(context, transaction, provider);
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, TransactionModel transaction, ExpenseProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A35),
        title: const Text('Delete Transaction', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this transaction?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              final db = Provider.of<AppDatabase>(context, listen: false);
              provider.deleteExpense(db, transaction.transactionId);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
