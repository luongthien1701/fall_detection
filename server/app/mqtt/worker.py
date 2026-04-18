from app.mqtt import mqtt_handle
import time
from app.core import state
from app.config import OFFLINE_TIMEOUT
def monitor_timeout():
    while True:
        now = time.time()

        if state.last_update is not None:
            if now - state.last_update > OFFLINE_TIMEOUT:
                if state.device_status != "offline":
                    print("Device OFFLINE")

                    state.device_status = "offline"

                    # 🔥 lấy client động
                    if mqtt_handle.mqtt_client:
                        mqtt_handle.mqtt_client.publish(
                            "esp32/device/status", "offline"
                        )

        time.sleep(1)