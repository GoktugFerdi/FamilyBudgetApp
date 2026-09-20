class NumberParser {
  static double parseAmount(String input) {
    if (input.contains('.') && input.contains(',')) {
      String clean = input.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(clean) ?? 0.0;
    } else if (input.contains('.')) {
      double? val = double.tryParse(input);
      if (val != null) {
        return val * 1000.0;
      }
    } else if (input.contains(',')) {
      String replaced = input.replaceAll(',', '.');
      return double.tryParse(replaced) ?? 0.0;
    }
    return double.tryParse(input) ?? 0.0;
  }
}
