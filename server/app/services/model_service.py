import joblib

model = joblib.load("model/fall_model.pkl")

def predict(X):
    return model.predict(X)[0]