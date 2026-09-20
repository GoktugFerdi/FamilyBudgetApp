import 'package:family_budget_app/core/theme/app_theme.dart';
import 'package:family_budget_app/domain/entities/goal.dart';
import 'package:family_budget_app/presentation/providers/goal_provider.dart';
import 'package:family_budget_app/presentation/providers/language_provider.dart';
import 'package:family_budget_app/presentation/widgets/login_wall_bottom_sheet.dart';
import 'package:family_budget_app/core/utils/number_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  void _showAddDialog() {
    final titleController = TextEditingController();
    final targetAmountController = TextEditingController();
    final currentAmountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'new_goal'.tr(ref),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'goal_title'.tr(ref)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: targetAmountController,
                decoration: InputDecoration(labelText: 'target_amount'.tr(ref)),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: currentAmountController,
                decoration: InputDecoration(
                  labelText: 'current_amount'.tr(ref),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty &&
                        targetAmountController.text.isNotEmpty) {
                      final targetAmount = NumberParser.parseAmount(targetAmountController.text);
                      final currentAmount = NumberParser.parseAmount(currentAmountController.text);
                      final goal = GoalEntity(
                        title: titleController.text,
                        targetAmount: targetAmount,
                        currentAmount: currentAmount,
                        deadline: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                      );
                      Navigator.pop(context);
                      await ref.read(goalProvider.notifier).addGoal(goal);
                    }
                  },
                  child: Text('save'.tr(ref)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showAddProgressDialog(GoalEntity goal) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${goal.title} İçin Para Ekle'),
          content: TextField(
            controller: amountController,
            decoration: const InputDecoration(hintText: 'Miktar girin'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr(ref)),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountToAdd = NumberParser.parseAmount(amountController.text);
                final remaining = goal.targetAmount - goal.currentAmount;
                if (amountToAdd > 0) {
                  Navigator.pop(context);
                  await ref
                      .read(goalProvider.notifier)
                      .updateGoalProgress(
                        goal.id!,
                        goal.currentAmount + amountToAdd,
                      );
                  if (amountToAdd >= remaining && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('congratulations'.tr(ref))),
                    );
                  }
                }
              },
              child: Text('add'.tr(ref)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalState = ref.watch(goalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('goals'.tr(ref)),
        elevation: 0,
      ),
      body: goalState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${'error'.tr(ref)} $err')),
        data: (goals) {
          if (goals.isEmpty) {
            return Center(child: Text('no_goals'.tr(ref)));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(goalProvider.notifier).loadGoals();
            },
            child: ListView.builder(
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];
                return Dismissible(
                  key: Key(goal.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    ref.read(goalProvider.notifier).deleteGoal(goal.id!);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                goal.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: AppTheme.incomeColor,
                                ),
                                onPressed: () => checkGuestAndProceed(
                                  context,
                                  ref,
                                  () => _showAddProgressDialog(goal),
                                ),
                                tooltip: 'add_savings'.tr(ref),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: goal.progressPercentage,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            color: AppTheme.incomeColor,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${formatter.format(goal.currentAmount)} / ${formatter.format(goal.targetAmount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '%${(goal.progressPercentage * 100).toStringAsFixed(1)}',
                                style: const TextStyle(
                                  color: AppTheme.incomeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kalan: ${formatter.format(goal.remainingAmount)}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => checkGuestAndProceed(context, ref, _showAddDialog),
        child: const Icon(Icons.add),
      ),
    );
  }
}
