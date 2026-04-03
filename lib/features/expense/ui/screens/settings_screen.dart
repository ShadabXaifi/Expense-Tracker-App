import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:expenseofflineapp/core/database/app_database.dart';
import 'package:expenseofflineapp/features/expense/providers/profile_provider.dart';
import 'package:expenseofflineapp/features/expense/providers/expense_provider.dart';
import 'package:expenseofflineapp/features/expense/providers/theme_provider.dart';
import 'package:expenseofflineapp/features/expense/ui/screens/profile_setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text('Settings', 
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87, 
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
      body: SafeArea(
        child: Consumer<ProfileProvider>(
          builder: (context, profileProvider, child) {
            final profile = profileProvider.profile;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildProfileCard(context, profile, isDark),
                  const SizedBox(height: 32),

                  // Theme Toggle
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05), 
                          blurRadius: 10, 
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SwitchListTile(
                      value: themeProvider.isDarkMode,
                      onChanged: (val) {
                        themeProvider.toggleTheme(val);
                      },
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        'Dark Mode',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        isDark ? 'Currently using dark theme' : 'Currently using light theme',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                      secondary: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode, 
                          color: const Color(0xFF6C63FF),
                        ),
                      ),
                      activeColor: const Color(0xFF6C63FF),
                    ),
                  ),

                  const SizedBox(height: 16),

                  _buildSettingsTile(
                    icon: Icons.delete_forever,
                    title: 'Reset Data',
                    subtitle: 'Wipe all accounts, transactions, and categories',
                    isDestructive: true,
                    isDarkMode: isDark,
                    onTap: () => _showResetDataDialog(context, isDark),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Profile? profile, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6C63FF), width: 1),
                ),
                child: Icon(
                  _getIconData(profile?.profileImage ?? 'person'),
                  size: 36,
                  color: const Color(0xFF6C63FF),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.name ?? 'Complete Setup',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 22, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.email ?? 'No email added',
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: isDark ? Colors.white30 : Colors.black26, size: 20),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen()));
                  // No need to await — Consumer will auto-update when ProfileProvider calls notifyListeners
                },
              )
            ],
          ),
          if (profile?.mobile != null && profile!.mobile!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: isDark ? Colors.white10 : Colors.black12, height: 1),
            ),
            Row(
              children: [
                Icon(Icons.phone_android, size: 16, color: isDark ? Colors.white38 : Colors.black38),
                const SizedBox(width: 12),
                Text(
                  profile.mobile!,
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getIconData(String name) {
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

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isDarkMode = true,
  }) {
    final color = isDestructive ? Colors.redAccent : (isDarkMode ? Colors.white : Colors.black87);
    final iconColor = isDestructive ? Colors.redAccent : const Color(0xFF6C63FF);

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E24) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDarkMode ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54, fontSize: 12)),
        trailing: Icon(Icons.arrow_forward_ios, color: isDarkMode ? Colors.white24 : Colors.black26, size: 16),
      ),
    );
  }

  void _showResetDataDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2A2A35) : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Reset Data', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
          ],
        ),
        content: Text(
          'Are you sure you want to reset all your data? This wipes everything and cannot be undone.',
          style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              final db = Provider.of<AppDatabase>(context, listen: false);
              final expProvider = Provider.of<ExpenseProvider>(context, listen: false);
              await db.delete(db.transactions).go();
              await db.delete(db.bankAccounts).go();
              await db.delete(db.upiAccounts).go();
              await db.delete(db.accounts).go();
              await db.delete(db.categories).go();
              await expProvider.fetchData(db);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data has been reset successfully.'), backgroundColor: Colors.redAccent),
              );
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
