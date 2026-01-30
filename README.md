# Mobile Calendar (Offline-First Architecture)

A cross-platform event management system featuring an **Offline-First** architecture and cloud synchronization. This project is a college MVP+ designed to demonstrate data persistence patterns and synchronization between a Flutter frontend and a FastAPI/MongoDB backend.

### Key Features:
* **Offline-First Architecture**: Designed with local persistence in mind to ensure functionality without an active internet connection.
* **Cloud Synchronization**: Bidirectional sync logic using `updated_at` and `is_deleted` (soft-delete) flags to maintain data consistency.
* **Cross-Platform**: Primarily developed and tested in **Flutter Web** for rapid iteration, while maintaining a codebase compatible with mobile environments.
* **User Authentication**: Secure JWT-based auth system for data ownership.
* **Progress Tracking**: Basic gamification elements including completion-based progress bars and efficiency metrics.

---

## Tech Stack

### Frontend
* **Framework:** [Flutter](https://flutter.dev/) (Web & Mobile)
* **State Management:** [Riverpod](https://riverpod.dev/) (Reactive state management)
* **Local Persistence:** Architecture prepared for SQLite integration (In-memory/Web-storage for MVP)
* **Network:** [Dio](https://pub.dev/packages/dio) (REST API client)

### Backend
* **Framework:** [FastAPI](https://fastapi.tiangolo.com/) (Asynchronous Python API)
* **Database:** [MongoDB](https://www.mongodb.com/) (Document-based storage with `motor` driver)
* **Auth:** [Python-jose](https://python-jose.readthedocs.io/) (JWT) and [Passlib](https://passlib.readthedocs.io/) (Bcrypt)
* **Containerization:** Docker & Docker Compose

---

## Installation & Setup

### 1. Clone the repository
```bash
git clone [https://github.com/Allcode-1/mobile-calendar](https://github.com/Allcode-1/mobile-calendar)
cd mobile-calendar
```

2. Backend Setup (Docker - Recommended)

The easiest way to run the backend and database is via Docker Compose:

```bash
docker-compose up --build
```

The API will be available at http://localhost:8000. Swagger docs: http://localhost:8000/docs.

3. Frontend Setup

Make sure you have Flutter installed.

```bash
# Get dependencies
flutter pub get

# Run on Web (Primary Development & Testing environment)
flutter run -d chrome
```

Architecture Disclaimer & MVP Scope

    Project Status: This is a college MVP+ project, not production-ready software.

    Data Persistence: Local SQLite integration is in the "bridge/preparation" stage; the current version focuses on state-to-cloud synchronization.

    Sync Strategy: Uses a Last Write Wins (LWW) strategy for conflict resolution via updated_at timestamps.

    Database Choice: MongoDB was selected for the backend to handle flexible event schemas and rapid prototyping of the sync layer.

    Security: Simplified JWT handling for demonstration purposes.