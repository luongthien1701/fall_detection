from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import sessionmaker, declarative_base

DATABASE_URL = "sqlite:///./app.db"

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False}
)

SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()


def ensure_schema():
    inspector = inspect(engine)

    migrations = {
        "fall_events": {
            "device_code": "ALTER TABLE fall_events ADD COLUMN device_code VARCHAR",
        },
        "devices": {
            "name": "ALTER TABLE devices ADD COLUMN name VARCHAR",
            "status": "ALTER TABLE devices ADD COLUMN status VARCHAR",
            "last_update": "ALTER TABLE devices ADD COLUMN last_update FLOAT",
        },
        "users": {
            "app_phone": "ALTER TABLE users ADD COLUMN app_phone VARCHAR",
            "relative_phone_1": "ALTER TABLE users ADD COLUMN relative_phone_1 VARCHAR",
            "relative_phone_2": "ALTER TABLE users ADD COLUMN relative_phone_2 VARCHAR",
        },
    }

    with engine.begin() as conn:
        for table, columns in migrations.items():
            if not inspector.has_table(table):
                continue

            existing_columns = {
                column["name"] for column in inspector.get_columns(table)
            }
            for column, statement in columns.items():
                if column not in existing_columns:
                    conn.execute(text(statement))

        if inspector.has_table("users"):
            existing_user_columns = {
                column["name"] for column in inspector.get_columns("users")
            }
            existing_user_columns.update(migrations["users"].keys())
            if {"app_phone", "phone"}.issubset(existing_user_columns):
                conn.execute(text("""
                    UPDATE users
                    SET app_phone = phone
                    WHERE (app_phone IS NULL OR app_phone = '')
                      AND phone IS NOT NULL
                      AND phone != ''
                """))

        users_has_legacy_device_code = False
        if inspector.has_table("users"):
            users_has_legacy_device_code = any(
                column["name"] == "device_code"
                for column in inspector.get_columns("users")
            )

        if (
            users_has_legacy_device_code
            and inspector.has_table("users")
            and inspector.has_table("devices")
        ):
            conn.execute(text("""
                INSERT OR IGNORE INTO devices (code, name, status)
                SELECT DISTINCT device_code, 'Thiết bị ' || device_code, 'offline'
                FROM users
                WHERE device_code IS NOT NULL AND device_code != ''
            """))

        if (
            users_has_legacy_device_code
            and inspector.has_table("users")
            and inspector.has_table("devices")
            and inspector.has_table("user_devices")
        ):
            conn.execute(text("""
                INSERT INTO user_devices (user_id, device_id)
                SELECT users.id, devices.id
                FROM users
                JOIN devices ON devices.code = users.device_code
                WHERE users.device_code IS NOT NULL
                  AND users.device_code != ''
                  AND NOT EXISTS (
                      SELECT 1
                      FROM user_devices
                      WHERE user_devices.user_id = users.id
                        AND user_devices.device_id = devices.id
                  )
            """))
