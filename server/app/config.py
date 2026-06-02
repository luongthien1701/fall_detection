WINDOW_SIZE = 25
STEP_SIZE = 10

ALERT_COOLDOWN = 5

SERVICE_ACCOUNT_FILE = "service-account.json"
PROJECT_ID = "device-streaming-79c92ab1"


BROKER = "broker.hivemq.com"
PORT = 1883
OFFLINE_TIMEOUT = 5

MQTT_DATA_TOPIC = "esp32/fall_detection/data"
MQTT_STATUS_TOPIC = "esp32/fall_detection/status"
MQTT_EVENT_TOPIC = "esp32/fall_detection/events"
MQTT_CONTROL_TOPIC_TEMPLATE = "esp32/fall_detection/{device_code}/control"
MQTT_BUZZER_TOPIC_TEMPLATE = "esp32/fall_detection/{device_code}/buzzer"
BUZZER_DURATION_MS = 2000
