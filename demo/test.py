import asyncio
import websockets
import pandas as pd
import json
import time

# ===== CONFIG =====
WS_URL = "ws://localhost:8181"   # sửa nếu server khác
CSV_FILE = "test_data.csv"
DELAY = 0.1   # thời gian giữa mỗi lần gửi (giả lập realtime)

columns = [
    "time","AccelX","AccelY","AccelZ",
    "GyroX","GyroY","GyroZ","Total_A"
]

async def send_data():
    async with websockets.connect(WS_URL) as ws:
        print("✅ Connected to server")

        df = pd.read_csv(CSV_FILE)

        # đảm bảo đúng cột
        df = df[columns]

        for _, row in df.iterrows():
            data = row.to_dict()

            # convert numpy -> float (tránh lỗi json)
            for k in data:
                data[k] = float(data[k])

            msg = json.dumps(data)

            await ws.send(msg)
            print("📤 Sent:", msg)

            try:
                response = await asyncio.wait_for(ws.recv(), timeout=0.01)
                print("📥 Received:", response)
            except:
                pass

            time.sleep(DELAY)

asyncio.run(send_data())