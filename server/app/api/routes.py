import time
from fastapi import APIRouter
from app.core import state
from app.db.database import SessionLocal
from app.db.model import FallEvent

router = APIRouter()

@router.get("/status")
def get_status():

    if state.last_update is None:
        return {"status": "offline"}

    # nếu quá 10s không có data → offline
    if time.time() - state.last_update > 10:
        state.device_status = "offline"

    return {
        "status": state.device_status,
        "last_update": state.last_update
    }

@router.get("/is-online")
def is_online():
    if state.last_update is None:
        return {"online": False}
    return {"online": (time.time() - state.last_update < 10)}


@router.get("/history")
def history():
    db = SessionLocal()
    data = db.query(FallEvent).all()
    db.close()
    return data