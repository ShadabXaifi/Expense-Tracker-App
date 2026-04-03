import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:expenseofflineapp/core/database/app_database.dart';
import 'package:expenseofflineapp/features/expense/providers/expense_provider.dart';
import 'package:expenseofflineapp/features/expense/providers/profile_provider.dart';
import 'transaction_history_screen.dart';
import 'add_transaction_screen.dart';
import 'settings_screen.dart';
import 'account_list_screen.dart';
import 'account_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final db = Provider.of<AppDatabase>(context, listen: false);
      Provider.of<ExpenseProvider>(context, listen: false).fetchData(db);
      // Ensure profile is loaded into memory
      Provider.of<ProfileProvider>(context, listen: false).loadProfile(db);
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  IconData _getAvatarIcon(String name) {
    switch (name) {
      case 'person': return Icons.person;
      case 'face': return Icons.face;
      case 'cruelty_free': return Icons.cruelty_free;
      case 'account_circle': return Icons.account_circle;
      case 'psychology': return Icons.psychology;
      case 'rocket_launch': return Icons.rocket_launch;
      default: return Icons.person;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<ExpenseProvider>(
                      builder: (context, provider, child) => _buildBalanceCard(provider),
                    ),
                    const SizedBox(height: 32),
                    _buildAccountsList(),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Transactions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TransactionHistoryScreen(),
                              ),
                            );
                          },
                          child: const Text('See All', style: TextStyle(color: Color(0xFF6C63FF))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            _buildTransactionsList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTransactionScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 80,
      floating: true,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Consumer<ProfileProvider>(
            builder: (context, profileProvider, child) {
              final profile = profileProvider.profile;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                      Text(
                        profile?.name ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsScreen()),
                      );
                    },
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF1E1E24),
                      child: Icon(
                        _getAvatarIcon(profile?.profileImage ?? 'person'),
                        color: const Color(0xFF6C63FF),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(ExpenseProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF4A47A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '₹ ${provider.totalBalance.toStringAsFixed(2)}', 
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _IncomeExpenseMiniView(
                title: 'Income',
                amount: '₹ ${provider.totalIncome.toStringAsFixed(0)}',
                icon: Icons.arrow_downward,
                color: Colors.greenAccent,
              ),
              _IncomeExpenseMiniView(
                title: 'Expense',
                amount: '₹ ${provider.totalExpense.toStringAsFixed(0)}',
                icon: Icons.arrow_upward,
                color: Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Accounts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AccountListScreen()),
                );
              },
              child: const Text('See All', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 13)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: Consumer<ExpenseProvider>(
            builder: (context, provider, child) {
              if (provider.accounts.isEmpty) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text('No Accounts Found', style: TextStyle(color: Colors.white54)),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.accounts.length,
                itemBuilder: (context, index) {
                  final account = provider.accounts[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AccountDetailScreen(account: account),
                        ),
                      );
                    },
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            account.accountType == 'BANK' 
                                ? Icons.account_balance 
                                : account.accountType == 'UPI'
                                    ? Icons.qr_code_scanner
                                    : Icons.wallet,
                            color: const Color(0xFF6C63FF),
                          ),
                          const Spacer(),
                          Text(
                            account.accountName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹ ${account.balance.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionsList() {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        if (provider.expenses.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 40.0),
              child: Center(
                child: Text(
                  'No transactions yet.',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          );
        }

        final recentTx = provider.expenses.take(10).toList();

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final transaction = recentTx[index];
              final isExpense = transaction.transactionType == 'EXPENSE';
              
              final formattedDate =
                  DateFormat('dd MMM, yyyy').format(transaction.transactionDate);
                  
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
                      isExpense ? Icons.arrow_upward : Icons.arrow_downward, 
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
                    style: const TextStyle(color: Colors.white54),
                  ),
                  trailing: Text(
                    '${isExpense ? '-' : '+'} ₹ ${transaction.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: isExpense ? Colors.redAccent : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            },
            childCount: recentTx.length,
          ),
        );
      },
    );
  }
}

class _IncomeExpenseMiniView extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;
  final Color color;

  const _IncomeExpenseMiniView({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        )
      ],
    );
  }
}
