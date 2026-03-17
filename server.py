import asyncio
import pandas as pd
import joblib
from collections import deque

WINDOW_SIZE = 25
STEP_SIZE = 10

queue = deque()

model = joblib.load("fall_model.pkl")

columns = [
    "time","AccelX","AccelY","AccelZ",
    "GyroX","GyroY","GyroZ","Total_A"
]

# ===== feature =====
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

# ===== xử lý data =====
async def handler(websocket):

    print("ESP32 connected")

    async for data in websocket:

        try:
            row = list(map(float, data.split(",")))
            if len(row) < 7:
                continue

            values = [
                pd.Timestamp.now().timestamp(),
                row[0],row[1],row[2],
                row[3],row[4],row[5],
                row[6]
            ]

            queue.append(values)

            # ===== predict luôn tại đây =====
            if len(queue) >= WINDOW_SIZE:

                window = list(queue)[:WINDOW_SIZE]
                df = pd.DataFrame(window, columns=columns)

                X = extract_features(df)
                pred = model.predict(X)[0]

                if pred == 1:
                    print("\n⚠️ FALL DETECTED\n")
                    print(df[["time","AccelX","AccelY","AccelZ","GyroX","GyroY","GyroZ","Total_A"]])
                # sliding window
                for _ in range(STEP_SIZE):
                    if queue:
                        queue.popleft()

        except Exception as e:
            print("Error:", e)

# ===== chạy server =====
async def main():
    print("Server running...")
    async with websockets.serve(handler, "0.0.0.0", 81):
        await asyncio.Future()  # chạy mãi

import websockets
asyncio.run(main())