import 'knowledge_document.dart';

enum GraphRelation { prerequisite, topic, related }

class KnowledgeEdge {
  const KnowledgeEdge(this.sourceId, this.targetId, this.relation);
  final String sourceId;
  final String targetId;
  final GraphRelation relation;
}

class OverviewKnowledgeGraph {
  const OverviewKnowledgeGraph(this.nodes, this.edges);
  final List<KnowledgeDocument> nodes;
  final List<KnowledgeEdge> edges;
}

class LocalKnowledgeGraph {
  const LocalKnowledgeGraph({
    required this.focus,
    required this.nodes,
    required this.edges,
    required this.omittedCount,
  });
  final KnowledgeDocument focus;
  final List<KnowledgeDocument> nodes;
  final List<KnowledgeEdge> edges;
  final int omittedCount;
}

/// No Flutter imports: graph facts are derived from document metadata/links.
class KnowledgeGraphService {
  KnowledgeGraphService(this.snapshot) {
    _build();
  }
  final KnowledgeSnapshot snapshot;
  final List<KnowledgeEdge> _edges = [];
  List<KnowledgeEdge> get edges => List.unmodifiable(_edges);

  OverviewKnowledgeGraph overviewGraph({
    bool includeConcepts = false,
    bool includeNotes = false,
    bool includeDemo = false,
  }) {
    final nodes =
        snapshot.documents
            .where(
              (document) =>
                  (includeDemo || !document.demo) &&
                  switch (document.type) {
                    DocumentType.course => true,
                    DocumentType.concept => includeConcepts,
                    DocumentType.note => includeNotes,
                    DocumentType.reference => false,
                  },
            )
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final ids = nodes.map((node) => node.id).toSet();
    final visibleEdges = _edges
        .where(
          (edge) =>
              ids.contains(edge.sourceId) &&
              ids.contains(edge.targetId) &&
              (edge.relation != GraphRelation.related ||
                  snapshot.resolve(edge.sourceId)!.type !=
                      DocumentType.course ||
                  snapshot.resolve(edge.targetId)!.type != DocumentType.course),
        )
        .toList();
    return OverviewKnowledgeGraph(
      List.unmodifiable(nodes),
      List.unmodifiable(visibleEdges),
    );
  }

  void _build() {
    final seen = <String>{};
    final typedPairs = <String>{};
    String pair(String a, String b) => ([a, b]..sort()).join('|');
    void add(
      KnowledgeDocument source,
      KnowledgeDocument target,
      GraphRelation relation,
    ) {
      if (source.id == target.id) return;
      final identity = relation == GraphRelation.related
          ? 'related:${pair(source.id, target.id)}'
          : '${relation.name}:${source.id}:${target.id}';
      if (!seen.add(identity)) return;
      _edges.add(KnowledgeEdge(source.id, target.id, relation));
      if (relation != GraphRelation.related) {
        typedPairs.add(pair(source.id, target.id));
      }
    }

    for (final course in snapshot.courses) {
      for (final required in snapshot.prerequisites(course)) {
        if (required.type == DocumentType.course) {
          add(course, required, GraphRelation.prerequisite);
        }
      }
      for (final concept in snapshot.conceptsFor(course)) {
        add(course, concept, GraphRelation.topic);
      }
    }
    for (final document in snapshot.documents) {
      if (document.type == DocumentType.reference) continue;
      for (final link in document.links) {
        final target = snapshot.resolve(link, fromPath: document.path);
        if (target == null ||
            target.type == DocumentType.reference ||
            typedPairs.contains(pair(document.id, target.id))) {
          continue;
        }
        add(document, target, GraphRelation.related);
      }
    }
  }

  LocalKnowledgeGraph localGraph(
    KnowledgeDocument focus, {
    int maxNodes = 24,
    bool includeDemo = false,
  }) {
    if (maxNodes < 1) throw RangeError.range(maxNodes, 1, null, 'maxNodes');
    final byId = {
      for (final document in snapshot.documents) document.id: document,
    };
    final adjacent =
        _edges
            .where(
              (edge) => edge.sourceId == focus.id || edge.targetId == focus.id,
            )
            .toList()
          ..sort((a, b) {
            final relation = a.relation.index.compareTo(b.relation.index);
            if (relation != 0) return relation;
            final aId = a.sourceId == focus.id ? a.targetId : a.sourceId;
            final bId = b.sourceId == focus.id ? b.targetId : b.sourceId;
            return aId.compareTo(bId);
          });
    final neighbors = <String, KnowledgeDocument>{};
    final linkedNotes = snapshot.notes
        .where(
          (note) => note.links.any(
            (link) =>
                snapshot.resolve(link, fromPath: note.path)?.id == focus.id,
          ),
        )
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));
    for (final note in linkedNotes) {
      if (includeDemo || focus.demo || !note.demo) {
        neighbors[note.id] = note;
      }
    }
    for (final edge in adjacent) {
      final id = edge.sourceId == focus.id ? edge.targetId : edge.sourceId;
      final node = byId[id];
      if (node != null && (includeDemo || focus.demo || !node.demo)) {
        neighbors[id] = node;
      }
    }
    final nodes = [focus, ...neighbors.values.take(maxNodes - 1)];
    final visible = nodes.map((node) => node.id).toSet();
    return LocalKnowledgeGraph(
      focus: focus,
      nodes: List.unmodifiable(nodes),
      edges: List.unmodifiable(
        adjacent.where(
          (edge) =>
              visible.contains(edge.sourceId) &&
              visible.contains(edge.targetId),
        ),
      ),
      omittedCount: neighbors.length - (nodes.length - 1),
    );
  }
}
