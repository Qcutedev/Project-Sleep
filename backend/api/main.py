from pathlib import Path

import joblib
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware

from api.schemas import SleepPredictionRequest, SleepPredictionResponse


MODEL_PATH = Path(__file__).resolve().parents[1] / "model" / "sleep_quality_model.pkl"

if not MODEL_PATH.is_file():
    raise FileNotFoundError(f"Model file not found: {MODEL_PATH}")

model = joblib.load(MODEL_PATH)

app = FastAPI(title="SleepWise AI API", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


def _quality_label(score: float) -> str:
    if score >= 8:
        return "Good"
    if score >= 5:
        return "Fair"
    return "Poor"


def _factors(request: SleepPredictionRequest) -> list[str]:
    factors: list[str] = []
    if request.sleep_duration < 6.5:
        factors.append("Short sleep duration")
    if request.stress_level >= 7:
        factors.append("High stress level")
    if request.physical_activity < 20:
        factors.append("Low physical activity")
    return factors or ["No major risk factors found"]


def _recommendation(quality: str) -> str:
    if quality == "Good":
        return "Keep up your current routine — consistency is what helps most."
    if quality == "Fair":
        return "Try winding down screens 30 minutes before bed to help you fall asleep faster."
    return "Consider an earlier, more consistent bedtime and a short walk during the day."


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.post("/predict", response_model=SleepPredictionResponse)
def predict(request: SleepPredictionRequest) -> SleepPredictionResponse:
    features = pd.DataFrame(
        [
            {
                "Age": request.age,
                "Gender": request.gender,
                "Physical Activity Level": request.physical_activity,
                "Sleep Duration": request.sleep_duration,
                "Stress Level": request.stress_level,
            }
        ]
    )

    try:
        raw_score = float(model.predict(features)[0])
    except Exception as exc:
        raise HTTPException(status_code=500, detail="Model prediction failed") from exc

    model_score = max(4.0, min(9.0, raw_score))
    score = round(((model_score - 4.0) / 5.0) * 99.0 + 1.0)
    quality = _quality_label(model_score)
    return SleepPredictionResponse(
        sleep_quality=quality,
        score=score,
        factors=_factors(request),
        recommendation=_recommendation(quality),
    )