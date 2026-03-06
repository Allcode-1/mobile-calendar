# Architecture

## 1. System Overview
Mobile Calendar is split into two runtime parts:
- Flutter client (`lib/`) for UI, local persistence, and sync orchestration.
- FastAPI backend (`server/`) for auth, data ownership, sync conflict resolution, and API access.

Persistence layers:
- Client: SQLite (`sqflite`) for offline-first behavior.
- Server: MongoDB (user-scoped documents with logical IDs).

## 2. High-Level Data Flow
1. User authenticates (`/api/v1/auth/*`) and gets JWT.
2. Client stores token in `SharedPreferences`.
3. CRUD operations are written locally first (mobile) and synced to server.
4. Server applies Last-Write-Wins using `updated_at`.
5. Client merges server state back into local DB.

## 3. Backend Architecture (`server/`)
Main modules:
- `main.py`: app bootstrap, middleware wiring, router mount.
- `app/api/v1/endpoints/*`: HTTP handlers.
- `app/schemas/*`: request/response contracts and validation.
- `app/db/mongodb.py`: Mongo client lifecycle and indexes.
- `app/middleware/logging.py`: request logging and request ID headers.
- `app/middleware/rate_limit.py`: path/method based throttling.
- `app/core/logging.py`: unified `loguru` logging + stdlib intercept.
- `app/core/config.py`: env-driven settings.

API boundaries:
- `auth`: register/login/me
- `events`: CRUD + `/events/sync`
- `categories`: CRUD
- `stats`: summary endpoint

## 4. Flutter Architecture (`lib/`)
Layers:
- `presentation/`: screens and widgets.
- `logic/`: Riverpod notifiers/providers (state orchestration).
- `data/repositories/`: sync and API/local composition.
- `data/sources/`: `ApiClient` (Dio), `DatabaseService` (SQLite).
- `data/models/`: typed entities and serialization.
- `core/utils/`: app-wide logger and utilities.

State management:
- Riverpod `StateNotifier` for auth/events/categories.
- Provider observer logs provider updates and failures.

## 5. Offline-First Strategy
### Events
- Mobile writes to local SQLite.
- Sync endpoint sends all user-scoped local events.
- Server resolves by `updated_at`, returns canonical state.
- Client upserts merged result.

### Categories
- Mobile writes locally and queues pending operations.
- Queue is user-scoped (`pending_category_ops.user_id`).
- Sync flushes pending operations, then refreshes remote categories.

## 6. Data Ownership and Multi-User Safety
- Server queries are scoped by authenticated user.
- Local SQLite reads/writes are scoped by `user_id`.
- Logout clears current user local state to avoid cross-account leakage.

## 7. Security and Reliability
- JWT auth with configurable `SECRET_KEY` (required in compose).
- Rate limiting supports method + wildcard path patterns.
- CORS and runtime behavior configured from environment.
- Backend indexes reduce latency for user-scoped queries and sync.

## 8. Logging and Observability
- Backend: `loguru` with unified format and intercepted framework logs.
- Middleware adds `X-Request-ID` and `X-Process-Time`.
- Flutter: centralized `AppLogger`, global error hooks, provider observer logs.

## 9. CI
GitHub Actions workflow (`.github/workflows/ci.yml`) runs:
1. Backend tests (`pytest -q`).
2. Flutter static analysis.
3. Flutter tests.

## 10. Known Tradeoffs
- Client/server conflict resolution uses LWW; no CRDT/operational merge.
- Category sync currently relies on upsert refresh and queued operations.
- No full E2E environment test in CI yet (unit/integration focused).
