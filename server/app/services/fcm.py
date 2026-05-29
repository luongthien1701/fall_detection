from pathlib import Path

import requests
from google.oauth2 import service_account
from google.auth.transport.requests import Request
from app.config import SERVICE_ACCOUNT_FILE, PROJECT_ID

# ===== CONFIG =====
FCM_URL = f"https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send"
SCOPES = ["https://www.googleapis.com/auth/firebase.messaging"]
credentials = None


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

def send_fcm(user_token, body_text):
    try:
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
                "android": {
                    "priority": "HIGH"
                },
                "apns": {
                    "headers": {
                        "apns-priority": "10"
                    }
                }
            }
        }

        res = requests.post(FCM_URL, headers=headers, json=payload)

        print("FCM:", res.status_code, res.text)

    except Exception as e:
        print("FCM error:", e)
