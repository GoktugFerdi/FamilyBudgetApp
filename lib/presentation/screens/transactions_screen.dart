import 'package:family_budget_app/core/theme/app_theme.dart';
import 'package:family_budget_app/domain/entities/transaction.dart';
import 'package:family_budget_app/presentation/providers/auth_provider.dart';
import 'package:family_budget_app/presentation/providers/language_provider.dart';
import 'package:family_budget_app/presentation/providers/transaction_provider.dart';
import 'package:family_budget_app/presentation/widgets/login_wall_bottom_sheet.dart';
import 'package:family_budget_app/core/utils/number_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  void _showAddDialog({TransactionEntity? existingTransaction}) {
    final titleController = TextEditingController(
      text: existingTransaction?.title ?? '',
    );

    String amountText = '';
    if (existingTransaction != null) {
      if (existingTransaction.amount % 1000 == 0) {
        amountText = (existingTransaction.amount / 1000).toStringAsFixed(1);
      } else {
        amountText = existingTransaction.amount.toString().replaceAll('.', ',');
      }
    }
    final amountController = TextEditingController(text: amountText);

    TransactionType selectedType =
        existingTransaction?.type ?? TransactionType.expense;
    DateTime selectedDate = existingTransaction?.date ?? DateTime.now();
    final activePlan = ref.read(authProvider).activePlan;
    final currentUser = ref.read(authProvider).userName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    'new_transaction'.tr(ref),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'transaction_title'.tr(ref),
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
                  ListTile(
                    title: Text('date_select'.tr(ref)),
                    subtitle: Text(
                      DateFormat('dd.MM.yyyy').format(selectedDate),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<TransactionType>(
                    segments: [
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('income'.tr(ref)),
                      ),
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('expense'.tr(ref)),
                      ),
                      ButtonSegment(
                        value: TransactionType.debt,
                        label: Text('debt'.tr(ref)),
                      ),
                      ButtonSegment(
                        value: TransactionType.investment,
                        label: Text('investment'.tr(ref)),
                      ),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (Set<TransactionType> newSelection) {
                      setModalState(() {
                        selectedType = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (titleController.text.isNotEmpty &&
                            amountController.text.isNotEmpty) {
                          final amount = NumberParser.parseAmount(
                            amountController.text.trim(),
                          );

                          final transaction = TransactionEntity(
                            id: existingTransaction?.id,
                            title: titleController.text,
                            amount: amount,
                            date: selectedDate,
                            type: selectedType,
                            creatorName:
                                existingTransaction?.creatorName ??
                                (activePlan == 'family' ? currentUser : null),
                          );

                          Navigator.pop(context);
                          if (existingTransaction != null) {
                            await ref
                                .read(transactionProvider.notifier)
                                .updateTransaction(transaction);
                          } else {
                            await ref
                                .read(transactionProvider.notifier)
                                .addTransaction(transaction);
                          }
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionProvider);
    final activePlan = ref.watch(authProvider).activePlan;

    return Scaffold(
      appBar: AppBar(
        title: Text('transactions'.tr(ref)),
        elevation: 0,
      ),
      body: transactionState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${'error'.tr(ref)} $err')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return Center(child: Text('no_transactions'.tr(ref)));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(transactionProvider.notifier).loadTransactions();
            },
            child: ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final item = transactions[index];
                Color iconColor;
                IconData iconData;
                switch (item.type) {
                  case TransactionType.income:
                    iconColor = AppTheme.incomeColor;
                    iconData = Icons.arrow_upward;
                    break;
                  case TransactionType.expense:
                    iconColor = AppTheme.expenseColor;
                    iconData = Icons.arrow_downward;
                    break;
                  case TransactionType.debt:
                    iconColor = AppTheme.debtColor;
                    iconData = Icons.money_off;
                    break;
                  case TransactionType.investment:
                    iconColor = AppTheme.investmentColor;
                    iconData = Icons.trending_up;
                    break;
                }

                return Dismissible(
                  key: Key(item.id.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    ref
                        .read(transactionProvider.notifier)
                        .deleteTransaction(item.id!);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      onLongPress: () {
                        checkGuestAndProceed(
                          context,
                          ref,
                          () => _showAddDialog(existingTransaction: item),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundColor: iconColor.withValues(alpha: 0.2),
                        child: Icon(iconData, color: iconColor),
                      ),
                      title: Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('dd.MM.yyyy HH:mm').format(item.date)),
                          if (activePlan == 'family' && item.creatorName != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${'person'.tr(ref)}: ${item.creatorName}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(
                        formatter.format(item.amount),
                        style: TextStyle(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
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
