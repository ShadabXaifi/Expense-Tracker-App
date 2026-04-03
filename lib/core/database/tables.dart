import 'package:drift/drift.dart';

@DataClassName('Profile')
class Profiles extends Table {
  IntColumn get profileId => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get mobile => text().nullable()();
  TextColumn get profileImage => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Account')
class Accounts extends Table {
  IntColumn get accountId => integer().autoIncrement()();
  TextColumn get accountName => text()();
  TextColumn get accountType => text()(); // BANK, UPI, CASH
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

@DataClassName('BankAccount')
class BankAccounts extends Table {
  IntColumn get bankId => integer().autoIncrement()();
  IntColumn get accountId => integer().unique().customConstraint('NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE')();
  TextColumn get bankName => text()();
  TextColumn get accountNumber => text().unique()();
  TextColumn get ifscCode => text()();
  TextColumn get accountHolderName => text().nullable()();
  TextColumn get bankAccountType => text().nullable()(); // SAVINGS, CURRENT
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('UpiAccount')
class UpiAccounts extends Table {
  IntColumn get upiId => integer().autoIncrement()();
  IntColumn get accountId => integer().unique().customConstraint('NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE')();
  TextColumn get upiAddress => text().unique()();
  TextColumn get upiName => text().nullable()();
  TextColumn get userName => text().nullable()();
  TextColumn get mobileNumber => text().nullable()();
  IntColumn get linkedBankId => integer().nullable().customConstraint('REFERENCES bank_accounts(bank_id)')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('Category')
class Categories extends Table {
  IntColumn get categoryId => integer().autoIncrement()();
  TextColumn get categoryName => text().unique()();
  TextColumn get categoryType => text().nullable()(); // INCOME, EXPENSE
}

@DataClassName('TransactionModel')
class Transactions extends Table {
  IntColumn get transactionId => integer().autoIncrement()();
  IntColumn get accountId => integer().customConstraint('NOT NULL REFERENCES accounts(account_id)')();
  IntColumn get categoryId => integer().nullable().customConstraint('REFERENCES categories(category_id)')();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  TextColumn get transactionType => text()(); // INCOME, EXPENSE
  TextColumn get note => text().nullable()();
  TextColumn get referenceId => text().nullable()();
  TextColumn get transactionStatus => text().withDefault(const Constant('COMPLETED'))(); // PENDING, COMPLETED, FAILED
  DateTimeColumn get transactionDate => dateTime().named('date_time')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
}
