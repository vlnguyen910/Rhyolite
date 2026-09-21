import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';
import '../../domain/models/curriculum_catalog.dart';
import '../../domain/models/student_transcript.dart';
import '../../services/transcript_service.dart';

class TranscriptPage extends StatefulWidget {
  const TranscriptPage({
    super.key,
    required this.courses,
    required this.onTranscriptChanged,
    this.parser,
    this.repository,
  });

  final List<CurriculumCourse> courses;
  final ValueChanged<StudentTranscript?> onTranscriptChanged;
  final ITranscriptParser? parser;
  final ITranscriptRepository? repository;

  @override
  State<TranscriptPage> createState() => _TranscriptPageState();
}

class _TranscriptPageState extends State<TranscriptPage> {
  late final ITranscriptParser _parser;
  late final ITranscriptRepository _repository;
  StudentTranscript? _saved;
  StudentTranscript? _preview;
  bool _loading = true;
  bool _importing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _parser = widget.parser ?? FapTranscriptParser();
    _repository = widget.repository ?? TranscriptRepository();
    _load();
  }

  Future<void> _load() async {
    try {
      final stored = await _repository.load();
      final transcript = stored?.matchCurriculum(
        widget.courses.map((course) => course.code),
      );
      if (!mounted) return;
      setState(() {
        _saved = transcript;
        _loading = false;
      });
      widget.onTranscriptChanged(transcript);
    } on Object {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void didUpdateWidget(covariant TranscriptPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.courses == widget.courses || _saved == null) return;
    final updated = _saved!.matchCurriculum(
      widget.courses.map((course) => course.code),
    );
    _saved = updated;
  }

  Future<void> _pickFile() async {
    setState(() {
      _importing = true;
      _error = null;
    });
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Chọn Academic Transcript từ FAP',
        type: FileType.custom,
        allowedExtensions: const ['xls', 'xlsx'],
        windowsOptions: const WindowsOptions(acceptLabel: 'Import'),
        linuxOptions: const LinuxOptions(acceptLabel: 'Import'),
      );
      if (file == null || !mounted) {
        if (mounted) setState(() => _importing = false);
        return;
      }
      if (file.path == null) {
        throw const TranscriptImportException(
          'Không đọc được đường dẫn của file đã chọn.',
        );
      }
      final preview = await _parser.parseFile(file.path!, widget.courses);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _importing = false;
      });
    } on TranscriptImportException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _importing = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể import file. Hãy kiểm tra lại file Excel từ FAP.';
        _importing = false;
      });
    }
  }

  Future<void> _confirmImport() async {
    final preview = _preview;
    if (preview == null) return;
    setState(() => _importing = true);
    try {
      await _repository.save(preview);
      if (!mounted) return;
      setState(() {
        _saved = preview;
        _preview = null;
        _importing = false;
      });
      widget.onTranscriptChanged(preview);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã import và gắn điểm vào các môn học.')),
      );
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể lưu bảng điểm trên máy.';
        _importing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final transcript = _preview ?? _saved;
    return CustomScrollView(
      key: const PageStorageKey('transcript-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          sliver: SliverList.list(
            children: [
              _ImportHero(
                importing: _importing,
                hasTranscript: _saved != null,
                onImport: _pickFile,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _error!),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (transcript == null)
                const _EmptyTranscript()
              else ...[
                _TranscriptSummary(
                  transcript: transcript,
                  preview: _preview != null,
                  importing: _importing,
                  onConfirm: _confirmImport,
                  onCancel: () => setState(() => _preview = null),
                ),
                const SizedBox(height: AppSpacing.lg),
                _TranscriptRecords(transcript: transcript),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ImportHero extends StatelessWidget {
  const _ImportHero({
    required this.importing,
    required this.hasTranscript,
    required this.onImport,
  });

  final bool importing;
  final bool hasTranscript;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) => Card(
    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .5),
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 720;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.table_view_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Bảng điểm học tập',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Vào FAP → Academic Transcript → cuộn xuống cuối trang → '
                'Export to Excel, sau đó import file vào đây.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'File được xử lý và lưu cục bộ trên máy.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
          final button = FilledButton.icon(
            key: const ValueKey('transcript-import-button'),
            onPressed: importing ? null : onImport,
            icon: importing
                ? const SizedBox.square(
                    dimension: 17,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            label: Text(hasTranscript ? 'Import lại' : 'Chọn file Excel'),
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [content, const SizedBox(height: 18), button],
            );
          }
          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: 24),
              button,
            ],
          );
        },
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
  );
}

