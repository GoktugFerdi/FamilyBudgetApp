enum TransactionType {
  income,
  expense,
  debt,
  investment
}

class TransactionEntity {
  final int? id;
  final String title;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String? description;
  final String? creatorName;

  const TransactionEntity({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    this.description,
    this.creatorName,
  });

  TransactionEntity copyWith({
    int? id,
    String? title,
    double? amount,
    DateTime? date,
    TransactionType? type,
    String? description,
    String? creatorName,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      description: description ?? this.description,
      creatorName: creatorName ?? this.creatorName,
    );
  }
}
