import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Một node trên canvas. Anchor dùng tọa độ tương đối (0..1) khi muốn đặt cụm.
class ObsidianGraphNode {
  const ObsidianGraphNode({
    required this.id,
    required this.label,
    required this.group,
    required this.color,
    required this.keyPrefix,
    this.keyValue,
    this.subtitle,
    this.anchor,
    this.isFocus = false,
  });

  final String id;
  final String label;
  final String? subtitle;
  final String group;
  final Color color;
  final String keyPrefix;
  final String? keyValue;
  final Offset? anchor;
  final bool isFocus;
}

class ObsidianGraphEdge {
  const ObsidianGraphEdge(this.from, this.to, {this.color});

  final String from;
  final String to;
  final Color? color;
}

class ObsidianGraphView extends StatefulWidget {
  const ObsidianGraphView({
    super.key,
    required this.nodes,
    required this.edges,
    required this.onTapNode,
    this.selectedId,
    this.query = '',
    this.showEdges = true,
    this.viewerKey,
  });

  final List<ObsidianGraphNode> nodes;
  final List<ObsidianGraphEdge> edges;
  final ValueChanged<String> onTapNode;
  final String? selectedId;
  final String query;
  final bool showEdges;
  final Key? viewerKey;

  @override
  ObsidianGraphViewState createState() => ObsidianGraphViewState();
}

