import pandas as pd
import time
from app.core import state
from app.config import WINDOW_SIZE, STEP_SIZE, ALERT_COOLDOWN
from app.services.feature_service import extract_features, columns
from app.services.model_service import predict
from app.services.fcm import send_fcm
from app.db.database import SessionLocal
from app.db.model import Device, FallEvent, User, UserDevice


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

async def handler(websocket):

    print("ESP32 connected")

    state.device_status = "online"
    state.last_update = time.time()
    
    async for data in websocket:
        try:
            device_code, row = _parse_payload(data)

            if not device_code or not row:
                continue

            state.devices[device_code] = {
                "status": "online",
                "last_update": time.time(),
            }

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
                        users = (
                            db.query(User)
                            .join(UserDevice, UserDevice.user_id == User.id)
                            .join(Device, Device.id == UserDevice.device_id)
                            .filter(Device.code == device_code)
                            .all()
                        )

                        message = f"Fall detected! A={row[6]:.2f}"

                        for user in users:
                            if user.fcm_token:
                                send_fcm(user.fcm_token, message)

                        # lưu DB
                        event = FallEvent(
                            time=time.ctime(),
                            total_a=row[6],
                            device_code=device_code,
                        )
                        db.add(event)
                        db.commit()
                        db.close()

                        state.last_alert_time = now
                        state.device_last_alert_time[device_code] = now

                for _ in range(STEP_SIZE):
                    if device_queue:
                        device_queue.popleft()

        except Exception as e:
            print("Error:", e)
