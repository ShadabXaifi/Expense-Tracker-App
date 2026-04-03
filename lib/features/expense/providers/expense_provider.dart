import 'package:flutter/material.dart';
import 'package:drift/drift.dart' as drift;
import 'package:expenseofflineapp/core/database/app_database.dart';

class ExpenseProvider with ChangeNotifier {
  List<TransactionModel> _expenses = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;

  List<TransactionModel> get expenses => _expenses;
  List<Account> get accounts => _accounts;
  List<Category> get categories => _categories;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get totalBalance => _totalIncome - _totalExpense;

  ExpenseProvider();

  Future<void> fetchData(AppDatabase db) async {
    _accounts = await db.select(db.accounts).get();
    _categories = await db.select(db.categories).get();
    
    _expenses = await (db.select(db.transactions)
      ..orderBy([(t) => drift.OrderingTerm(expression: t.transactionDate, mode: drift.OrderingMode.desc)])
    ).get();
    
    _calculateSummaries();
    notifyListeners();
  }

  void _calculateSummaries() {
    _totalIncome = 0.0;
    _totalExpense = 0.0;
    for (var tx in _expenses) {
      if (tx.transactionType == 'INCOME') {
        _totalIncome += tx.amount;
      } else if (tx.transactionType == 'EXPENSE') {
        _totalExpense += tx.amount;
      }
    }
  }

  /// Adds a transaction AND updates the account balance atomically.
  Future<void> addExpense(AppDatabase db, TransactionsCompanion expense) async {
    await db.transaction(() async {
      // 1. Insert the transaction
      await db.into(db.transactions).insert(expense);

      // 2. Update the account balance
      final accountId = expense.accountId.value;
      final amount = expense.amount.value;
      final txType = expense.transactionType.value;

      final account = await (db.select(db.accounts)
        ..where((a) => a.accountId.equals(accountId))
      ).getSingle();

      double newBalance;
      if (txType == 'EXPENSE') {
        newBalance = account.balance - amount;
      } else {
        // INCOME
        newBalance = account.balance + amount;
      }

      await (db.update(db.accounts)
        ..where((a) => a.accountId.equals(accountId))
      ).write(AccountsCompanion(balance: drift.Value(newBalance)));
    });

    await fetchData(db);
  }

  /// Deletes a transaction AND reverses the balance change.
  Future<void> deleteExpense(AppDatabase db, int id) async {
    // First get the transaction to know the amount and type
    final tx = await (db.select(db.transactions)
      ..where((t) => t.transactionId.equals(id))
    ).getSingleOrNull();

    if (tx != null) {
      await db.transaction(() async {
        // 1. Reverse the balance
        final account = await (db.select(db.accounts)
          ..where((a) => a.accountId.equals(tx.accountId))
        ).getSingleOrNull();

        if (account != null) {
          double newBalance;
          if (tx.transactionType == 'EXPENSE') {
            // Refund: add back the amount
            newBalance = account.balance + tx.amount;
          } else {
            // Remove income: subtract the amount
            newBalance = account.balance - tx.amount;
          }

          await (db.update(db.accounts)
            ..where((a) => a.accountId.equals(tx.accountId))
          ).write(AccountsCompanion(balance: drift.Value(newBalance)));
        }

        // 2. Delete the transaction
        await (db.delete(db.transactions)
          ..where((t) => t.transactionId.equals(id))
        ).go();
      });
    }

    await fetchData(db);
  }

  Future<void> addAccount(
    AppDatabase db,
    AccountsCompanion account, {
    BankAccountsCompanion? bankAccount,
    UpiAccountsCompanion? upiAccount,
  }) async {
    await db.transaction(() async {
      final accountId = await db.into(db.accounts).insert(account);

      if (bankAccount != null) {
        await db.into(db.bankAccounts).insert(
          bankAccount.copyWith(accountId: drift.Value(accountId)),
        );
      } else if (upiAccount != null) {
        await db.into(db.upiAccounts).insert(
          upiAccount.copyWith(accountId: drift.Value(accountId)),
        );
      }
    });

    await fetchData(db);
  }

  Future<BankAccount?> getBankAccount(AppDatabase db, int accountId) async {
    return await (db.select(db.bankAccounts)
          ..where((t) => t.accountId.equals(accountId)))
        .getSingleOrNull();
  }

  Future<UpiAccount?> getUpiAccount(AppDatabase db, int accountId) async {
    return await (db.select(db.upiAccounts)
          ..where((t) => t.accountId.equals(accountId)))
        .getSingleOrNull();
  }

  Future<void> deleteAccount(AppDatabase db, int accountId) async {
    await (db.delete(db.accounts)..where((t) => t.accountId.equals(accountId))).go();
    await fetchData(db);
  }
}
