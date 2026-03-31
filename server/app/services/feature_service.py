import pandas as pd

columns = [
    "time","AccelX","AccelY","AccelZ",
    "GyroX","GyroY","GyroZ","Total_A"
]

def extract_features(df):
    feat = {}

    for col in columns[1:]:
        feat[col+"_mean"] = df[col].mean()
        feat[col+"_std"] = df[col].std()
        feat[col+"_max"] = df[col].max()
        feat[col+"_min"] = df[col].min()
        feat[col+"_range"] = df[col].max() - df[col].min()

    feat["A_peak"] = df["Total_A"].max()
    feat["A_mean"] = df["Total_A"].mean()
    feat["A_std"] = df["Total_A"].std()
    feat["A_range"] = df["Total_A"].max() - df["Total_A"].min()
    feat["A_min"] = df["Total_A"].min()

    return pd.DataFrame([feat])