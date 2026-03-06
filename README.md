# Mobile Calendar

Offline-first calendar app with Flutter client and FastAPI + MongoDB backend.

## Documentation
- Architecture: [ARCHITECTURE.md](ARCHITECTURE.md)
- Backend API docs (runtime): `http://localhost:8000/docs`

## Tech Stack
- Frontend: Flutter, Riverpod, Dio, sqflite
- Backend: FastAPI, Motor (MongoDB), Pydantic
- Infra: Docker, Docker Compose, GitHub Actions CI

## Repository Structure
```text
lib/                      Flutter application
server/                   FastAPI backend
test/                     Flutter tests
server/tests/             Backend tests
docker-compose.yml        Local orchestration (backend + MongoDB)
.github/workflows/ci.yml  CI pipeline
```

## Quick Start (Docker)
1. Copy env template and set secrets.
```bash
cp .env.example .env
```
PowerShell alternative:
```powershell
Copy-Item .env.example .env
```
2. Set a strong `SECRET_KEY` in `.env` (minimum 32 chars).
3. Start services.
```bash
docker compose up --build -d
```
4. Open API docs:
`http://localhost:8000/docs`

## Local Development
### Backend
```bash
cd server
py -3 -m pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### Flutter
```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

For Android emulator:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

## Quality Gates
### Backend
```bash
cd server
py -3 -m pytest -q
```

### Flutter
```bash
flutter analyze
flutter test
```

## GitHub Push Checklist
1. Ensure `.env` is not tracked.
2. Run quality gates locally.
3. Confirm `git status` only contains intended files.
4. Push to `main`/`master` or open PR (CI will run automatically).

## Notes
- Compose requires `SECRET_KEY`; startup fails intentionally if it is missing.
- Backend logs use `loguru`; Flutter logs use centralized `AppLogger`.
- Offline-first sync is implemented for events and categories with user-scoped local data.
