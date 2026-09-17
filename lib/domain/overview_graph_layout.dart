import 'dart:math' as math;

import 'knowledge_document.dart';
import 'knowledge_graph.dart';

typedef GraphPoint = ({double x, double y});

class GraphColumn {
  const GraphColumn(this.label, this.nodes);
  final String label;
  final List<KnowledgeDocument> nodes;
}

class OverviewEdgeRoute {
  const OverviewEdgeRoute(this.edge, this.points, {this.bezier = false});
  final KnowledgeEdge edge;
  final List<GraphPoint> points;
  final bool bezier;
}

/// Fixed semester columns; reorder rows to reduce adjacent-column crossings.
/// Long edges travel above the columns, never through intermediate node boxes.
class OverviewGraphLayout {
  OverviewGraphLayout(OverviewKnowledgeGraph graph) {
    final groups = <int, List<KnowledgeDocument>>{};
    for (final course in graph.nodes.where(
      (node) => node.type == DocumentType.course,
    )) {
      groups.putIfAbsent(course.semester!, () => []).add(course);
    }
    final semesters = groups.keys.toList()..sort();
    final ordered = [
      for (final semester in semesters)
        (groups[semester]!..sort((a, b) => a.code!.compareTo(b.code!))),
    ];
    for (final type in [DocumentType.concept, DocumentType.note]) {
      final extras = graph.nodes.where((node) => node.type == type).toList()
        ..sort((a, b) => a.title.compareTo(b.title));
      if (extras.isNotEmpty) ordered.add(extras);
    }
    initialCrossings = _crossings(ordered, graph.edges);
    var best = [for (final group in ordered) List<KnowledgeDocument>.of(group)];
    var bestScore = initialCrossings;
    final neighbors = <String, Set<String>>{};
    for (final edge in graph.edges) {
      neighbors.putIfAbsent(edge.sourceId, () => {}).add(edge.targetId);
      neighbors.putIfAbsent(edge.targetId, () => {}).add(edge.sourceId);
    }
    for (var pass = 0; pass < 8; pass++) {
      final indices = List.generate(ordered.length, (i) => i);
      for (final column in pass.isEven ? indices : indices.reversed) {
        final ranks = <String, double>{};
        for (var other = 0; other < ordered.length; other++) {
          if (other == column) continue;
          for (var row = 0; row < ordered[other].length; row++) {
            ranks[ordered[other][row].id] = (row + .5) / ordered[other].length;
          }
        }
        final previous = {
          for (var row = 0; row < ordered[column].length; row++)
            ordered[column][row].id: row,
        };
        double barycenter(KnowledgeDocument doc) {
          final values = (neighbors[doc.id] ?? {})
              .map((id) => ranks[id])
              .whereType<double>()
              .toList();
          return values.isEmpty
              ? (previous[doc.id]! + .5) / ordered[column].length
              : values.reduce((a, b) => a + b) / values.length;
        }

        ordered[column].sort((a, b) {
          final difference = barycenter(a).compareTo(barycenter(b));
          return difference != 0
              ? difference
              : previous[a.id]!.compareTo(previous[b.id]!);
        });
      }
      final score = _crossings(ordered, graph.edges);
      if (score < bestScore) {
        bestScore = score;
        best = [for (final group in ordered) List.of(group)];
      }
    }
    crossings = bestScore;
    columns = List.unmodifiable([
      for (var i = 0; i < best.length; i++)
        GraphColumn(
          i < semesters.length
              ? 'Học kỳ ${semesters[i]}'
              : best[i].first.type == DocumentType.concept
              ? 'Concept'
              : 'My Notes',
          List.unmodifiable(best[i]),
        ),
    ]);
    final columnOf = {
      for (var i = 0; i < columns.length; i++)
        for (final node in columns[i].nodes) node.id: i,
    };
    final longEdges = graph.edges
        .where(
          (edge) =>
              (columnOf[edge.sourceId]! - columnOf[edge.targetId]!).abs() > 1,
        )
        .length;
    headerY = 28 + longEdges * 6.0;
    final rows = columns.isEmpty
        ? 0
        : columns.map((group) => group.nodes.length).reduce(math.max);
    width = math.max(600, padding * 2 + columns.length * columnStep);
    height = math.max(360, headerY + 52 + rows * rowStep + padding);
    for (var column = 0; column < columns.length; column++) {
      for (var row = 0; row < columns[column].nodes.length; row++) {
        positions[columns[column].nodes[row].id] = (
          x: padding + column * columnStep,
          y: headerY + 52 + row * rowStep,
        );
      }
    }

    // Distinct node ports and vertical tracks keep parallel wires separable.
    final incident = <String, List<KnowledgeEdge>>{};
    final sortedEdges = List<KnowledgeEdge>.of(graph.edges)
      ..sort(
        (a, b) => '${a.sourceId}|${a.targetId}|${a.relation.name}'.compareTo(
          '${b.sourceId}|${b.targetId}|${b.relation.name}',
        ),
      );
    for (final edge in sortedEdges) {
      incident.putIfAbsent(edge.sourceId, () => []).add(edge);
      incident.putIfAbsent(edge.targetId, () => []).add(edge);
    }
    double portY(String id, KnowledgeEdge edge) {
      final siblings = incident[id]!;
      return positions[id]!.y +
          4 +
          (siblings.indexOf(edge) + 1) *
              (nodeHeight - 8) /
              (siblings.length + 1);
    }

    final tracks = <int, int>{};
    double trackX(int column, {required bool left}) {
      final gap = left ? column - 1 : column;
      final slot = tracks.update(gap, (slot) => slot + 1, ifAbsent: () => 0);
      // More tracks squeeze within a gap rather than entering a node column.
      final offset = 10 + (columnGap - 20) * (slot / (slot + 8));
      return padding + (gap + 1) * columnStep - columnGap + offset;
    }

    var upperTrack = 0;
    for (final edge in sortedEdges) {
      final sourceColumn = columnOf[edge.sourceId]!;
      final targetColumn = columnOf[edge.targetId]!;
      final same = sourceColumn == targetColumn;
      final goesLeft = targetColumn < sourceColumn;
      final start = (
        x: positions[edge.sourceId]!.x + (goesLeft && !same ? 0 : nodeWidth),
        y: portY(edge.sourceId, edge),
      );
      final end = (
        x: positions[edge.targetId]!.x + (goesLeft || same ? nodeWidth : 0),
        y: portY(edge.targetId, edge),
      );
      if (same) {
        final rail = trackX(sourceColumn, left: false);
        routes.add(
          OverviewEdgeRoute(edge, [
            start,
            (x: rail, y: start.y),
            (x: rail, y: end.y),
            end,
          ]),
        );
      } else if ((sourceColumn - targetColumn).abs() == 1) {
        final middle = (start.x + end.x) / 2;
        routes.add(
          OverviewEdgeRoute(edge, [
            start,
            (x: middle, y: start.y),
            (x: middle, y: end.y),
            end,
          ], bezier: true),
        );
      } else {
        final startRail = trackX(sourceColumn, left: goesLeft);
        final endRail = trackX(targetColumn, left: !goesLeft);
        final upperY = 18.0 + upperTrack++ * 6;
        routes.add(
          OverviewEdgeRoute(edge, [
            start,
            (x: startRail, y: start.y),
            (x: startRail, y: upperY),
            (x: endRail, y: upperY),
            (x: endRail, y: end.y),
            end,
          ]),
        );
      }
    }
  }

