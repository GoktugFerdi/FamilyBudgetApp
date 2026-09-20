class Subscription {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final String cycle; // 'weekly', 'monthly', 'yearly'
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.cycle,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'amount': amount,
      'cycle': cycle,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map, String docId) {
    return Subscription(
      id: docId,
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      cycle: map['cycle'] ?? 'monthly',
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt']) 
          : DateTime.now(),
    );
  }
}