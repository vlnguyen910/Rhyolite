# Personal Notes — implemented MVP

Personal notes are user-owned Markdown files, separate from the bundled course
vault. The app reads both through `MarkdownAdapter` and validates the combined
`KnowledgeSnapshot`. The default application repository enables
`PersonalNoteStore`; tests can inject a temporary directory or omit that store.

## Model and linking

`DocumentType.note` uses the common `KnowledgeDocument` model. A random 128-bit
hex token identifies a note with `note:<token>` and logical path
`notes/<token>.md`. IDs and filenames remain stable when the title changes.
Serialization uses JSON strings/lists, which are valid YAML, to escape titles
containing quotes, colons, Unicode or newlines.

Frontmatter contains `id`, `type: note`, `title`, and `related` canonical IDs.
The editor round-trips these fields; extra frontmatter is not preserved. Body
wikilinks are indexed alongside `related`. `relatedTargets` stays separate from
body links so removing a body link does not silently recreate it as metadata.

`KnowledgeSnapshot.notesFor(document)` computes incoming personal-note links.
`KnowledgeGraphService` uses ordinary undirected `related` edges; notes do not
assert prerequisites or official course topics. Note nodes have purple borders.
My Notes searches title and Markdown body, and saved-reader links open targets.

## Storage and error behavior

`path_provider.getApplicationSupportDirectory()` supplies the platform location;
`notes/` is appended with the cross-platform `path` library. **Thư mục lưu** shows
the actual directory. Knowledge assets are never rewritten. Persistence does not
depend on Git, working directory or the development build output.

When editing, the current file must match the source originally opened. A missing
or externally modified file causes a conflict error instead of being overwritten.
The store validates the note's identity/path before any write.

Saving flushes new content to a temporary sibling file, copies the existing file
to `.md.bak`, and renames the temporary file into place. If replacement fails
after removing the target, the backup is restored. Loading also recovers a missing
target from a backup. The backup contains one previous saved version, not a full
revision history. Temporary files and backups are not indexed as documents.

Failures leave title/body/link selections in the editor. Users can retry or copy
the draft. `PopScope` guards navigation and `AppLifecycleListener` guards
cancelable exit requests. Forced termination/power loss can discard unsaved
drafts; there is no autosave. Backup the notes directory separately.

File comparison is optimistic, not a cross-process transaction lock. Concurrent
external edits during the write itself are outside this MVP; use one editor/app
instance at a time for a given note.

## Deletion

The note detail exposes **Xóa note** with a confirmation naming the note. The
store validates identity, file type and unchanged source before deletion. It
creates a unique `notes/.trash/<token>-<suffix>/` directory, moves `.md.bak`
there first, then moves the current `.md`. Removing the backup first prevents
startup recovery from resurrecting an intentionally deleted note. If the note
move fails, the backup is moved back; archive failures keep the current note.
If backup rollback also fails, its data remains in the trash directory and the
operation reports an error. An interruption before the final note move leaves
the current note live; an interruption after it leaves both versions archived.

Trash directories are excluded from indexing. There is no restore, trash browser
or automatic purge UI yet. Manual recovery can move the archived `.md` back to
`notes/` with its original filename, then refresh; keep its ID unchanged.
File checks remain optimistic rather than a cross-process lock.

Successful deletion reloads library, backlinks and overview graph, clears a
deleted selection and closes the initiating detail route. Older stacked routes
to the same deleted note show a missing-note message. Incoming links remain in
other documents and validation reports missing targets; no other note is edited.

## UI updates and checks

After a successful save the workspace reloads the combined snapshot and selects
the saved note. A shared snapshot notifier updates stacked detail routes, so
returning to a course reflects renamed note backlinks without restarting.
Wide editors show side-by-side preview; narrow editors offer a preview toggle.

Store tests cover reopening, stable identity, duplicate titles, YAML escaping,
foreign paths, disk failures, external changes, backup recovery, malformed-note
isolation and merged assets/backlinks/graph. Widget tests exercise create, preview,
body search, Ctrl+S editing, reopening, failed-save draft retention, discard
confirmation and nested narrow-window navigation.
