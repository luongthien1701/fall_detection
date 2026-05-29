from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def hash_password(password):
    return pwd_context.hash(password)

def verify_password(plain, hashed):
    if not plain or not hashed:
        return False

    if hashed.startswith(("$2a$", "$2b$", "$2y$")):
        return pwd_context.verify(plain, hashed)

    # Backward compatibility for users created before password hashing.
    return plain == hashed
