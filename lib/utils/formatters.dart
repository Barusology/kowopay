String formatNaira(num amount, {bool withDecimals = true}) {
  final String fixed = amount.toStringAsFixed(withDecimals ? 2 : 0);
  final List<String> parts = fixed.split('.');
  final String whole = parts.first;
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
    buffer.write(whole[i]);
  }
  return withDecimals
      ? '₦${buffer.toString()}.${parts.last}'
      : '₦${buffer.toString()}';
}

DateTime? parseTimestamp(Object? value) {
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

const List<String> _months = <String>[
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDate(Object? value) {
  final DateTime? date = parseTimestamp(value);
  if (date == null) return '—';
  final DateTime local = date.toLocal();
  return '${_months[local.month - 1]} ${local.day}, ${local.year}';
}

String formatTime(Object? value) {
  final DateTime? date = parseTimestamp(value);
  if (date == null) return '';
  final DateTime local = date.toLocal();
  final int hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final String minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${local.hour >= 12 ? 'PM' : 'AM'}';
}

String greetingFor(DateTime time) {
  if (time.hour < 12) return 'Good morning';
  if (time.hour < 17) return 'Good afternoon';
  return 'Good evening';
}
