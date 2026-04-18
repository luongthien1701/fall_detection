import 'package:intl/intl.dart';
class History {
  final double value;
  final int id;
  final DateTime time;
  History(this.value, this.id, this.time);
  factory History.fromJson(Map<String, dynamic> json) {
  final format = DateFormat("EEE MMM dd HH:mm:ss yyyy", "en_US");

  return History(
    (json['total_a'] as num).toDouble(),
    json['id'] as int,
    format.parse(json['time']),
  );
}
}