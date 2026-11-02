"""พิมพ์ข้อมูลของโมเดลที่ใช้ใน docs/MODEL_CARD.md รันจากโฟลเดอร์ backend:

    python scripts/inspect_model.py
"""

import itertools
import warnings
from pathlib import Path

import joblib
import numpy as np
import pandas as pd

warnings.filterwarnings("ignore")

MODEL_PATH = Path(__file__).resolve().parents[1] / "model" / "sleep_quality_model.pkl"
NUMERIC = ["Age", "Physical Activity Level", "Sleep Duration", "Stress Level"]

model = joblib.load(MODEL_PATH)
preprocessor = model.named_steps["preprocessor"]
forest = model.named_steps["model"]
scaler = preprocessor.named_transformers_["num"].named_steps["scaler"]


def score(duration, stress, activity, age, gender) -> int:
    """คำนวณคะแนน 1-100 ด้วยสูตรเดียวกับ backend/api/main.py"""
    row = {
        "Age": age,
        "Gender": gender,
        "Physical Activity Level": activity,
        "Sleep Duration": duration,
        "Stress Level": stress,
    }
    raw = float(model.predict(pd.DataFrame([row]))[0])
    return round((max(4.0, min(9.0, raw)) - 4.0) / 5.0 * 99.0 + 1.0)


print("model:", type(forest).__name__, forest.get_params()["n_estimators"], "trees")
print("training rows:", forest.estimators_[0].tree_.weighted_n_node_samples[0])
print("training means:", dict(zip(NUMERIC, scaler.mean_.round(2).tolist())))

print("\nfeature importance:")
names = preprocessor.get_feature_names_out()
for name, value in zip(names, forest.feature_importances_):
    print(f"  {name}: {value:.3f}")

print("\nsplit thresholds in original units:")
for index, name in enumerate(NUMERIC):
    values = np.concatenate(
        [t.tree_.threshold[t.tree_.feature == index] for t in forest.estimators_]
    )
    values = values * scaler.scale_[index] + scaler.mean_[index]
    print(f"  {name}: {values.min():.2f} to {values.max():.2f}")

print("\none value at a time, from 7 hrs, stress 5, 30 min, age 25, Male:")
sweeps = {
    "duration": ([0, 2, 3, 4, 5, 6, 6.5, 7, 8, 9, 10], lambda v: (v, 5, 30, 25, "Male")),
    "stress": (list(range(1, 11)), lambda v: (7, v, 30, 25, "Male")),
    "activity": ([0, 10, 20, 30, 45, 60, 90, 120], lambda v: (7, 5, v, 25, "Male")),
    "age": ([10, 18, 25, 30, 40, 50, 60, 70, 90], lambda v: (7, 5, 30, v, "Male")),
    "gender": (["Male", "Female"], lambda v: (7, 5, 30, 25, v)),
}
for label, (values, make) in sweeps.items():
    print(f"  {label}:", [(v, score(*make(v))) for v in values])

grid = list(
    itertools.product(
        [0, 3, 5, 6, 7, 8, 10],
        [1, 3, 5, 7, 10],
        [0, 20, 45, 90, 120],
        [15, 25, 40, 60, 80],
        ["Male", "Female"],
    )
)
scores = np.array([score(*row) for row in grid])
print(f"\ngrid of {len(grid)} inputs:")
print(f"  min {scores.min()}, max {scores.max()}, distinct {len(set(scores.tolist()))}")
print(f"  Good {(scores >= 80).mean():.1%}")
print(f"  Fair {((scores >= 21) & (scores < 80)).mean():.1%}")
print(f"  Poor {(scores < 21).mean():.1%}")
