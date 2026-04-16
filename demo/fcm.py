import requests
from google.oauth2 import service_account
from google.auth.transport.requests import Request

# ====== CONFIG ======
SERVICE_ACCOUNT_FILE = "service-account.json"
PROJECT_ID = "device-streaming-79c92ab1"
FCM_URL = f"https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send"

DEVICE_TOKEN = "eKIws_keQa2FbF_JFWBSTF:APA91bGRUYtLg9ZRu8wAxKvyO--dIn_FwbE9n04eb5g4evMImcL1ae6OjmurdR5oiUY1P8L26vDWE-v_fM0TvuftAzxXwieQajbRGBD25IDED2bCTR6kZww"

# ====== GET ACCESS TOKEN ======
SCOPES = ["https://www.googleapis.com/auth/firebase.messaging"]

credentials = service_account.Credentials.from_service_account_file(
    SERVICE_ACCOUNT_FILE, scopes=SCOPES
)

credentials.refresh(Request())
access_token = credentials.token

# ====== DATA ======
headers = {
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json"
}
body = {
    "message": {
        "token": DEVICE_TOKEN,

        "notification": {  # 👉 để hệ thống tự hiển thị (background)
            "title": "Test nhanh",
            "body": "Thông báo về ngay lập tức 🚀"
        },

        "data": {  # 👉 để Flutter xử lý foreground
            "type": "alert",
            "screen": "alert"
        },

        "android": {
            "priority": "HIGH",
            "notification": {
                "channel_id": "high_importance_channel"  # 🔥 QUAN TRỌNG
            }
        },

        "apns": {
            "headers": {
                "apns-priority": "10"
            }
        }
    }
}

# ====== SEND ======
response = requests.post(FCM_URL, headers=headers, json=body)

print(response.status_code)
print(response.text)