import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  MqttServerClient? _client;

  final String broker = "broker.hivemq.com";
  final String clientId =
      "flutter_client_${DateTime.now().millisecondsSinceEpoch}";

  MqttServerClient get client => _client!;

  bool get isConnected =>
      _client?.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect() async {
    if (isConnected) {
      print("MQTT already connected");
      return;
    }

    final mqttClient = MqttServerClient(broker, clientId);
    _client = mqttClient;

    mqttClient.port = 1883;
    mqttClient.keepAlivePeriod = 20;
    mqttClient.logging(on: false);
    mqttClient.autoReconnect = true;
    mqttClient.resubscribeOnAutoReconnect = true;

    mqttClient.onConnected = () => print("MQTT connected");
    mqttClient.onDisconnected = () => print("MQTT disconnected");
    mqttClient.onAutoReconnect = () => print("MQTT auto reconnecting");
    mqttClient.onAutoReconnected = () => print("MQTT auto reconnected");

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .keepAliveFor(20);

    mqttClient.connectionMessage = connMess;

    try {
      await mqttClient.connect();
    } catch (e) {
      mqttClient.disconnect();
      rethrow;
    }
  }

  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atMostOnce);
  }

  void publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
  }

  Stream<String> listen(String topic) {
    return client.updates!
        .where((event) => event.isNotEmpty && event[0].topic == topic)
        .map((event) => event[0].payload as MqttPublishMessage)
        .map(
          (msg) =>
              MqttPublishPayload.bytesToStringAsString(msg.payload.message),
        );
  }
}
