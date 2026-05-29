from pathlib import Path

import joblib


def _find_model_path():
    root_dir = Path(__file__).resolve().parents[3]
    server_dir = Path(__file__).resolve().parents[2]
    candidates = [
        server_dir / "model" / "fall_model.pkl",
        root_dir / "fall_model.pkl",
        root_dir / "falldetact_model.pkl",
    ]

    for path in candidates:
        if path.exists():
            return path

    raise FileNotFoundError(
        "Could not find fall model. Expected one of: "
        + ", ".join(str(path) for path in candidates)
    )


model = joblib.load(_find_model_path())

def predict(X):
    return model.predict(X)[0]
