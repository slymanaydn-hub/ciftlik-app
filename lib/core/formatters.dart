String todayIso() => DateTime.now().toIso8601String().substring(0, 10);

String monthStartIso() {
  final now = DateTime.now();
  return DateTime(now.year, now.month).toIso8601String().substring(0, 10);
}

String monthEndIso() {
  final now = DateTime.now();
  return DateTime(now.year, now.month + 1, 0).toIso8601String().substring(0, 10);
}

String showDate(Object? iso) {
  final raw = iso?.toString() ?? '';
  if (raw.isEmpty) return '-';
  final date = DateTime.tryParse(raw);
  if (date == null) return raw;
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String money(Object? value) => '${asDouble(value).toStringAsFixed(2)} ₺';

String ageText(Object? birthDate) {
  final raw = birthDate?.toString() ?? '';
  final birth = DateTime.tryParse(raw);
  if (birth == null) return '-';
  final now = DateTime.now();
  var months = (now.year - birth.year) * 12 + now.month - birth.month;
  if (now.day < birth.day) months--;
  if (months < 1) return '1 aydan küçük';
  if (months < 12) return '$months ay';
  final years = months ~/ 12;
  final rest = months % 12;
  return rest == 0 ? '$years yıl' : '$years yıl $rest ay';
}

double asDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '.')) ?? 0;
}

int asInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

DateTime estimatedBirth(DateTime breedingDate) => breedingDate.add(const Duration(days: 150));
