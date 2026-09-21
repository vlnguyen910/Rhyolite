import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/models/curriculum_catalog.dart';

abstract class ICurriculumService {
  Future<CurriculumCatalog> loadCatalog();
}

class CurriculumService implements ICurriculumService {
  CurriculumService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/data/curricula.json';

  final AssetBundle _bundle;

  @override
  Future<CurriculumCatalog> loadCatalog() async {
    final source = await _bundle.loadString(assetPath);
    final json = jsonDecode(source);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Curriculum asset must contain an object');
    }
    return CurriculumCatalog.fromJson(json);
  }
}
