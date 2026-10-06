import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/views/widgets/obsidian_graph_view.dart';

void main() {
  testWidgets('graph nodes can be selected and dragged on the canvas', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ObsidianGraphView(
            nodes: const [
              ObsidianGraphNode(
                id: 'A',
                label: 'A',
                group: 'one',
                color: Colors.blue,
                keyPrefix: 'node',
              ),
              ObsidianGraphNode(
                id: 'B',
                label: 'B',
                group: 'two',
                color: Colors.orange,
                keyPrefix: 'node',
              ),
            ],
            edges: const [ObsidianGraphEdge('A', 'B')],
            onTapNode: (id) => selected = id,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final node = find.byKey(const ValueKey('node:A'));
    await tester.tap(node);
    expect(selected, 'A');

    final before = tester.getCenter(node);
    await tester.drag(node, const Offset(70, 40));
    await tester.pumpAndSettle();
    expect((tester.getCenter(node) - before).distance, greaterThan(30));
  });
}
