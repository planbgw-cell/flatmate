abstract final class CurrencyFormatter {
  /// 한국 원화 표기. 예: `₩1,200,000`
  static String krw(num amount) {
    final digits = amount.round().abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    final sign = amount < 0 ? '-' : '';
    return '$sign₩$buffer';
  }
}
