from typing import Literal

from pydantic import BaseModel, Field


class SleepPredictionRequest(BaseModel):
    sleep_duration: float = Field(..., ge=0, le=24)
    stress_level: int = Field(..., ge=1, le=10)
    physical_activity: int = Field(..., ge=0, le=1440)
    age: int = Field(..., ge=1, le=120)
    # โมเดลรู้จักแค่สองค่านี้ ค่าอื่นจะถูก OneHotEncoder มองข้ามแล้วได้คะแนนโดยไม่มีข้อผิดพลาด
    gender: Literal["Male", "Female"]


class SleepPredictionResponse(BaseModel):
    sleep_quality: str
    score: int = Field(..., ge=1, le=100)
    factors: list[str]
    recommendation: str
