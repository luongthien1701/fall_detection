import pandas as pd
import joblib

model = joblib.load("fall_model.pkl")

df = pd.read_csv("test_data.csv", header=None)

df.columns = [
    "time",
    "AccelX",
    "AccelY",
    "AccelZ",
    "GyroX",
    "GyroY",
    "GyroZ",
    "Total_A"
]

df = df[df["time"] != 0]

features = {}

for col in ["AccelX","AccelY","AccelZ","GyroX","GyroY","GyroZ","Total_A"]:
    features[col+"_mean"] = df[col].mean()
    features[col+"_std"] = df[col].std()
    features[col+"_max"] = df[col].max()
    features[col+"_min"] = df[col].min()

X = pd.DataFrame([features])

result = model.predict(X)[0]

if result == 1:
    print("FALL")
else:
    print("NORMAL")