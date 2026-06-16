import pandas as pd

COLUMNS = [
    "time", "AccelX", "AccelY", "AccelZ",
    "GyroX", "GyroY", "GyroZ", "Total_A"
]

SENSOR_COLUMNS = COLUMNS[1:]
AXIS_COLUMNS = ["AccelX", "AccelY", "AccelZ", "GyroX", "GyroY", "GyroZ"]


def extract_features(df):
    df = df[COLUMNS].copy()
    df = df.dropna(subset=COLUMNS).reset_index(drop=True)

    feat = {
        "rows": len(df),
        "duration": df["time"].iloc[-1] - df["time"].iloc[0],
    }

    for col in SENSOR_COLUMNS:
        feat[f"{col}_mean"] = df[col].mean()
        feat[f"{col}_std"] = df[col].std()
        feat[f"{col}_max"] = df[col].max()
        feat[f"{col}_min"] = df[col].min()
        feat[f"{col}_range"] = df[col].max() - df[col].min()
        feat[f"{col}_median"] = df[col].median()

    gyro_abs = df[["GyroX", "GyroY", "GyroZ"]].abs()
    accel_abs = df[["AccelX", "AccelY", "AccelZ"]].abs()

    feat["A_peak"] = df["Total_A"].max()
    feat["A_mean"] = df["Total_A"].mean()
    feat["A_std"] = df["Total_A"].std()
    feat["A_range"] = df["Total_A"].max() - df["Total_A"].min()
    feat["A_min"] = df["Total_A"].min()
    feat["A_peak_index_ratio"] = df["Total_A"].idxmax() / max(len(df) - 1, 1)

    feat["gyro_abs_peak"] = gyro_abs.max(axis=1).max()
    feat["gyro_abs_mean"] = gyro_abs.max(axis=1).mean()
    feat["accel_abs_peak"] = accel_abs.max(axis=1).max()

    for col in AXIS_COLUMNS:
        feat[f"{col}_first"] = df[col].iloc[0]
        feat[f"{col}_last"] = df[col].iloc[-1]
        feat[f"{col}_delta"] = df[col].iloc[-1] - df[col].iloc[0]

    return pd.DataFrame([feat]).fillna(0)