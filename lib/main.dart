import 'package:flutter/material.dart';

import 'data/knowledge_repository.dart';
import 'features/knowledge/knowledge_workspace.dart';

void main() => runApp(const RhyoliteApp());

class RhyoliteApp extends StatelessWidget {
  const RhyoliteApp({super.key, this.repository = const KnowledgeRepository()});
  final KnowledgeRepository repository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FPTU SE Knowledge',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff136f63)),
      scaffoldBackgroundColor: const Color(0xfff5f7f8),
      useMaterial3: true,
    ),
    home: KnowledgeWorkspace(repository: repository),
  );
}
