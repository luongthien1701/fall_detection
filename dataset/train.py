from pathlib import Path

import joblib
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.ensemble import (      
    GradientBoostingClassifier,
    RandomForestClassifier,
)

from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    classification_report,
    confusion_matrix,
    ConfusionMatrixDisplay,
    log_loss,
)

from sklearn.model_selection import train_test_split


RANDOM_STATE = 42
TEST_SIZE = 0.25
MIN_ROWS = 15

# Folder hiện tại
CURRENT_DIR = Path(__file__).resolve().parent

FALL_DIR = CURRENT_DIR / "split" / "fall"
NORMAL_DIR = CURRENT_DIR / "split" / "normal"

MODEL_FILE = CURRENT_DIR / "falldetact_model.pkl"
SERVER_MODEL_FILE = CURRENT_DIR / "fall_model.pkl"

FEATURE_FILE = CURRENT_DIR / "features.csv"
TRAIN_FEATURE_FILE = CURRENT_DIR / "train_features.csv"
TEST_FEATURE_FILE = CURRENT_DIR / "test_features.csv"

RESULT_FILE = CURRENT_DIR / "model_comparison.csv"

FALL_THRESHOLD = 0.85

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
    feat["accel_abs_mean"] = accel_abs.max(axis=1).mean()

    for col in AXIS_COLUMNS:
        feat[f"{col}_first"] = df[col].iloc[0]
        feat[f"{col}_last"] = df[col].iloc[-1]
        feat[f"{col}_delta"] = df[col].iloc[-1] - df[col].iloc[0]

    return feat


def build_feature_frame(directory, prefix, label):
    rows = []

    files = list_event_files(directory, prefix)

    print(f"\nReading {prefix} files from: {directory}")
    print(f"Found files: {len(files)}")

    for file_path in files:
        df = load_event(file_path)

        if len(df) < MIN_ROWS:
            continue

        feat = extract_features_from_event(df)
        feat["source_file"] = file_path.name
        feat["label"] = label

        rows.append(feat)

    return pd.DataFrame(rows)


def build_dataset_from_split():
    fall_df = build_feature_frame(FALL_DIR, "fall", 1)
    normal_df = build_feature_frame(NORMAL_DIR, "normal", 0)

    data_df = pd.concat([fall_df, normal_df], ignore_index=True)

    if data_df.empty:
        raise ValueError("No training data found in split/fall or split/normal.")

    return data_df


def save_feature_csv(data_df):
    export_df = data_df.copy()

    export_df["label_name"] = export_df["label"].map({
        0: "normal",
        1: "fall",
    })

    export_df.to_csv(FEATURE_FILE, index=False, encoding="utf-8-sig")

    print(f"\nFeature file saved: {FEATURE_FILE}")


def save_train_test_csv(X_train, X_test, y_train, y_test):
    train_df = X_train.copy()
    train_df["label"] = y_train.values
    train_df["label_name"] = train_df["label"].map({
        0: "normal",
        1: "fall",
    })

    test_df = X_test.copy()
    test_df["label"] = y_test.values
    test_df["label_name"] = test_df["label"].map({
        0: "normal",
        1: "fall",
    })

    train_df.to_csv(TRAIN_FEATURE_FILE, index=False, encoding="utf-8-sig")
    test_df.to_csv(TEST_FEATURE_FILE, index=False, encoding="utf-8-sig")

    print(f"Train feature file saved: {TRAIN_FEATURE_FILE}")
    print(f"Test feature file saved: {TEST_FEATURE_FILE}")


def create_models():
    models = {
        "Random Forest": RandomForestClassifier(
    n_estimators=1000,
    max_depth=10,
    min_samples_leaf=5,
    min_samples_split=10,
    max_features="sqrt",
    class_weight={0: 1, 1: 0.7},
    bootstrap=True,
    oob_score=True,
    n_jobs=-1,
    random_state=RANDOM_STATE,
),
       "Gradient Boosting": GradientBoostingClassifier(
    n_estimators=200,
    learning_rate=0.01,
    max_depth=3,
    min_samples_leaf=5,
    min_samples_split=10,
    subsample=0.8,
    random_state=RANDOM_STATE,
)
    }

    return models


def predict_with_threshold(model, X_test, threshold=0.5):
    if hasattr(model, "predict_proba"):
        proba = model.predict_proba(X_test)
        fall_proba = proba[:, 1]
        pred = (fall_proba >= threshold).astype(int)
        return pred, proba

    pred = model.predict(X_test)
    return pred, None


def save_confusion_matrix(name, y_test, pred):
    cm = confusion_matrix(y_test, pred)

    disp = ConfusionMatrixDisplay(
        confusion_matrix=cm,
        display_labels=["normal", "fall"],
    )

    fig, ax = plt.subplots(figsize=(6, 5))
    disp.plot(ax=ax, values_format="d")

    plt.title(f"Confusion Matrix - {name}")
    plt.tight_layout()

    file_name = f"confusion_matrix_{name.replace(' ', '_').lower()}.png"
    cm_file = CURRENT_DIR / file_name

    plt.savefig(cm_file, dpi=300)
    plt.close()

    return cm_file


