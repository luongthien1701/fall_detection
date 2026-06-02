import threading

import uvicorn
from fastapi import FastAPI
from app.api.routes import router
from app.db.database import Base, engine, ensure_schema

from app.mqtt.mqtt_handle import start_mqtt, handler
from app.mqtt.worker import monitor_timeout

app = FastAPI()
services_started = False

Base.metadata.create_all(bind=engine)
ensure_schema()
app.include_router(router)


@app.on_event("startup")
def start_background_services():
    global services_started
    if services_started:
        return

    start_mqtt(handler)
    threading.Thread(target=monitor_timeout, daemon=True).start()
    services_started = True


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
