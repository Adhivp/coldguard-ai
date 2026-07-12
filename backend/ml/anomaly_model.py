"""
Anomaly Detector — 1D-CNN
Input : (batch, 60, 3)  →  [temperature_c_norm, humidity_pct_norm, gap_norm]
Output: (batch, 1)      →  anomaly_score 0.0–1.0

A score > 0.80 means the last 60 seconds of readings look anomalous given
what the model learned about this product's normal operating range.
"""

import tensorflow as tf
from tensorflow import keras


def build_anomaly_model(input_steps: int = 60, n_features: int = 3) -> keras.Model:
    inputs = keras.Input(shape=(input_steps, n_features), name="readings")

    x = keras.layers.Conv1D(32, kernel_size=5, activation="relu", padding="same")(inputs)
    x = keras.layers.Conv1D(16, kernel_size=3, activation="relu", padding="same")(x)
    x = keras.layers.GlobalMaxPooling1D()(x)
    x = keras.layers.Dense(16, activation="relu")(x)
    x = keras.layers.Dropout(0.2)(x)
    output = keras.layers.Dense(1, activation="sigmoid", name="anomaly_score")(x)

    model = keras.Model(inputs, output, name="anomaly_detector")
    model.compile(
        optimizer=keras.optimizers.Adam(1e-3),
        loss="binary_crossentropy",
        metrics=["accuracy", keras.metrics.AUC(name="auc")],
    )
    return model
