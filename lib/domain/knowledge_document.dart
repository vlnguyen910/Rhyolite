enum DocumentType { course, concept, note, reference }

/// Normalized data shared by the UI, search and future graph features.
class KnowledgeDocument {
  const KnowledgeDocument({
    required this.id,
    required this.type,
    required this.title,
    required this.path,
    required this.body,
    required this.sourceMarkdown,
    this.code,
    this.semester,
    this.syllabusId,
    this.demo = false,
    this.prerequisiteText,
    this.prerequisiteTargets = const [],
    this.conceptTargets = const [],
    this.courseTargets = const [],
    this.links = const [],
    this.relatedTargets = const [],
    this.sources = const [],
  });

  final String id;
  final DocumentType type;
  final String title;
  final String path;
  final String body;
  final String sourceMarkdown;
  final String? code;
  final int? semester;
  final String? syllabusId;
  final bool demo;
  // Original syllabus condition: preserves OR, cohort and credit constraints.
  final String? prerequisiteText;
  final List<String> prerequisiteTargets;
  final List<String> conceptTargets;
  final List<String> courseTargets;
  final List<String> links;
  final List<String> relatedTargets;
  final List<String> sources;
}

enum IssueSeverity { error, warning }

class ValidationIssue {
  const ValidationIssue(this.path, this.message, this.severity);

  final String path;
  final String message;
  final IssueSeverity severity;
}

class KnowledgeSnapshot {
  const KnowledgeSnapshot(this.documents, this.issues);

  final List<KnowledgeDocument> documents;
  final List<ValidationIssue> issues;

  List<KnowledgeDocument> get courses => documents
      .where((document) => document.type == DocumentType.course)
      .toList();

  List<KnowledgeDocument> get concepts => documents
      .where((document) => document.type == DocumentType.concept)
      .toList();

  List<KnowledgeDocument> get notes => documents
      .where((document) => document.type == DocumentType.note)
      .toList();

  List<KnowledgeDocument> notesFor(KnowledgeDocument document) => notes
      .where(
        (note) =>
            note.id != document.id &&
            note.links.any(
              (link) => resolve(link, fromPath: note.path)?.id == document.id,
            ),
      )
      .toList();

  List<KnowledgeDocument> conceptsFor(KnowledgeDocument course) => concepts
      .where(
        (concept) =>
            course.conceptTargets.any(
              (target) => resolve(target, fromPath: course.path) == concept,
            ) ||
            concept.courseTargets.any(
              (target) => resolve(target, fromPath: concept.path) == course,
            ),
      )
      .toList();

  List<KnowledgeDocument> coursesFor(KnowledgeDocument concept) =>
      courses.where((course) => conceptsFor(course).contains(concept)).toList();

  /// Resolve IDs, Obsidian paths and unique basenames, including dots in names.
  /// Relative paths are resolved against the current document first.
  KnowledgeDocument? resolve(String raw, {String? fromPath}) {
    var key = raw.split('|').first.split('#').first.trim();
    if (key.isEmpty && fromPath != null) key = fromPath;
    if (key.endsWith('.md')) key = key.substring(0, key.length - 3);
    final relative = fromPath == null
        ? null
        : '${fromPath.substring(0, fromPath.lastIndexOf('/') + 1)}$key';
    for (final document in documents) {
      final path = document.path.substring(0, document.path.length - 3);
      if (document.id == key ||
          path == key ||
          path == 'knowledge/$key' ||
          path == relative) {
        return document;
      }
    }
    final matches = documents.where((document) {
      final basename = document.path.split('/').last;
      return basename.substring(0, basename.length - 3) == key;
    }).toList();
    return matches.length == 1 ? matches.single : null;
  }

  List<KnowledgeDocument> prerequisites(KnowledgeDocument document) => document
      .prerequisiteTargets
      .map((target) => resolve(target, fromPath: document.path))
      .whereType<KnowledgeDocument>()
      .toSet()
      .toList();

  List<KnowledgeDocument> dependents(KnowledgeDocument document) => courses
      .where((course) => prerequisites(course).contains(document))
      .toList();
}
