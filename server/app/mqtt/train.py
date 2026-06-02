from pathlib import Path

import joblib
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.model_selection import train_test_split


RANDOM_STATE = 42
TEST_SIZE = 0.25
MIN_ROWS = 15

FALL_DIR = Path("dataset/split/fall")
NORMAL_DIR = Path("dataset/split/normal")

MODEL_FILE = Path(__file__).resolve().parent / "falldetact_model.pkl"
SERVER_MODEL_FILE = Path(__file__).resolve().parent / "fall_model.pkl"

COLUMNS = [
    "time",
    "AccelX",
    "AccelY",
    "AccelZ",
    "GyroX",
    "GyroY",
    "GyroZ",
    "Total_A",
]

SENSOR_COLUMNS = COLUMNS[1:]
AXIS_COLUMNS = ["AccelX", "AccelY", "AccelZ", "GyroX", "GyroY", "GyroZ"]


def load_event(file_path):
    df = pd.read_csv(file_path)
    df = df[COLUMNS]
    df = df.dropna(subset=COLUMNS).reset_index(drop=True)
    return df


def list_event_files(directory, prefix):
    files = []

    for file_path in sorted(directory.glob(f"{prefix}_*.csv")):
        suffix = file_path.stem.removeprefix(f"{prefix}_")

        if suffix.isdigit():
            files.append(file_path)

    return files


def extract_features_from_event(df):
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

    return feat


def build_feature_frame(directory, prefix, label):
    rows = []
    skipped = 0

    for file_path in list_event_files(directory, prefix):
        df = load_event(file_path)

        if len(df) < MIN_ROWS:
            skipped += 1
            continue

        feat = extract_features_from_event(df)
        feat["source_file"] = str(file_path)
        feat["label"] = label
        rows.append(feat)

    result = pd.DataFrame(rows)
    print(
        f"{directory}: files={len(list_event_files(directory, prefix))}, "
        f"used={len(result)}, skipped_short={skipped}"
    )
    return result


fall_df = build_feature_frame(FALL_DIR, "fall", 1)
normal_df = build_feature_frame(NORMAL_DIR, "normal", 0)

data_df = pd.concat([fall_df, normal_df], ignore_index=True)

if data_df.empty:
    raise ValueError("No training data found. Run demo/split_recordings.py first.")

feature_df = data_df.drop(columns=["label", "source_file"])
feature_df = feature_df.fillna(0)
label_series = data_df["label"]

X_train, X_test, y_train, y_test = train_test_split(
    feature_df,
    label_series,
    test_size=TEST_SIZE,
    random_state=RANDOM_STATE,
    stratify=label_series,
)

print("\nDataset:")
print(label_series.value_counts().rename({0: "normal", 1: "fall"}))
print(f"Train samples: {len(X_train)}")
print(f"Test samples: {len(X_test)}")

model = RandomForestClassifier(
    n_estimators=600,
    max_depth=15,
    min_samples_leaf=2,
    class_weight="balanced",
    random_state=RANDOM_STATE,
)

model.fit(X_train, y_train)

pred = model.predict(X_test)

print("\nAccuracy:", accuracy_score(y_test, pred))

print("\nConfusion Matrix:")
print(confusion_matrix(y_test, pred))

print("\nClassification Report:")
print(classification_report(y_test, pred))

joblib.dump(model, MODEL_FILE)
joblib.dump(model, SERVER_MODEL_FILE)
print(f"\nModel saved: {MODEL_FILE}")
print(f"Server model saved: {SERVER_MODEL_FILE}")
