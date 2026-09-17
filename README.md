# Rhyolite — FPTU SE Knowledge

A local-first Flutter desktop workspace inspired by Obsidian. Markdown is the
source of truth; the application does not require Obsidian to run.

## Run

The current SDK constraint requires Dart 3.13.3 or compatible newer 3.x versions.
The foundation was created with Flutter 3.47.3. Configure the desktop toolchain
for your operating system, then run:

```bash
flutter pub get
flutter run -d linux
```

On a Windows development machine, use `flutter run -d windows`.
Windows platform files are included, but the Windows build has not been verified.

## Implemented milestone

- Course browser grouped by semester, with local code/title search.
- Detail view with original prerequisite conditions, linked courses and sources.
- Clickable Obsidian wikilinks in the Markdown reader.
- Validation report with paths and error/warning severity.
- Demo data hidden by default and available through a toggle.
- Responsive layout: two panes on desktop, separate detail route in narrow windows.

The imported dataset contains 76 course documents across 9 semester groups,
including alternative course versions and combinations. It is not presented as
one verified mandatory curriculum for every student.

## Data pipeline

```text
Bundled Markdown
  → MarkdownAdapter
  → KnowledgeDocument
  → KnowledgeSnapshot + validation issues
  → Course browser and detail view
```

- `knowledge/Mon hoc/`: the original Obsidian syllabus dataset, preserved.
- `knowledge/`: the Obsidian course hub and resource notes.
- `knowledge/courses/`, `knowledge/concepts/`: explicitly marked demo content.
- `lib/domain/knowledge_document.dart`: shared models, link resolution and reverse queries.
- `lib/data/markdown_adapter.dart`: normalization of legacy and demo schemas.
- `lib/data/knowledge_repository.dart`: asset loading and cross-file validation.
- `lib/features/knowledge/knowledge_workspace.dart`: browser, detail and diagnostics UI.

The adapter maps `course_code` to a canonical `course:<code>` ID, converts
semester strings to integers, reads the title from H1, and extracts FLM source URLs.
Obsidian aliases, paths, heading fragments and dots in filenames are recognized.
Heading links open the document; scrolling to individual headings is not implemented.

Prerequisite links are navigation references, not a complete eligibility engine.
The original syllabus condition is kept separately so OR choices, credit rules
and cohort restrictions remain visible. Reverse course references are computed
from prerequisite links rather than entered twice.

Validation detects malformed metadata, invalid semester values, duplicate IDs or
codes, duplicate basenames, unresolved links, missing syllabus sources and course
codes outside the dataset mentioned in original prerequisite text. It does not
authenticate FLM content or decide whether a student meets a prerequisite.
Currently 13 imported courses trigger the outside-dataset warning.

The Markdown reader converts wikilinks to clickable links and `<br>` tags to
separators for display. Original Markdown remains available in the source view.
No source file is rewritten by the reader. The `.obsidian` configuration is not
loaded by the app. Sources open in the system browser; if unavailable, their text
is copied to the clipboard.

## Check

```bash
flutter analyze
flutter test
flutter build linux
```

Tests cover malformed data, link resolution, duplicate identity, prerequisite
direction, the full dataset, actual asset loading and responsive UI navigation.

Manual walkthrough:

1. Search for `PRM393`, then open Mobile Programming.
2. Check semester, syllabus source and original prerequisite text.
3. Click `PRO192`; verify the reverse reference includes `PRM393`.
4. Open the Markdown reader and click a wikilink.
5. Search `SWR302`; verify the original OR condition remains visible.
6. Open validation and inspect file-specific warnings.
7. Enable demo content and open `DEMO_SQL`.
8. Resize the window and verify navigation still works.

## Add data and maintain

This milestone reads bundled assets. Changes to Markdown require rebuilding or
restarting through Flutter's development runner so the asset bundle is updated.
The refresh button reloads the bundle; it does not scan an external vault.

For existing-format course files, supply `course_code`, `semester`, an H1 title,
the original syllabus body and its source URL. For demo-schema files, use `id`,
`type`, `code`, `title`, `semester` and `demo: true`. Keep IDs and basenames unique.
Declare each new asset subdirectory in `pubspec.yaml`, then run the checks.

Keep source Markdown under Git and make a separate backup of personal vaults.
The app currently does not edit files or provide sync. Generated build output and
`.dart_tool` are ignored and can be recreated; they are not knowledge backups.

Next milestones: concept exploration, graph visualization and persistent personal
notes. AI, cloud sync and accounts remain outside this milestone.

See `docs/README.md` for the original planning and architecture documents.
