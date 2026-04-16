import asyncio
import pandas as pd
import joblib
from collections import deque
import http.client
import urllib.parse
import time
import websockets
from fastapi import FastAPI
import uvicorn

# ===== CONFIG =====
WINDOW_SIZE = 25
STEP_SIZE = 10

TELEGRAM_TOKEN = "YOUR_TOKEN"
CHAT_ID = "YOUR_CHAT_ID"

model = joblib.load("fall_model.pkl")

queue = deque()

columns = [
    "time","AccelX","AccelY","AccelZ",
    "GyroX","GyroY","GyroZ","Total_A"
]

last_alert_time = 0
ALERT_COOLDOWN = 5  # giây

# ===== trạng thái + lịch sử =====
device_status = "offline"
last_update = None
history = []

# ===== TELEGRAM =====
def send_telegram(message):

    conn = http.client.HTTPSConnection("api.telegram.org")

    url = f"/bot{TELEGRAM_TOKEN}/sendMessage?" + urllib.parse.urlencode({
        "chat_id": CHAT_ID,
        "text": message
    })

    try:
        conn.request("GET", url)
        res = conn.getresponse()
        print("Telegram:", res.status)
    except Exception as e:
        print("Telegram error:", e)

# ===== feature extraction =====
def extract_features(df):

    feat = {}

    for col in columns[1:]:
        feat[col+"_mean"] = df[col].mean()
        feat[col+"_std"] = df[col].std()
        feat[col+"_max"] = df[col].max()
        feat[col+"_min"] = df[col].min()
        feat[col+"_range"] = df[col].max() - df[col].min()

    feat["A_peak"] = df["Total_A"].max()
    feat["A_mean"] = df["Total_A"].mean()
    feat["A_std"] = df["Total_A"].std()
    feat["A_range"] = df["Total_A"].max() - df["Total_A"].min()
    feat["A_min"] = df["Total_A"].min()

    return pd.DataFrame([feat])

# ===== WEBSOCKET =====
async def handler(websocket):

    global last_alert_time, device_status, last_update, history

    print("ESP32 connected")

    async for data in websocket:

        try:
            row = list(map(float, data.split(",")))

            if len(row) < 7:
                continue

            # update trạng thái
            device_status = "online"
            last_update = time.time()

            values = [
                pd.Timestamp.now().timestamp(),
                row[0],row[1],row[2],
                row[3],row[4],row[5],
                row[6]
            ]

            queue.append(values)

            # ===== predict =====
            if len(queue) >= WINDOW_SIZE:

                window = list(queue)[:WINDOW_SIZE]
                df = pd.DataFrame(window, columns=columns)

                X = extract_features(df)
                pred = model.predict(X)[0]

                if pred == 1:

                    now = time.time()

                    if now - last_alert_time > ALERT_COOLDOWN:

                        print("\n⚠️ FALL DETECTED\n")

                        message = f"""
⚠️ FALL DETECTED
Time: {time.ctime()}
Accel: {row[0]:.2f}, {row[1]:.2f}, {row[2]:.2f}
Gyro: {row[3]:.2f}, {row[4]:.2f}, {row[5]:.2f}
Total_A: {row[6]:.2f}
"""

                        send_telegram(message)

                        # lưu lịch sử
                        history.append({
                            "time": time.ctime(),
                            "accel": row[:3],
                            "gyro": row[3:6],
                            "total_a": row[6]
                        })

                        last_alert_time = now

                # sliding window
                for _ in range(STEP_SIZE):
                    if queue:
                        queue.popleft()

        except Exception as e:
            print("Error:", e)

# ===== FASTAPI =====
app = FastAPI()

@app.get("/")
def root():
    return {"msg": "Fall Detection API running"}

@app.get("/status")
def get_status():
    return {
        "status": device_status,
        "last_update": last_update
    }

@app.get("/is-online")
def is_online():
    if last_update is None:
        return {"online": False}

    return {"online": (time.time() - last_update < 10)}

@app.get("/history")
def get_history():
    return history[-50:]

# ===== MAIN =====
async def start_ws():
    async with websockets.serve(handler, "0.0.0.0", 81):
        await asyncio.Future()

async def start_api():
    config = uvicorn.Config(app, host="0.0.0.0", port=8000)
    server = uvicorn.Server(config)
    await server.serve()

async def main():
    await asyncio.gather(
        start_ws(),
        start_api()
    )

if __name__ == "__main__":
    asyncio.run(main())