import bcrypt
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

def hash_password(password):
    return pwd_context.hash(password)

def verify_password(plain, hashed):
    if not plain or not hashed:
        return False

    if hashed.startswith(("$2a$", "$2b$", "$2y$")):
        try:
            return bcrypt.checkpw(plain.encode("utf-8"), hashed.encode("utf-8"))
        except ValueError:
            return False

    if hashed.startswith("$pbkdf2-sha256$"):
        return pwd_context.verify(plain, hashed)

    # Backward compatibility for users created before password hashing.
    return plain == hashed