class _EmptyTranscript extends StatelessWidget {
  const _EmptyTranscript();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.description_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 14),
            const Text(
              'Chưa có bảng điểm',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Import file Academic Transcript để gắn điểm vào chương trình học.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TranscriptSummary extends StatelessWidget {
  const _TranscriptSummary({
    required this.transcript,
    required this.preview,
    required this.importing,
    required this.onConfirm,
    required this.onCancel,
  });

  final StudentTranscript transcript;
  final bool preview;
  final bool importing;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final records = transcript.records;
    final matched = records.where((record) => record.matchesCurriculum).length;
    final passed = records.where((record) => record.isPassed).length;
    final unmatched = records.length - matched;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview
                            ? 'Kiểm tra trước khi lưu'
                            : 'Bảng điểm đã import',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        transcript.sourceFileName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (preview)
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: importing ? null : onCancel,
                        child: const Text('Hủy'),
                      ),
                      FilledButton.icon(
                        key: const ValueKey('transcript-confirm-button'),
                        onPressed: importing ? null : onConfirm,
                        icon: const Icon(Icons.check),
                        label: const Text('Xác nhận import'),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _SummaryMetric(
                  label: 'Dòng môn học',
                  value: '${records.length}',
                ),
                _SummaryMetric(label: 'Đã ghép curriculum', value: '$matched'),
                _SummaryMetric(label: 'Đã qua', value: '$passed'),
                _SummaryMetric(
                  label: 'Cần kiểm tra',
                  value: '$unmatched',
                  warning: unmatched > 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    this.warning = false,
  });

  final String label;
  final String value;
  final bool warning;

  @override
  Widget build(BuildContext context) => Container(
    width: 170,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: warning
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _TranscriptRecords extends StatelessWidget {
  const _TranscriptRecords({required this.transcript});
  final StudentTranscript transcript;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chi tiết môn học',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Các môn không có trong curriculum đang chọn vẫn được giữ để bạn kiểm tra.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < transcript.records.length; index++) ...[
            _TranscriptRecordTile(record: transcript.records[index]),
            if (index != transcript.records.length - 1)
              const Divider(height: 1),
          ],
        ],
      ),
    ),
  );
}

class _TranscriptRecordTile extends StatelessWidget {
  const _TranscriptRecordTile({required this.record});
  final TranscriptRecord record;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context, record.status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              record.grade.isEmpty ? '—' : record.grade,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.subjectCode,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  record.subjectName.isEmpty
                      ? 'Chưa có tên môn'
                      : record.subjectName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  [
                    record.semester,
                    if (record.credit.isNotEmpty) '${record.credit} tín chỉ',
                  ].where((value) => value.isNotEmpty).join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!record.matchesCurriculum)
            const Chip(
              avatar: Icon(Icons.warning_amber_rounded, size: 17),
              label: Text('Chưa khớp'),
            ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              record.status.isEmpty ? 'Chưa rõ' : record.status,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(BuildContext context, String status) {
  switch (status.trim().toLowerCase()) {
    case 'passed':
      return Theme.of(context).extension<KnowledgeColors>()!.success;
    case 'not passed':
    case 'failed':
      return Theme.of(context).colorScheme.error;
    case 'studying':
      return Theme.of(context).colorScheme.primary;
    default:
      return Theme.of(context).colorScheme.outline;
  }
}