class ObsidianGraphViewState extends State<ObsidianGraphView> {
  final _transform = TransformationController();
  Map<String, Offset> _positions = {};
  Size _worldSize = Size.zero;
  Size _viewportSize = Size.zero;
  String _layoutSignature = '';
  String? _hoveredId;
  bool _initialFitScheduled = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  void zoom(double factor) {
    if (_viewportSize.isEmpty) return;
    final currentScale = _transform.value.getMaxScaleOnAxis();
    final targetScale = (currentScale * factor).clamp(.25, 3.0);
    final focal = _viewportSize.center(Offset.zero);
    final scenePoint = _transform.toScene(focal);
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        focal.dx - scenePoint.dx * targetScale,
        focal.dy - scenePoint.dy * targetScale,
        0,
        1,
      )
      ..scaleByDouble(targetScale, targetScale, 1, 1);
  }

  void fit() {
    if (_viewportSize.isEmpty || _worldSize.isEmpty) return;
    final scale = math
        .min(
          _viewportSize.width / _worldSize.width,
          _viewportSize.height / _worldSize.height,
        )
        .clamp(.25, 1.0);
    _transform.value = Matrix4.identity()
      ..translateByDouble(
        (_viewportSize.width - _worldSize.width * scale) / 2,
        (_viewportSize.height - _worldSize.height * scale) / 2,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _ensureLayout(Size viewport) {
    final world = Size(
      math.max(1500, viewport.width * 1.18),
      math.max(1050, viewport.height * 1.18),
    );
    final signature = widget.nodes
        .map(
          (node) => '${node.id}:${node.group}:${node.anchor}:${node.isFocus}',
        )
        .join('|');
    final shouldRebuild = signature != _layoutSignature || world != _worldSize;
    _viewportSize = viewport;
    if (!shouldRebuild) return;
    _worldSize = world;
    _layoutSignature = signature;
    _positions = _GraphLayout.compute(world, widget.nodes, widget.edges);
    if (!_initialFitScheduled) {
      _initialFitScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initialFitScheduled = false;
        if (mounted) fit();
      });
    }
  }

  void _moveNode(String id, DragUpdateDetails details) {
    final current = _positions[id];
    if (current == null) return;
    final scale = _transform.value.getMaxScaleOnAxis();
    setState(() {
      _positions = {
        ..._positions,
        id: Offset(
          (current.dx + details.delta.dx / scale).clamp(
            28,
            _worldSize.width - 28,
          ),
          (current.dy + details.delta.dy / scale).clamp(
            28,
            _worldSize.height - 28,
          ),
        ),
      };
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewport = Size(constraints.maxWidth, constraints.maxHeight);
      _ensureLayout(viewport);
      final activeId = widget.selectedId ?? _hoveredId;
      final connected = <String>{?activeId};
      if (activeId != null) {
        for (final edge in widget.edges) {
          if (edge.from == activeId) connected.add(edge.to);
          if (edge.to == activeId) connected.add(edge.from);
        }
      }
      final query = widget.query.trim().toLowerCase();
      final scheme = Theme.of(context).colorScheme;
      return ColoredBox(
        color: scheme.surface,
        child: ClipRect(
          child: InteractiveViewer(
            key: widget.viewerKey,
            transformationController: _transform,
            constrained: false,
            minScale: .25,
            maxScale: 3,
            boundaryMargin: const EdgeInsets.all(500),
            child: SizedBox.fromSize(
              size: _worldSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _GraphPainter(
                        edges: widget.edges,
                        positions: _positions,
                        activeId: activeId,
                        showEdges: widget.showEdges,
                        edgeColor: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  for (final node in widget.nodes)
                    _DotNode(
                      key: ValueKey(
                        '${node.keyPrefix}:${node.keyValue ?? node.id}',
                      ),
                      node: node,
                      center: _positions[node.id]!,
                      selected: node.id == widget.selectedId,
                      hovered: node.id == _hoveredId,
                      dimmed: activeId != null && !connected.contains(node.id),
                      searchMatch:
                          query.isNotEmpty &&
                          '${node.id} ${node.label} ${node.subtitle ?? ''}'
                              .toLowerCase()
                              .contains(query),
                      onTap: () => widget.onTapNode(node.id),
                      onHover: (value) {
                        if (_hoveredId == (value ? node.id : null)) return;
                        setState(() => _hoveredId = value ? node.id : null);
                      },
                      onPanUpdate: (details) => _moveNode(node.id, details),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _DotNode extends StatelessWidget {
  const _DotNode({
    super.key,
    required this.node,
    required this.center,
    required this.selected,
    required this.hovered,
    required this.dimmed,
    required this.searchMatch,
    required this.onTap,
    required this.onHover,
    required this.onPanUpdate,
  });

  final ObsidianGraphNode node;
  final Offset center;
  final bool selected;
  final bool hovered;
  final bool dimmed;
  final bool searchMatch;
  final VoidCallback onTap;
  final ValueChanged<bool> onHover;
  final GestureDragUpdateCallback onPanUpdate;

  @override
  Widget build(BuildContext context) {
    final highlight = selected || hovered || searchMatch;
    final radius = node.isFocus
        ? 17.0
        : highlight
        ? 10.0
        : 6.5;
    final textColor = highlight
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Positioned(
      left: center.dx - 64,
      top: center.dy - 24,
      width: 128,
      height: 68,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: onTap,
          onPanUpdate: onPanUpdate,
          child: Semantics(
            button: true,
            label: '${node.id}: ${node.label}',
            child: Opacity(
              opacity: dimmed && !searchMatch ? .28 : 1,
              child: Column(
                children: [
                  SizedBox(
                    height: 36,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: radius * 2,
                        height: radius * 2,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: node.color,
                          boxShadow: [
                            BoxShadow(
                              color: node.color.withValues(
                                alpha: highlight ? .6 : .35,
                              ),
                              blurRadius: highlight ? 17 : 9,
                              spreadRadius: highlight ? 3 : 1,
                            ),
                          ],
                          border: selected
                              ? Border.all(color: Colors.white, width: 2)
                              : null,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    node.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: node.isFocus ? 13 : 11,
                      fontWeight: highlight || node.isFocus
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  if (highlight && node.subtitle != null)
                    Text(
                      node.subtitle!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: textColor, fontSize: 9),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  const _GraphPainter({
    required this.edges,
    required this.positions,
    required this.activeId,
    required this.showEdges,
    required this.edgeColor,
  });

  final List<ObsidianGraphEdge> edges;
  final Map<String, Offset> positions;
  final String? activeId;
  final bool showEdges;
  final Color edgeColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final active =
          activeId != null && (edge.from == activeId || edge.to == activeId);
      if (!showEdges && !active) continue;
      final from = positions[edge.from];
      final to = positions[edge.to];
      if (from == null || to == null) continue;
      canvas.drawLine(
        from,
        to,
        Paint()
          ..color = active
              ? (edge.color ?? edgeColor).withValues(alpha: .9)
              : edgeColor.withValues(alpha: activeId == null ? .22 : .07)
          ..strokeWidth = active ? 2 : 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter oldDelegate) =>
      oldDelegate.positions != positions ||
      oldDelegate.activeId != activeId ||
      oldDelegate.showEdges != showEdges ||
      oldDelegate.edges != edges ||
      oldDelegate.edgeColor != edgeColor;
}

class _GraphLayout {
  static Map<String, Offset> compute(
    Size size,
    List<ObsidianGraphNode> nodes,
    List<ObsidianGraphEdge> edges,
  ) {
    if (nodes.isEmpty) return {};
    final groups = nodes.map((node) => node.group).toSet().toList()..sort();
    final center = size.center(Offset.zero);
    final anchors = <String, Offset>{};
    for (var index = 0; index < groups.length; index++) {
      final angle = -math.pi / 2 + 2 * math.pi * index / groups.length;
      anchors[groups[index]] = Offset(
        center.dx + math.cos(angle) * size.width * .31,
        center.dy + math.sin(angle) * size.height * .31,
      );
    }
    final positions = <String, Offset>{};
    for (var index = 0; index < nodes.length; index++) {
      final node = nodes[index];
      final anchor = node.anchor == null
          ? anchors[node.group]!
          : Offset(node.anchor!.dx * size.width, node.anchor!.dy * size.height);
      if (node.isFocus) {
        positions[node.id] = center;
        continue;
      }
      final seed = node.id.runes.fold<int>(0, (hash, rune) => hash * 31 + rune);
      final angle = (seed.abs() % 6283) / 1000;
      final radius = 45 + (index % 9) * 15.0;
      positions[node.id] = Offset(
        anchor.dx + math.cos(angle) * radius,
        anchor.dy + math.sin(angle) * radius,
      );
    }

    // Lực đẩy giữ các node tách nhau; lực lò xo giữ liên kết trong cụm.
    for (var step = 0; step < 85; step++) {
      final movement = {for (final node in nodes) node.id: Offset.zero};
      for (var i = 0; i < nodes.length; i++) {
        for (var j = i + 1; j < nodes.length; j++) {
          final first = nodes[i].id;
          final second = nodes[j].id;
          final delta = positions[first]! - positions[second]!;
          final distance = math.max(1.0, delta.distance);
          if (distance > 95) continue;
          final push = delta / distance * ((95 - distance) * .16);
          movement[first] = movement[first]! + push;
          movement[second] = movement[second]! - push;
        }
      }
      for (final edge in edges) {
        final from = positions[edge.from];
        final to = positions[edge.to];
        if (from == null || to == null) continue;
        final delta = to - from;
        final distance = math.max(1.0, delta.distance);
        final pull = delta / distance * ((distance - 125) * .008);
        movement[edge.from] = movement[edge.from]! + pull;
        movement[edge.to] = movement[edge.to]! - pull;
      }
      for (final node in nodes) {
        if (node.isFocus) continue;
        final anchor = node.anchor == null
            ? anchors[node.group]!
            : Offset(
                node.anchor!.dx * size.width,
                node.anchor!.dy * size.height,
              );
        final current = positions[node.id]!;
        final next = current + movement[node.id]! + (anchor - current) * .014;
        positions[node.id] = Offset(
          next.dx.clamp(80, size.width - 80),
          next.dy.clamp(70, size.height - 70),
        );
      }
    }
    return positions;
  }
}
