from pathlib import Path

import requests
from google.oauth2 import service_account
from google.auth.transport.requests import Request
from app.config import SERVICE_ACCOUNT_FILE, PROJECT_ID

# ===== CONFIG =====
FCM_URL = f"https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send"
SCOPES = ["https://www.googleapis.com/auth/firebase.messaging"]
credentials = None


def _mask_token(token):
    if not token:
        return "<empty>"
    if len(token) <= 16:
        return f"{token[:4]}...{token[-4:]}"
    return f"{token[:12]}...{token[-8:]}"


def _find_service_account_file():
    root_dir = Path(__file__).resolve().parents[3]
    server_dir = Path(__file__).resolve().parents[2]
    candidates = [
        Path(SERVICE_ACCOUNT_FILE),
        server_dir / SERVICE_ACCOUNT_FILE,
        root_dir / SERVICE_ACCOUNT_FILE,
    ]

    for path in candidates:
        if path.exists():
            return path

    raise FileNotFoundError(
        "Could not find Firebase service account file. Expected one of: "
        + ", ".join(str(path) for path in candidates)
    )


def _get_credentials():
    global credentials
    if credentials is None:
        credentials = service_account.Credentials.from_service_account_file(
            _find_service_account_file(),
            scopes=SCOPES,
        )
    return credentials

def send_fcm(user_token, body_text, device_code=None):
    try:
        if not user_token:
            print("FCM skipped: empty user token")
            return False

        # refresh token
        creds = _get_credentials()
        creds.refresh(Request())
        access_token = creds.token

        headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }

        payload = {
            "message": {
                "token": user_token,
                "notification": {
                    "title": "Alert",
                    "body": body_text
                },
                "data": {
                    "type": "fall_alert",
                    "route": "/hazardous",
                    "device_code": device_code or "",
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                },
                "android": {
                    "priority": "HIGH",
                    "notification": {
                        "click_action": "FLUTTER_NOTIFICATION_CLICK",
                    },
                },
                "apns": {
                    "headers": {
                        "apns-priority": "10"
                    }
                }
            }
        }

        res = requests.post(FCM_URL, headers=headers, json=payload)
        ok = 200 <= res.status_code < 300

        print(
            "FCM:",
            res.status_code,
            res.text,
            "token=",
            _mask_token(user_token),
            "device_code=",
            device_code,
        )
        return ok

    except Exception as e:
        print("FCM error:", e)
        return False
