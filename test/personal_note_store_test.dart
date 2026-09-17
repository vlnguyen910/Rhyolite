import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rhyolite/data/knowledge_repository.dart';
import 'package:rhyolite/data/personal_note_store.dart';
import 'package:rhyolite/domain/knowledge_document.dart';
import 'package:rhyolite/domain/knowledge_graph.dart';

class FailingStore extends PersonalNoteStore {
  FailingStore(Directory directory) : super(directory: directory);
  @override
  Future<void> writeAtomically(File target, String content) async =>
      throw const FileSystemException('Simulated disk failure');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late PersonalNoteStore store;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('rhyolite-notes-test-');
    store = PersonalNoteStore(directory: directory);
  });
  tearDown(() async => directory.delete(recursive: true));

  test(
    'Notes persist on reopening, preserve YAML characters and use stable IDs',
    () async {
      final note = await store.save(
        title: 'Flutter: "Câu hỏi" #1',
        body: '# Widget\n\nState **changes**\n[[concept:flutter|Flutter]]',
        related: ['course:PRM393'],
      );
      final reopened = PersonalNoteStore(directory: directory);
      final files = await reopened.load();
      final snapshot = const KnowledgeRepository().build(files.files);
      expect(files.issues, isEmpty);
      expect(snapshot.notes.single.title, note.title);
      expect(snapshot.notes.single.body, note.body);
      expect(snapshot.notes.single.relatedTargets, ['course:PRM393']);
      final edited = await reopened.save(
        title: 'Renamed',
        body: 'Revised',
        related: ['concept:flutter'],
        original: snapshot.notes.single,
      );
      expect(edited.id, note.id);
      expect(edited.path, note.path);
      expect((await reopened.load()).files.length, 1);
      expect(
        await File(p.join(directory.path, '${note.path.split('/').last}.bak'))
            .readAsString(),
        note.sourceMarkdown,
      );
    },
  );

  test('Same title creates distinct files; invalid title and foreign paths cannot overwrite', () async {
    final a = await store.save(title: 'Same', body: 'A', related: []);
    final b = await store.save(title: 'Same', body: 'B', related: []);
    expect(a.id, isNot(b.id));
    expect((await store.load()).files.length, 2);
    await expectLater(
      store.save(title: ' ', body: 'bad', related: [], original: a),
      throwsFormatException,
    );
    const foreign = KnowledgeDocument(
      id: 'note:outside',
      type: DocumentType.note,
      title: 'Foreign',
      path: 'notes/../../outside.md',
      body: '',
      sourceMarkdown: '',
    );
    await expectLater(
      store.save(title: 'Bad', body: 'bad', related: [], original: foreign),
      throwsFormatException,
    );
    expect((await store.load()).files[a.path], a.sourceMarkdown);
  });

  test('External edits and disk failures preserve stored content', () async {
    final note = await store.save(title: 'Original', body: 'Safe', related: []);
    await expectLater(
      FailingStore(directory)
          .save(title: 'Changed', body: 'Draft', related: [], original: note),
      throwsA(isA<FileSystemException>()),
    );
    final target = File(p.join(directory.path, note.path.split('/').last));
    expect(await target.readAsString(), note.sourceMarkdown);
    await target.writeAsString('${note.sourceMarkdown}\nExternal edit');
    await expectLater(
      store.save(title: 'Changed', body: 'Draft', related: [], original: note),
      throwsA(isA<FileSystemException>()),
    );
    expect(await target.readAsString(), contains('External edit'));
  });

  test(
    'Interrupted replacement restores backup; malformed note is isolated',
    () async {
      final note = await store.save(
        title: 'Original',
        body: 'Safe',
        related: [],
      );
      await store.save(
        title: 'New',
        body: 'New body',
        related: [],
        original: note,
      );
      await File(p.join(directory.path, note.path.split('/').last)).delete();
      await File(p.join(directory.path, '${'f' * 32}.md'))
          .writeAsString('---\ntype: course\n---');
      final recovered = await store.load();
      expect(recovered.files[note.path], note.sourceMarkdown);
      expect(
        recovered.issues
            .where((issue) => issue.severity == IssueSeverity.error)
            .length,
        1,
      );
      expect(
        recovered.issues.any((issue) => issue.message.contains('khôi phục')),
        isTrue,
      );
    },
  );

  test(
    'Rename failure cleans temporary file and keeps target intact',
    () async {
      final target = Directory(p.join(directory.path, 'blocked.md'));
      await target.create();
      await expectLater(
        store.writeAtomically(File(target.path), 'Draft'),
        throwsA(isA<FileSystemException>()),
      );
      expect(await target.exists(), isTrue);
      expect(
        directory.listSync().where((entry) => entry.path.endsWith('.tmp')),
        isEmpty,
      );
    },
  );

  test(
    'Bundled courses plus personal notes produce backlinks and graph nodes',
    () async {
      final note = await store.save(
        title: 'My PRM notes',
        body: 'Read [[concept:flutter]]',
        related: ['course:PRM393'],
      );
      final snapshot = await KnowledgeRepository(noteStore: store).load();
      expect(snapshot.courses.where((course) => !course.demo).length, 76);
      expect(snapshot.notes.single.id, note.id);
      final course = snapshot.resolve('course:PRM393')!;
      final concept = snapshot.resolve('concept:flutter')!;
      expect(snapshot.notesFor(course).single.id, note.id);
      expect(snapshot.notesFor(concept).single.id, note.id);
      final graph = KnowledgeGraphService(snapshot).localGraph(course);
      expect(graph.nodes.any((node) => node.id == note.id), isTrue);
      expect(
        graph.edges.any(
          (edge) =>
              edge.relation == GraphRelation.related &&
              (edge.sourceId == note.id || edge.targetId == note.id),
        ),
        isTrue,
      );
    },
  );
}
