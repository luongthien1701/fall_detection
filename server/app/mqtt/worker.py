from app.mqtt import mqtt_handle
import time
from app.core import state
from app.config import MQTT_STATUS_TOPIC, OFFLINE_TIMEOUT
from app.db.database import SessionLocal
from app.db.model import Device


def monitor_timeout():
    while True:
        now = time.time()

        for device_code, device in list(state.devices.items()):
            last_update = device.get("last_update")
            if last_update is None:
                continue

            if now - last_update > OFFLINE_TIMEOUT:
                if device.get("status") != "offline":
                    print(f"Device {device_code} OFFLINE")
                    device["status"] = "offline"

                    if mqtt_handle.mqtt_client:
                        mqtt_handle.mqtt_client.publish(
                            MQTT_STATUS_TOPIC,
                            f"{device_code},offline",
                            retain=True,
                        )

                    db = SessionLocal()
                    try:
                        db_device = (
                            db.query(Device)
                            .filter(Device.code == device_code)
                            .first()
                        )
                        if db_device:
                            db_device.status = "offline"
                            db.commit()
                    finally:
                        db.close()

        if state.last_update is not None:
            if now - state.last_update > OFFLINE_TIMEOUT:
                if state.device_status != "offline":
                    print("Device OFFLINE")

                    state.device_status = "offline"

                    # 🔥 lấy client động
                    if mqtt_handle.mqtt_client:
                        mqtt_handle.mqtt_client.publish(
                            MQTT_STATUS_TOPIC,
                            "offline",
                            retain=True,
                        )

        time.sleep(1)
