import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhyolite/services/personal_note_service.dart';

void main() {
  test(
    'personal note persists as Markdown and can be updated and deleted',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'rhyolite-notes-',
      );
      addTearDown(() => temporary.delete(recursive: true));
      final service = PersonalNoteService(rootDirectory: temporary);

      final created = await service.save(
        title: 'Ôn Flutter',
        body: '# Widget tree',
        courseCode: 'PRM393',
      );
      expect(await File(created.path).readAsString(), contains('courseCode'));
      expect(await service.loadForCourse('PRM393'), hasLength(1));
      expect(await service.loadForCourse('PRO192'), isEmpty);
      expect(await service.loadRecent(limit: 1), hasLength(1));

      final updated = await service.save(
        title: 'Ôn Flutter nâng cao',
        body: '# State management',
        courseCode: 'PRM393',
        original: created,
      );
      final loaded = await service.loadForCourse('PRM393');
      expect(loaded, hasLength(1));
      expect(loaded.single.title, 'Ôn Flutter nâng cao');
      expect(loaded.single.body, contains('State management'));

      await service.delete(updated);
      expect(await service.loadForCourse('PRM393'), isEmpty);
    },
  );
}
