abstract final class CurrencyUtils {
  static int? tryParseCents(String value) {
    var text = value.trim().replaceAll(RegExp(r'[^0-9,.]'), '');
    if (text.isEmpty) return null;
    final comma = text.lastIndexOf(',');
    final dot = text.lastIndexOf('.');
    final separator = comma > dot ? comma : dot;
    if (separator >= 0 && text.length - separator - 1 <= 2) {
      final integer = text
          .substring(0, separator)
          .replaceAll(RegExp(r'[^0-9]'), '');
      final decimal = text
          .substring(separator + 1)
          .replaceAll(RegExp(r'[^0-9]'), '')
          .padRight(2, '0');
      return int.tryParse(
        '${integer.isEmpty ? '0' : integer}${decimal.substring(0, 2)}',
      );
    }
    text = text.replaceAll(RegExp(r'[^0-9]'), '');
    final whole = int.tryParse(text);
    return whole == null ? null : whole * 100;
  }

  static String format(int cents) {
    final absolute = cents.abs();
    final whole = absolute ~/ 100;
    final decimal = (absolute % 100).toString().padLeft(2, '0');
    final chars = whole.toString().split('').reversed.toList();
    final groups = <String>[];
    for (var index = 0; index < chars.length; index += 3) {
      groups.add(chars.skip(index).take(3).toList().reversed.join());
    }
    final sign = cents < 0 ? '-' : '';
    return '${sign}R\$ ${groups.reversed.join('.')},$decimal';
  }
}