def evaluate_model(name, model, X_train, X_test, y_train, y_test):
    print("\n" + "=" * 60)
    print(name)

    model.fit(X_train, y_train)

    pred, proba = predict_with_threshold(
        model,
        X_test,
        threshold=FALL_THRESHOLD,
    )

    acc = accuracy_score(y_test, pred)

    precision_fall = precision_score(
        y_test,
        pred,
        pos_label=1,
        zero_division=0,
    )

    recall_fall = recall_score(
        y_test,
        pred,
        pos_label=1,
        zero_division=0,
    )

    f1_fall = f1_score(
        y_test,
        pred,
        pos_label=1,
        zero_division=0,
    )

    cm = confusion_matrix(y_test, pred)
    tn, fp, fn, tp = cm.ravel()

    loss_value = None

    if proba is not None:
        loss_value = log_loss(y_test, proba, labels=[0, 1])

    print(f"Accuracy       : {acc:.4f}")
    print(f"Precision fall : {precision_fall:.4f}")
    print(f"Recall fall    : {recall_fall:.4f}")
    print(f"F1 fall        : {f1_fall:.4f}")

    if loss_value is not None:
        print(f"Log Loss       : {loss_value:.4f}")

    print("\nConfusion Matrix:")
    print(cm)

    print("\nConfusion Matrix Explain:")
    print(f"Normal đoán đúng: {tn}")
    print(f"Normal bị báo nhầm thành fall: {fp}")
    print(f"Fall bị bỏ sót, đoán thành normal: {fn}")
    print(f"Fall đoán đúng: {tp}")

    print("\nClassification Report:")
    print(classification_report(
        y_test,
        pred,
        target_names=["normal", "fall"],
        zero_division=0,
    ))

    cm_file = save_confusion_matrix(name, y_test, pred)

    model_file = CURRENT_DIR / f"{name.replace(' ', '_').lower()}_model.pkl"
    joblib.dump(model, model_file)

    return {
        "model": name,
        "accuracy": acc,
        "precision_fall": precision_fall,
        "recall_fall": recall_fall,
        "f1_fall": f1_fall,
        "log_loss": loss_value,
        "tn_normal_correct": tn,
        "fp_normal_as_fall": fp,
        "fn_fall_missed": fn,
        "tp_fall_correct": tp,
        "model_file": str(model_file),
        "confusion_matrix_file": str(cm_file),
    }


def plot_compare_chart(results_df):
    metrics = [
        "accuracy",
        "precision_fall",
        "recall_fall",
        "f1_fall",
    ]

    for metric in metrics:
        plt.figure(figsize=(9, 5))
        plt.bar(results_df["model"], results_df[metric])
        plt.ylim(0, 1.05)
        plt.title(f"Compare {metric}")
        plt.xlabel("Model")
        plt.ylabel(metric)
        plt.xticks(rotation=20)
        plt.tight_layout()

        chart_file = CURRENT_DIR / f"compare_{metric}.png"
        plt.savefig(chart_file, dpi=300)
        plt.close()

        print(f"Chart saved: {chart_file}")


def train_deploy_model(best_model_name, best_model, final_feature_df, final_label_series):
    print("\nTraining deploy model with all data...")
    print(f"Best model: {best_model_name}")

    best_model.fit(final_feature_df, final_label_series)

    joblib.dump(best_model, MODEL_FILE)
    joblib.dump(best_model, SERVER_MODEL_FILE)

    print("\nDeploy model saved:")
    print(f"Model saved: {MODEL_FILE}")
    print(f"Server model saved: {SERVER_MODEL_FILE}")


def main():
    data_df = build_dataset_from_split()

    print("\nDataset:")
    print(data_df["label"].value_counts().rename({
        0: "normal",
        1: "fall",
    }))
    print(f"Total samples: {len(data_df)}")

    save_feature_csv(data_df)

    feature_df = data_df.drop(
        columns=["label", "source_file"],
        errors="ignore",
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
    print(f"Test samples : {len(X_test)}")

    save_train_test_csv(X_train, X_test, y_train, y_test)

    models = create_models()

    results = []

    for name, model in models.items():
        result = evaluate_model(
            name,
            model,
            X_train,
            X_test,
            y_train,
            y_test,
        )

        results.append(result)

    results_df = pd.DataFrame(results)
    results_df.to_csv(RESULT_FILE, index=False, encoding="utf-8-sig")

    print("\n" + "=" * 60)
    print("MODEL COMPARISON")

    print(results_df[
        [
            "model",
            "accuracy",
            "precision_fall",
            "recall_fall",
            "f1_fall",
            "fp_normal_as_fall",
            "fn_fall_missed",
        ]
    ])

    print(f"\nComparison file saved: {RESULT_FILE}")

    plot_compare_chart(results_df)

    best_row = results_df.sort_values(
        by=["f1_fall", "recall_fall", "accuracy"],
        ascending=False,
    ).iloc[0]

    best_model_name = best_row["model"]
    best_model = models[best_model_name]

    print("\nBest model:")
    print(best_model_name)

    final_feature_df = data_df.drop(
        columns=["label", "source_file"],
        errors="ignore",
    ).fillna(0)

    final_label_series = data_df["label"]

    train_deploy_model(
        best_model_name,
        best_model,
        final_feature_df,
        final_label_series,
    )

    print("\nOutput files:")
    print(f"Feature CSV: {FEATURE_FILE}")
    print(f"Train Feature CSV: {TRAIN_FEATURE_FILE}")
    print(f"Test Feature CSV: {TEST_FEATURE_FILE}")
    print(f"Comparison CSV: {RESULT_FILE}")
    print(f"Deploy Model: {MODEL_FILE}")


if __name__ == "__main__":
    main()