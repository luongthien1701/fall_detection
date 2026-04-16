#include <WiFi.h>
#include <Wire.h>
#include <MPU6050_tockn.h>
#include <WiFiManager.h>
#include <PubSubClient.h>

// ===== MQTT =====
const char* mqtt_server = "20.19.56.30";
const int mqtt_port = 1883;

WiFiClient espClient;
PubSubClient client(espClient);

// ===== MPU =====
MPU6050 mpu6050(Wire);
WiFiManager wm;

// ===== timing =====
unsigned long lastSend = 0;
const int sendInterval = 200;

// ===== reconnect MQTT =====
void reconnect() {
  while (!client.connected()) {
    Serial.print("Connecting MQTT...");
    
    if (client.connect("ESP32_Client")) {
      Serial.println("connected");
    } else {
      Serial.print("failed, rc=");
      Serial.print(client.state());
      Serial.println(" retry in 2s");
      delay(2000);
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

  // ===== MQTT =====
  client.setServer(mqtt_server, mqtt_port);

  WiFi.setSleep(false); // 🔥 giảm mất WiFi
}

void loop() {
  // ===== reconnect MQTT =====
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // ===== gửi dữ liệu =====
  if (millis() - lastSend > sendInterval) {
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
    sprintf(data, "%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f",
            ax, ay, az, gx, gy, gz, A);

    // ===== publish =====
    client.publish("esp32/data", data);

    Serial.println(data);
  }
}