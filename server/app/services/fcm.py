import requests
from google.oauth2 import service_account
from google.auth.transport.requests import Request
from app.config import SERVICE_ACCOUNT_FILE, PROJECT_ID

# ===== CONFIG =====
FCM_URL = f"https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send"
SCOPES = ["https://www.googleapis.com/auth/firebase.messaging"]

# load credentials 1 lần
credentials = service_account.Credentials.from_service_account_file(
    SERVICE_ACCOUNT_FILE,
    scopes=SCOPES
)

def send_fcm(user_token, body_text):
    try:
        # refresh token
        credentials.refresh(Request())
        access_token = credentials.token

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