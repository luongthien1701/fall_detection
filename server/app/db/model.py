from sqlalchemy import Column, Integer, String, Float, ForeignKey
from app.db.database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    username = Column(String, unique=True)
    email = Column(String, unique=True)
    password = Column(String)
    fcm_token = Column(String)


class FallEvent(Base):
    __tablename__ = "fall_events"

    id = Column(Integer, primary_key=True)
    time = Column(String)
    total_a = Column(Float)