# 🎵 Multi-Instrument AI Music Tutor

A comprehensive, scalable AI-powered platform for learning and practicing **solos, chords, and lessons** across **multiple musical instruments** (guitar, piano, violin, drums, and more).

## 🎯 Project Vision

Build an intelligent music tutoring system that:
- ✅ Supports **multiple instruments** with specialized analysis
- ✅ Provides **real-time feedback** on practice sessions
- ✅ Evaluates **solos, chords, and lessons** with detailed metrics
- ✅ Tracks **progress** and generates personalized insights
- ✅ Scales from MVP to enterprise-level platform

---

## 📋 Table of Contents

- [Features](#-features)
- [Architecture](#-architecture)
- [Technology Stack](#-technology-stack)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Database Schema](#-database-schema)
- [API Endpoints](#-api-endpoints)
- [Implementation Roadmap](#-implementation-roadmap)
- [Sprint Backlog (Kanban)](#-sprint-backlog-kanban)
- [Contributing](#-contributing)

---

## ✨ Features

### Core Features
- 🎸 **Multi-Instrument Support**: Guitar, Piano, Violin, Drums, Wind Instruments, and more
- 🎼 **Three Practice Modes**:
  - **Lessons**: Structured learning paths with theory & techniques
  - **Solos**: Practice famous solos with AI evaluation
  - **Chords**: Master chord progressions and voicings

### Intelligent Evaluation
- 🎯 **Pitch Accuracy**: Frequency analysis with instrument-specific thresholds
- ⏱️ **Timing & Rhythm**: Precision timing and rhythm feel detection
- 🎭 **Technique Detection**: Bends, vibrato, slides, sustain, and more
- 🎨 **Expression Analysis**: Dynamics, phrasing, and musicality scoring
- 📊 **Consistency Tracking**: Improvement over multiple attempts

### User Experience
- 📈 **Progress Dashboard**: Track improvements over time
- 🏆 **Achievements & Milestones**: Gamification and motivation
- 📱 **Real-time Feedback**: Live pitch visualization and suggestions
- 💾 **Practice History**: Detailed session recordings and analysis
- 🔄 **Speed Control**: Practice at different tempos (50%, 75%, 100%)

---

## 🏗️ Architecture

### High-Level System Design

```
┌──────────────────────────────────────────────────────────┐
│                  Frontend (Web/Mobile)                    │
│  Instrument Selector | Library | Practice | Dashboard   │
└────────────────────────┬─────────────────────────────────┘
                         │
┌────────────────────────▼──────────────────────────────────┐
│              Backend API (Go + chi)                      │
│  Lessons | Solos | Chords | Audio Processing | Eval     │
└─┬────────────┬──────────────┬─────────────┬──────────────┬┘
  │            │              │             │              │
  │       Instrument-Specific Modules (Pluggable)         │
  │       - Guitar | Piano | Violin | Drums | Wind...     │
  │                                                        │
  └────────────┬──────────────────────────────────────────┘
               │
    ┌──────────▼──────────────────┐
    │  Core ML/Audio Engine       │
    │  - Pitch Detection          │
    │  - Note Recognition         │
    │  - Technique Analysis       │
    │  - Rhythm Detection         │
    └──────────┬──────────────────┘
               │
    ┌──────────▼──────────────────┐
    │  Data Layer (PostgreSQL)    │
    │  - Users & Instruments      │
    │  - Content & Practice Data  │
    │  - Performance Metrics      │
    └─────────────────────────────┘
```

---

## 🛠️ Technology Stack

| Layer | Technologies |
|-------|--------------|
| **Frontend** | Flutter (Web, iOS, Android), shared packages (`app_shared`, `network`, `shared_ui`) |
| **Backend** | Go 1.25, chi router, pgx |
| **Real-time** | WebSocket (gorilla/websocket) |
| **Audio Processing** | Go WAV parser + autocorrelation pitch detection |
| **Pitch Detection** | Autocorrelation with silence gate (server-side) |
| **Database** | PostgreSQL |
| **Deployment** | Docker Compose |
| **API** | REST + WebSocket |

---

## 📁 Project Structure

```
guitar-ai/
├── backend/                    # Go REST API
│   ├── cmd/server/             # Entrypoint + migrate command
│   ├── internal/               # api, evaluation, service, config
│   ├── migrations/             # SQL schema + seed data
│   └── go.mod
├── frontend/                   # Flutter monorepo (web + mobile)
│   ├── apps/
│   │   ├── app_web/            # Flutter Web app
│   │   └── app_mobile/         # Flutter iOS + Android app
│   └── packages/
│       ├── app_shared/         # Shared screens + auth
│       ├── network/            # API client (Go backend)
│       └── shared_ui/          # Theme + shared widgets
├── docs/
├── docker-compose.yml
├── Makefile
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- Go 1.25+
- PostgreSQL 16+ (or Docker)
- Flutter 3.16+ (for frontend)
- Git

### Quick Start

**1. Backend**

```bash
cp .env.example .env
make docker-up    # Postgres + Go API (or: make migrate && make run)
make test
```

**2. Frontend (Flutter Web)**

```bash
make frontend-run
# Open http://localhost:3000
```

**3. Full stack (Docker — API + Postgres + Web)**

```bash
docker compose up -d --build
# Web UI: http://localhost:3000
# API:    http://localhost:5000
```

**4. E2E smoke tests (requires Postgres)**

```bash
make e2e-test
```

See [docs/DEPLOY.md](docs/DEPLOY.md) for production deployment (Docker Compose prod, Fly.io).

---

## 🗄️ Database Schema

### Key Tables

#### `instruments`
Stores all supported instruments with their specifications.

```sql
CREATE TABLE instruments (
  id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255),
  family VARCHAR(100), -- 'stringed', 'keys', 'percussion', 'wind'
  frequency_range_min INT,
  frequency_range_max INT,
  note_range_low VARCHAR(10),
  note_range_high VARCHAR(10),
  tuning JSONB,
  techniques JSONB,
  config JSONB
);
```

#### `musical_content`
Universal table for lessons, solos, and chords.

```sql
CREATE TABLE musical_content (
  id UUID PRIMARY KEY,
  type VARCHAR(20), -- 'lesson', 'solo', 'chord'
  title VARCHAR(255),
  difficulty_level INT,
  duration_seconds INT,
  bpm INT,
  key VARCHAR(10),
  created_at TIMESTAMP
);
```

#### `practice_sessions`
Records all user practice attempts.

```sql
CREATE TABLE practice_sessions (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES users,
  content_id UUID REFERENCES musical_content,
  instrument_id VARCHAR(50) REFERENCES instruments,
  recorded_audio_url VARCHAR(500),
  overall_score DECIMAL(5,2),
  created_at TIMESTAMP
);
```

#### `performance_metrics`
Detailed evaluation results.

```sql
CREATE TABLE performance_metrics (
  id UUID PRIMARY KEY,
  session_id UUID REFERENCES practice_sessions,
  pitch_accuracy DECIMAL(5,2),
  timing_accuracy DECIMAL(5,2),
  technique_score DECIMAL(5,2),
  expression_score DECIMAL(5,2),
  instrument_specific_metrics JSONB
);
```

See [DATABASE.md](docs/DATABASE.md) for complete schema.

---

## 📡 API Endpoints

### Instruments

```
GET    /api/instruments                    -- List all instruments
GET    /api/instruments/:id                -- Get instrument details
```

### Content (Lessons, Solos, Chords)

```
GET    /api/content                        -- List all content
GET    /api/content?type=solo&instrument=guitar&difficulty=3
GET    /api/content/:contentId             -- Get content details
GET    /api/content/:contentId/instrument/:instrumentId
```

### Practice Sessions

```
POST   /api/practice/start/:contentId     -- Start practice session
POST   /api/practice/:sessionId/evaluate  -- Submit played notes for scoring
POST   /api/practice/:sessionId/upload    -- Upload WAV for pitch detection + scoring
GET    /api/practice/:sessionId/results   -- Get evaluation results
GET    /api/practice/history              -- Get practice history (paginated)
```

### Statistics & Progress

```
GET    /api/stats/progress                -- Overall progress + trends
GET    /api/stats/achievements            -- User achievement badges
GET    /api/stats/leaderboard             -- Rankings by average score
GET    /api/stats/insights                -- Personalized practice tips
GET    /api/content/recommendations       -- Difficulty-aware content suggestions
```

### Real-time

```
GET    /ws/practice/:sessionId            -- WebSocket live feedback during practice
```

See [docs/API_SPEC.md](docs/API_SPEC.md) for complete API documentation.

---

## 📊 Performance Evaluation

### Universal Scoring System (0-100)

```
┌─ PITCH ACCURACY (40%)
│  └─ Instrument-specific thresholds
├─ TIMING & RHYTHM (35%)
│  └─ Note onset precision, swing feel
├─ TECHNIQUE EXECUTION (15%)
│  └─ Bends, vibrato, sustain, etc.
├─ EXPRESSION & MUSICALITY (7%)
│  └─ Phrasing, dynamics, feeling
└─ CONSISTENCY (3%)
   └─ Stability across repeats
```

### Instrument-Specific Metrics

- **Guitar**: Fret accuracy, string clarity, bend smoothness
- **Piano**: Key velocity, sustain timing, voicing accuracy
- **Violin**: Intonation (cents deviation), bow control
- **Drums**: Pocket feel, dynamics, timing grid precision
- **Wind Instruments**: Tone quality, articulation, breath support

---

## 🛣️ Implementation Roadmap

### Phase 1: MVP (Weeks 1-3)
- [x] Project setup & database schema
- [x] User authentication
- [x] Instrument management system
- [x] Basic audio recording
- [x] Pitch detection (Go autocorrelation)
- [x] Simple scoring algorithm

### Phase 2: Core Features (Weeks 4-6)
- [x] Real-time pitch visualization
- [x] Detailed performance metrics
- [x] Practice history & dashboard
- [x] Technique hints (rule-based feedback)
- [x] Multiple speed variations
- [x] WebSocket real-time feedback

### Phase 3: Enhancement (Weeks 7-9)
- [x] Practice insights API
- [x] Achievements & gamification
- [x] Multiple instrument support (guitar, piano, violin, drums)
- [ ] Performance optimization
- [x] Mobile-responsive UI

### Phase 4: Scale & Polish (Weeks 10+)
- [x] Mobile app (Flutter iOS/Android)
- [x] Recommendation engine (difficulty-aware)
- [x] Social features (leaderboard)
- [x] Cloud deployment configs (Docker prod, Fly.io)
- [ ] Analytics dashboard

---

## 🎸 Supported Instruments

### Currently Available

- ✅ Guitar
- ✅ Piano
- ✅ Violin
- ✅ Drums

### Planned

- ⏳ Flute
- ⏳ Trumpet
- ⏳ Bass
- ⏳ Ukulele

### Extensibility

To add a new instrument:

1. Add a SQL migration under `backend/migrations/` with instrument config + seed content
2. Tune `pitchToleranceCents` / `timingToleranceMs` in the instrument `config` JSONB
3. Content appears automatically in the Flutter library (instruments loaded from API)

See [docs/FLUTTER_ARCHITECTURE.md](docs/FLUTTER_ARCHITECTURE.md) for frontend structure.

---

## 🔧 Development

### Environment Setup

```bash
# Copy environment template
cp .env.example .env

# Configure your settings:
# - Database URL
# - API Port
# - Audio Storage Path
# - etc.
```

### Running Tests

```bash
# Backend
make test

# Frontend
cd frontend/apps/app_web && flutter test
```

### Building Docker Images

```bash
docker-compose build
docker-compose up
```

See [DEVELOPMENT.md](docs/DEVELOPMENT.md) for more.

---

## 📌 Sprint Backlog (Kanban)

Track work via **GitHub Issues** + **Projects** board:

- **Backlog doc:** [docs/SPRINT_BACKLOG.md](docs/SPRINT_BACKLOG.md)
- **Issue templates:** `.github/ISSUE_TEMPLATE/`
- **Bulk create issues:** `./scripts/create-github-issues.sh`

**Kanban columns:** Backlog → Ready → In Progress → In Review → Done

---

## 🤝 Contributing

Contributions are welcome! Here's how to help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Guidelines

- Follow Go and Dart/Flutter conventions in each package
- Write tests for new features
- Update [docs/API_SPEC.md](docs/API_SPEC.md) when adding endpoints
- Run `make test` and `make e2e-test` before opening PRs

---

## 📚 Documentation

- [API Specification](docs/API_SPEC.md) - REST + WebSocket reference
- [Deploy Guide](docs/DEPLOY.md) - Production deployment
- [Sprint Backlog](docs/SPRINT_BACKLOG.md) - Kanban / issue tracking
- [Flutter Architecture](docs/FLUTTER_ARCHITECTURE.md) - Frontend monorepo layout

---

## 🐛 Known Issues

- Real-time audio processing latency on high-complexity pieces
- Polyphonic pitch detection accuracy (work in progress)
- Mobile browser WebSocket limitations

See [Issues](https://github.com/Trinhleo/guitar-ai/issues) for more.

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Librosa** - Audio analysis library
- **Essentia** - Audio analysis framework
- **Web Audio API** - Browser audio processing
- Music education community for inspiration

---

## 📧 Contact

**Author**: Trinh Leo  
**Email**: contact@example.com  
**GitHub**: [@Trinhleo](https://github.com/Trinhleo)

---

## 🌟 Show Your Support

If this project helps you learn music, please give it a ⭐ on GitHub!

---

**Happy practicing! 🎵🎸**
