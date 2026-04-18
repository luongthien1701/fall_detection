import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  late MqttServerClient client;

  final String broker = "broker.hivemq.com";
  final String clientId = "flutter_client_${DateTime.now().millisecondsSinceEpoch}";

  Future<void> connect() async {
    client = MqttServerClient(broker, clientId);
    client.port = 1883;
    client.keepAlivePeriod = 20;
    client.logging(on: false);

    client.onConnected = () => print("MQTT connected");
    client.onDisconnected = () => print("MQTT disconnected");

    final connMess = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .keepAliveFor(20);

    client.connectionMessage = connMess;

    try {
      await client.connect();
    } catch (e) {
      client.disconnect();
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
        .map((event) => event[0].payload as MqttPublishMessage)
        .map((msg) =>
            MqttPublishPayload.bytesToStringAsString(msg.payload.message));
  }
}