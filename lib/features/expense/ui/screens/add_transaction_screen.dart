import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;

import 'package:expenseofflineapp/core/database/app_database.dart';
import 'package:expenseofflineapp/features/expense/providers/expense_provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final String initialType;
  
  const AddTransactionScreen({super.key, this.initialType = 'EXPENSE'});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _txType; // 'EXPENSE' or 'INCOME'

  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _selectedTitle;
  String? _selectedCategory;
  int? _selectedAccountId;
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;

  // Pre-defined title suggestions
  static const Map<String, List<String>> _titleSuggestions = {
    'EXPENSE': [
      'Groceries',
      'Rent',
      'Electricity Bill',
      'Water Bill',
      'Gas Bill',
      'Mobile Recharge',
      'Internet Bill',
      'Petrol / Fuel',
      'Bus / Metro Fare',
      'Auto / Cab Fare',
      'Breakfast',
      'Lunch',
      'Dinner',
      'Snacks & Tea',
      'Movie / Entertainment',
      'Shopping / Clothes',
      'Medical / Pharmacy',
      'Gym / Fitness',
      'Education / Books',
      'Subscription (Netflix, etc.)',
      'Insurance Premium',
      'EMI Payment',
      'Household Items',
      'Repair / Maintenance',
      'Gift / Donation',
    ],
    'INCOME': [
      'Monthly Salary',
      'Freelance Payment',
      'Business Income',
      'Rental Income',
      'Interest Earned',
      'Dividend',
      'Cashback / Reward',
      'Gift Received',
      'Refund',
      'Side Hustle',
      'Investment Return',
      'Bonus',
    ],
  };

  // Pre-defined category suggestions
  static const Map<String, List<String>> _categorySuggestions = {
    'EXPENSE': [
      '🍔 Food & Dining',
      '🏠 Housing & Rent',
      '🚗 Transport',
      '⚡ Utilities & Bills',
      '🛍️ Shopping',
      '💊 Health & Medical',
      '🎬 Entertainment',
      '📚 Education',
      '💇 Personal Care',
      '🎁 Gifts & Donations',
      '💳 EMI & Loans',
      '📱 Phone & Internet',
      '🏋️ Fitness',
      '🔧 Maintenance',
      '📦 Miscellaneous',
    ],
    'INCOME': [
      '💰 Salary',
      '💼 Freelance',
      '🏢 Business',
      '🏠 Rental Income',
      '📈 Investments',
      '🎁 Gifts',
      '💸 Cashback & Rewards',
      '🔄 Refunds',
      '📦 Miscellaneous',
    ],
  };

  @override
  void initState() {
    super.initState();
    _txType = widget.initialType;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      if (provider.accounts.isNotEmpty) {
        setState(() {
          _selectedAccountId = provider.accounts.first.accountId;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    // Determine the final title
    final finalTitle = _selectedTitle == '__custom__' || _selectedTitle == null
        ? _titleCtrl.text.trim()
        : _selectedTitle!;

    if (finalTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter a title')),
      );
      return;
    }

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an Account. Add one first if needed.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final db = Provider.of<AppDatabase>(context, listen: false);
    final provider = Provider.of<ExpenseProvider>(context, listen: false);

    final amount = double.tryParse(_amountCtrl.text) ?? 0.0;

    // Check balance for EXPENSE transactions
    if (_txType == 'EXPENSE') {
      final selectedAccount = provider.accounts.firstWhere(
        (a) => a.accountId == _selectedAccountId,
      );
      if (selectedAccount.balance < amount) {
        setState(() => _isLoading = false);
        _showInsufficientBalanceDialog(selectedAccount, amount);
        return;
      }
    }
    
    final newTx = TransactionsCompanion(
      accountId: drift.Value(_selectedAccountId!),
      title: drift.Value(finalTitle),
      amount: drift.Value(amount),
      transactionType: drift.Value(_txType),
      note: drift.Value(_noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()),
      transactionDate: drift.Value(_selectedDate),
    );

    try {
      await provider.addExpense(db, newTx);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding transaction: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildToggle() {
    final isExpense = _txType == 'EXPENSE';
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _txType = 'EXPENSE';
                _selectedTitle = null;
                _selectedCategory = null;
                _titleCtrl.clear();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isExpense ? Colors.redAccent.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: isExpense ? Border.all(color: Colors.redAccent, width: 1.5) : Border.all(color: Colors.transparent),
                ),
                child: Center(
                  child: Text(
                    'EXPENSE',
                    style: TextStyle(
                      color: isExpense ? Colors.redAccent : Colors.white54,
                      fontWeight: isExpense ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _txType = 'INCOME';
                _selectedTitle = null;
                _selectedCategory = null;
                _titleCtrl.clear();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: !isExpense ? Colors.greenAccent.withOpacity(0.2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: !isExpense ? Border.all(color: Colors.greenAccent, width: 1.5) : Border.all(color: Colors.transparent),
                ),
                child: Center(
                  child: Text(
                    'INCOME',
                    style: TextStyle(
                      color: !isExpense ? Colors.greenAccent : Colors.white54,
                      fontWeight: !isExpense ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ExpenseProvider>(context);
    final isExpense = _txType == 'EXPENSE';
    final accentColor = isExpense ? Colors.redAccent : Colors.greenAccent;

    final titles = _titleSuggestions[_txType] ?? [];
    final categories = _categorySuggestions[_txType] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: Text('Add ${isExpense ? 'Expense' : 'Income'}', 
                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: accentColor.withOpacity(0.1),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildToggle(),
                const SizedBox(height: 32),
                
                // Amount Field
                Center(
                  child: SizedBox(
                    width: 250,
                    child: TextFormField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                      validator: (v) {
                         if (v == null || v.isEmpty) return 'Amount required';
                         if (double.tryParse(v) == null || double.tryParse(v)! <= 0) return 'Invalid amount';
                         return null;
                      },
                      decoration: InputDecoration(
                        prefixIcon: Text(
                          '₹ ',
                          style: TextStyle(fontSize: 48, color: accentColor.withOpacity(0.6), fontWeight: FontWeight.normal),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        border: InputBorder.none,
                        hintText: '0.00',
                        hintStyle: const TextStyle(
                          fontSize: 48,
                          color: Colors.white10,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title Dropdown
                _buildStyledDropdown<String>(
                  label: 'Title',
                  icon: Icons.title,
                  value: _selectedTitle,
                  accentColor: accentColor,
                  hint: 'What is this for?',
                  items: [
                    ...titles.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t, overflow: TextOverflow.ellipsis),
                    )),
                    DropdownMenuItem(
                      value: '__custom__',
                      child: Text('✏️  Custom Title...', style: TextStyle(color: accentColor)),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedTitle = val;
                      if (val != '__custom__' && val != null) {
                        _titleCtrl.text = val;
                      } else {
                        _titleCtrl.clear();
                      }
                    });
                  },
                  validator: (v) {
                    if (v == null && _titleCtrl.text.trim().isEmpty) {
                      return 'Select or enter a title';
                    }
                    return null;
                  },
                ),

                // Custom title field
                if (_selectedTitle == '__custom__') ...[
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _titleCtrl,
                    label: 'Custom Title',
                    icon: Icons.edit,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
                    accentColor: accentColor,
                  ),
                ],

                const SizedBox(height: 16),
                
                // Category Dropdown
                _buildStyledDropdown<String>(
                  label: 'Category',
                  icon: Icons.category,
                  value: _selectedCategory,
                  accentColor: accentColor,
                  hint: 'Select Category',
                  items: categories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (val) {
                    setState(() => _selectedCategory = val);
                  },
                ),

                const SizedBox(height: 16),

                // Account Dropdown — shows balance next to name
                _buildStyledDropdown<int>(
                  label: 'Account',
                  icon: Icons.account_balance_wallet,
                  value: _selectedAccountId,
                  accentColor: accentColor,
                  hint: 'Select Account',
                  items: provider.accounts.map((a) => DropdownMenuItem(
                    value: a.accountId,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(a.accountName, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${a.balance.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: a.balance > 0 ? Colors.greenAccent.withOpacity(0.8) : Colors.redAccent.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                  validator: (v) => v == null ? 'Please select an account' : null,
                ),

                // Show selected account balance hint
                if (_selectedAccountId != null) ...[                  
                  Builder(builder: (context) {
                    final acc = provider.accounts.firstWhere((a) => a.accountId == _selectedAccountId);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8, left: 12),
                      child: Text(
                        'Available: ₹${acc.balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: acc.balance > 0 ? Colors.greenAccent.withOpacity(0.6) : Colors.redAccent.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    );
                  }),
                ],

                const SizedBox(height: 16),

                // Date Picker
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (context, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: accentColor,
                            onPrimary: Colors.white,
                            surface: const Color(0xFF2A2A35),
                            onSurface: Colors.white,
                          ),
                        ),
                        child: child!,
                      ),
                    );
                    if (date != null) {
                      setState(() => _selectedDate = date);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white54),
                        const SizedBox(width: 16),
                        Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down, color: Colors.white54),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                _buildTextField(
                  controller: _noteCtrl,
                  label: 'Note (Optional)',
                  icon: Icons.note,
                  accentColor: accentColor,
                ),

                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Save Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    required Color accentColor,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1E1E24),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: accentColor, width: 1)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
      ),
    );
  }

  Widget _buildStyledDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required Color accentColor,
    required String hint,
    String? Function(T?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        dropdownColor: const Color(0xFF2A2A35),
        style: const TextStyle(color: Colors.white),
        isExpanded: true,
        menuMaxHeight: 350,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        hint: Text(hint, style: const TextStyle(color: Colors.white54)),
      ),
    );
  }

  void _showInsufficientBalanceDialog(Account account, double requiredAmount) {
    final shortfall = requiredAmount - account.balance;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 28),
            SizedBox(width: 10),
            Text('Insufficient Balance', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  _dialogRow('Account', account.accountName),
                  const SizedBox(height: 8),
                  _dialogRow('Available', '₹ ${account.balance.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _dialogRow('Required', '₹ ${requiredAmount.toStringAsFixed(2)}'),
                  const Divider(color: Colors.white12, height: 16),
                  _dialogRow('Shortfall', '₹ ${shortfall.toStringAsFixed(2)}', valueColor: Colors.redAccent),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'You can:',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Select a different account with sufficient balance\n• Add funds to this account first\n• Reduce the expense amount',
              style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.6),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
