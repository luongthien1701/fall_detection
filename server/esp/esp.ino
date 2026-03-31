#include <WiFi.h>
#include <Wire.h>
#include <MPU6050_tockn.h>
#include <WebSocketsClient.h>
#include <WiFiManager.h>  // thêm

WebSocketsClient webSocket;
MPU6050 mpu6050(Wire);
WiFiManager wm;

void webSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_CONNECTED:
      Serial.println("Connected to server");
      break;

    case WStype_DISCONNECTED:
      Serial.println("Disconnected");
      break;
  }
}

void setup() {
  Serial.begin(115200);

  // ===== MPU =====
  Wire.begin();
  mpu6050.begin();
  mpu6050.calcGyroOffsets(true);

  // ===== WiFiManager =====
  bool res;
  res = wm.autoConnect("ESP32_Config"); 
  // tên WiFi AP khi chưa connect được

  if(!res) {
    Serial.println("Failed to connect");
    ESP.restart();
  }

  Serial.println("WiFi connected");
  Serial.print("IP: ");
  Serial.println(WiFi.localIP());

  // ===== WebSocket =====
  webSocket.begin("192.168.196.183", 8181, "/");
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(5000);
}

void loop() {
  webSocket.loop();

  // đọc MPU6050
  mpu6050.update();

  float ax = mpu6050.getAccX();
  float ay = mpu6050.getAccY();
  float az = mpu6050.getAccZ();

  float gx = mpu6050.getGyroX();
  float gy = mpu6050.getGyroY();
  float gz = mpu6050.getGyroZ();

  float A = sqrt(ax*ax + ay*ay + az*az);

  String data = String(ax) + "," + String(ay) + "," + String(az) + "," +
                String(gx) + "," + String(gy) + "," +
                String(gz) + "," + String(A);

  webSocket.sendTXT(data);
  Serial.println(data);

  delay(100);
}