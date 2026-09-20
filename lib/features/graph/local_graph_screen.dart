import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/knowledge_document.dart';
import '../../domain/knowledge_graph.dart';

const _courseNodeSize = Size(190, 190);
const _smallNodeSize = Size(104, 104);
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
                              width: _nodeSizeFor(node, _graph.focus.id).width,
                              height: _nodeSizeFor(
                                node,
                                _graph.focus.id,
                              ).height,
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
                'Môn học ở giữa · concept, môn liên quan và note ở xung quanh. Click node để mở nội dung.',
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
        shape: CircleBorder(
          side: BorderSide(
            color: focused ? const Color(0xff136f63) : color,
            width: focused ? 3 : 1.5,
          ),
        ),
        child: InkWell(
          key: ValueKey('graph-node:${document.id}'),
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(focused ? 28 : 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: focused
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
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

Size _nodeSizeFor(KnowledgeDocument document, String focusId) =>
    document.id == focusId ? _courseNodeSize : _smallNodeSize;

/// Stable radial layout with the selected course at the center.
class _GraphLayout {
  _GraphLayout(LocalKnowledgeGraph graph) {
    final neighbors = graph.nodes.skip(1).toList();
    final radius = math.max(280.0, neighbors.length * 38.0);
    final width = math.max(760.0, radius * 2 + 260);
    final height = math.max(680.0, radius * 2 + 260);
    size = Size(width, height);
    final center = Offset(width / 2, height / 2);
    positions[graph.focus.id] = center - _centerOf(_courseNodeSize);
    for (var index = 0; index < neighbors.length; index++) {
      final angle = -math.pi / 2 + (math.pi * 2 * index / neighbors.length);
      final nodeCenter =
          center + Offset(math.cos(angle), math.sin(angle)) * radius;
      positions[neighbors[index].id] = nodeCenter - _centerOf(_smallNodeSize);
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
    final isFocus =
        center ==
        layout.positions[graph.focus.id]! + _centerOf(_courseNodeSize);
    final halfWidth = isFocus
        ? _courseNodeSize.width / 2
        : _smallNodeSize.width / 2;
    final halfHeight = isFocus
        ? _courseNodeSize.height / 2
        : _smallNodeSize.height / 2;
    final ratio = math.min(
      halfWidth / math.max(delta.dx.abs(), 0.001),
      halfHeight / math.max(delta.dy.abs(), 0.001),
    );
    return center + delta * ratio;
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in graph.edges) {
      final a =
          layout.positions[edge.sourceId]! +
          _centerOf(_nodeSizeForId(edge.sourceId));
      final b =
          layout.positions[edge.targetId]! +
          _centerOf(_nodeSizeForId(edge.targetId));
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
    }
  }

  Size _nodeSizeForId(String id) =>
      id == graph.focus.id ? _courseNodeSize : _smallNodeSize;

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) =>
      oldDelegate.graph != graph ||
      oldDelegate.layout != layout ||
      oldDelegate.labelStyle != labelStyle;
}

Offset _centerOf(Size size) => Offset(size.width / 2, size.height / 2);
