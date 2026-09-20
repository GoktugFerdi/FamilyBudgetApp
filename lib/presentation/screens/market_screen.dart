import 'package:family_budget_app/core/theme/app_theme.dart';
import 'package:family_budget_app/presentation/providers/language_provider.dart';
import 'package:family_budget_app/presentation/providers/market_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class MarketScreen extends ConsumerWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marketState = ref.watch(marketProvider);
    final formatter = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('live_markets'.tr(ref)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(marketProvider.notifier).fetchRates(),
          )
        ],
      ),
      body: marketState.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('loading'.tr(ref)),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('${'error'.tr(ref)}\n$err', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(marketProvider.notifier).fetchRates(),
                child: Text('retry'.tr(ref)),
              )
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(child: Text('no_market_data'.tr(ref)));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(marketProvider.notifier).fetchRates();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                // Kripto, Döviz veya simülasyona göre renk ve format ayarı
                final isCrypto = item.symbol == 'BTC' || item.symbol == 'ETH';
                
                String priceText;
                if (item.currency == '₺') {
                  priceText = formatter.format(item.currentPrice);
                } else {
                  priceText = '${item.currentPrice.toStringAsFixed(2)}${item.currency}';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isCrypto 
                          ? Colors.orange.shade100 
                          : (item.isSimulation ? Colors.purple.shade100 : Colors.green.shade100),
                      child: Text(
                        item.symbol.substring(0, 1),
                        style: TextStyle(
                          color: isCrypto 
                              ? Colors.orange.shade900 
                              : (item.isSimulation ? Colors.purple.shade900 : Colors.green.shade900),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(item.symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Row(
                      children: [
                        Text(item.name),
                        if (item.isSimulation) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                        ]
                      ],
                    ),
                    trailing: Text(
                      priceText,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.incomeColor),
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
