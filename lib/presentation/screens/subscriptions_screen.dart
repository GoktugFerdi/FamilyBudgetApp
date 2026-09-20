import 'package:family_budget_app/domain/entities/subscription.dart';
import 'package:family_budget_app/presentation/providers/auth_provider.dart';
import 'package:family_budget_app/presentation/providers/subscription_provider.dart';
import 'package:family_budget_app/presentation/providers/language_provider.dart';
import 'package:family_budget_app/presentation/widgets/login_wall_bottom_sheet.dart';
import 'package:family_budget_app/core/utils/number_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() =>
      _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  void _showAddSubscriptionDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String cycle = 'monthly';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('add_subscription_title'.tr(ref)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'subscription_name_hint'.tr(ref),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(labelText: 'amount'.tr(ref)),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: cycle,
                    decoration: InputDecoration(
                      labelText: 'billing_cycle'.tr(ref),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text('weekly'.tr(ref)),
                      ),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('monthly'.tr(ref)),
                      ),
                      DropdownMenuItem(
                        value: 'yearly',
                        child: Text('yearly'.tr(ref)),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          cycle = val;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('cancel'.tr(ref)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isNotEmpty &&
                        amountController.text.isNotEmpty) {
                      final amount = NumberParser.parseAmount(
                        amountController.text,
                      );
                      final sub = Subscription(
                        id: '',
                        userId: ref.read(authProvider).userId ?? '',
                        title: titleController.text,
                        amount: amount,
                        cycle: cycle,
                        createdAt: DateTime.now(),
                      );
                      Navigator.pop(context);
                      await ref
                          .read(subscriptionProvider.notifier)
                          .addSubscription(sub);
                    }
                  },
                  child: Text('add'.tr(ref)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('subscriptions_title'.tr(ref)),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => checkGuestAndProceed(context, ref, _showAddSubscriptionDialog),
        child: const Icon(Icons.add),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('${'error'.tr(ref)} $err')),
        data: (subs) {
          if (subs.isEmpty) {
            return Center(child: Text('no_subscriptions'.tr(ref)));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(subscriptionProvider.notifier).loadSubscriptions();
            },
            child: ListView.builder(
              itemCount: subs.length,
              itemBuilder: (context, index) {
                final sub = subs[index];
                IconData icon = Icons.subscriptions;
                Color color = Colors.orange;
                String cycleText = 'monthly'.tr(ref);

                if (sub.cycle == 'weekly') {
                  cycleText = 'weekly'.tr(ref);
                  color = Colors.purple;
                } else if (sub.cycle == 'yearly') {
                  cycleText = 'yearly'.tr(ref);
                  color = Colors.teal;
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.2),
                      child: Icon(icon, color: color),
                    ),
                    title: Text(
                      sub.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('$cycleText - ${sub.amount} ₺'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        ref
                            .read(subscriptionProvider.notifier)
                            .deleteSubscription(sub.id);
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
