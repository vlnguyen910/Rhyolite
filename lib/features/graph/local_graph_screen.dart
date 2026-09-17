import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/knowledge_document.dart';
import '../../domain/knowledge_graph.dart';

const _nodeSize = Size(200, 84);
const _edgeColors = {
  GraphRelation.prerequisite: Color(0xff2767b0),
  GraphRelation.topic: Color(0xffb96516),
  GraphRelation.related: Color(0xff77828e),
};
const _edgeLabels = {
  GraphRelation.prerequisite: 'cần',
  GraphRelation.topic: 'concept',
  GraphRelation.related: 'liên quan',
};

class LocalGraphScreen extends StatefulWidget {
  const LocalGraphScreen({
    super.key,
    required this.snapshot,
    required this.focus,
    required this.onOpen,
    this.includeDemo = false,
  });
  final KnowledgeSnapshot snapshot;
  final KnowledgeDocument focus;
  final ValueChanged<KnowledgeDocument> onOpen;
  final bool includeDemo;

  @override
  State<LocalGraphScreen> createState() => _LocalGraphScreenState();
}

class _LocalGraphScreenState extends State<LocalGraphScreen> {
  final _transform = TransformationController();
  late final LocalKnowledgeGraph _graph;
  late final _GraphLayout _layout;
  Size _viewport = Size.zero;

