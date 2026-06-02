import time
from fastapi import APIRouter, Body, Depends, Query
from app.core import state
from app.db.database import SessionLocal
from app.db.model import Device, FallEvent, UserDevice
from sqlalchemy.orm import Session
from app.db.model import User
from app.services.auth_service import hash_password, verify_password
from app.mqtt.mqtt_handle import publish_buzzer, publish_control

router = APIRouter()
BEEP_COMMANDS = {"beep", "buzzer", "alarm"}
DEVICE_COMMANDS = {"on", "off"}


@router.get("/health")
def health():
    return {
        "success": True,
        "supported_control_commands": sorted([*DEVICE_COMMANDS, *BEEP_COMMANDS]),
    }


def get_user_device_codes(db: Session, user_id: int):
    rows = (
        db.query(Device.code)
        .join(UserDevice, UserDevice.device_id == Device.id)
        .filter(UserDevice.user_id == user_id)
        .all()
    )
    return [row[0] for row in rows]


def get_or_create_device(db: Session, device_code: str):
    device = db.query(Device).filter(Device.code == device_code).first()
    if device:
        return device

    state_device = state.devices.get(device_code)
    device = Device(
        code=device_code,
        name=f"Thiết bị {device_code}",
        status=state_device.get("status") if state_device else "offline",
        last_update=state_device.get("last_update") if state_device else None,
    )
    db.add(device)
    db.flush()
    return device

@router.get("/status")
def get_status(device_code: str | None = Query(default=None)):

    if device_code:
        device = state.devices.get(device_code)
        if not device:
            return {"status": "offline", "last_update": None}

        if time.time() - device["last_update"] > 10:
            device["status"] = "offline"

        return {
            "status": device["status"],
            "last_update": device["last_update"],
            "device_code": device_code,
        }

    if state.last_update is None:
        return {"status": "offline", "last_update": None}

    # nếu quá 10s không có data → offline
    if time.time() - state.last_update > 10:
        state.device_status = "offline"

    return {
        "status": state.device_status,
        "last_update": state.last_update
    }

@router.get("/is-online")
def is_online(device_code: str | None = Query(default=None)):
    if device_code:
        device = state.devices.get(device_code)
        if not device:
            return {"online": False}
        return {"online": (time.time() - device["last_update"] < 10)}

    if state.last_update is None:
        return {"online": False}
    return {"online": (time.time() - state.last_update < 10)}


@router.get("/history")
def history(device_code: str | None = Query(default=None)):
    db = SessionLocal()
    query = db.query(FallEvent)
    if device_code:
        query = query.filter(FallEvent.device_code == device_code)
    data = query.all()
    db.close()
    return data



def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/api/auth/signup")
def register(data: dict = Body(...), db: Session = Depends(get_db)):
    print("Register data:", data)
    email = data.get("email")
    password = data.get("password")

    if not email or not password:
        return {"success": False, "message": "Email and password are required"}

    if db.query(User).filter(User.email == email).first():
        return {"success": False, "message": "Email already exists"}

    user = User(
        firstname=data.get("firstname"),
        email=email,
        password=hash_password(password),
        phone=data.get("phone"),
        fcm_token=data.get("fcm_token")
    )

    db.add(user)
    db.commit()

    return {
        "success": True,
        "message": "User created successfully",
        "user_id": user.id,
        "device_code": None,
        "device_codes": [],
    }

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
    device_codes = get_user_device_codes(db, user.id)
    selected_device_code = device_codes[0] if device_codes else None

    return {
        "success": True,
        "message": "Login successful",
        "user_id": user.id,
        "device_code": selected_device_code,
        "device_codes": device_codes,
    }


@router.post("/api/device/connect")
def connect_device(data: dict = Body(...), db: Session = Depends(get_db)):
    user_id = data.get("user_id")
    device_code = (data.get("device_code") or "").strip()

    if not user_id or not device_code:
        return {"success": False, "message": "User and device code are required"}

    device = state.devices.get(device_code)
    if not device or device.get("status") != "online":
        return {
            "success": False,
            "message": "Device code not found or device is offline.",
        }

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return {"success": False, "message": "User not found"}

    db_device = get_or_create_device(db, device_code)
    exists = (
        db.query(UserDevice)
        .filter(
            UserDevice.user_id == user.id,
            UserDevice.device_id == db_device.id,
        )
        .first()
    )

    if not exists:
        db.add(UserDevice(user_id=user.id, device_id=db_device.id))

    db.commit()
    device_codes = get_user_device_codes(db, user.id)

    return {
        "success": True,
        "message": "Device connected successfully",
        "device_code": device_code,
        "device_codes": device_codes,
    }


@router.get("/api/devices")
def list_devices(user_id: int = Query(...), db: Session = Depends(get_db)):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        return {"success": False, "message": "User not found", "devices": []}

    devices = (
        db.query(Device)
        .join(UserDevice, UserDevice.device_id == Device.id)
        .filter(UserDevice.user_id == user_id)
        .all()
    )

    return {
        "success": True,
        "devices": [
            {
                "code": device.code,
                "name": device.name,
                "status": device.status,
                "last_update": device.last_update,
            }
            for device in devices
        ],
    }


@router.post("/control")
def control_device(
    command: str = Body(..., embed=True),
    device_code: str = Body(..., embed=True),
):
    command = (command or "").strip().lower()
    device_code = (device_code or "").strip()
    print(f"CONTROL request: command={command}, device_code={device_code}")

    if not device_code:
        print("CONTROL failed: missing device_code")
        return {"success": False, "message": "Device code is required"}

    if command in DEVICE_COMMANDS:
        success = publish_control(command, device_code)
        print(
            f"CONTROL response: command={command}, "
            f"device_code={device_code}, success={success}"
        )
        return {
            "success": success,
            "command": command,
            "device_code": device_code,
        }

    if command in BEEP_COMMANDS:
        success = publish_buzzer(device_code)
        print(
            f"CONTROL response: command=beep, "
            f"device_code={device_code}, success={success}"
        )
        return {
            "success": success,
            "command": "beep",
            "device_code": device_code,
        }

    else:
        print(f"CONTROL failed: invalid command={command}")
        return {"success": False, "message": "Invalid command"}
