import 'package:intl/intl.dart';
class History {
  final double value;
  final int id;
  final DateTime time;
  History(this.value, this.id, this.time);
  factory History.fromJson(Map<String, dynamic> json) {
  final format = DateFormat("EEE MMM d HH:mm:ss yyyy", "en_US");

  String timeStr = json['time'];

  // đổi nhiều space thành 1 space
  timeStr = timeStr.replaceAll(RegExp(r'\s+'), ' ');

  return History(
    (json['total_a'] as num).toDouble(),
    json['id'] as int,
    format.parse(timeStr),
  );
}
}