class TransactionModel {
  final int? id;
  final String type; // 'income' atau 'expense'
  final double amount;
  final String category;
  final String date;
  final String? note;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'date': date,
      'note': note ?? '',
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      type: map['type'],
      amount: map['amount'],
      category: map['category'],
      date: map['date'],
      note: map['note'],
    );
  }
}