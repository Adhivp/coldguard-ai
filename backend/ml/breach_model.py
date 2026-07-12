"""
Breach Predictor — MLP
Input : (batch, 10, 3)  →  [temperature_c_norm, humidity_pct_norm, gap_norm]
Output: (batch, 1)      →  breach_probability 0.0–1.0

A score > 0.75 means the temperature trend in the last 10 seconds suggests
the product will exceed its safe range AND surpass max_minutes_above_limit
within the next 60 seconds.
"""

import tensorflow as tf
from tensorflow import keras


def build_breach_model(input_steps: int = 10, n_features: int = 3) -> keras.Model:
    inputs = keras.Input(shape=(input_steps, n_features), name="recent_readings")

    x = keras.layers.Flatten()(inputs)
    x = keras.layers.Dense(32, activation="relu")(x)
    x = keras.layers.Dense(16, activation="relu")(x)
    x = keras.layers.Dense(8, activation="relu")(x)
    x = keras.layers.Dropout(0.2)(x)
    output = keras.layers.Dense(1, activation="sigmoid", name="breach_probability")(x)

    model = keras.Model(inputs, output, name="breach_predictor")
    model.compile(
        optimizer=keras.optimizers.Adam(1e-3),
        loss="binary_crossentropy",
        metrics=["accuracy", keras.metrics.AUC(name="auc")],
    )
    return model
