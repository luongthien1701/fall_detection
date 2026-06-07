import joblib
import pandas as pd

model = joblib.load("model/fall_model.pkl")


def _align_features(X: pd.DataFrame):
    # Đảm bảo cột realtime đúng thứ tự cột lúc train
    if hasattr(model, "feature_names_in_"):
        X = X.reindex(columns=model.feature_names_in_, fill_value=0)
    return X


def predict(X):
    X = _align_features(X)
    return int(model.predict(X)[0])


def predict_with_proba(X, threshold=0.7):
    """
    threshold càng cao thì càng khó báo té ngã.
    0.75: nhạy
    0.80: vừa
    0.85: khó hơn
    0.90: rất khó báo
    """

    X = _align_features(X)

    proba = model.predict_proba(X)[0]

    # Lấy xác suất của class 1 = fall
    fall_index = list(model.classes_).index(1)
    fall_prob = float(proba[fall_index])

    pred = 1 if fall_prob >= threshold else 0

    return pred, fall_prob