# Rhyolite

> **FPTU SE Personalized Study Assistant** — Local-first desktop application for FPT University Software Engineering students.

## Features & Architecture

Rhyolite helps students navigate curriculum pathways, explore course relationships, manage academic transcripts offline, analyze performance, and receive personalized study guidance powered by bounded AI context.

The desktop application is built with **Flutter** (Linux & Windows) following a **clean, flat MVVM (Model-View-ViewModel)** architecture:

```text
View (lib/views/ — Passive UI Widgets & Screens)
  ↓
ViewModel (lib/viewmodels/ — ChangeNotifier UI State & Logic)
  ↓
Services (lib/services/ — Knowledge, Transcript, AI, File I/O)
  ↓
Models (lib/models/ — Entities & Data Classes)
```

### Project Directory Layout

```text
lib/
├── models/           # Pure Dart entities, data models, and JSON serialization
├── services/         # Application services (Transcript parser, AI, File I/O, Notes)
├── viewmodels/       # UI state managers (ChangeNotifier) mediating between Views & Services
├── views/            # Passive UI screens and page widgets
│   └── widgets/      # Reusable sub-widgets and UI components
├── design_system/    # Theme tokens, colors, breakpoints, typography
├── app.dart          # Root MaterialApp setup
└── main.dart         # Desktop application entrypoint
```

For project documentation, requirements, and decisions, see:
- [`docs/00-README.md`](docs/00-README.md) — Documentation index
- [`docs/06-technical-architecture.md`](docs/06-technical-architecture.md) — Architecture specification
- [`docs/08-milestones-and-tasks.md`](docs/08-milestones-and-tasks.md) — Implementation roadmap
- [`docs/10-decision-log.md`](docs/10-decision-log.md) — Architectural decision log

## Development

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x or higher)
- Clang / CMake / GTK development libraries (for Linux desktop development)
- Visual Studio C++ build tools (for Windows desktop development)

### Common Commands

```bash
# Fetch dependencies
flutter pub get

# Static analysis
flutter analyze

# Format code
dart format .

# Run test suite
flutter test

# Run desktop application
flutter run -d linux
# or on Windows:
flutter run -d windows
```

### Groq Assistant Configuration

Copy `.env.example` to `.env`, then set your local `GROQ_API_KEY`. The app reads `GROQ_API_KEY` and `GROQ_MODEL` from the operating-system environment first and falls back to the local `.env` file while running from the project directory. The `.env` file is ignored by Git and must never be committed.
