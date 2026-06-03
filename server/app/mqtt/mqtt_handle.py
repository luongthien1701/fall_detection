import paho.mqtt.client as mqtt
import pandas as pd
import time

from app.core import state
from app.config import (
    ALERT_COOLDOWN,
    BROKER,
    BUZZER_DURATION_MS,
    MQTT_BUZZER_TOPIC_TEMPLATE,
    MQTT_CONTROL_TOPIC_TEMPLATE,
    MQTT_DATA_TOPIC,
    MQTT_EVENT_TOPIC,
    MQTT_STATUS_TOPIC,
    PORT,
    STEP_SIZE,
    WINDOW_SIZE,
)
from app.services.feature_service import extract_features, columns
from app.services.model_service import predict
from app.services.fcm import send_fcm
from app.db.database import SessionLocal
from app.db.model import Device, FallEvent, User, UserDevice

mqtt_client = None


def _parse_payload(data):
    parts = [part.strip() for part in data.split(",")]

    if len(parts) >= 8:
        device_code = parts[0]
        row = list(map(float, parts[1:8]))
        return device_code, row

    row = list(map(float, parts))
    if len(row) < 7:
        return None, None

    return "UNKNOWN", row[:7]


def _mark_device_online(device_code):
    now = time.time()
    previous_status = state.devices.get(device_code, {}).get("status")
    state.devices[device_code] = {
        "status": "online",
        "last_update": now,
    }
    state.device_status = "online"
    state.last_update = now

    if mqtt_client and previous_status != "online":
        mqtt_client.publish(
            MQTT_STATUS_TOPIC,
            f"{device_code},online",
            retain=True,
        )

    db = SessionLocal()
    try:
        device = db.query(Device).filter(Device.code == device_code).first()
        if not device:
            device = Device(
                code=device_code,
                name=f"Thiết bị {device_code}",
                status="online",
                last_update=now,
            )
            db.add(device)
        else:
            device.status = "online"
            device.last_update = now
        db.commit()
    finally:
        db.close()


def _control_topic(device_code):
    return MQTT_CONTROL_TOPIC_TEMPLATE.format(device_code=device_code)


def _buzzer_topic(device_code):
    return MQTT_BUZZER_TOPIC_TEMPLATE.format(device_code=device_code)


def publish_buzzer(device_code, duration_ms=BUZZER_DURATION_MS):
    topic = _buzzer_topic(device_code)
    payload = f"beep,{duration_ms}"
    

    if mqtt_client:
        result = mqtt_client.publish(topic, payload)
        success = result.rc == mqtt.MQTT_ERR_SUCCESS
        return success

    return False


def handler(data):
    try:
        device_code, row = _parse_payload(data)

        if not device_code or not row:
            return

        _mark_device_online(device_code)

        values = [
            pd.Timestamp.now().timestamp(),
            *row[:6],
            row[6]
        ]

        device_queue = state.device_queues[device_code]
        device_queue.append(values)

        if len(device_queue) >= WINDOW_SIZE:

            df = pd.DataFrame(list(device_queue)[:WINDOW_SIZE], columns=columns)
            pred = predict(extract_features(df))

            if pred == 1:

                now = time.time()

                if now - state.device_last_alert_time[device_code] > ALERT_COOLDOWN:

                    db = SessionLocal()
                    try:
                        users = (
                            db.query(User)
                            .join(UserDevice, UserDevice.user_id == User.id)
                            .join(Device, Device.id == UserDevice.device_id)
                            .filter(Device.code == device_code)
                            .filter(User.fcm_token.isnot(None))
                            .filter(User.fcm_token != "")
                            .distinct()
                            .all()
                        )

                        message = f"Fall detected!"

                        for user in users:
                            send_fcm(user.fcm_token, message, device_code)

                        db.add(FallEvent(
                            time=time.ctime(),
                            total_a=row[6],
                            device_code=device_code,
                        ))
                        db.commit()
                    finally:
                        db.close()

                    if mqtt_client:
                        mqtt_client.publish(
                            MQTT_EVENT_TOPIC, f"{device_code},fall_detected"
                        )
                        publish_buzzer(device_code)

                    state.last_alert_time = now
                    state.device_last_alert_time[device_code] = now

            for _ in range(STEP_SIZE):
                if device_queue:
                    device_queue.popleft()

    except Exception as e:
        print("Error:", e)


# ===== MQTT WRAPPER (ẨN ĐI) =====
def start_mqtt(handler_func):
    global mqtt_client
    mqtt_client = mqtt.Client()

    def on_connect(client, userdata, flags, rc):
        print("MQTT connected:", rc)
        client.subscribe(MQTT_DATA_TOPIC)

    def on_message(client, userdata, msg):
        data = msg.payload.decode()
        handler_func(data)   # 👈 gọi handler giống WS

    mqtt_client.on_connect = on_connect
    mqtt_client.on_message = on_message

    mqtt_client.connect(BROKER, PORT, 60)
    mqtt_client.loop_start()
# ===== PUBLISH CONTROL =====
def publish_control(command, device_code):
    topic = _control_topic(device_code)
    print(
        f"MQTT publish control requested: topic={topic}, payload={command}, "
        f"client_ready={mqtt_client is not None}"
    )

    if mqtt_client:
        result = mqtt_client.publish(topic, command)
        success = result.rc == mqtt.MQTT_ERR_SUCCESS
        print(
            f"MQTT publish control result: topic={topic}, "
            f"rc={result.rc}, mid={result.mid}, success={success}"
        )
        return success
    else:
        print("MQTT publish control failed: MQTT client not connected")
        return False
