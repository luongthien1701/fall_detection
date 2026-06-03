from pathlib import Path

import joblib
import pandas as pd
import matplotlib.pyplot as plt

from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score,
    classification_report,
    confusion_matrix,
    ConfusionMatrixDisplay,
    log_loss,
)
from sklearn.model_selection import train_test_split


RANDOM_STATE = 42
TEST_SIZE = 0.3
MIN_ROWS = 15

PROJECT_ROOT = Path(__file__).resolve().parents[1]

FALL_DIR = PROJECT_ROOT / "dataset" / "split" / "fall"
NORMAL_DIR = PROJECT_ROOT / "dataset" / "split" / "normal"

MODEL_FILE = PROJECT_ROOT / "dataset" / "falldetact_model.pkl"
SERVER_MODEL_FILE = PROJECT_ROOT / "server" / "model" / "fall_model.pkl"

OUTPUT_DIR = PROJECT_ROOT / "dataset" / "train_outputs"

FEATURE_FILE = OUTPUT_DIR / "features.csv"
TRAIN_FEATURE_FILE = OUTPUT_DIR / "train_features.csv"
TEST_FEATURE_FILE = OUTPUT_DIR / "test_features.csv"

METRICS_FILE = OUTPUT_DIR / "metrics_summary.csv"
REPORT_FILE = OUTPUT_DIR / "classification_report.csv"

ACCURACY_CHART_FILE = OUTPUT_DIR / "accuracy_chart.png"
LOSS_CHART_FILE = OUTPUT_DIR / "loss_chart.png"
CONFUSION_MATRIX_FILE = OUTPUT_DIR / "confusion_matrix.png"

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

    for file_path in list_event_files(directory, prefix):
        df = load_event(file_path)

        if len(df) < MIN_ROWS:
            continue

        feat = extract_features_from_event(df)
        feat["source_file"] = str(file_path)
        feat["label"] = label
        rows.append(feat)

    return pd.DataFrame(rows)


def create_model(n_estimators=2000):
    return RandomForestClassifier(
        n_estimators=n_estimators,
        max_depth=15,
        min_samples_leaf=5,
        class_weight={0: 1, 1: 2.2},
        random_state=RANDOM_STATE,
    )


def save_feature_csv(data_df):
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    export_df = data_df.copy()
    export_df["label_name"] = export_df["label"].map({0: "normal", 1: "fall"})

    export_df.to_csv(FEATURE_FILE, index=False, encoding="utf-8-sig")

    print(f"\nFeature file saved: {FEATURE_FILE}")


def save_train_test_csv(X_train, X_test, y_train, y_test):
    train_df = X_train.copy()
    train_df["label"] = y_train.values
    train_df["label_name"] = train_df["label"].map({0: "normal", 1: "fall"})

    test_df = X_test.copy()
    test_df["label"] = y_test.values
    test_df["label_name"] = test_df["label"].map({0: "normal", 1: "fall"})

    train_df.to_csv(TRAIN_FEATURE_FILE, index=False, encoding="utf-8-sig")
    test_df.to_csv(TEST_FEATURE_FILE, index=False, encoding="utf-8-sig")

    print(f"Train feature file saved: {TRAIN_FEATURE_FILE}")
    print(f"Test feature file saved: {TEST_FEATURE_FILE}")


def train_with_history(X_train, y_train, X_test, y_test):
    """
    RandomForest không có epoch và loss như neural network.
    Vì vậy ta train nhiều lần với số cây tăng dần để lấy accuracy/loss theo n_estimators.
    """

    tree_steps = [50, 100, 200, 500, 1000, 1500, 2000]

    history = []

    for n_tree in tree_steps:
        model = create_model(n_estimators=n_tree)
        model.fit(X_train, y_train)

        train_pred = model.predict(X_train)
        test_pred = model.predict(X_test)

        train_proba = model.predict_proba(X_train)
        test_proba = model.predict_proba(X_test)

        train_acc = accuracy_score(y_train, train_pred)
        test_acc = accuracy_score(y_test, test_pred)

        train_loss = log_loss(y_train, train_proba, labels=[0, 1])
        test_loss = log_loss(y_test, test_proba, labels=[0, 1])

        history.append({
            "n_estimators": n_tree,
            "train_accuracy": train_acc,
            "test_accuracy": test_acc,
            "train_loss": train_loss,
            "test_loss": test_loss,
        })

        print(
            f"Trees: {n_tree:4d} | "
            f"Train Acc: {train_acc:.4f} | Test Acc: {test_acc:.4f} | "
            f"Train Loss: {train_loss:.4f} | Test Loss: {test_loss:.4f}"
        )

    history_df = pd.DataFrame(history)
    history_df.to_csv(METRICS_FILE, index=False, encoding="utf-8-sig")

    return history_df


def plot_accuracy(history_df):
    plt.figure(figsize=(8, 5))

    plt.plot(
        history_df["n_estimators"],
        history_df["train_accuracy"],
        marker="o",
        label="Train Accuracy",
    )

    plt.plot(
        history_df["n_estimators"],
        history_df["test_accuracy"],
        marker="o",
        label="Test Accuracy",
    )

    plt.title("Accuracy theo số lượng cây Random Forest")
    plt.xlabel("Số lượng cây")
    plt.ylabel("Accuracy")
    plt.ylim(0, 1.05)
    plt.grid(True)
    plt.legend()
    plt.tight_layout()

    plt.savefig(ACCURACY_CHART_FILE, dpi=300)
    plt.close()

    print(f"Accuracy chart saved: {ACCURACY_CHART_FILE}")


