import 'package:family_budget_app/core/theme/app_theme.dart';
import 'package:family_budget_app/domain/entities/bank_debt.dart';
import 'package:family_budget_app/presentation/providers/bank_debt_provider.dart';
import 'package:family_budget_app/presentation/providers/language_provider.dart';
import 'package:family_budget_app/presentation/widgets/login_wall_bottom_sheet.dart';
import 'package:family_budget_app/core/utils/number_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class BankDebtsScreen extends ConsumerStatefulWidget {
  const BankDebtsScreen({super.key});

  @override
  ConsumerState<BankDebtsScreen> createState() => _BankDebtsScreenState();
}

class _BankDebtsScreenState extends ConsumerState<BankDebtsScreen> {
  final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

  void _showAddDebtDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final installmentController = TextEditingController(text: '1');
    DateTime? selectedDate;

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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Yeni Borç Ekle',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Banka / Alacaklı Adı',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Toplam Borç Miktarı (₺)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: installmentController,
                    decoration: const InputDecoration(
                      labelText: 'Taksit Sayısı (İsteğe Bağlı)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Son Ödeme Tarihi (İsteğe Bağlı)'),
                    subtitle: Text(
                      selectedDate != null
                          ? DateFormat('dd.MM.yyyy').format(selectedDate!)
                          : 'Tarih Seçilmedi',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isNotEmpty &&
                          amountController.text.isNotEmpty) {
                        final amount = NumberParser.parseAmount(amountController.text);
                        final installments =
                            int.tryParse(installmentController.text) ?? 1;
                        if (amount > 0) {
                          final debt = BankDebtEntity(
                            creditorName: nameController.text,
                            totalAmount: amount,
                            installmentCount: installments,
                            dueDate: selectedDate,
                          );
                          Navigator.pop(context);
                          await ref.read(bankDebtProvider.notifier).addDebt(debt);
                        }
                      }
                    },
                    child: Text('add'.tr(ref)),
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
    final debtsState = ref.watch(bankDebtProvider);

    return Scaffold(
      appBar: AppBar(title: Text('bank_debts'.tr(ref))),
      body: debtsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${'error'.tr(ref)} $err')),
        data: (debts) {
          if (debts.isEmpty) {
            return const Center(child: Text('Henüz borç eklenmedi.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(bankDebtProvider.notifier).loadDebts();
            },
            child: ListView.builder(
              itemCount: debts.length,
              itemBuilder: (context, index) {
                final item = debts[index];
                return Dismissible(
                  key: Key(item.id.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    ref.read(bankDebtProvider.notifier).deleteDebt(item.id!);
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.debtColor,
                        child: Icon(Icons.account_balance, color: Colors.white),
                      ),
                      title: Text(
                        item.creditorName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Toplam: ${formatter.format(item.totalAmount)} (${item.installmentCount} Taksit)',
                          ),
                          if (item.dueDate != null)
                            Text(
                              'Son Ödeme: ${DateFormat('dd.MM.yyyy').format(item.dueDate!)}',
                              style: const TextStyle(color: Colors.orange),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'monthly'.tr(ref),
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                          Text(
                            formatter.format(item.monthlyInstallmentAmount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.expenseColor,
                              fontSize: 14,
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
        onPressed: () => checkGuestAndProceed(context, ref, _showAddDebtDialog),
        child: const Icon(Icons.add),
      ),
    );
  }
}
