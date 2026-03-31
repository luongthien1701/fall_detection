from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.database import SessionLocal
from app.db.model import User
from app.services.auth_service import hash_password, verify_password

router = APIRouter()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.post("/register")
def register(username: str, email: str, password: str, fcm_token: str, db: Session = Depends(get_db)):
    user = User(
        username=username,
        email=email,
        password=hash_password(password),
        fcm_token=fcm_token
    )
    db.add(user)
    db.commit()
    return {"msg": "ok"}

@router.post("/login")
def login(username: str, password: str, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.username == username).first()

    if not user or not verify_password(password, user.password):
        return {"msg": "fail"}

    return {"msg": "ok"}