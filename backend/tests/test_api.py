from fastapi.testclient import TestClient

from api.main import _factors, _quality_label, _recommendation, app
from api.schemas import SleepPredictionRequest

client = TestClient(app)

VALID = {
    "sleep_duration": 7,
    "stress_level": 5,
    "physical_activity": 30,
    "age": 25,
    "gender": "Male",
}


def request_with(**changes) -> SleepPredictionRequest:
    return SleepPredictionRequest(**{**VALID, **changes})


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_predict_returns_the_contract_the_app_expects():
    response = client.post("/predict", json=VALID)
    assert response.status_code == 200
    body = response.json()
    assert set(body) == {"sleep_quality", "score", "factors", "recommendation"}
    assert body["sleep_quality"] in {"Good", "Fair", "Poor"}
    assert 1 <= body["score"] <= 100
    assert body["factors"]


def test_more_sleep_does_not_lower_the_score():
    short = client.post("/predict", json={**VALID, "sleep_duration": 4}).json()
    long = client.post("/predict", json={**VALID, "sleep_duration": 8}).json()
    assert long["score"] > short["score"]


def test_invalid_values_are_rejected():
    for change in (
        {"age": 0},
        {"stress_level": 11},
        {"sleep_duration": 25},
        {"physical_activity": -1},
        {"gender": "   "},
    ):
        response = client.post("/predict", json={**VALID, **change})
        assert response.status_code == 422, change


def test_quality_limits_match_the_app():
    # qualityForScore ใน lib/services/sleep_stats.dart ถอดมาจากเกณฑ์นี้ แก้ต้องแก้คู่กัน
    assert _quality_label(8.0) == "Good"
    assert _quality_label(7.99) == "Fair"
    assert _quality_label(5.0) == "Fair"
    assert _quality_label(4.99) == "Poor"


def test_factor_limits():
    assert _factors(request_with(sleep_duration=6.4)) == ["Short sleep duration"]
    assert _factors(request_with(stress_level=7)) == ["High stress level"]
    assert _factors(request_with(physical_activity=19)) == ["Low physical activity"]
    assert _factors(request_with()) == ["No major risk factors found"]
    assert len(_factors(request_with(sleep_duration=5, stress_level=9, physical_activity=0))) == 3


def test_factor_and_recommendation_text_is_translated_by_the_app():
    # แอปจับคู่ข้อความเหล่านี้แบบตรงตัวเพื่อแปลภาษาไทย ดูจุดที่ผูกกันใน docs/ARCHITECTURE.md
    assert _recommendation("Good").startswith("Keep up your current routine")
    assert _recommendation("Fair").startswith("Try winding down screens")
    assert _recommendation("Poor").startswith("Consider an earlier")
