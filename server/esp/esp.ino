#include <WiFi.h>
#include <Wire.h>
#include <MPU6050_tockn.h>
#include <WiFiManager.h>
#include <PubSubClient.h>

// ===== MQTT =====
const char* mqtt_server = "broker.hivemq.com";
const int mqtt_port = 1883;
const char* device_code = "FD-001";
const char* mqtt_data_topic = "esp32/fall_detection/data";
String mqtt_control_topic = String("esp32/fall_detection/") + device_code + "/control";

WiFiClient espClient;
PubSubClient client(espClient);

// ===== MPU =====
MPU6050 mpu6050(Wire);
WiFiManager wm;

// ===== timing =====
unsigned long lastSend = 0;
const int sendInterval = 200;
// ===== device state =====
bool deviceOn = true;  // default on

// ===== reconnect MQTT =====
void reconnect() {
  while (!client.connected()) {
    Serial.print("Connecting MQTT...");
    
    if (client.connect("ESP32_Client")) {
      Serial.println("connected");
      client.subscribe(mqtt_control_topic.c_str());
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" retry in 2s");
      delay(2000);
    }
  }
}
// ===== callback for MQTT messages =====
void callback(char* topic, byte* payload, unsigned int length) {
  String message = "";
  for (int i = 0; i < length; i++) {
    message += (char)payload[i];
  }
  Serial.print("Message arrived [");
  Serial.print(topic);
  Serial.print("]: ");
  Serial.println(message);

  if (String(topic) == mqtt_control_topic) {
    if (message == "on") {
      deviceOn = true;
      Serial.println("Device turned ON");
    } else if (message == "off") {
      deviceOn = false;
      Serial.println("Device turned OFF");
    }
  }
}
void setup() {
  Serial.begin(115200);

  // ===== MPU =====
  Wire.begin(21, 22);
  mpu6050.begin();
  mpu6050.calcGyroOffsets(true);

  // ===== WiFi =====
  if (!wm.autoConnect("ESP32_Config")) {
    Serial.println("WiFi Failed");
    ESP.restart();
  }

  Serial.println("WiFi connected");
  Serial.println(WiFi.localIP());
  Serial.print("Device code: ");
  Serial.println(device_code);

  // ===== MQTT =====
  client.setServer(mqtt_server, mqtt_port);
  client.setCallback(callback);

  WiFi.setSleep(false); // 🔥 giảm mất WiFi
}

void loop() {
  // ===== reconnect MQTT =====
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // ===== gửi dữ liệu =====
  if (deviceOn && millis() - lastSend > sendInterval) {
    lastSend = millis();

    mpu6050.update();

    float ax = mpu6050.getAccX();
    float ay = mpu6050.getAccY();
    float az = mpu6050.getAccZ();

    float gx = mpu6050.getGyroX();
    float gy = mpu6050.getGyroY();
    float gz = mpu6050.getGyroZ();

    float A = sqrt(ax*ax + ay*ay + az*az);

    // 🔥 dùng char thay vì String (tránh crash)
    char data[120];
    sprintf(data, "%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f",
            device_code, ax, ay, az, gx, gy, gz, A);

    // ===== publish =====
    client.publish(mqtt_data_topic, data);

    Serial.println(data);
  }
}
