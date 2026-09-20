class BudgetLimits {
  final double? dailyLimit;
  final double? weeklyLimit;
  final double? monthlyLimit;
  final double? yearlyLimit;

  BudgetLimits({
    this.dailyLimit,
    this.weeklyLimit,
    this.monthlyLimit,
    this.yearlyLimit,
  });

  BudgetLimits copyWith({
    double? dailyLimit,
    double? weeklyLimit,
    double? monthlyLimit,
    double? yearlyLimit,
    bool clearDaily = false,
    bool clearWeekly = false,
    bool clearMonthly = false,
    bool clearYearly = false,
  }) {
    return BudgetLimits(
      dailyLimit: clearDaily ? null : (dailyLimit ?? this.dailyLimit),
      weeklyLimit: clearWeekly ? null : (weeklyLimit ?? this.weeklyLimit),
      monthlyLimit: clearMonthly ? null : (monthlyLimit ?? this.monthlyLimit),
      yearlyLimit: clearYearly ? null : (yearlyLimit ?? this.yearlyLimit),
    );
  }
}
