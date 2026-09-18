# Repository Guidelines

## Project Structure & Module Organization

- `docs/` contains the numbered product, requirements, architecture, privacy, scope, milestone, acceptance, and decision documents. Start with [`docs/00-README.md`](docs/00-README.md).
- `knowledge/` is the course-content source used as an Obsidian vault. Course notes are under `knowledge/Mon hoc/`; keep curriculum structure (future JSON) separate from course Markdown.
- `build/` and `.dart_tool/` are generated Flutter/Dart artifacts; do not edit them by hand or commit regenerated output unless a task explicitly requires it.
- Application source, tests, and asset manifests are not present yet. The planned application is Flutter desktop using MVVM.

## Build, Test, and Development Commands

There is currently no committed package manifest or automated build/test command. For documentation-only changes, review the affected Markdown directly and check links and headings. Once the Flutter shell is added, document the project’s canonical commands here (typically `flutter pub get`, `flutter analyze`, `flutter test`, and `flutter run -d <device>`).

## Coding Style & Naming Conventions

Use Markdown with one clear H1 per document, descriptive H2/H3 headings, short paragraphs, and fenced diagrams/examples where useful. Preserve the numbered naming pattern in `docs/` (for example, `07-mvp-scope.md`). Course files should retain their official course code and readable title, such as `knowledge/Mon hoc/FER202 - Front-End web development with React.md`.

Treat course Markdown as the knowledge source of truth and curriculum data as JSON. Derived indexes, graph caches, parsed models, and retrieval data must be rebuildable. Do not turn a `TBD` item into an implementation assumption without recording a decision.

## Testing Guidelines

No test framework or coverage threshold is configured yet. Validate documentation changes by checking internal links, code blocks, and consistency with `docs/10-decision-log.md`. Future Flutter changes should add unit tests for loaders, parsers, matching, and services, plus widget tests for important flows.

## Documentation and Data Safety

Keep personal or uploaded transcript data out of the repository. Before changing product behavior, consult the decision log and privacy policy; update the relevant specification when a previously open decision is resolved.
