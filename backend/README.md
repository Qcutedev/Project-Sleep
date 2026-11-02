# SleepWise API

FastAPI service for the Flutter app's sleep-quality prediction flow.

## Run locally

From the `backend` directory:

```bash
python -m pip install -r requirements.txt
uvicorn api.main:app --reload --host 0.0.0.0 --port 8000
```

The model file must be at `backend/model/sleep_quality_model.pkl`.

## Endpoints

`GET /health`

`POST /predict`

Example request:

```json
{
  "sleep_duration": 7,
  "stress_level": 5,
  "physical_activity": 30,
  "age": 25,
  "gender": "Male"
}
```

The response matches the Flutter client contract: `sleep_quality`, `score` (1-100), `factors`, and `recommendation`.

## Flutter connection

The Flutter app reads the URL from `SLEEP_API_BASE_URL` at build time (see `lib/services/api_config.dart`). Without it, the app uses `http://127.0.0.1:8000`, which does not work on a real phone:

```bash
flutter run --dart-define=SLEEP_API_BASE_URL=http://192.168.1.10:8000
```
