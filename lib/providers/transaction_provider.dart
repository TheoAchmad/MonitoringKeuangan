import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../database/db_helper.dart';
import 'notification_helper.dart';

class TransactionProvider extends ChangeNotifier {
  final DbHelper _db = DbHelper();
  final NotificationHelper _notif = NotificationHelper();

  List<TransactionModel> _transactions = [];
  List<CategoryModel> _categories = [];
  List<Map<String, dynamic>> _budgets = [];
  List<Map<String, dynamic>> _savings = [];
  double _totalBalance = 0;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  List<TransactionModel> get transactions => _transactions;
  List<CategoryModel> get categories => _categories;
  List<Map<String, dynamic>> get budgets => _budgets;
  List<Map<String, dynamic>> get savings => _savings;
  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;

  // ✅ Saldo kumulatif semua waktu
  double get totalBalance => _totalBalance;

  // Transaksi bulan yang dipilih
  List<TransactionModel> get monthlyTransactions => _transactions.where((t) {
        final d = DateTime.parse(t.date);
        return d.month == _selectedMonth && d.year == _selectedYear;
      }).toList();

  double get totalIncome => monthlyTransactions
      .where((t) => t.type == 'income')
      .fold(0, (sum, t) => sum + t.amount);

  double get totalExpense => monthlyTransactions
      .where((t) => t.type == 'expense')
      .fold(0, (sum, t) => sum + t.amount);

  // Saldo bulan ini (untuk info bulanan)
  double get monthlyBalance => totalIncome - totalExpense;

  Future<void> loadAll() async {
    await Future.wait([
      loadTransactions(),
      loadCategories(),
      loadBudgets(),
      loadSavings(),
    ]);
  }

  Future<void> loadTransactions() async {
    _transactions = await _db.getAllTransactions();
    _totalBalance = await _db.getTotalBalance();
    notifyListeners();
  }

  Future<void> loadCategories() async {
    _categories = await _db.getAllCategories();
    notifyListeners();
  }

  Future<void> loadBudgets() async {
    _budgets = await _db.getBudgets(_selectedMonth, _selectedYear);
    notifyListeners();
  }

  Future<void> loadSavings() async {
    _savings = await _db.getAllSavings();
    notifyListeners();
  }

  // ==================== TRANSACTIONS ====================

  Future<void> addTransaction(TransactionModel t) async {
    await _db.insertTransaction(t);
    await loadTransactions();

    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final amountStr = fmt.format(t.amount);
    if (t.type == 'income') {
      await _notif.showIncomeNotification(category: t.category, amount: amountStr);
    } else {
      await _notif.showExpenseNotification(category: t.category, amount: amountStr);
    }
  }

  Future<void> updateTransaction(TransactionModel t) async {
    await _db.updateTransaction(t);
    await loadTransactions();

    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final amountStr = fmt.format(t.amount);
    if (t.type == 'income') {
      await _notif.showIncomeNotification(category: t.category, amount: amountStr);
    } else {
      await _notif.showExpenseNotification(category: t.category, amount: amountStr);
    }
  }

  Future<void> deleteTransaction(int id) async {
    await _db.deleteTransaction(id);
    await loadTransactions();
  }

  void setMonth(int month, int year) {
    _selectedMonth = month;
    _selectedYear = year;
    loadBudgets();
    notifyListeners();
  }

  Map<String, double> get expenseByCategory {
    final Map<String, double> result = {};
    for (final t in monthlyTransactions.where((t) => t.type == 'expense')) {
      result[t.category] = (result[t.category] ?? 0) + t.amount;
    }
    return result;
  }

  Future<Map<int, Map<String, double>>> getYearlyData(int year) async {
    final data = await _db.getTransactionsByYear(year);
    final Map<int, Map<String, double>> result = {};
    for (int m = 1; m <= 12; m++) {
      result[m] = {'income': 0, 'expense': 0};
    }
    for (final t in data) {
      final month = DateTime.parse(t.date).month;
      if (t.type == 'income') {
        result[month]!['income'] = result[month]!['income']! + t.amount;
      } else {
        result[month]!['expense'] = result[month]!['expense']! + t.amount;
      }
    }
    return result;
  }

  Future<void> addCategory(CategoryModel c) async {
    await _db.insertCategory(c);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    await loadCategories();
  }

  Future<void> deleteAllData() async {
    await _db.deleteAllTransactions();
    await loadTransactions();
  }

  // ==================== BUDGETS ====================

  // Pengeluaran per kategori bulan ini
  double getSpentForCategory(String category) {
    return monthlyTransactions
        .where((t) => t.type == 'expense' && t.category == category)
        .fold(0, (sum, t) => sum + t.amount);
  }

  Future<void> setBudget(String category, double amount) async {
    await _db.insertBudget({
      'category': category,
      'limit_amount': amount,
      'month': _selectedMonth,
      'year': _selectedYear,
    });
    await loadBudgets();
  }

  Future<void> deleteBudget(int id) async {
    await _db.deleteBudget(id);
    await loadBudgets();
  }

  // ==================== SAVINGS ====================

  double get totalSavingsTarget =>
      _savings.fold(0, (sum, s) => sum + (s['target_amount'] as num).toDouble());

  double get totalSavingsCurrent =>
      _savings.fold(0, (sum, s) => sum + (s['current_amount'] as num).toDouble());

  Future<void> addSaving(String name, double target) async {
    await _db.insertSaving({
      'name': name,
      'target_amount': target,
      'current_amount': 0,
      'created_date': DateTime.now().toIso8601String().substring(0, 10),
    });
    await loadSavings();
  }

  Future<void> addToSaving(int id, double amount, Map<String, dynamic> saving) async {
    final newAmount = (saving['current_amount'] as num).toDouble() + amount;
    await _db.updateSaving({...saving, 'current_amount': newAmount});
    await loadSavings();
    await loadTransactions(); // update balance
  }

  Future<void> deleteSaving(int id) async {
    await _db.deleteSaving(id);
    await loadSavings();
  }
}