import pandas as pd
import time
from app.core import state
from app.config import WINDOW_SIZE, STEP_SIZE, ALERT_COOLDOWN
from app.services.feature_service import extract_features, columns
from app.services.model_service import predict
from app.services.fcm import send_fcm
from app.db.database import SessionLocal
from app.db.model import User, FallEvent

async def handler(websocket):

    print("ESP32 connected")

    state.device_status = "online"
    state.last_update = time.time()
    
    async for data in websocket:
        try:
            row = list(map(float, data.split(",")))

            if len(row) < 7:
                continue

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

                        print("⚠️ FALL DETECTED")

                        db = SessionLocal()
                        users = db.query(User).all()

                        message = f"Fall detected! A={row[6]:.2f}"

                        for user in users:
                            if user.fcm_token:
                                send_fcm(user.fcm_token, "⚠️ FALL", message)

                        # lưu DB
                        event = FallEvent(
                            time=time.ctime(),
                            total_a=row[6]
                        )
                        db.add(event)
                        db.commit()
                        db.close()

                        state.last_alert_time = now

                for _ in range(STEP_SIZE):
                    if state.queue:
                        state.queue.popleft()

        except Exception as e:
            print("Error:", e)