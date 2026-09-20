import 'package:family_budget_app/presentation/providers/subscription_provider.dart';
import 'package:family_budget_app/core/theme/app_theme.dart';
import 'package:family_budget_app/presentation/providers/alert_provider.dart';
import 'package:family_budget_app/presentation/providers/bank_debt_provider.dart';
import 'package:family_budget_app/presentation/providers/budget_limit_provider.dart';
import 'package:family_budget_app/presentation/providers/language_provider.dart';
import 'package:family_budget_app/presentation/providers/auth_provider.dart';
import 'package:family_budget_app/core/utils/pdf_generator.dart';
import 'package:family_budget_app/presentation/providers/transaction_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final PageController _pageController = PageController();
  int _currentChartIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredState = ref.watch(filteredTransactionsProvider);
    final bankDebtsState = ref.watch(bankDebtProvider);
    final subscriptionsState = ref.watch(subscriptionProvider);
    final currentFilter = ref.watch(timeFilterProvider);

    final dismissedAlerts = ref.watch(alertProvider);
    final budgetLimits = ref.watch(budgetLimitProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('pdf_report_title'.tr(ref)),
        toolbarHeight: 48,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            tooltip: 'pdf_report_title'.tr(ref),
            onPressed: () {
              filteredState.whenData((transactions) {
                final activePlan = ref.read(authProvider).activePlan;
                PdfGenerator.generateAndPrintPdf(
                  transactions: transactions,
                  title: 'pdf_report_title'.tr(ref),
                  incomeLabel: 'pdf_income'.tr(ref),
                  expenseLabel: 'pdf_expense'.tr(ref),
                  netLabel: 'pdf_net'.tr(ref),
                  personLabel: 'person'.tr(ref),
                  isFamilyPlan: activePlan == 'family',
                );
              });
            },
          ),
        ],
      ),
      body: filteredState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${'error'.tr(ref)} $err')),
        data: (transactions) {
          final bankDebtsList = bankDebtsState.value ?? [];

          final income = getTotalIncome(transactions);
          final expense = getTotalExpense(transactions);

          // Normal borçlar + Banka taksitleri
          final bankDebtAmount = getBankDebtForFilter(
            bankDebtsList,
            currentFilter,
          );
          final debt = getTotalDebt(transactions) + bankDebtAmount;

          final investment = getTotalInvestment(transactions);

          double weeklySub = 0;
          double monthlySub = 0;
          double yearlySub = 0;

          final subsList = subscriptionsState.value ?? [];
          for (var sub in subsList) {
            if (sub.cycle == 'weekly') {
              weeklySub += sub.amount;
            } else if (sub.cycle == 'monthly') {
              monthlySub += sub.amount;
            } else if (sub.cycle == 'yearly') {
              yearlySub += sub.amount;
            }
          }

          // Net bakiye hesaplaması
          final netBalance = income - expense - debt - investment;

          final formatter = NumberFormat.currency(
            locale: 'tr_TR',
            symbol: '₺',
          );

          // Yaklaşan ödemeleri bul (3 gün içinde) ve kapatılanları filtrele
          final upcomingDebts = bankDebtsList.where((d) {
            if (d.dueDate == null) return false;
            if (dismissedAlerts.contains(d.id)) return false;
            final difference = d.dueDate!.difference(DateTime.now()).inDays;
            return difference >= 0 && difference <= 3;
          }).toList();

          // Harcama Limiti Hesaplaması
          double? currentLimit;
          switch (currentFilter) {
            case TimeFilter.daily:
              currentLimit = budgetLimits.dailyLimit;
              break;
            case TimeFilter.weekly:
              currentLimit = budgetLimits.weeklyLimit;
              break;
            case TimeFilter.monthly:
              currentLimit = budgetLimits.monthlyLimit;
              break;
            case TimeFilter.yearly:
              currentLimit = budgetLimits.yearlyLimit;
              break;
          }

          bool isLimitApproaching = false;
          bool isLimitExceeded = false;
          if (currentLimit != null && currentLimit > 0) {
            if (expense >= currentLimit) {
              isLimitExceeded = true;
            } else if (expense >= currentLimit * 0.8) {
              isLimitApproaching = true;
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(transactionProvider.notifier).loadTransactions();
              await ref.read(bankDebtProvider.notifier).loadDebts();
              await ref.read(subscriptionProvider.notifier).loadSubscriptions();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Zaman Filtresi
                SegmentedButton<TimeFilter>(
                  segments: [
                    ButtonSegment(
                      value: TimeFilter.daily,
                      label: Text('daily'.tr(ref)),
                    ),
                    ButtonSegment(
                      value: TimeFilter.weekly,
                      label: Text('weekly'.tr(ref)),
                    ),
                    ButtonSegment(
                      value: TimeFilter.monthly,
                      label: Text('monthly'.tr(ref)),
                    ),
                    ButtonSegment(
                      value: TimeFilter.yearly,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [Text('yearly'.tr(ref))],
                      ),
                    ),
                  ],
                  selected: {currentFilter},
                  onSelectionChanged: (Set<TimeFilter> newSelection) {
                    final selected = newSelection.first;
                    ref.read(timeFilterProvider.notifier).state = selected;
                  },
                ),
                const SizedBox(height: 16),

                // Yaklaşan Ödeme Uyarıları (Kapatılabilir)
                if (upcomingDebts.isNotEmpty)
                  ...upcomingDebts.map(
                    (d) => Dismissible(
                      key: Key('alert_${d.id}'),
                      direction: DismissDirection.horizontal,
                      onDismissed: (direction) {
                        ref.read(alertProvider.notifier).dismissAlert(d.id!);
                      },
                      background: Container(
                        color: Colors.transparent,
                        alignment: Alignment.centerLeft,
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 32,
                        ),
                      ),
                      secondaryBackground: Container(
                        color: Colors.transparent,
                        alignment: Alignment.centerRight,
                        child: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 32,
                        ),
                      ),
                      child: Card(
                        color: Colors.orange.shade100,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                          ),
                          title: Text(
                            '${d.creditorName} ${'upcoming_payment'.tr(ref)}',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${formatter.format(d.monthlyInstallmentAmount)} - ${DateFormat('dd.MM.yyyy').format(d.dueDate!)}\n${'swipe_to_close'.tr(ref)}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Harcama Limiti Uyarıları
                if (isLimitExceeded)
                  Card(
                    color: Colors.red.shade100,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.error, color: Colors.red),
                      title: Text(
                        'exceeded_limit'.tr(ref),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${formatter.format(expense)} / ${formatter.format(currentLimit!)}\n${'exceeded_desc'.tr(ref)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  )
                else if (isLimitApproaching)
                  Card(
                    color: Colors.orange.shade100,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.warning, color: Colors.orange),
                      title: Text(
                        'approaching_limit'.tr(ref),
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${formatter.format(expense)} / ${formatter.format(currentLimit!)}\n${'approaching_desc'.tr(ref)}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Bakiye Kartı
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          'net_balance'.tr(ref),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatter.format(netBalance),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: netBalance >= 0
                                ? AppTheme.incomeColor
                                : AppTheme.expenseColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Grafikler (Carousel / PageView)
                if (income > 0 || expense > 0 || debt > 0 || investment > 0 || weeklySub > 0 || monthlySub > 0 || yearlySub > 0)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _currentChartIndex > 0
                                ? () => _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                                : null,
                          ),
                          Text(
                            _currentChartIndex == 0
                                ? 'spending_dist'.tr(ref)
                                : 'comparison'.tr(ref),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: _currentChartIndex < 1
                                ? () => _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  )
                                : null,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 250,
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() {
                              _currentChartIndex = index;
                            });
                          },
                          children: [
                            // 1. Grafik: Pie Chart (Dağılım)
                            PieChart(
                              PieChartData(
                                sectionsSpace: 4,
                                centerSpaceRadius: 60,
                                sections: [
                                  if (income > 0)
                                    PieChartSectionData(
                                      color: AppTheme.incomeColor,
                                      value: income,
                                      title: 'income'.tr(ref),
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  if (expense > 0)
                                    PieChartSectionData(
                                      color: AppTheme.expenseColor,
                                      value: expense,
                                      title: 'expense'.tr(ref),
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  if (debt > 0)
                                    PieChartSectionData(
                                      color: AppTheme.debtColor,
                                      value: debt,
                                      title: 'debt'.tr(ref),
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  if (investment > 0)
                                    PieChartSectionData(
                                      color: AppTheme.investmentColor,
                                      value: investment,
                                      title: 'investment'.tr(ref),
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  if (weeklySub > 0)
                                    PieChartSectionData(
                                      color: Colors.purple,
                                      value: weeklySub,
                                      title: 'weekly'.tr(ref),
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  if (monthlySub > 0)
                                    PieChartSectionData(
                                      color: Colors.orange,
                                      value: monthlySub,
                                      title: 'monthly'.tr(ref),
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  if (yearlySub > 0)
                                    PieChartSectionData(
                                      color: Colors.teal,
                                      value: yearlySub,
                                      title: 'yearly'.tr(ref),
                                      radius: 50,
                                      titleStyle: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // 2. Grafik: Bar Chart (Karşılaştırma)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  maxY:
                                      [
                                        income,
                                        expense,
                                        debt,
                                        investment,
                                      ].reduce((a, b) => a > b ? a : b) *
                                      1.2,
                                  barTouchData: BarTouchData(enabled: false),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget:
                                            (double value, TitleMeta meta) {
                                              const style = TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              );
                                              Widget text;
                                              switch (value.toInt()) {
                                                case 0:
                                                  text = Text(
                                                    'income'.tr(ref),
                                                    style: style,
                                                  );
                                                  break;
                                                case 1:
                                                  text = Text(
                                                    'expense'.tr(ref),
                                                    style: style,
                                                  );
                                                  break;
                                                case 2:
                                                  text = Text(
                                                    'debt'.tr(ref),
                                                    style: style,
                                                  );
                                                  break;
                                                case 3:
                                                  text = Text(
                                                    'investment'.tr(ref),
                                                    style: style,
                                                  );
                                                  break;
                                                default:
                                                  text = const Text('');
                                                  break;
                                              }
                                              return SideTitleWidget(
                                                meta: meta,
                                                child: text,
                                              );
                                            },
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: [
                                    BarChartGroupData(
                                      x: 0,
                                      barRods: [
                                        BarChartRodData(
                                          toY: income,
                                          color: AppTheme.incomeColor,
                                          width: 20,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ],
                                    ),
                                    BarChartGroupData(
                                      x: 1,
                                      barRods: [
                                        BarChartRodData(
                                          toY: expense,
                                          color: AppTheme.expenseColor,
                                          width: 20,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ],
                                    ),
                                    BarChartGroupData(
                                      x: 2,
                                      barRods: [
                                        BarChartRodData(
                                          toY: debt,
                                          color: AppTheme.debtColor,
                                          width: 20,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ],
                                    ),
                                    BarChartGroupData(
                                      x: 3,
                                      barRods: [
                                        BarChartRodData(
                                          toY: investment,
                                          color: AppTheme.investmentColor,
                                          width: 20,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Indicator Dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(2, (index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentChartIndex == index
                                  ? Colors.blue
                                  : Colors.grey.withValues(alpha: 0.5),
                            ),
                          );
                        }),
                      ),
                    ],
                  )
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'no_data'.tr(ref),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
                // Detaylı Özet
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryItem(
                      title: 'income'.tr(ref),
                      amount: formatter.format(income),
                      color: AppTheme.incomeColor,
                    ),
                    _SummaryItem(
                      title: 'expense'.tr(ref),
                      amount: formatter.format(expense),
                      color: AppTheme.expenseColor,
                    ),
                    _SummaryItem(
                      title: 'debt'.tr(ref),
                      amount: formatter.format(debt),
                      color: AppTheme.debtColor,
                    ),
                    _SummaryItem(
                      title: 'investment'.tr(ref),
                      amount: formatter.format(investment),
                      color: AppTheme.investmentColor,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const _SummaryItem({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
