class MarketItem {
  final String name;
  final String symbol;
  final double currentPrice;
  final String currency; // Örn: '₺' veya 'USD' veya 'Puan'
  final bool isSimulation; // Gerçek mi yoksa simüle mi edildiğini belirtir
  final String iconPath; // Eğer yerel asset kullanırsak, şimdilik emoji veya basit harf kullanacağız

  MarketItem({
    required this.name,
    required this.symbol,
    required this.currentPrice,
    this.currency = '₺',
    this.isSimulation = false,
    this.iconPath = '',
  });
}
