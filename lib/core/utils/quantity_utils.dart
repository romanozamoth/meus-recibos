abstract final class QuantityUtils {
  static int? tryParseMillis(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(\.\d{0,3})?$').hasMatch(normalized)) return null;
    final parts = normalized.split('.');
    final whole = int.tryParse(parts.first);
    if (whole == null) return null;
    final fraction = parts.length == 1 ? '000' : parts.last.padRight(3, '0');
    return whole * 1000 + int.parse(fraction);
  }

  static String formatMillis(int millis) {
    final whole = millis ~/ 1000;
    final remainder = (millis % 1000).abs();
    if (remainder == 0) return whole.toString();
    return '$whole,${remainder.toString().padLeft(3, '0').replaceFirst(RegExp(r'0+$'), '')}';
  }

  static int calculateTotal(int quantityMillis, int unitPriceCents) =>
      (quantityMillis * unitPriceCents + 500) ~/ 1000;
}
