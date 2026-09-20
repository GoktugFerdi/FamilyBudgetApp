class BankDebtEntity {
  final int? id;
  final String creditorName; // Banka veya kişi adı
  final double totalAmount;
  final int installmentCount; // 1 veya daha fazla. 1 ise tek çekim.
  final DateTime? dueDate; // Opsiyonel son ödeme tarihi

  BankDebtEntity({
    this.id,
    required this.creditorName,
    required this.totalAmount,
    this.installmentCount = 1,
    this.dueDate,
  });

  double get monthlyInstallmentAmount {
    if (installmentCount <= 0) return totalAmount;
    return totalAmount / installmentCount;
  }

  BankDebtEntity copyWith({
    int? id,
    String? creditorName,
    double? totalAmount,
    int? installmentCount,
    DateTime? dueDate,
  }) {
    return BankDebtEntity(
      id: id ?? this.id,
      creditorName: creditorName ?? this.creditorName,
      totalAmount: totalAmount ?? this.totalAmount,
      installmentCount: installmentCount ?? this.installmentCount,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