  static const nodeWidth = 124.0;
  static const nodeHeight = 32.0;
  static const columnGap = 100.0;
  static const columnStep = nodeWidth + columnGap;
  static const rowStep = 44.0;
  static const padding = 32.0;
  late final double width;
  late final double height;
  late final double headerY;
  late final int initialCrossings;
  late final int crossings;
  late final List<GraphColumn> columns;
  final positions = <String, GraphPoint>{};
  final routes = <OverviewEdgeRoute>[];

  static int _crossings(
    List<List<KnowledgeDocument>> groups,
    List<KnowledgeEdge> edges,
  ) {
    final locations = {
      for (var c = 0; c < groups.length; c++)
        for (var r = 0; r < groups[c].length; r++) groups[c][r].id: (c, r),
    };
    var count = 0;
    for (var c = 0; c + 1 < groups.length; c++) {
      final segments = <(int, int)>[];
      for (final edge in edges) {
        final a = locations[edge.sourceId]!;
        final b = locations[edge.targetId]!;
        if (a.$1 == c && b.$1 == c + 1) segments.add((a.$2, b.$2));
        if (b.$1 == c && a.$1 == c + 1) segments.add((b.$2, a.$2));
      }
      for (var i = 0; i < segments.length; i++) {
        for (var j = i + 1; j < segments.length; j++) {
          if ((segments[i].$1 - segments[j].$1) *
                  (segments[i].$2 - segments[j].$2) <
              0) {
            count++;
          }
        }
      }
    }
    return count;
  }
}
