abstract final class DocumentUtils {
  static String digitsOnly(String value) =>
      value.replaceAll(RegExp(r'[^0-9]'), '');

  static String format(String? value) {
    final digits = digitsOnly(value ?? '');
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.'
          '${digits.substring(6, 9)}-${digits.substring(9)}';
    }
    if (digits.length == 14) {
      return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.'
          '${digits.substring(5, 8)}/${digits.substring(8, 12)}-'
          '${digits.substring(12)}';
    }
    return digits;
  }
}