def plot_loss(history_df):
    plt.figure(figsize=(8, 5))

    plt.plot(
        history_df["n_estimators"],
        history_df["train_loss"],
        marker="o",
        label="Train Loss",
    )

    plt.plot(
        history_df["n_estimators"],
        history_df["test_loss"],
        marker="o",
        label="Test Loss",
    )

    plt.title("Log Loss theo số lượng cây Random Forest")
    plt.xlabel("Số lượng cây")
    plt.ylabel("Log Loss")
    plt.grid(True)
    plt.legend()
    plt.tight_layout()

    plt.savefig(LOSS_CHART_FILE, dpi=300)
    plt.close()

    print(f"Loss chart saved: {LOSS_CHART_FILE}")


def plot_confusion_matrix(y_test, pred):
    cm = confusion_matrix(y_test, pred)

    disp = ConfusionMatrixDisplay(
        confusion_matrix=cm,
        display_labels=["normal", "fall"],
    )

    fig, ax = plt.subplots(figsize=(6, 5))
    disp.plot(ax=ax, values_format="d")

    plt.title("Confusion Matrix")
    plt.tight_layout()
    plt.savefig(CONFUSION_MATRIX_FILE, dpi=300)
    plt.close()

    print(f"Confusion matrix image saved: {CONFUSION_MATRIX_FILE}")


def save_classification_report(y_test, pred):
    report_dict = classification_report(
        y_test,
        pred,
        target_names=["normal", "fall"],
        output_dict=True,
    )

    report_df = pd.DataFrame(report_dict).transpose()
    report_df.to_csv(REPORT_FILE, encoding="utf-8-sig")

    print(f"Classification report saved: {REPORT_FILE}")


def evaluate_model(y_test, pred):
    acc = accuracy_score(y_test, pred)
    cm = confusion_matrix(y_test, pred)

    print("\nAccuracy:", acc)

    print("\nConfusion Matrix:")
    print(cm)

    tn, fp, fn, tp = cm.ravel()

    print("\nConfusion Matrix Explain:")
    print(f"Normal đoán đúng: {tn}")
    print(f"Normal bị báo nhầm thành fall: {fp}")
    print(f"Fall bị bỏ sót, đoán thành normal: {fn}")
    print(f"Fall đoán đúng: {tp}")

    print("\nClassification Report:")
    print(
        classification_report(
            y_test,
            pred,
            target_names=["normal", "fall"],
        )
    )


def main():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    fall_df = build_feature_frame(FALL_DIR, "fall", 1)
    normal_df = build_feature_frame(NORMAL_DIR, "normal", 0)

    data_df = pd.concat([fall_df, normal_df], ignore_index=True)

    if data_df.empty:
        raise ValueError("No training data found in dataset/split.")

    print("\nDataset:")
    print(data_df["label"].value_counts().rename({0: "normal", 1: "fall"}))
    print(f"Total samples: {len(data_df)}")

    # 1. Xuất feature ra file CSV trước khi train
    save_feature_csv(data_df)

    feature_df = data_df.drop(
        columns=["label", "source_file"]
    ).fillna(0)

    label_series = data_df["label"]

    X_train, X_test, y_train, y_test = train_test_split(
        feature_df,
        label_series,
        test_size=TEST_SIZE,
        random_state=RANDOM_STATE,
        stratify=label_series,
    )

    print("\nTrain/Test:")
    print(f"Train samples: {len(X_train)}")
    print(f"Test samples: {len(X_test)}")

    # 2. Xuất train/test feature
    save_train_test_csv(X_train, X_test, y_train, y_test)

    # 3. Train nhiều lần để lấy history accuracy/loss
    print("\nTraining history for chart...")
    history_df = train_with_history(X_train, y_train, X_test, y_test)

    # 4. Vẽ accuracy và loss
    plot_accuracy(history_df)
    plot_loss(history_df)

    # 5. Train model chính
    print("\nTraining final evaluation model...")

    model = create_model(n_estimators=2000)
    model.fit(X_train, y_train)

    fall_threshold = 0.4

    proba = model.predict_proba(X_test)
    fall_proba = proba[:, 1]

    pred = (fall_proba >= fall_threshold).astype(int)

    print("\nEvaluation Result:")
    evaluate_model(y_test, pred)

    # 6. Lưu classification report và confusion matrix
    save_classification_report(y_test, pred)
    plot_confusion_matrix(y_test, pred)

    # 7. Train lại bằng toàn bộ dataset để deploy
    print("\nTraining deploy model with all data...")

    final_feature_df = data_df.drop(
        columns=["label", "source_file"]
    ).fillna(0)

    final_label_series = data_df["label"]

    final_model = create_model(n_estimators=2000)
    final_model.fit(final_feature_df, final_label_series)

    MODEL_FILE.parent.mkdir(parents=True, exist_ok=True)
    SERVER_MODEL_FILE.parent.mkdir(parents=True, exist_ok=True)

    joblib.dump(final_model, MODEL_FILE)
    joblib.dump(final_model, SERVER_MODEL_FILE)

    print("\nModel saved:")
    print(f"Model saved: {MODEL_FILE}")
    print(f"Server model saved: {SERVER_MODEL_FILE}")

    print("\nOutput files:")
    print(f"Feature CSV: {FEATURE_FILE}")
    print(f"Train Feature CSV: {TRAIN_FEATURE_FILE}")
    print(f"Test Feature CSV: {TEST_FEATURE_FILE}")
    print(f"Metrics CSV: {METRICS_FILE}")
    print(f"Classification Report CSV: {REPORT_FILE}")
    print(f"Accuracy Chart: {ACCURACY_CHART_FILE}")
    print(f"Loss Chart: {LOSS_CHART_FILE}")
    print(f"Confusion Matrix: {CONFUSION_MATRIX_FILE}")


if __name__ == "__main__":
    main()