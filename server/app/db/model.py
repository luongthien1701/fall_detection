from sqlalchemy import Column, Integer, String, Float, ForeignKey
from app.db.database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    email = Column(String, unique=True)
    password = Column(String)
    phone = Column(String)
    relative_phone_1 = Column(String)
    relative_phone_2 = Column(String)
    fcm_token = Column(String)


class Device(Base):
    __tablename__ = "devices"

    id = Column(Integer, primary_key=True)
    code = Column(String, unique=True, index=True)
    name = Column(String)
    status = Column(String)
    last_update = Column(Float)


class UserDevice(Base):
    __tablename__ = "user_devices"

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    device_id = Column(Integer, ForeignKey("devices.id"), index=True)


class FallEvent(Base):
    __tablename__ = "fall_events"

    id = Column(Integer, primary_key=True)
    time = Column(String)
    total_a = Column(Float)
    device_code = Column(String, index=True)
