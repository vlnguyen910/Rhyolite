import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/knowledge_document.dart';
import '../../domain/knowledge_graph.dart';
import '../../domain/overview_graph_layout.dart';

const _colors = {
  GraphRelation.prerequisite: Color(0xff2767b0),
  GraphRelation.topic: Color(0xffb96516),
  GraphRelation.related: Color(0xff7955b0),
};

class OverviewGraphView extends StatefulWidget {
  const OverviewGraphView({
    super.key,
    required this.snapshot,
    required this.onOpen,
    this.includeDemo = false,
    required this.onDemoChanged,
  });
  final KnowledgeSnapshot snapshot;
  final ValueChanged<KnowledgeDocument> onOpen;
  final bool includeDemo;
  final ValueChanged<bool> onDemoChanged;
  @override
  State<OverviewGraphView> createState() => _OverviewGraphViewState();
}

class _OverviewGraphViewState extends State<OverviewGraphView>
    with AutomaticKeepAliveClientMixin {
  final _transform = TransformationController();
  late OverviewKnowledgeGraph _graph;
  late OverviewGraphLayout _layout;
  bool _concepts = false;
  bool _notes = false;
  bool _onlyRelated = true;
  String? _selectedId;
  bool _pendingCenter = false;
  Size _viewport = Size.zero;

  KnowledgeDocument? get _selected => _selectedId == null
      ? null
      : _graph.nodes.where((node) => node.id == _selectedId).firstOrNull;
  Set<String> get _neighbors => {
    ?_selectedId,
    for (final edge in _graph.edges)
      if (edge.sourceId == _selectedId)
        edge.targetId
      else if (edge.targetId == _selectedId)
        edge.sourceId,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _rebuild();
  }

  @override
  void didUpdateWidget(OverviewGraphView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot != widget.snapshot ||
        oldWidget.includeDemo != widget.includeDemo) {
      _rebuild();
    }
  }

  void _rebuild() {
    _graph = KnowledgeGraphService(widget.snapshot).overviewGraph(
      includeConcepts: _concepts,
      includeNotes: _notes,
      includeDemo: widget.includeDemo,
    );
    _layout = OverviewGraphLayout(_graph);
    if (_selected == null) _selectedId = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fit();
    });
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
          (_viewport.width - 32) / _layout.width,
          (_viewport.height - 32) / _layout.height,
        )
        .clamp(.02, 1.0);
    _transform.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        (_viewport.width - _layout.width * scale) / 2,
        (_viewport.height - _layout.height * scale) / 2,
        0,
      );
  }

  void _zoom(double factor) {
    final old = _transform.value;
    final next = (old.storage[0] * factor).clamp(.02, 3.0);
    final ratio = next / old.storage[0];
    _transform.value = Matrix4.diagonal3Values(next, next, 1)
      ..setTranslationRaw(
        _viewport.width / 2 - (_viewport.width / 2 - old.storage[12]) * ratio,
        _viewport.height / 2 - (_viewport.height / 2 - old.storage[13]) * ratio,
        0,
      );
  }

  void _select(KnowledgeDocument node, {bool center = false}) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _selectedId = node.id;
      _pendingCenter = center;
    });
  }

  void _centerSelected() {
    if (_selected == null || _viewport.isEmpty) return;
    final point = _layout.positions[_selectedId]!;
    _transform.value = Matrix4.identity()
      ..setTranslationRaw(
        _viewport.width / 2 - point.x - OverviewGraphLayout.nodeWidth / 2,
        _viewport.height / 2 - point.y - OverviewGraphLayout.nodeHeight / 2,
        0,
      );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final selected = _selected;
    final neighbors = _neighbors;
    final edges = _graph.edges
        .where(
          (edge) =>
              selected == null ||
              !_onlyRelated ||
              edge.sourceId == selected.id ||
              edge.targetId == selected.id,
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 280,
                child: Autocomplete<KnowledgeDocument>(
                  key: ObjectKey(_graph),
                  displayStringForOption: (node) => node.code ?? node.title,
                  optionsBuilder: (value) {
                    final query = value.text.trim().toLowerCase();
                    if (query.isEmpty) {
                      return const Iterable<KnowledgeDocument>.empty();
                    }
                    return _graph.nodes
                        .where(
                          (node) => '${node.code ?? ''} ${node.title}'
                              .toLowerCase()
                              .contains(query),
                        )
                        .take(12);
                  },
                  onSelected: (node) => _select(node, center: true),
                  fieldViewBuilder: (_, controller, focus, submit) => TextField(
                    key: const ValueKey('overview-search'),
                    controller: controller,
                    focusNode: focus,
                    onSubmitted: (_) => submit(),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Tìm node trên graph',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  optionsViewBuilder: (context, onSelected, options) => Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 360,
                        height: math.min(options.length, 5) * 64.0,
                        child: ListView(
                          children: [
                            for (final node in options)
                              ListTile(
                                key: ValueKey('overview-result:${node.id}'),
                                selected:
                                    options.toList().indexOf(node) ==
                                    AutocompleteHighlightedOption.of(context),
                                dense: true,
                                title: Text(node.code ?? node.title),
                                subtitle: Text(
                                  node.code == null
                                      ? node.type.name
                                      : node.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => onSelected(node),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              FilterChip(
                key: const ValueKey('overview-concepts'),
                label: const Text('Concept'),
                selected: _concepts,
                onSelected: (value) => setState(() {
                  _concepts = value;
                  _rebuild();
                }),
              ),
              FilterChip(
                key: const ValueKey('overview-notes'),
                label: const Text('My Notes'),
                selected: _notes,
                onSelected: (value) => setState(() {
                  _notes = value;
                  _rebuild();
                }),
              ),
              FilterChip(
                key: const ValueKey('overview-demo'),
                label: const Text('Demo'),
                selected: widget.includeDemo,
                onSelected: widget.onDemoChanged,
              ),
              IconButton(
                tooltip: 'Thu nhỏ graph tổng quan',
                onPressed: () => _zoom(1 / 1.3),
                icon: const Icon(Icons.zoom_out),
              ),
              IconButton(
                tooltip: 'Phóng to graph tổng quan',
                onPressed: () => _zoom(1.3),
                icon: const Icon(Icons.zoom_in),
              ),
              IconButton(
                tooltip: 'Vừa khung graph tổng quan',
                onPressed: _fit,
                icon: const Icon(Icons.fit_screen),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${_graph.nodes.length} node · ${edges.length}/${_graph.edges.length} liên kết',
                key: const ValueKey('overview-count'),
              ),
              _legend('A → B: A cần B', GraphRelation.prerequisite),
              if (_concepts) _legend('Môn → concept', GraphRelation.topic),
              if (_concepts || _notes)
                _legend('Liên kết tham khảo', GraphRelation.related),
            ],
          ),
        ),
        if (selected != null)
          Container(
            key: const ValueKey('overview-selection'),
            color: Theme.of(context).colorScheme.primaryContainer
                .withValues(alpha: .45),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${selected.code == null ? '' : '${selected.code} · '}${selected.title}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('Chỉ dây liên quan'),
                      selected: _onlyRelated,
                      onSelected: (value) =>
                          setState(() => _onlyRelated = value),
                    ),
                    TextButton.icon(
                      onPressed: _centerSelected,
                      icon: const Icon(Icons.center_focus_strong),
                      label: const Text('Đến node'),
                    ),
                    TextButton.icon(
                      key: const ValueKey('overview-open'),
                      onPressed: () => widget.onOpen(selected),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Mở chi tiết'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedId = null),
                      child: const Text('Bỏ chọn'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        Expanded(
          child: _graph.nodes.isEmpty
              ? const Center(child: Text('Chưa có node để hiển thị.'))
              : ColoredBox(
                  color: const Color(0xffedf2f5),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (_viewport != constraints.biggest || _pendingCenter) {
                        _viewport = constraints.biggest;
                        final center = _pendingCenter;
                        _pendingCenter = false;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          if (center) {
                            _centerSelected();
                          } else {
                            _fit();
                          }
                        });
                      }
                      return ClipRect(
                        child: InteractiveViewer(
                          key: const ValueKey('overview-graph-viewer'),
                          transformationController: _transform,
                          constrained: false,
                          alignment: Alignment.topLeft,
                          minScale: .02,
                          maxScale: 3,
                          boundaryMargin: const EdgeInsets.all(1500),
                          child: RepaintBoundary(
                            child: SizedBox(
                              width: _layout.width,
                              height: _layout.height,
                              child: Stack(
                                children: [
                                  for (
                                    var column = 0;
                                    column < _layout.columns.length;
                                    column++
                                  )
                                    Positioned(
                                      left:
                                          OverviewGraphLayout.padding +
                                          column *
                                              OverviewGraphLayout.columnStep -
                                          8,
                                      top: _layout.headerY,
                                      width: OverviewGraphLayout.nodeWidth + 16,
                                      height:
                                          _layout.height - _layout.headerY - 16,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: .65,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Align(
                                          alignment: Alignment.topCenter,
                                          child: Text(
                                            _layout.columns[column].label,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _OverviewPainter(
                                        layout: _layout,
                                        edges: edges,
                                        selectedId: selected?.id,
                                        isolate: _onlyRelated,
                                      ),
                                    ),
                                  ),
                                  for (final node in _graph.nodes)
                                    Positioned(
                                      left: _layout.positions[node.id]!.x,
                                      top: _layout.positions[node.id]!.y,
                                      width: OverviewGraphLayout.nodeWidth,
                                      height: OverviewGraphLayout.nodeHeight,
                                      child: _OverviewNode(
                                        node: node,
                                        selected: selected?.id == node.id,
                                        dimmed:
                                            selected != null &&
                                            !neighbors.contains(node.id),
                                        onSelect: () => _select(node),
                                        onOpen: () => widget.onOpen(node),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Column(
            children: [
              Text(
                'Click chọn · Double-click mở · Kéo để di chuyển · Cuộn để zoom',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
              Text(
                'Các học kỳ có thể chứa phiên bản môn thay thế. Xem điều kiện AND/OR trong syllabus.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legend(String text, GraphRelation relation) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        relation == GraphRelation.related
            ? Icons.more_horiz
            : Icons.arrow_right_alt,
        color: _colors[relation],
        size: 20,
      ),
      const SizedBox(width: 4),
      Text(text),
    ],
  );
}

class _OverviewNode extends StatelessWidget {
  const _OverviewNode({
    required this.node,
    required this.selected,
    required this.dimmed,
    required this.onSelect,
    required this.onOpen,
  });
  final KnowledgeDocument node;
  final bool selected;
  final bool dimmed;
  final VoidCallback onSelect;
  final VoidCallback onOpen;
  @override
  Widget build(BuildContext context) {
    final color = switch (node.type) {
      DocumentType.concept => _colors[GraphRelation.topic]!,
      DocumentType.note => _colors[GraphRelation.related]!,
      _ => _colors[GraphRelation.prerequisite]!,
    };
    return Tooltip(
      message: '${node.code == null ? '' : '${node.code} · '}${node.title}',
      child: Opacity(
        opacity: dimmed ? .38 : 1,
        child: Material(
          color: selected ? const Color(0xffd9eee7) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9),
            side: BorderSide(
              color: selected ? const Color(0xff136f63) : color,
              width: selected ? 3 : 1.4,
            ),
          ),
          child: InkWell(
            key: ValueKey('overview-node:${node.id}'),
            onTap: onSelect,
            onDoubleTap: onOpen,
            borderRadius: BorderRadius.circular(9),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  node.code ?? node.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: node.code == null ? 12 : 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewPainter extends CustomPainter {
  const _OverviewPainter({
    required this.layout,
    required this.edges,
    required this.selectedId,
    required this.isolate,
  });
  final OverviewGraphLayout layout;
  final List<KnowledgeEdge> edges;
  final String? selectedId;
  final bool isolate;

  @override
  void paint(Canvas canvas, Size size) {
    final visible = edges.toSet();
    final routes =
        layout.routes.where((route) => visible.contains(route.edge)).toList()
          ..sort((a, b) => _focused(a.edge).compareTo(_focused(b.edge)));
    for (final route in routes) {
      final points = route.points
          .map((point) => Offset(point.x, point.y))
          .toList();
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      if (route.bezier) {
        path.cubicTo(
          points[1].dx,
          points[1].dy,
          points[2].dx,
          points[2].dy,
          points[3].dx,
          points[3].dy,
        );
      } else {
        for (var i = 1; i < points.length; i++) {
          if (i == points.length - 1) {
            path.lineTo(points[i].dx, points[i].dy);
            continue;
          }
          final corner = points[i];
          final before = corner - points[i - 1];
          final after = points[i + 1] - corner;
          final radius = math.min(
            6.0,
            math.min(before.distance, after.distance) / 2,
          );
          final entry = corner - before / before.distance * radius;
          final exit = corner + after / after.distance * radius;
          path.lineTo(entry.dx, entry.dy);
          path.quadraticBezierTo(corner.dx, corner.dy, exit.dx, exit.dy);
        }
      }
      final focused = _focused(route.edge) == 1;
      final alpha = selectedId == null
          ? .6
          : focused
          ? 1.0
          : .12;
      final stroke = focused ? 2.5 : 1.5;
      final paint = Paint()
        ..color = _colors[route.edge.relation]!.withValues(alpha: alpha)
        ..strokeWidth = stroke
        ..style = PaintingStyle.stroke;
      // Light casing separates wires where they must cross.
      if (selectedId == null || focused) {
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xffedf2f5)
            ..strokeWidth = stroke + 2.5
            ..style = PaintingStyle.stroke,
        );
      }
      if (route.edge.relation == GraphRelation.related) {
        for (final metric in path.computeMetrics()) {
          for (var distance = 0.0; distance < metric.length; distance += 11) {
            canvas.drawPath(
              metric.extractPath(
                distance,
                math.min(distance + 6, metric.length),
              ),
              paint,
            );
          }
        }
      } else {
        canvas.drawPath(path, paint);
        final tangent = path.computeMetrics().last.getTangentForOffset(
          path.computeMetrics().last.length,
        );
        if (tangent == null) continue;
        final end = tangent.position;
        final direction = tangent.vector;
        final normal = Offset(-direction.dy, direction.dx);
        canvas.drawPath(
          Path()
            ..moveTo(end.dx, end.dy)
            ..lineTo(
              (end - direction * 8 + normal * 4).dx,
              (end - direction * 8 + normal * 4).dy,
            )
            ..lineTo(
              (end - direction * 8 - normal * 4).dx,
              (end - direction * 8 - normal * 4).dy,
            )
            ..close(),
          Paint()..color = paint.color,
        );
      }
    }
  }

  int _focused(KnowledgeEdge edge) =>
      selectedId != null &&
          (edge.sourceId == selectedId || edge.targetId == selectedId)
      ? 1
      : 0;

  @override
  bool shouldRepaint(_OverviewPainter oldDelegate) =>
      oldDelegate.layout != layout ||
      oldDelegate.selectedId != selectedId ||
      oldDelegate.isolate != isolate;
}
