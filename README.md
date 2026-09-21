# Rhyolite

> **FPTU SE Personalized Study Assistant** — Local-first desktop application for FPT University Software Engineering students.

## Features & Architecture

Rhyolite helps students navigate curriculum pathways, explore course relationships, manage academic transcripts offline, analyze performance, and receive personalized study guidance powered by bounded AI context.

The desktop application is built with **Flutter** (Linux & Windows) following the **MVVM** architecture:

```text
View (Widgets/Screens) 
  ↓
ViewModel (ChangeNotifier State)
  ↓
Application / Service Layer (App, Knowledge, Transcript, AI)
  ↓
Local Storage & Bundled Knowledge
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

### Groq assistant

Copy `.env.example` to `.env`, then set your local `GROQ_API_KEY`. The app reads
`GROQ_API_KEY` and `GROQ_MODEL` from the operating-system environment first and
falls back to the local `.env` file while running from the project directory.
The `.env` file is ignored by Git and must never be committed.

When Groq is unavailable or is not configured, the assistant continues to
answer from the bundled curriculum and syllabus data.
