import 'dart:convert';
import 'package:family_budget_app/domain/entities/market_item.dart';
import 'package:http/http.dart' as http;

class MarketApiService {
  // Döviz Kurları (Ücretsiz API)
  static const String fiatUrl = 'https://open.er-api.com/v6/latest/TRY';
  // Kripto Paralar (CoinGecko Ücretsiz API)
  static const String cryptoUrl = 'https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=try';

  Future<List<MarketItem>> fetchLiveRates() async {
    List<MarketItem> items = [];

    try {
      // 1. Dolar ve Euro (Gerçek Zamanlı)
      final fiatResponse = await http.get(Uri.parse(fiatUrl));
      if (fiatResponse.statusCode == 200) {
        final data = json.decode(fiatResponse.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        // API 1 TRY = X USD döndürdüğü için 1/X yaparak 1 USD = X TRY buluyoruz
        double usdTry = 1 / (rates['USD'] ?? 1);
        double eurTry = 1 / (rates['EUR'] ?? 1);

        items.add(MarketItem(name: 'Amerikan Doları', symbol: 'USD', currentPrice: usdTry));
        items.add(MarketItem(name: 'Euro', symbol: 'EUR', currentPrice: eurTry));
      }
    } catch (e) {
      // Hata olursa (internet yoksa) listeye eklenmez, simülasyonlar gösterilir
    }

    try {
      // 2. Bitcoin ve Ethereum (Gerçek Zamanlı)
      final cryptoResponse = await http.get(Uri.parse(cryptoUrl));
      if (cryptoResponse.statusCode == 200) {
        final data = json.decode(cryptoResponse.body);
        
        double btcTry = (data['bitcoin']?['try'] ?? 0).toDouble();
        double ethTry = (data['ethereum']?['try'] ?? 0).toDouble();

        if (btcTry > 0) items.add(MarketItem(name: 'Bitcoin', symbol: 'BTC', currentPrice: btcTry));
        if (ethTry > 0) items.add(MarketItem(name: 'Ethereum', symbol: 'ETH', currentPrice: ethTry));
      }
    } catch (e) {
      // Hata durumunda yoksay
    }

    return items;
  }
}
