# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**DNGO** is an online marketplace system with 4 independent sub-projects, all sharing a single remote PostgreSQL database and Firebase project:

| Directory | Role | Stack |
|-----------|------|-------|
| `DNGO-fastapi/` | Backend API | Python FastAPI + PostgreSQL (SQLAlchemy) |
| `Done-demo/` | Buyer & Seller app | Flutter (BLoC/Cubit + GetIt + Dio) |
| `dngo_shipper_app/` | Shipper app | Flutter (BLoC + `http` package) |
| `market-app/` | Market admin app (web) | Flutter (Clean Architecture + BLoC) |
| `LLM-master/` | AI Chatbot / RAG service | Python FastAPI + FAISS + Ollama |

---

## Commands

### Backend (`DNGO-fastapi/`)
```bash
cd DNGO-fastapi
python -m venv venv && venv\Scripts\activate  # Windows
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
# Swagger UI: http://localhost:8000/docs
```
Requires a `.env` file with `DATABASE_URL`, `JWT_SECRET`, `JWT_ALGORITHM`, `ACCESS_TOKEN_EXPIRE_MINUTES`, `REFRESH_TOKEN_EXPIRE_DAYS`, `VNP_*` (VNPAY), `CORS_ORIGINS`, `PORT`, `DEBUG`, `GRAPH_HOPPER_API_KEY`, `FIREBASE_*` fields, and a Firebase service account JSON file.

### Flutter apps (Done-demo / dngo_shipper_app / market-app)
```bash
cd <app-dir>
flutter clean && flutter pub get
flutter run                          # device / emulator
flutter run -d chrome --web-browser-flag "--disable-web-security"  # web (CORS bypass for testing)
```
`market-app` is built primarily for web. When running on a physical device, change `baseUrl` in `lib/core/services/api_service.dart` from `207.180.233.84` to the LAN IP of the machine running the backend.

### LLM / Chatbot service (`LLM-master/`)
```bash
cd LLM-master
python -m venv venv && venv\Scripts\activate
pip install -r requirements.txt
python main.py     # or: start.bat
```
Requires Ollama running locally with the Qwen2.5 model pulled. The FAISS index is built on startup from `rag_menu_final.csv`.

---

## Architecture

### Backend (`DNGO-fastapi/app/`)

- **Entry point:** `main.py` — registers all routers, CORS, a request-logging middleware, a startup lifespan that initialises Firebase and APScheduler.
- **Routers** (`routers/`): one file per domain — `auth`, `buyer`, `seller`, `shipper`, `cart`, `order`, `payment`, `market_management`, `wallet`, `chat`, `chat_ws`, `review`, `search`, `upload`.
- **Layers:** `routers/` → `repositories/` → `models/models.py` (SQLAlchemy ORM). Business logic sits in `repositories/` and thin `services/` (payment, cart, auto-confirm).
- **Auth:** JWT tokens; `Authorization: Bearer <token>` header. Refresh tokens are stored in the DB.
- **Real-time:** `chat_ws.py` exposes a WebSocket endpoint at `/api/chat/ws`. Firebase Realtime Database is used for shipper GPS tracking.
- **Scheduled jobs:** APScheduler auto-creates monthly stall fees (`utils/scheduler.py`).

### Done-demo Flutter app (`Done-demo/lib/`)

Feature-driven structure under `lib/feature/`:
```
feature/
  buyer/       — cart, home, ingredient, menu, order, payment, product, search, shop, shops, ...
  seller/      — ingredient, main, order, revenue, user
  admin/       — home, map, market, seller, user
  chat/        — chat hub + chat room screens
  login/  signup/  splash/  user/  wallet/
```
Each feature follows `presentation/screen/` + `presentation/cubit/` (BLoC pattern with Cubit). State management uses `flutter_bloc`. DI is managed with `GetIt`; all services are registered in `lib/core/dependency/injection.dart`.

- **HTTP client:** `lib/core/services/api_service.dart` uses **Dio** with a `NetworkInterceptor` that attaches JWT tokens and handles 401 refresh.
- **Config:** All base URLs are in `lib/core/config/app_config.dart` and can be overridden via `--dart-define=BASE_URL=...` at build time.
- **Routing:** `lib/core/router/app_router.dart` uses `Navigator` with named routes defined in `lib/core/config/route_name.dart`.
- **WebSocket chat:** `lib/core/services/chat_socket_service.dart` manages the buyer↔seller chat using `web_socket_channel`.

### Shipper app (`dngo_shipper_app/lib/`)

Simpler than Done-demo; uses the `http` package (no Dio). All API calls are static methods on `lib/core/services/api_service.dart`. BLoC is used for state. Firebase Realtime Database is used for live GPS location updates from the shipper to the buyer.

### Market Admin app (`market-app/lib/`)

Follows Clean Architecture: `data/` → `domain/` → `presentation/`. Uses `go_router` for routing and `get_it` for DI (configured in `injection_container.dart`). Targets web; uses `flutter_map` to render the market stall map.

### LLM / Chatbot (`LLM-master/`)

Two chatbot flows:
1. **Meal suggestion → ingredient selection → stall lookup** (main RAG flow using FAISS + Qwen2.5 via Ollama).
2. **Direct stall query** — user asks what a stall sells.

Key modules: `data_loader.py` (loads CSV data), `vector_store.py` (builds FAISS index), `llama_service.py` (Ollama integration), `intent_detector.py`, `query_understanding.py`. The production LLM endpoint is a Cloudflare Worker proxy (`https://llm-dngo.thaophuongbui2211.workers.dev`).

---

## Key Business Rules

- **Order cutoff:** Orders are not accepted after 19:00 (closes the daily batch).
- **Minimum delivery lead time:** The earliest selectable delivery slot must be at least 1 hour after the order time.
- **Shipper pickup constraint:** A shipper cannot mark an order as "delivering" (`dang_giao`) until every ingredient item from every stall has been confirmed as picked up (`da_lay_hang`). This is enforced in the app, not just the API.
- **Batching:** A single shipper trip can bundle items from multiple orders and multiple stalls simultaneously.

## Vietnamese Status Strings (Backend Enum Values)

These string literals are used as-is in API payloads and must match exactly:

| Context | String | Meaning |
|---------|--------|---------|
| Stall status | `mo_cua` | Open |
| Stall status | `dong_cua` | Closed |
| Order item status | `da_lay_hang` | Picked up from stall |
| Order status | `dang_giao` | Out for delivery |
| Order status | `da_giao` | Delivered |
| Order status | `cho_xac_nhan` | Awaiting confirmation |

## API Endpoints Reference

- Production backend: `http://207.180.233.84:8000/api`
- Images/uploads: `http://207.180.233.84:8000/uploads/<filename>`
- Chat WebSocket: `ws://207.180.233.84:8000/api/chat/ws`
- LLM Chatbot (prod): `https://llm-dngo.thaophuongbui2211.workers.dev/chat`

Role-scoped URL prefixes: `/api/auth/`, `/api/buyer/`, `/api/seller/`, `/api/quan-ly-cho/`, `/api/shipper/`.

## UI Brand Guidelines

- Primary colour: `#00B40F` (green). Also accepted: `#4CAF50`.
- Use `Card` widgets with rounded corners and light `BoxShadow` (Glassmorphism/Clean UI style).
- Vietnamese is used throughout UI labels, API field names, and status strings.