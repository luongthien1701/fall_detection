import paho.mqtt.client as mqtt
import pandas as pd
import time

from app.core import state
from app.config import WINDOW_SIZE, STEP_SIZE, ALERT_COOLDOWN, BROKER, PORT
from app.services.feature_service import extract_features, columns
from app.services.model_service import predict
from app.services.fcm import send_fcm
from app.db.database import SessionLocal
from app.db.model import User, FallEvent


# ===== HANDLER (GIỐNG WS) =====
def handler(data):
    try:
        row = list(map(float, data.split(",")))

        if len(row) < 7:
            return

        state.device_status = "online"
        state.last_update = time.time()

        values = [
            pd.Timestamp.now().timestamp(),
            *row[:6],
            row[6]
        ]

        state.queue.append(values)

        if len(state.queue) >= WINDOW_SIZE:

            df = pd.DataFrame(list(state.queue)[:WINDOW_SIZE], columns=columns)
            pred = predict(extract_features(df))

            if pred == 1:

                now = time.time()

                if now - state.last_alert_time > ALERT_COOLDOWN:

                    db = SessionLocal()
                    users = db.query(User).all()

                    message = f"Fall detected!"

                    for user in users:
                        if user.fcm_token:
                            send_fcm(user.fcm_token, message)

                    db.add(FallEvent(
                        time=time.ctime(),
                        total_a=row[6]
                    ))
                    db.commit()
                    db.close()

                    state.last_alert_time = now

            for _ in range(STEP_SIZE):
                if state.queue:
                    state.queue.popleft()

    except Exception as e:
        print("Error:", e)


# ===== MQTT WRAPPER (ẨN ĐI) =====
def start_mqtt(handler_func):
    client = mqtt.Client()

    def on_connect(client, userdata, flags, rc):
        print("MQTT connected:", rc)
        client.subscribe("esp32/fall_detection/data")

    def on_message(client, userdata, msg):
        data = msg.payload.decode()
        handler_func(data)   # 👈 gọi handler giống WS

    client.on_connect = on_connect
    client.on_message = on_message

    client.connect(BROKER, PORT, 60)
    client.loop_start()