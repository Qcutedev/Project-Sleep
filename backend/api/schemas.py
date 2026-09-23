from pydantic import BaseModel, Field, field_validator


class SleepPredictionRequest(BaseModel):
    sleep_duration: float = Field(..., ge=0, le=24)
    stress_level: int = Field(..., ge=1, le=10)
    physical_activity: int = Field(..., ge=0, le=1440)
    age: int = Field(..., ge=1, le=120)
    gender: str = Field(..., min_length=1, max_length=32)

    @field_validator("gender")
    @classmethod
    def normalize_gender(cls, value: str) -> str:
        normalized = value.strip()
        if not normalized:
            raise ValueError("gender must not be blank")
        return normalized


class SleepPredictionResponse(BaseModel):
    sleep_quality: str
    score: int = Field(..., ge=1, le=100)
    factors: list[str]
    recommendation: str
