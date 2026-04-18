import threading

import uvicorn
from fastapi import FastAPI
from app.api.routes import router
from app.db.database import Base, engine

from app.mqtt.mqtt_handle import start_mqtt, handler
from app.mqtt.worker import monitor_timeout

app = FastAPI()

Base.metadata.create_all(bind=engine)
app.include_router(router)


if __name__ == "__main__":
    # 🚀 start MQTT
    start_mqtt(handler)
    threading.Thread(target=monitor_timeout, daemon=True).start()
    # 🚀 start API
    uvicorn.run(app, host="0.0.0.0", port=8000)