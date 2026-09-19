# Repository Guidelines

## Project Overview

Rhyolite is the planned **FPTU SE Personalized Study Assistant**: a local-first desktop application for exploring FPT University Software Engineering curricula, course relationships, transcripts, academic analysis, AI chat, and personalized study strategies. This repository is currently documentation-only.

## Project Structure

- `docs/` contains numbered product, requirements, architecture, privacy, milestone, acceptance, and decision documents. Start with [`docs/00-README.md`](docs/00-README.md).
- `knowledge/` is the Obsidian-compatible course-content vault. Course notes are under `knowledge/Mon hoc/`; working material is under `knowledge/New Knowledge/`.
- Course Markdown is the source of truth; curriculum structure is separate JSON.
- `build/` and `.dart_tool/` are generated Flutter/Dart artifacts; do not edit or commit them by hand.
- `lib/`, `test/`, and application assets are not present yet.

## Architecture & Tech Stack

The client is planned as a **Flutter desktop application written in Dart**, using MVVM:

`View → ViewModel → Application/Service layer → Knowledge, Transcript, and AI services → Local storage / bundled knowledge`

Markdown and curriculum JSON are bundled inputs. Transcript parsing is local, and curriculum, course information, search, and local transcript features must work offline. Browser-extension transcript import communicates through localhost and requires preview plus user confirmation. The local database, graph engine, AI provider, API-key strategy, and localhost transport remain `TBD`; consult `docs/10-decision-log.md` before choosing one.

## Build, Test, and Development Commands

No package manifest or commands are committed yet. For documentation changes, review links, headings, code blocks, and consistency with the decision log. Once the Flutter shell exists, use `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter run -d <device>`.

## Coding, Testing, and Review

Use one clear H1 per Markdown file, clear H2/H3 headings, short paragraphs, and fenced diagrams. Preserve numbered document names (for example, `07-mvp-scope.md`) and course filenames containing the official course code. Future Dart code should use `dart format` and Flutter linting; add unit tests for loaders, parsers, matching, and services plus widget tests for key flows. Use the `*_test.dart` naming convention.

Commits should follow the concise prefixes already present in history, such as `docs:` and `feat:`, with an imperative summary. Pull requests should explain scope and decisions, link relevant issues or documents, list validation performed, and include screenshots for UI changes.

## Data Safety

Do not commit personal transcripts or uploaded student data. Preserve the local-first privacy model. Before changing product behavior, read the privacy policy and decision log, and update the relevant specification when a `TBD` decision is resolved.
