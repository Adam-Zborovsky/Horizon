# Horizon — AI-Driven Market Intelligence Platform

Horizon transforms global news, geopolitical events, and financial data into actionable market intelligence. Multi-agent AI workflows analyze cross-domain signals, surface alpha opportunities, and deliver personalized daily briefings — eliminating information overload for tactical traders and strategic investors.

![Flutter](https://img.shields.io/badge/Flutter-3.11-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart)
![Node.js](https://img.shields.io/badge/Node.js-18-339933?logo=node.js)
![Express](https://img.shields.io/badge/Express-5.2-000000?logo=express)
![MongoDB](https://img.shields.io/badge/MongoDB-8-47A248?logo=mongodb)
![Docker](https://img.shields.io/badge/Docker-✓-2496ED?logo=docker)

<!-- TODO: screenshot -->

---

## Highlights

- **Multi-agent briefing pipeline** — Specialized AI agents (Strategic News Intel, Market Analyst, Opportunity Scout) run via n8n workflows and produce structured JSON briefings cross-referenced against real-time Yahoo Finance data to flag hallucinated tickers and overwrite stale prices.
- **Hallucination guard** — The backend validates every AI-generated briefing: if a ticker mentioned in a response doesn't appear in any user's watchlist, the system rejects the payload (HTTP 422), logs a warning, and automatically re-triggers the workflow.
- **Dual-target Flutter app** — Single codebase compiles to a mobile app (Android/iOS) with a dark glassmorphism UI and a Wear OS companion with rotary-scroll navigation, watchlist tiles, and adaptive text sizing.
- **Background polling with push notifications** — A `DataPollingService` (Riverpod, `keepAlive: true`) polls the `/briefing/status` endpoint every 2 minutes; when a new briefing timestamp is detected, the app fires a local notification and auto-invalidates the briefing provider for zero-tap UI refresh.
- **Sentiment normalization pipeline** — Free-text sentiment labels ("very bullish", "bearish", "neutral") from heterogeneous AI outputs are parsed into numeric scores (-1 to +1), enabling consistent sparkline overlays, sorting, and opportunity ranking.
- **Synthetic history generation** — When real historical price data is unavailable, the backend generates 15-point trendlines from current price, change%, and sentiment score, with weekend-aware propagation to the Flutter chart layer.
- **User-controlled intelligence feed** — Each user configures topic subscriptions (e.g., "Geopolitical Defense & AI Strategy") and ticker watchlists; the backend filters briefings server-side and surfaces only enabled categories.
- **Opportunity streak tracking** — The `/opportunity-stats/:ticker` endpoint computes 30-day appearance counts and consecutive trading-day streaks for any ticker across a user's briefing history.

---

## Architecture

```
┌────────────────────────────────────────────┐
│                 n8n (external)              │
│  ┌─────────┐  ┌──────────┐  ┌───────────┐  │
│  │News Intel│  │ Market   │  │Opportunity│  │
│  │  Agent   │  │ Analyst  │  │  Scout    │  │
│  └────┬─────┘  └────┬─────┘  └─────┬─────┘  │
│       └──────────────┼──────────────┘        │
│                      │ POST /webhook          │
└──────────────────────┼───────────────────────┘
                       │
┌──────────────────────▼───────────────────────┐
│              Express Backend (:8181)          │
│                                               │
│  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │   Auth   │  │ Briefing │  │  Scheduler  │  │
│  │  (JWT)   │  │  Service │  │ (node-cron) │  │
│  └────┬─────┘  └────┬─────┘  └──────┬─────┘  │
│       │              │               │        │
│       └──────────────┼───────────────┘        │
│                      │                        │
│              ┌───────▼───────┐                │
│              │   MongoDB 8   │                │
│              │ (Users,       │                │
│              │  Briefings,   │                │
│              │  Configs)     │                │
│              └───────────────┘                │
└──────────────────────┬───────────────────────┘
                       │ REST /api/v1/*
                       │
┌──────────────────────▼───────────────────────┐
│           Flutter Frontend (Nginx:80)         │
│                                               │
│  ┌──────┐ ┌───────┐ ┌──────┐ ┌──────────┐   │
│  │ Dash │ │ Vault │ │Nexus │ │ Scanner  │   │
│  └──────┘ └───────┘ └──────┘ └──────────┘   │
│                                               │
│  Riverpod + GoRouter + Freezed + FL Chart     │
│  Wear OS companion (rotary scroll, tiles)     │
└───────────────────────────────────────────────┘
```

**Data lifecycle**: `n8n agents` → POST `/webhook` → `BriefingService.save()` validates tickers against user config, cross-references Yahoo Finance for real prices, strips hallucinated tickers, stores in MongoDB → Frontend polls `/api/v1/briefing/status` → detects new timestamp → invalidates Riverpod provider → UI re-renders with fresh data.

---

## Tech Stack

| Layer                | Technology                       | Version                |
| -------------------- | -------------------------------- | ---------------------- |
| **Mobile app**       | Flutter (Dart)                   | SDK ≥3.11.0            |
| **State management** | Riverpod                         | 3.2.1                  |
| **Routing**          | GoRouter                         | 17.1.0                 |
| **Data classes**     | Freezed + json_serializable      | 3.2.5 / 6.13.0         |
| **Charts**           | FL Chart                         | 1.1.1                  |
| **Fonts**            | Google Fonts (Inter, Montserrat) | 8.0.2                  |
| **Wear OS**          | wearable_rotary                  | 2.0.4                  |
| **Notifications**    | flutter_local_notifications      | 18.0.1                 |
| **API server**       | Express.js (Node.js 18)          | 5.2.1                  |
| **Database**         | MongoDB via Mongoose             | 9.2.1                  |
| **Auth**             | JWT (jsonwebtoken) + bcryptjs    | 9.0.3 / 3.0.3          |
| **Validation**       | Zod                              | 4.3.6                  |
| **Scheduling**       | node-cron                        | 4.2.1                  |
| **Security**         | Helmet + CORS + Morgan           | 8.1.0 / 2.8.6 / 1.10.1 |
| **Automation**       | n8n (external)                   | —                      |
| **Web server**       | Nginx (Alpine)                   | latest                 |
| **Containerization** | Docker Compose                   | —                      |

---

## Project Structure

```
Horizon/
├── docker-compose.yml            # Full-stack orchestration
├── .env.example                  # Environment variable template
├── backend/
│   ├── Dockerfile                # Node:18-alpine, port 8181
│   ├── package.json
│   ├── scripts/
│   │   └── wipe-db.js            # Database purge utility
│   └── src/
│       ├── server.js             # Entry point (DB connect + scheduler start)
│       ├── app.js                # Express app (middleware + routes)
│       ├── config/
│       │   ├── env.js            # Zod-validated env parsing
│       │   └── db.js             # Mongoose connection
│       ├── middleware/
│       │   ├── auth.middleware.js # JWT Bearer token verification
│       │   └── error.middleware.js
│       ├── features/
│       │   ├── auth/
│       │   │   ├── auth.controller.js
│       │   │   ├── auth.service.js  # Register, login, token generation
│       │   │   ├── auth.routes.js
│       │   │   └── user.model.js    # Mongoose schema, bcrypt pre-save hook
│       │   └── briefing/
│       │       ├── briefing.controller.js
│       │       ├── briefing.service.js  # Core logic: save, filter, validate
│       │       ├── briefing.routes.js
│       │       ├── briefing.model.js    # Mixed-schema for flexible AI output
│       │       ├── briefing_config.model.js
│       │       └── webhook.routes.js
│       └── utils/
│           ├── scheduler.js       # Daily cron @ 06:00, staggered triggers
│           └── market.js          # Yahoo Finance API fetch
└── frontend/
    ├── Dockerfile                 # 2-stage: Flutter build → Nginx:alpine serve
    ├── nginx.conf                 # API proxy to horizon-backend:8181
    ├── pubspec.yaml               # Flutter dependencies
    ├── assets/
    │   ├── branding/app_icon.png
    │   ├── example_output.json
    │   └── daily_briefing.json
    └── lib/
        ├── main.dart              # Mobile entry (Riverpod + GoRouter + polling)
        ├── main_wear.dart         # Wear OS entry
        └── src/
            ├── core/
            │   ├── api/api_config.dart
            │   ├── theme/app_theme.dart
            │   ├── widgets/       # GlassCard, SectionHeader
            │   └── services/      # NotificationService, DataPollingService
            ├── features/
            │   ├── auth/          # Login, register, JWT persistence
            │   ├── briefing/      # Briefing model, repository, config
            │   ├── dashboard/     # War Room home screen
            │   ├── vault/         # Intelligence Vault (categorized archive)
            │   ├── nexus/         # Market Nexus (watchlist + charts)
            │   ├── scanner/       # Opportunity scanner
            │   ├── stock/         # Stock data aggregation, detail screen
            │   ├── notifications/
            │   ├── onboarding/    # Tutorial coach marks
            │   └── profile/
            └── wear/              # Wear OS screens + glass card + rotary scroll
```

---

## Getting Started

### Prerequisites

- **Docker** and **Docker Compose** (recommended) — or —
- **Node.js 18+**, **Flutter SDK ≥3.11**, **MongoDB 8**

### Option 1: Docker (full stack)

```bash
git clone https://github.com/Adam-Zborovsky/Horizon.git
cd Horizon
cp .env.example .env
# Edit .env with your MongoDB URI and JWT_SECRET
docker compose up -d
```

The frontend will be available at `http://localhost`.

### Option 2: Local Development

**Backend:**

```bash
cd backend
cp ../.env.example .env
# Edit .env: set MONGODB_URI, JWT_SECRET, N8N_WEBHOOK_URL
npm install
node src/server.js
# → Running on :8181
```

**Frontend (mobile):**

```bash
cd frontend
flutter pub get
flutter run --flavor mobile
# Set HORIZON_API_HOST for non-web targets:
# flutter run --dart-define=HORIZON_API_HOST=https://your-server.com
```

**Wear OS:**

```bash
cd frontend
flutter run -t lib/main_wear.dart
```

### Database Wipe (development)

```bash
cd backend
npm run wipe-db
```

---

## Configuration Reference

### Environment Variables

| Variable          | Default       | Required | Description                                                            |
| ----------------- | ------------- | -------- | ---------------------------------------------------------------------- |
| `PORT`            | `8181`        | No       | Backend listen port                                                    |
| `NODE_ENV`        | `development` | No       | `development` / `production` / `test`                                  |
| `MONGODB_URI`     | —             | **Yes**  | MongoDB connection string (e.g., `mongodb://horizon-db:27017/horizon`) |
| `API_PREFIX`      | `/api/v1`     | No       | API route prefix                                                       |
| `JWT_SECRET`      | —             | **Yes**  | Secret key for signing JWTs                                            |
| `JWT_EXPIRES_IN`  | `30d`         | No       | JWT token expiration                                                   |
| `N8N_WEBHOOK_URL` | —             | No       | n8n webhook URL for briefing trigger                                   |

### Flutter Build Arguments

| Argument           | Default                | Description                   |
| ------------------ | ---------------------- | ----------------------------- |
| `HORIZON_API_HOST` | `http://10.0.2.2:8181` | Backend URL for mobile builds |

---

## API Reference

All endpoints are prefixed with `/api/v1` unless noted.

### Auth

| Method | Path                    | Auth   | Description                            |
| ------ | ----------------------- | ------ | -------------------------------------- |
| `POST` | `/api/v1/auth/register` | No     | Register user (`username`, `password`) |
| `POST` | `/api/v1/auth/login`    | No     | Login, returns JWT                     |
| `GET`  | `/api/v1/auth/me`       | Bearer | Get current user                       |

### Briefing

| Method   | Path                                         | Auth   | Description                                      |
| -------- | -------------------------------------------- | ------ | ------------------------------------------------ |
| `GET`    | `/api/v1/briefing`                           | Bearer | Get latest briefing (filtered by enabled topics) |
| `GET`    | `/api/v1/briefing/status`                    | Bearer | Lightweight timestamp-only check for polling     |
| `GET`    | `/api/v1/briefing/history`                   | Bearer | Paginated briefing history (`?page=&limit=`)     |
| `GET`    | `/api/v1/briefing/config`                    | Bearer | Get user's topic/ticker configuration            |
| `PUT`    | `/api/v1/briefing/config`                    | Bearer | Update full configuration                        |
| `PUT`    | `/api/v1/briefing/config/topic/:topicName`   | Bearer | Toggle topic enabled/disabled                    |
| `DELETE` | `/api/v1/briefing/config/topic/:topicName`   | Bearer | Remove topic                                     |
| `GET`    | `/api/v1/briefing/config/recommended`        | Bearer | Get recommended topics                           |
| `GET`    | `/api/v1/briefing/search`                    | Bearer | Ticker autocomplete (`?q=AAPL`)                  |
| `GET`    | `/api/v1/briefing/opportunity-stats/:ticker` | Bearer | 30-day appearance count + streak                 |
| `POST`   | `/api/v1/briefing/trigger`                   | Bearer | Manually trigger briefing generation             |
| `GET`    | `/api/v1/briefing/config/system`             | None   | Config lookup by `?userId=` (for n8n)            |
| `POST`   | `/api/v1/briefing`                           | None   | Save briefing from agents (webhook endpoint)     |

### System

| Method | Path       | Auth | Description                          |
| ------ | ---------- | ---- | ------------------------------------ |
| `GET`  | `/health`  | No   | Health check                         |
| `POST` | `/webhook` | No   | External webhook receiver (reserved) |

---

## Data Model

### User

| Field                    | Type     | Notes                                    |
| ------------------------ | -------- | ---------------------------------------- |
| `_id`                    | ObjectId | Auto                                     |
| `username`               | String   | Unique, lowercase, trimmed               |
| `password`               | String   | bcrypt-hashed (12 rounds), pre-save hook |
| `createdAt`, `updatedAt` | Date     | Mongoose timestamps                      |

### Briefing

| Field       | Type            | Notes                        |
| ----------- | --------------- | ---------------------------- |
| `_id`       | ObjectId        | Auto                         |
| `user`      | ObjectId → User | Required                     |
| `data`      | Mixed           | Freeform JSON from AI agents |
| `source`    | String          | `n8n` / `manual` / `agent`   |
| `createdAt` | Date            | Indexed (descending)         |

### BriefingConfig

| Field                    | Type              | Notes                             |
| ------------------------ | ----------------- | --------------------------------- |
| `_id`                    | ObjectId          | Auto                              |
| `user`                   | ObjectId → User   | Unique (one config per user)      |
| `topics`                 | [{name, enabled}] | Default: 5 built-in topic pillars |
| `tickers`                | [String]          | User's watchlist tickers          |
| `createdAt`, `updatedAt` | Date              | Mongoose timestamps               |

---

## Engineering Notes

- **Validation-first env loading** — `config/env.js` uses Zod to parse and validate all environment variables at startup. The server refuses to start if `MONGODB_URI` or `JWT_SECRET` are missing, preventing runtime surprises.
- **AI output resilience** — `BriefingService.save()` handles JSON with trailing commas (a common LLM artifact), double-encoded strings, markdown code fences, and arbitrary nesting depths — normalizing everything to a consistent structure before storage.
- **Staggered cron** — The daily scheduler triggers n8n workflows for all users at 06:00 but staggers them 15 minutes apart per user to avoid rate-limiting downstream services or overloading the n8n instance.
- **Client-side polling over WebSockets** — The app uses HTTP polling (`/briefing/status` every 2 minutes) rather than persistent WebSocket connections. This simplifies the backend (no socket management), works reliably through mobile network switches, and costs only ~11 bytes per poll for a timestamp comparison.
- **Freezed + Riverpod code generation** — All models use `freezed` for immutability and `riverpod_generator` for providers. The `build_runner` generates `.freezed.dart`, `.g.dart` files — these are checked into git so the project builds without running code generation.
- **Nginx reverse proxy** — The Flutter web build is served by Nginx, which proxies `/api/` and `/health` to the backend container. This eliminates CORS issues in production and keeps the architecture standard.
- **Wear OS as a first-class target** — The Wear companion is not an afterthought: it shares Riverpod providers with the mobile app, implements rotary input scrolling, and includes Wear-specific tile services (WatchlistTileService, AlphaTileService) written in Kotlin.

---

## Roadmap

- [ ] Real-time WebSocket push for briefing updates
- [ ] iOS production build and App Store deployment
- [ ] Admin dashboard for monitoring hallucination rates and agent performance
- [ ] Multi-language briefing support
- [ ] Backtesting module for opportunity scout signals
- [ ] Integration with additional market data providers (Alpha Vantage, Polygon)

---

## License

This project is licensed under the ISC License. See `backend/package.json` for details.
