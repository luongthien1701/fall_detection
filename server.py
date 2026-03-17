import websocket
import pandas as pd
import joblib
import threading
import time
from collections import deque

WS_URL = "ws://192.168.196.237:81"

WINDOW_SIZE = 25      # giống train
STEP_SIZE = 10

queue = deque()

model = joblib.load("fall_model.pkl")

columns = [
    "time","AccelX","AccelY","AccelZ",
    "GyroX","GyroY","GyroZ","Total_A"
]


def extract_features(df):

    feat = {}

    for col in columns[1:]:

        feat[col+"_mean"] = df[col].mean()
        feat[col+"_std"] = df[col].std()
        feat[col+"_max"] = df[col].max()
        feat[col+"_min"] = df[col].min()
        feat[col+"_range"] = df[col].max() - df[col].min()

    # feature giống code train
    feat["A_peak"] = df["Total_A"].max()
    feat["A_mean"] = df["Total_A"].mean()
    feat["A_std"] = df["Total_A"].std()
    feat["A_range"] = df["Total_A"].max() - df["Total_A"].min()
    feat["A_min"] = df["Total_A"].min()

    return pd.DataFrame([feat])


def predictor():

    global queue

    while True:

        if len(queue) < WINDOW_SIZE:
            time.sleep(0.01)
            continue

        window = list(queue)[:WINDOW_SIZE]

        df = pd.DataFrame(window, columns=columns)

        X = extract_features(df)

        pred = model.predict(X)[0]

        if pred == 1:

            print("\n⚠️ FALL DETECTED\n")

            for row in window:
                print(",".join(map(str,row)))

            return

        # sliding window
        for _ in range(STEP_SIZE):
            if queue:
                queue.popleft()


def receiver():

    ws = websocket.create_connection(WS_URL)

    print("Connected to ESP32 WebSocket")

    while True:

        try:

            data = ws.recv()

            if not data:
                continue

            row = list(map(float,data.split(",")))

            if len(row) < 7:
                continue

            values = [
                pd.Timestamp.now().timestamp(),
                row[0],row[1],row[2],
                row[3],row[4],row[5],
                row[6]
            ]

            queue.append(values)

        except Exception as e:
            print("Receive error:",e)


print("Fall detection server running...")

threading.Thread(target=predictor,daemon=True).start()

receiver()