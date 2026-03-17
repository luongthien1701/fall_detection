import pandas as pd
import joblib

WINDOW = 20
STEP = 5

columns = [
"time","AccelX","AccelY","AccelZ",
"GyroX","GyroY","GyroZ","Total_A"
]

model = joblib.load("fall_model.pkl")
def extract_features(seg):

    feat = {}

    for col in [
        "AccelX","AccelY","AccelZ",
        "GyroX","GyroY","GyroZ","Total_A"
    ]:

        feat[col+"_mean"] = seg[col].mean()
        feat[col+"_std"] = seg[col].std()
        feat[col+"_max"] = seg[col].max()
        feat[col+"_min"] = seg[col].min()
        feat[col+"_range"] = seg[col].max() - seg[col].min()

    # giống code train
    feat["A_peak"] = seg["Total_A"].max()
    feat["A_mean"] = seg["Total_A"].mean()
    feat["A_std"] = seg["Total_A"].std()
    feat["A_range"] = seg["Total_A"].max() - seg["Total_A"].min()
    feat["A_min"] = seg["Total_A"].min()

    return pd.DataFrame([feat])

df = pd.read_csv("test_data.csv", header=None)
df.columns = columns


for i in range(0, len(df) - WINDOW+1, STEP):

    seg = df.iloc[i:i+WINDOW]

    X = extract_features(seg)

    pred = model.predict(X)[0]

    if pred == 1:
        print("⚠️ FALL")
    else:
        print("NORMAL")