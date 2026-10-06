# Repository Guidelines

## Project Overview

Rhyolite is the **FPTU SE Personalized Study Assistant**: a local-first desktop application for exploring FPT University Software Engineering curricula, course relationships, transcripts, academic analysis, AI chat, and personalized study strategies.

## Project Structure

- `docs/` contains numbered product, requirements, architecture, privacy, milestone, acceptance, and decision documents. Start with [`docs/00-README.md`](docs/00-README.md).
- `knowledge/` is the Obsidian-compatible course-content vault. Course notes are under `knowledge/Mon hoc/`; working material is under `knowledge/New Knowledge/`.
- `assets/` contains bundled runtime knowledge: `assets/curricula/` (JSON) and `assets/courses/` (Markdown).
- `lib/` contains the application codebase organized in a **flat, canonical MVVM structure**:
  - `lib/models/`: Immutable domain models, data entities, and DTOs (Pure Dart, no Flutter UI imports).
  - `lib/services/`: Application, I/O, parsing, AI adapters, and storage services (independent of UI).
  - `lib/viewmodels/`: UI state controllers extending `ChangeNotifier` / `Listenable`, bridging Views and Services.
  - `lib/views/`: Passive UI widgets, screens, and dialogs.
  - `lib/views/widgets/`: Modular, reusable UI sub-components.
  - `lib/design_system/`: App theme, typography, breakpoints, and colors.
- `test/` contains unit tests (`*_test.dart`) for services, models, viewmodels, and widget smoke tests.
- `build/` and `.dart_tool/` are generated Flutter/Dart artifacts; do not edit or commit them by hand.

## Architecture & Tech Stack

The client is a **Flutter desktop application written in Dart** (supporting Linux & Windows), strictly following the **MVVM** pattern:

`View (Passive UI) → ViewModel (State & Logic) → Service Layer (I/O, AI, Storage) → Models (Data Entities)`

### Core Architecture Rules:
1. **Passive Views**: Widgets in `lib/views/` must only render UI. Never perform file I/O, network calls, complex algorithms ($O(N)$ filtering, regex, map grouping) inside a Widget's `build()` method.
2. **ViewModel Responsibility**: All UI states, asynchronous operations (`isLoading`, `errorMessage`), and filtering/formatting logic belong in `lib/viewmodels/`.
3. **Service Independence**: Services in `lib/services/` must never import `package:flutter/material.dart` or depend on UI elements.
4. **Avoid Over-engineering**: Maintain the flat 4-layer MVVM layout (`models/`, `services/`, `viewmodels/`, `views/`). Do not introduce nested `features/`, `domain/`, or complex Clean Architecture sub-layers unless explicitly requested.

## Build, Test, and Development Commands

Canonical commands for development:
- `flutter pub get`: Fetch dependencies.
- `flutter analyze`: Run Dart analyzer (must maintain 0 warnings/issues).
- `dart format .`: Auto-format all Dart code.
- `flutter test`: Run test suite (both unit tests and widget tests).
- `flutter run -d linux` / `flutter run -d windows`: Launch desktop app.

## Coding, Testing, and Review

- Future Dart code should strictly pass `flutter analyze` and adhere to `dart format`.
- Add pure Dart unit tests for any new parser, loader, service, or ViewModel. Use the `*_test.dart` naming convention.
- Commits should follow concise prefixes: `docs:`, `feat:`, `refactor:`, `test:`, `fix:`.
- Pull requests must document scope, decisions, and verification steps.

## Data Safety

Do not commit personal transcripts or uploaded student data. Preserve the local-first privacy model. Keep cloud AI usage consent-gated and strictly bounded by course context.
