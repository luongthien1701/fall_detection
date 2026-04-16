import websocket
import csv
import time

# kết nối websocket
try:
    ws = websocket.create_connection("ws://192.168.196.237:81")
    print("Kết nối thành công!")
except Exception as e:
    print(f"Lỗi kết nối: {e}")
    exit()

with open("mpu_data_chest.csv", "w", newline="") as f:
    writer = csv.writer(f)

    writer.writerow(["time","AccelX","AccelY","AccelZ",
                     "GyroX","GyroY","GyroZ","Total_A","Activity"])

    while True:
        try:
            data = ws.recv()

            if not data:
                continue

            row = data.split(",")

            if len(row) < 7:
                continue

            ax = float(row[0])
            ay = float(row[1])
            az = float(row[2])
            gx = float(row[3])
            gy = float(row[4])
            gz = float(row[5])
            A  = float(row[6])

            activity = "Moving"

            if A > 2 and (abs(gx) > 150 or abs(gy) > 150 or abs(gz) > 150):

                if az > 0.6:
                    activity = "Fall_Forward"
                elif az < -0.6:
                    activity = "Fall_Backward"
                elif ax < -0.6:
                    activity = "Fall_Right"
                elif ax > 0.6:
                    activity = "Fall_Left"
                else:
                    activity = "Fall_Detected"

            else:

                if abs(ay) > 0.8:
                    activity = "Standing"

                elif abs(ay) > 0.4 and abs(az) > 0.4:
                    activity = "Sitting"

                elif abs(az) > 0.7 or abs(ax) > 0.7:
                    activity = "Lying"

                else:
                    activity = "Moving/Walking"

            current_time = time.time()

            writer.writerow([current_time,ax,ay,az,gx,gy,gz,A,activity])

            print(f"[{activity:15}] AX:{ax:>6.2f} AY:{ay:>6.2f} AZ:{az:>6.2f} | A:{A:>5.2f}")

        except KeyboardInterrupt:
            print("Dừng chương trình")
            break

        except Exception as e:
            print("Lỗi nhận dữ liệu:", e)
            time.sleep(1)

ws.close()