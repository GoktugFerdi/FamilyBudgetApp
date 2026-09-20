import 'package:family_budget_app/presentation/providers/budget_limit_provider.dart';
import 'package:family_budget_app/presentation/providers/language_provider.dart';
import 'package:family_budget_app/presentation/widgets/login_wall_bottom_sheet.dart';
import 'package:family_budget_app/presentation/providers/transaction_provider.dart';
import 'package:family_budget_app/core/utils/number_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetLimitsScreen extends ConsumerStatefulWidget {
  const BudgetLimitsScreen({super.key});

  @override
  ConsumerState<BudgetLimitsScreen> createState() => _BudgetLimitsScreenState();
}

class _BudgetLimitsScreenState extends ConsumerState<BudgetLimitsScreen> {
  final TextEditingController _dailyController = TextEditingController();
  final TextEditingController _weeklyController = TextEditingController();
  final TextEditingController _monthlyController = TextEditingController();
  final TextEditingController _yearlyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final limits = ref.read(budgetLimitProvider);
      if (limits.dailyLimit != null) _dailyController.text = limits.dailyLimit.toString();
      if (limits.weeklyLimit != null) _weeklyController.text = limits.weeklyLimit.toString();
      if (limits.monthlyLimit != null) _monthlyController.text = limits.monthlyLimit.toString();
      if (limits.yearlyLimit != null) _yearlyController.text = limits.yearlyLimit.toString();
    });
  }

  @override
  void dispose() {
    _dailyController.dispose();
    _weeklyController.dispose();
    _monthlyController.dispose();
    _yearlyController.dispose();
    super.dispose();
  }

  void _saveLimits() {
    final notifier = ref.read(budgetLimitProvider.notifier);
    
    double? parseOrNull(String text) {
      if (text.trim().isEmpty) return null;
      return NumberParser.parseAmount(text.trim());
    }
    
    notifier.updateLimit(TimeFilter.daily, parseOrNull(_dailyController.text));
    notifier.updateLimit(TimeFilter.weekly, parseOrNull(_weeklyController.text));
    notifier.updateLimit(TimeFilter.monthly, parseOrNull(_monthlyController.text));
    notifier.updateLimit(TimeFilter.yearly, parseOrNull(_yearlyController.text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Limitler başarıyla kaydedildi!'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('budget_limits'.tr(ref)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => checkGuestAndProceed(context, ref, _saveLimits),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Bütçe disiplinini sağlamak için kendine harcama sınırları koy. Boş bıraktığın alanlarda limit uygulanmaz.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildLimitField('${'daily'.tr(ref)} Limit (₺)', _dailyController, Icons.today),
          const SizedBox(height: 16),
          _buildLimitField('${'weekly'.tr(ref)} Limit (₺)', _weeklyController, Icons.view_week),
          const SizedBox(height: 16),
          _buildLimitField('${'monthly'.tr(ref)} Limit (₺)', _monthlyController, Icons.calendar_month),
          const SizedBox(height: 16),
          _buildLimitField('${'yearly'.tr(ref)} Limit (₺)', _yearlyController, Icons.calendar_today),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => checkGuestAndProceed(context, ref, _saveLimits),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
            child: Text('save'.tr(ref), style: const TextStyle(fontSize: 16)),
          )
        ],
      ),
    );
  }

  Widget _buildLimitField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear, size: 20),
          onPressed: () => controller.clear(),
        ),
      ),
    );
  }
}
