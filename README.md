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
- Local graph with typed arrows, reference links, pan/zoom, fit-to-view and clickable nodes.
- Concept browser with title/content search, related concepts and course navigation.
- Four initial sourced PRM393 concepts: Dart, Flutter, Future/async-await and state management.
- My Notes: create/edit Markdown, live preview, course/concept links, local persistence,
  title/content search, backlinks and graph navigation.

The imported dataset contains 76 course documents across 9 semester groups,
including alternative course versions and combinations. It is not presented as
one verified mandatory curriculum for every student.

## Data pipeline

```text
Bundled Markdown + user-owned Markdown notes
  → MarkdownAdapter
  → KnowledgeDocument
  → KnowledgeSnapshot + validation issues
  → Browsers, document details and local graph
```

- `knowledge/Mon hoc/`: the original Obsidian syllabus dataset, preserved.
- `knowledge/`: the Obsidian course hub and resource notes.
- `knowledge/courses/`, `knowledge/concepts/`: demo content and sourced concept notes.
- `lib/domain/knowledge_document.dart`: shared models, link resolution and reverse queries.
- `lib/domain/knowledge_graph.dart`: typed edges, deduplication and depth-one graph queries.
- `lib/features/graph/local_graph_screen.dart`: deterministic graph layout and interactive rendering.
- `lib/data/markdown_adapter.dart`: normalization of legacy and demo schemas.
- `lib/data/knowledge_repository.dart`: asset loading and cross-file validation.
- `lib/data/personal_note_store.dart`: personal Markdown storage and guarded replacement.
- `lib/features/notes/personal_note_editor.dart`: editor, preview and unsaved-change handling.
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
The refresh button reloads the bundle and personal notes; it does not scan an
arbitrary external Obsidian vault.

For existing-format course files, supply `course_code`, `semester`, an H1 title,
the original syllabus body and its source URL. For demo-schema files, use `id`,
`type`, `code`, `title`, `semester` and `demo: true`. Keep IDs and basenames unique.
Declare each new asset subdirectory in `pubspec.yaml`, then run the checks.

Keep source Markdown under Git and make a separate backup of personal vaults.
The app edits personal notes and does not provide sync. Generated build output and
`.dart_tool` are ignored and can be recreated; they are not knowledge backups.

## Explore concepts and graph

Search `PRM393`, open it, then choose **Graph cục bộ**. Its local graph contains
PRO192 and the four initial concepts. Drag the background to pan, scroll or use
the zoom buttons, and use **Vừa khung** to reset the view. Clicking a node closes
the graph and opens that document. Graphs are available from concept details too.

Blue arrows mean `A requires B`, with the arrow pointing from A to B. Orange
arrows point from a course to a linked syllabus concept. Dashed gray lines are
undirected references. The reverse view of a prerequisite is computed, not stored
as another fact. Reference hubs are omitted to keep local graphs useful.
The view is depth one and capped at 24 nodes including the focus. If neighbors
are omitted, their count is shown; full relation lists remain in document details.

Select **Concept** in the browser to search concept titles and Markdown content.
Demo concepts remain hidden unless the demo toggle is enabled. The new notes are
AI-authored initial summaries for group review, with official technical sources
and local PRM393 CLO references. They do not claim personal mastery or substitute
for an independently verified syllabus.

To associate a concept with a course without editing the original syllabus, use:

```yaml
id: "concept:my-topic"
type: concept
title: "My Topic"
courses: ["course:PRM393"]
related: ["concept:dart"]
sources: ["https://example.com/verified-source"]
demo: false
```

Replace the example source with an actual reference. Alternatively a course's
`concepts` property can list concept IDs. Either direction builds the same
course-to-concept edge; entering both does not create duplicates. Invalid target
types are reported by validation. Generic wikilinks never imply a prerequisite.

## Personal notes

Choose **Tạo note** to write a standalone note, or **Ghi chú về mục này** from a
course/concept to start with that link. Enter a title and Markdown, add links with
the picker or `[[concept:flutter|Flutter]]`, then press **Lưu note** or `Ctrl+S`.
Wide editors show a live preview beside the text; narrow windows offer a preview
toggle. Preview displays wikilink labels; the saved reader opens their targets.
Use **My Notes** to search titles and body text, then **Sửa note** to edit.
Linked documents show backlinks under **Personal notes liên quan**. Note nodes
are purple in the graph and their dashed reference edges imply no prerequisites.

Files live in the platform's application support directory, in `notes/`.
Use **Thư mục lưu** in the workspace to see the actual path. On Linux this is
normally `~/.local/share/com.example.rhyolite/notes/` (XDG settings can change it).
They are separate from bundled assets and Git, and survive app restarts/rebuilds.
Back up this directory yourself before reinstalling/moving machines.

Each note gets a stable `note:<random-id>` and `<random-id>.md` filename, so title
changes and duplicate titles do not break ID links. Supported frontmatter:

```yaml
id: "note:<32-character-hex-id>"
type: note
title: "My learning notes"
related: ["course:PRM393", "concept:flutter"]
```

The editor writes these fields and the Markdown body; arbitrary additional
frontmatter is not preserved on edit. Renaming files or changing IDs externally
is unsupported. Malformed/unreadable notes appear in validation without blocking
the bundled course browser.

Saving flushes a temporary file before replacement and keeps the previous version
in `.md.bak`. If the target is missing after an interrupted replacement, loading
restores that backup. The store refuses to overwrite a note changed/deleted
outside the editor. A failed save keeps the draft visible and offers a copy button;
navigation prompts before discarding unsaved edits. Cancelable app-exit requests
also prompt, but force quit/power loss can discard unsaved drafts. There is no
autosave or cloud backup; click **Lưu note** before closing.

Manual note check: create a note from PRM393, link Flutter, save, search a word in
the body in My Notes, inspect both backlinks and graph, edit its title, close the
app and reopen it. The same note and links should remain.

Next milestone: demo preparation and platform QA. AI integration, cloud sync and
accounts remain outside this milestone.

See `docs/README.md` for the original planning and architecture documents.
