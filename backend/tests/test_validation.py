from fastapi.testclient import TestClient

from api.main import app

client = TestClient(app)

VALID = {
    "sleep_duration": 7,
    "stress_level": 5,
    "physical_activity": 30,
    "age": 25,
    "gender": "Male",
}


def test_accepts_the_two_values_the_model_knows():
    for gender in ("Male", "Female"):
        response = client.post("/predict", json={**VALID, "gender": gender})
        assert response.status_code == 200, gender


def test_rejects_any_other_gender_value():
    for gender in ("male", "Other", "ชาย", "", "   "):
        response = client.post("/predict", json={**VALID, "gender": gender})
        assert response.status_code == 422, gender
