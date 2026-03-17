import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import joblib

WINDOW_SIZE = 25
STEP = 10

columns = [
"time","AccelX","AccelY","AccelZ",
"GyroX","GyroY","GyroZ","Total_A"
]


# ==============================
# đọc csv
# ==============================
def load_data(file):

    df = pd.read_csv(file)

    df = df[[
        "time",
        "AccelX",
        "AccelY",
        "AccelZ",
        "GyroX",
        "GyroY",
        "GyroZ",
        "Total_A"
    ]]

    return df


# ==============================
# sliding window
# ==============================
def create_segments(df):

    segments = []

    for i in range(0, len(df) - WINDOW_SIZE, STEP):

        seg = df.iloc[i:i+WINDOW_SIZE]

        if len(seg) == WINDOW_SIZE:
            segments.append(seg)

    return segments


# ==============================
# feature extraction
# ==============================
def extract_features(segments, label):

    features = []

    for seg in segments:

        feat = {}

        for col in columns[1:]:

            feat[col+"_mean"] = seg[col].mean()
            feat[col+"_std"] = seg[col].std()
            feat[col+"_max"] = seg[col].max()
            feat[col+"_min"] = seg[col].min()

            feat[col+"_range"] = seg[col].max() - seg[col].min()

        # feature quan trọng cho fall
        feat["A_peak"] = seg["Total_A"].max()
        feat["A_mean"] = seg["Total_A"].mean()
        feat["A_std"] = seg["Total_A"].std()
        feat["A_range"] = seg["Total_A"].max() - seg["Total_A"].min()
        feat["A_min"] = seg["Total_A"].min()

        feat["label"] = label

        features.append(feat)

    return pd.DataFrame(features)


# ==============================
# TRAIN DATA
# ==============================
fall_train = create_segments(load_data("fall_train.csv"))
normal_train = create_segments(load_data("normal_train.csv"))

print("Train fall segments:",len(fall_train))
print("Train normal segments:",len(normal_train))

fall_train_df = extract_features(fall_train,1)
normal_train_df = extract_features(normal_train,0)

train_df = pd.concat([fall_train_df,normal_train_df],ignore_index=True)

X_train = train_df.drop(columns=["label"])
y_train = train_df["label"]


# ==============================
# TEST DATA
# ==============================
fall_test = create_segments(load_data("fall_test.csv"))
normal_test = create_segments(load_data("normal_test.csv"))

print("Test fall segments:",len(fall_test))
print("Test normal segments:",len(normal_test))

fall_test_df = extract_features(fall_test,1)
normal_test_df = extract_features(normal_test,0)

test_df = pd.concat([fall_test_df,normal_test_df],ignore_index=True)

X_test = test_df.drop(columns=["label"])
y_test = test_df["label"]


# ==============================
# TRAIN MODEL
# ==============================
model = RandomForestClassifier(

    n_estimators=600,
    max_depth=15,
    min_samples_leaf=2,
    class_weight="balanced",
    random_state=42

)

model.fit(X_train,y_train)


# ==============================
# TEST MODEL
# ==============================
pred = model.predict(X_test)

print("\nAccuracy:",accuracy_score(y_test,pred))

print("\nConfusion Matrix:")
print(confusion_matrix(y_test,pred))

print("\nClassification Report:")
print(classification_report(y_test,pred))


# ==============================
# SAVE MODEL
# ==============================
joblib.dump(model,"fall_model.pkl")

print("\nModel saved: fall_model.pkl")