  @override
  void initState() {
    super.initState();
    _graph = KnowledgeGraphService(widget.snapshot)
        .localGraph(widget.focus, includeDemo: widget.includeDemo);
    _layout = _GraphLayout(_graph);
  }

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void _fit() {
    if (_viewport.isEmpty) return;
    final scale = math
        .min(
          (_viewport.width - 48) / _layout.size.width,
          (_viewport.height - 48) / _layout.size.height,
        )
        .clamp(0.08, 1.0);
    _transform.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        (_viewport.width - _layout.size.width * scale) / 2,
        (_viewport.height - _layout.size.height * scale) / 2,
        0,
      );
  }

  void _zoom(double factor) {
    final old = _transform.value;
    final scale = old.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(0.08, 3.0);
    final ratio = next / scale;
    _transform.value = Matrix4.diagonal3Values(next, next, 1)
      ..setTranslationRaw(
        _viewport.width / 2 - (_viewport.width / 2 - old.storage[12]) * ratio,
        _viewport.height / 2 - (_viewport.height / 2 - old.storage[13]) * ratio,
        0,
      );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Graph · ${widget.focus.code ?? widget.focus.title}'),
      actions: [
        IconButton(
          tooltip: 'Thu nhỏ',
          onPressed: () => _zoom(1 / 1.25),
          icon: const Icon(Icons.zoom_out),
        ),
        IconButton(
          tooltip: 'Phóng to',
          onPressed: () => _zoom(1.25),
          icon: const Icon(Icons.zoom_in),
        ),
        IconButton(
          tooltip: 'Vừa khung',
          onPressed: _fit,
          icon: const Icon(Icons.fit_screen),
        ),
      ],
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              for (final relation in GraphRelation.values)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      relation == GraphRelation.related
                          ? Icons.more_horiz
                          : Icons.arrow_right_alt,
                      color: _edgeColors[relation],
                    ),
                    Text(switch (relation) {
                      GraphRelation.prerequisite => 'A → B: A cần B',
                      GraphRelation.topic => 'Môn → concept trong syllabus',
                      GraphRelation.related => 'Liên kết tham khảo',
                    }),
                  ],
                ),
            ],
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: const Color(0xffedf2f5),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final viewport = constraints.biggest;
                if (viewport != _viewport) {
                  _viewport = viewport;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _fit();
                  });
                }
                return ClipRect(
                  child: InteractiveViewer(
                    key: const ValueKey('local-graph-viewer'),
                    transformationController: _transform,
                    constrained: false,
                    alignment: Alignment.topLeft,
                    minScale: 0.08,
                    maxScale: 3,
                    boundaryMargin: const EdgeInsets.all(1000),
                    child: SizedBox(
                      width: _layout.size.width,
                      height: _layout.size.height,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _GraphPainter(
                                _graph,
                                _layout,
                                Theme.of(context).textTheme.labelSmall!,
                              ),
                            ),
                          ),
                          for (final node in _graph.nodes)
                            Positioned(
                              left: _layout.positions[node.id]!.dx,
                              top: _layout.positions[node.id]!.dy,
                              width: _nodeSize.width,
                              height: _nodeSize.height,
                              child: _GraphNode(
                                document: node,
                                focused: node.id == _graph.focus.id,
                                onTap: () => widget.onOpen(node),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                '${_graph.nodes.length} node · ${_graph.edges.length} liên kết · độ sâu 1',
              ),
              if (_graph.omittedCount > 0)
                Text(
                  '${_graph.omittedCount} node khác chưa được vẽ; xem danh sách liên quan ở trang chi tiết.',
                ),
              if (_graph.nodes.length == 1)
                const Text('Chưa có liên kết kiến thức để khám phá.'),
              const Text(
                'Kéo để di chuyển, cuộn để zoom, click node để mở nội dung. Điều kiện AND/OR xem trong syllabus.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _GraphNode extends StatelessWidget {
  const _GraphNode({
    required this.document,
    required this.focused,
    required this.onTap,
  });
  final KnowledgeDocument document;
  final bool focused;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final concept = document.type == DocumentType.concept;
    final note = document.type == DocumentType.note;
    final color = note
        ? const Color(0xff7955b0)
        : concept
        ? const Color(0xffb96516)
        : const Color(0xff2767b0);
    return Tooltip(
      message: document.title,
      child: Material(
        color: focused ? const Color(0xffd9eee7) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: focused ? const Color(0xff136f63) : color,
            width: focused ? 3 : 1.5,
          ),
        ),
        child: InkWell(
          key: ValueKey('graph-node:${document.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    document.code ?? document.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${focused ? 'Đang xem · ' : ''}${note
                      ? 'Personal note'
                      : concept
                      ? 'Concept'
                      : 'Môn học'}${document.demo ? ' · DEMO' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stable four-lane layout, avoiding force simulation and frame-by-frame work.
class _GraphLayout {
  _GraphLayout(LocalKnowledgeGraph graph) {
    final lanes = List.generate(4, (_) => <KnowledgeDocument>[]);
    for (final node in graph.nodes.skip(1)) {
      final edge = graph.edges.firstWhere(
        (edge) => edge.sourceId == node.id || edge.targetId == node.id,
      );
      final lane = switch (edge.relation) {
        GraphRelation.prerequisite => edge.sourceId == graph.focus.id ? 0 : 1,
        GraphRelation.topic => 2,
        GraphRelation.related => 3,
      };
      lanes[lane].add(node);
    }
    final width = math.max(
      1040.0,
      math.max(lanes[2].length, lanes[3].length) * 224.0 + 80,
    );
    final height = math.max(
      640.0,
      math.max(lanes[0].length, lanes[1].length) * 112.0 + 260,
    );
    size = Size(width, height);
    positions[graph.focus.id] = Offset(width / 2 - 100, height / 2 - 42);
    for (var lane = 0; lane < 4; lane++) {
      final nodes = lanes[lane];
      for (var index = 0; index < nodes.length; index++) {
        positions[nodes[index].id] = lane < 2
            ? Offset(
                lane == 0 ? 40 : width - 240,
                (height - nodes.length * 112) / 2 + index * 112,
              )
            : Offset(
                (width - nodes.length * 224) / 2 + index * 224 + 12,
                lane == 2 ? height - 124 : 40,
              );
      }
    }
  }
  late final Size size;
  final Map<String, Offset> positions = {};
}

class _GraphPainter extends CustomPainter {
  _GraphPainter(this.graph, this.layout, this.labelStyle);
  final LocalKnowledgeGraph graph;
  final _GraphLayout layout;
  final TextStyle labelStyle;

  Offset _border(Offset center, Offset other) {
    final delta = other - center;
    final ratio = math.min(
      104 / math.max(delta.dx.abs(), 0.001),
      46 / math.max(delta.dy.abs(), 0.001),
    );
    return center + delta * ratio;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in graph.edges) {
      final a = layout.positions[edge.sourceId]! + const Offset(100, 42);
      final b = layout.positions[edge.targetId]! + const Offset(100, 42);
      final start = _border(a, b);
      final end = _border(b, a);
      final delta = end - start;
      final paint = Paint()
        ..color = _edgeColors[edge.relation]!
        ..strokeWidth = 2;
      if (edge.relation == GraphRelation.related) {
        final count = math.max(1, (delta.distance / 14).ceil());
        for (var i = 0; i < count; i++) {
          canvas.drawLine(
            start + delta * (i / count),
            start + delta * ((i + 0.55) / count),
            paint,
          );
        }
      } else {
        canvas.drawLine(start, end, paint);
        final angle = math.atan2(delta.dy, delta.dx);
        for (final offset in [-0.5, 0.5]) {
          canvas.drawLine(
            end,
            end -
                Offset(math.cos(angle + offset), math.sin(angle + offset)) * 12,
            paint,
          );
        }
      }
      final label = TextPainter(
        text: TextSpan(
          text: _edgeLabels[edge.relation],
          style: labelStyle.copyWith(
            color: paint.color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final midpoint = (start + end) / 2;
      final rect = Rect.fromCenter(
        center: midpoint,
        width: label.width + 12,
        height: label.height + 6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        Paint()..color = const Color(0xffedf2f5),
      );
      label.paint(canvas, midpoint - Offset(label.width / 2, label.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) =>
      oldDelegate.graph != graph ||
      oldDelegate.layout != layout ||
      oldDelegate.labelStyle != labelStyle;
}
