import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction.dart';
import '../models/category.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'keuangan.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        limit_amount REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE savings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL NOT NULL DEFAULT 0,
        created_date TEXT NOT NULL
      )
    ''');

    for (final cat in defaultCategories) {
      await db.insert('categories', cat.toMap());
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS budgets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          limit_amount REAL NOT NULL,
          month INTEGER NOT NULL,
          year INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS savings (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          target_amount REAL NOT NULL,
          current_amount REAL NOT NULL DEFAULT 0,
          created_date TEXT NOT NULL
        )
      ''');
    }
  }

  // ==================== TRANSACTIONS ====================

  Future<int> insertTransaction(TransactionModel t) async {
    final db = await database;
    return await db.insert('transactions', t.toMap());
  }

  Future<List<TransactionModel>> getAllTransactions() async {
    final db = await database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByMonth(int year, int month) async {
    final db = await database;
    final monthStr = month.toString().padLeft(2, '0');
    final prefix = '$year-$monthStr';
    final result = await db.query(
      'transactions',
      where: "date LIKE ?",
      whereArgs: ['$prefix%'],
      orderBy: 'date DESC',
    );
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<List<TransactionModel>> getTransactionsByYear(int year) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: "date LIKE ?",
      whereArgs: ['$year%'],
      orderBy: 'date ASC',
    );
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  Future<double> getTotalBalance() async {
    final db = await database;
    final incomeRes = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'income'",
    );
    final expenseRes = await db.rawQuery(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'expense'",
    );
    final income = (incomeRes.first['total'] as num?)?.toDouble() ?? 0.0;
    final expense = (expenseRes.first['total'] as num?)?.toDouble() ?? 0.0;
    return income - expense;
  }

  Future<int> updateTransaction(TransactionModel t) async {
    final db = await database;
    return await db.update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CATEGORIES ====================

  Future<List<CategoryModel>> getCategories(String type) async {
    final db = await database;
    final result = await db.query('categories', where: 'type = ?', whereArgs: [type]);
    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<List<CategoryModel>> getAllCategories() async {
    final db = await database;
    final result = await db.query('categories');
    return result.map((e) => CategoryModel.fromMap(e)).toList();
  }

  Future<int> insertCategory(CategoryModel c) async {
    final db = await database;
    return await db.insert('categories', c.toMap());
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllTransactions() async {
    final db = await database;
    await db.delete('transactions');
  }

  // ==================== BUDGETS ====================

  Future<int> insertBudget(Map<String, dynamic> budget) async {
    final db = await database;
    await db.delete('budgets',
        where: 'category = ? AND month = ? AND year = ?',
        whereArgs: [budget['category'], budget['month'], budget['year']]);
    return await db.insert('budgets', budget);
  }

  Future<List<Map<String, dynamic>>> getBudgets(int month, int year) async {
    final db = await database;
    return await db.query('budgets',
        where: 'month = ? AND year = ?', whereArgs: [month, year]);
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== SAVINGS ====================

  Future<int> insertSaving(Map<String, dynamic> saving) async {
    final db = await database;
    return await db.insert('savings', saving);
  }

  Future<List<Map<String, dynamic>>> getAllSavings() async {
    final db = await database;
    return await db.query('savings', orderBy: 'id DESC');
  }

  Future<int> updateSaving(Map<String, dynamic> saving) async {
    final db = await database;
    return await db.update('savings', saving,
        where: 'id = ?', whereArgs: [saving['id']]);
  }

  Future<int> deleteSaving(int id) async {
    final db = await database;
    return await db.delete('savings', where: 'id = ?', whereArgs: [id]);
  }
}