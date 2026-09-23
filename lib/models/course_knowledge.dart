class CourseKnowledge {
  const CourseKnowledge({
    required this.code,
    required this.name,
    required this.bodyMarkdown,
    required this.sourceMarkdown,
    required this.descriptionMarkdown,
    required this.durationMarkdown,
    required this.toolsMarkdown,
    this.topics = const [],
    this.concepts = const [],
    this.credits,
    this.sourceUrl,
  });

  final String code;
  final String name;
  final String bodyMarkdown;
  final String sourceMarkdown;
  final String descriptionMarkdown;
  final String durationMarkdown;
  final String toolsMarkdown;
  final List<KnowledgeTopic> topics;
  final List<String> concepts;
  final String? credits;
  final String? sourceUrl;
}

class KnowledgeTopic {
  const KnowledgeTopic({required this.id, required this.title});

  final String id;
  final String title;
}
