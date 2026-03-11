class CategoryModel {
  final int? id;
  final String name;
  final String icon;
  final String type; // 'income' atau 'expense'

  CategoryModel({
    this.id,
    required this.name,
    required this.icon,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'type': type,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      icon: map['icon'],
      type: map['type'],
    );
  }
}

// Kategori default saat pertama install
final List<CategoryModel> defaultCategories = [
  // Pengeluaran
  CategoryModel(name: 'Ngopi', icon: '☕️', type: 'expense'),
  CategoryModel(name: 'Rokok', icon: '🚬', type: 'expense'),
  CategoryModel(name: 'Jajan/Makan Diluar', icon: '🍚', type: 'expense'),
  CategoryModel(name: 'Belanja', icon: '🛍️', type: 'expense'),
  CategoryModel(name: 'Kesehatan', icon: '💊', type: 'expense'),
  CategoryModel(name: 'Hiburan', icon: '🎮', type: 'expense'),
  CategoryModel(name: 'Pendidikan', icon: '📚', type: 'expense'),
  CategoryModel(name: 'Lainnya', icon: '📦', type: 'expense'),
  // Pemasukan
  CategoryModel(name: 'Joki', icon: '💼', type: 'income'),
  CategoryModel(name: 'Freelance', icon: '💻', type: 'income'),
  CategoryModel(name: 'Cash', icon: '💵', type: 'income'),
  CategoryModel(name: 'Lainnya', icon: '💰', type: 'income'),
];