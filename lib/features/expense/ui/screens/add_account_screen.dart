import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;

import 'package:expenseofflineapp/core/database/app_database.dart';
import 'package:expenseofflineapp/features/expense/providers/expense_provider.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _accountType = 'CASH'; // CASH, BANK, UPI
  
  final _nameController = TextEditingController();
  String? _selectedNickname;
  final _initialBalanceController = TextEditingController();
  
  // Bank specific
  String? _selectedBankName;
  final _accountNoController = TextEditingController();
  final _ifscController = TextEditingController();
  
  // UPI specific
  final _upiIdController = TextEditingController();
  String? _selectedUpiApp;

  bool _isLoading = false;

  // Suggested nicknames per type
  static const Map<String, List<String>> _suggestedNicknames = {
    'CASH': ['Cash Wallet', 'Daily Cash', 'Pocket Money', 'Emergency Cash', 'Personal Cash'],
    'BANK': ['Savings Account', 'Salary Account', 'Current Account', 'Fixed Deposit', 'Joint Account', 'Business Account'],
    'UPI': ['GPay Personal', 'PhonePe Wallet', 'Paytm Account', 'BHIM UPI', 'Primary UPI', 'Business UPI'],
  };

  // List of common Indian banks
  static const List<String> _bankNames = [
    'State Bank of India (SBI)',
    'HDFC Bank',
    'ICICI Bank',
    'Punjab National Bank (PNB)',
    'Bank of Baroda',
    'Canara Bank',
    'Union Bank of India',
    'Axis Bank',
    'Kotak Mahindra Bank',
    'IndusInd Bank',
    'Yes Bank',
    'IDBI Bank',
    'Bank of India',
    'Central Bank of India',
    'Indian Overseas Bank',
    'UCO Bank',
    'Indian Bank',
    'Federal Bank',
    'South Indian Bank',
    'Bandhan Bank',
    'IDFC First Bank',
    'RBL Bank',
    'Other',
  ];

  // Common UPI apps
  static const List<String> _upiApps = [
    'Google Pay (GPay)',
    'PhonePe',
    'Paytm',
    'BHIM',
    'Amazon Pay',
    'WhatsApp Pay',
    'CRED',
    'MobiKwik',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _initialBalanceController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  void _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    // Extra validation
    if (_accountType == 'BANK' && _selectedBankName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bank')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final db = Provider.of<AppDatabase>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    final balance = double.tryParse(_initialBalanceController.text) ?? 0.0;
    
    final baseAccount = AccountsCompanion(
      accountName: drift.Value(_nameController.text.trim()),
      accountType: drift.Value(_accountType),
      balance: drift.Value(balance),
    );

    BankAccountsCompanion? bankAccount;
    UpiAccountsCompanion? upiAccount;

    if (_accountType == 'BANK') {
      bankAccount = BankAccountsCompanion(
        bankName: drift.Value(_selectedBankName!),
        accountNumber: drift.Value(_accountNoController.text.trim()),
        ifscCode: drift.Value(_ifscController.text.trim()),
      );
    } else if (_accountType == 'UPI') {
      upiAccount = UpiAccountsCompanion(
        upiAddress: drift.Value(_upiIdController.text.trim()),
        upiName: drift.Value(_selectedUpiApp ?? ''),
      );
    }

    try {
      await expenseProvider.addAccount(
        db, 
        baseAccount, 
        bankAccount: bankAccount, 
        upiAccount: upiAccount,
      );
      
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account added successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding account: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text('Add Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
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
                _buildTypeSelector(),
                const SizedBox(height: 32),
                // Account Nickname Dropdown with custom option
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedNickname,
                    dropdownColor: const Color(0xFF2A2A35),
                    style: const TextStyle(color: Colors.white),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Account Nickname',
                      labelStyle: TextStyle(color: Colors.white54),
                      prefixIcon: Icon(Icons.label_outline, color: Color(0xFF6C63FF)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    hint: const Text('Select a nickname', style: TextStyle(color: Colors.white54)),
                    items: [
                      ...(_suggestedNicknames[_accountType] ?? []).map((name) {
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name, overflow: TextOverflow.ellipsis),
                        );
                      }),
                      const DropdownMenuItem<String>(
                        value: '__custom__',
                        child: Text('✏️  Custom Name...', style: TextStyle(color: Color(0xFF6C63FF))),
                      ),
                    ],
                    onChanged: (val) {
                      if (val == '__custom__') {
                        setState(() => _selectedNickname = null);
                        _nameController.clear();
                        // Show the text field below
                      } else {
                        setState(() {
                          _selectedNickname = val;
                          _nameController.text = val ?? '';
                        });
                      }
                    },
                    validator: (v) {
                      if ((v == null || v == '__custom__') && _nameController.text.trim().isEmpty) {
                        return 'Select or enter a nickname';
                      }
                      return null;
                    },
                  ),
                ),
                
                // Custom name field (shows when 'Custom Name' is selected or nothing is selected)
                if (_selectedNickname == null) ...[
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Custom Nickname',
                    hint: 'Type your own account name',
                    icon: Icons.edit,
                    validator: (v) {
                      if (_selectedNickname == null && (v == null || v.trim().isEmpty)) {
                        return 'Enter a nickname';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _initialBalanceController,
                  label: 'Initial Balance (₹)',
                  hint: '0.00',
                  icon: Icons.account_balance_wallet_outlined,
                  keyboardType: TextInputType.number,
                ),
                
                // BANK specific fields
                if (_accountType == 'BANK') ...[
                  const SizedBox(height: 32),
                  const Text('Bank Details', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  // Bank Name DROPDOWN
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedBankName,
                      dropdownColor: const Color(0xFF2A2A35),
                      style: const TextStyle(color: Colors.white),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Select Bank',
                        labelStyle: TextStyle(color: Colors.white54),
                        prefixIcon: Icon(Icons.account_balance, color: Color(0xFF6C63FF)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      hint: const Text('Choose your bank', style: TextStyle(color: Colors.white54)),
                      items: _bankNames.map((bank) {
                        return DropdownMenuItem<String>(
                          value: bank,
                          child: Text(bank, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedBankName = val;
                          // Auto-suggest nickname from bank name
                          if (val != null && val != 'Other' && (_selectedNickname != null || _nameController.text.isEmpty)) {
                            final shortName = val.replaceAll(RegExp(r'\s*\(.*\)'), ''); // Remove (SBI) etc
                            _selectedNickname = 'Savings Account';
                            _nameController.text = '$shortName Savings';
                          }
                        });
                      },
                      validator: (v) => v == null ? 'Please select a bank' : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _accountNoController,
                    label: 'Account Number',
                    hint: 'e.g. 1234567890',
                    icon: Icons.numbers,
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Enter account number' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _ifscController,
                    label: 'IFSC Code',
                    hint: 'e.g. HDFC0001234',
                    icon: Icons.code,
                    validator: (v) => v!.isEmpty ? 'Enter IFSC' : null,
                  ),
                ],

                // UPI specific fields
                if (_accountType == 'UPI') ...[
                  const SizedBox(height: 32),
                  const Text('UPI Details', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  // UPI App DROPDOWN
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedUpiApp,
                      dropdownColor: const Color(0xFF2A2A35),
                      style: const TextStyle(color: Colors.white),
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'UPI App',
                        labelStyle: TextStyle(color: Colors.white54),
                        prefixIcon: Icon(Icons.phone_iphone, color: Color(0xFF6C63FF)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      hint: const Text('Select UPI App', style: TextStyle(color: Colors.white54)),
                      items: _upiApps.map((app) {
                        return DropdownMenuItem<String>(
                          value: app,
                          child: Text(app, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedUpiApp = val;
                          // Auto-suggest nickname from UPI app
                          if (val != null && val != 'Other' && (_selectedNickname != null || _nameController.text.isEmpty)) {
                            _selectedNickname = '$val Personal';
                            // Also find the matching suggested nickname if possible
                            final suggestions = _suggestedNicknames['UPI'] ?? [];
                            final match = suggestions.where((s) => s.toLowerCase().contains(val.split(' ').first.toLowerCase())).toList();
                            if (match.isNotEmpty) {
                              _selectedNickname = match.first;
                            }
                            _nameController.text = _selectedNickname ?? '$val Account';
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _upiIdController,
                    label: 'UPI ID',
                    hint: 'e.g. username@oksbi',
                    icon: Icons.qr_code,
                    validator: (v) => v!.isEmpty ? 'Enter UPI ID' : null,
                  ),
                ],

                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Save Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _buildTypeOption('CASH', Icons.wallet),
          _buildTypeOption('BANK', Icons.account_balance),
          _buildTypeOption('UPI', Icons.qr_code_scanner),
        ],
      ),
    );
  }

  Widget _buildTypeOption(String type, IconData icon) {
    bool isSelected = _accountType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _accountType = type;
            _selectedBankName = null;
            _selectedUpiApp = null;
            _selectedNickname = null;
            _nameController.clear();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.white54),
              const SizedBox(height: 4),
              Text(
                type,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white54,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        filled: true,
        fillColor: const Color(0xFF1E1E24),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1)),
      ),
    );
  }
}
