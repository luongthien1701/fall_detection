class Device {
  final String status;
  final double lastUpdate;
  
  Device(this.status, this.lastUpdate);
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      json['status'] as String,
      json['last_update'] as double,
    );
  }
}