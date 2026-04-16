import time
from fastapi import APIRouter
from app.core import state
from app.db.database import SessionLocal
from app.db.model import FallEvent
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.model import User
from app.services.auth_service import hash_password, verify_password


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



def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
from fastapi import Body

@router.post("/api/auth/signup")
def register(data: dict = Body(...), db: Session = Depends(get_db)):
    print("Register data:", data)
    user = User(
        firstname=data.get("firstname"),
        email=data.get("email"),
        password=data.get("password"),
        phone=data.get("phone"),
        fcm_token=data.get("fcm_token")
    )

    db.add(user)
    db.commit()

    return {
        "success": True,
        "message": "User created successfully",
        "user_id": user.id
    }
from fastapi import Body

@router.post("/api/auth/login")
def login(data: dict = Body(...), db: Session = Depends(get_db)):
    email = data.get("email")
    password = data.get("password")

    user = db.query(User).filter(User.email == email).first()

    if not user:
        return {"success": False, "message": "User not found"}

    if not verify_password(password, user.password):
        return {"success": False, "message": "Wrong password"}

    user.fcm_token = data.get("fcm_token")
    db.commit()
    return {
        "success": True,
        "message": "Login successful",
        "user_id": user.id
    }