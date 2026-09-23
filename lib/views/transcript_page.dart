import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../design_system/app_theme.dart';
import '../models/curriculum_catalog.dart';
import '../models/student_transcript.dart';
import '../services/transcript_service.dart';

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
  bool _mergeImport = true;
  bool _overwriteManual = false;
  String _semesterFilter = 'Tất cả kỳ';
  String _recordQuery = '';
  String? _error;
  final _recordSearchController = TextEditingController();

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

  @override
  void dispose() {
    _recordSearchController.dispose();
    super.dispose();
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
    final updated =
        _saved?.reimport(
          preview,
          merge: _mergeImport,
          overwriteManual: _overwriteManual,
        ) ??
        preview;
    setState(() => _importing = true);
    try {
      await _repository.save(updated);
      if (!mounted) return;
      setState(() {
        _saved = updated;
        _preview = null;
        _importing = false;
      });
      widget.onTranscriptChanged(updated);
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

  Future<void> _saveEdited(StudentTranscript updated) async {
    setState(() {
      _importing = true;
      _error = null;
    });
    try {
      await _repository.save(updated);
      if (!mounted) return;
      setState(() {
        _saved = updated;
        _importing = false;
      });
      widget.onTranscriptChanged(updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thay đổi bảng điểm trên máy.')),
      );
    } on Object {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể lưu thay đổi bảng điểm.';
        _importing = false;
      });
    }
  }

  Future<void> _editRecord(int index) async {
    final saved = _saved;
    if (saved == null || _importing || _preview != null) return;
    final edit = await showDialog<_TranscriptEdit>(
      context: context,
      builder: (_) => _TranscriptEditDialog(record: saved.records[index]),
    );
    if (edit == null || !mounted) return;
    await _saveEdited(
      saved.editRecord(index, grade: edit.grade, status: edit.status),
    );
  }

  Future<void> _addRecord() async {
    final saved = _saved;
    if (saved == null || _importing || _preview != null) return;
    final existingCodes = saved.latestBySubjectCode.keys.toSet();
    final available =
        widget.courses
            .where(
              (course) => !existingCodes.contains(course.code.toUpperCase()),
            )
            .toList()
          ..sort((a, b) => a.code.compareTo(b.code));
    if (available.isEmpty) return;
    final edit = await showDialog<_TranscriptEdit>(
      context: context,
      builder: (_) => _TranscriptEditDialog(availableCourses: available),
    );
    if (edit == null || edit.course == null || !mounted) return;
    final course = edit.course!;
    await _saveEdited(
      saved.addManualRecord(
        TranscriptRecord(
          term: '',
          semester: '${course.semester}',
          subjectCode: course.code,
          subjectName: course.name,
          prerequisite: course.prerequisiteCodes.join(', '),
          replacedSubject: '',
          credit: '',
          grade: edit.grade,
          status: edit.status,
          matchesCurriculum: true,
          isManual: true,
          editedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _restoreRecord(int index) async {
    final saved = _saved;
    if (saved == null || _importing || _preview != null) return;
    final record = saved.records[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          record.hasFapOriginal ? 'Khôi phục điểm FAP?' : 'Xóa điểm tự nhập?',
        ),
        content: Text(
          record.hasFapOriginal
              ? 'Điểm tự nhập của ${record.subjectCode} sẽ được thay bằng giá trị từ lần import FAP gần nhất.'
              : 'Môn ${record.subjectCode} chưa có trong file FAP. Xóa kết quả tự nhập này?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(record.hasFapOriginal ? 'Khôi phục' : 'Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _saveEdited(saved.restoreRecord(index));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final transcript = _preview ?? _saved;
    final filteredRecords = transcript == null
        ? const <_GradeRecordEntry>[]
        : [
            for (var index = 0; index < transcript.records.length; index++)
              if (_matchesGradebookFilter(transcript.records[index]))
                _GradeRecordEntry(
                  record: transcript.records[index],
                  index: index,
                ),
          ];
    final semesterOptions = transcript == null
        ? const <String>[]
        : _semesterOptions(transcript.records);
    return CustomScrollView(
      key: const PageStorageKey('transcript-scroll'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          sliver: SliverList.list(
            children: [
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBanner(message: _error!),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Bảng điểm',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const Text(
                'Bảng điểm học tập',
                style: TextStyle(
                  fontSize: 0,
                  height: 0,
                  color: Colors.transparent,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Nhập, kiểm tra và quản lý dữ liệu học tập',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (transcript == null)
                _EmptyTranscript(onImport: _pickFile)
              else ...[
                if (_preview != null)
                  _TranscriptSummary(
                    transcript: transcript,
                    existing: _saved,
                    preview: true,
                    importing: _importing,
                    mergeImport: _mergeImport,
                    overwriteManual: _overwriteManual,
                    onMergeChanged: (value) =>
                        setState(() => _mergeImport = value),
                    onOverwriteChanged: (value) =>
                        setState(() => _overwriteManual = value),
                    onConfirm: _confirmImport,
                    onCancel: () => setState(() => _preview = null),
                  )
                else
                  const SizedBox.shrink(),
                const SizedBox(height: AppSpacing.lg),
                _TranscriptRecords(
                  records: filteredRecords,
                  allRecords: transcript.records,
                  importing: _importing,
                  onImport: _pickFile,
                  totalCount: transcript.records.length,
                  semesterFilter: _semesterFilter,
                  semesterOptions: semesterOptions,
                  searchController: _recordSearchController,
                  onSearchChanged: (value) =>
                      setState(() => _recordQuery = value),
                  onSemesterChanged: (value) =>
                      setState(() => _semesterFilter = value),
                  editingEnabled: _preview == null && !_importing,
                  canAdd: _saved != null,
                  onAdd: _addRecord,
                  onEdit: _editRecord,
                  onRestore: _restoreRecord,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  bool _matchesGradebookFilter(TranscriptRecord record) {
    final query = _recordQuery.trim().toLowerCase();
    final matchesQuery =
        query.isEmpty ||
        record.subjectCode.toLowerCase().contains(query) ||
        record.subjectName.toLowerCase().contains(query);
    final matchesSemester =
        _semesterFilter == 'Tất cả kỳ' ||
        record.semester.trim() == _semesterFilter;
    return matchesQuery && matchesSemester;
  }
}

List<String> _semesterOptions(List<TranscriptRecord> records) {
  final values =
      {
        for (final record in records)
          if (record.semester.trim().isNotEmpty) record.semester.trim(),
      }.toList()..sort(
        (left, right) =>
            _semesterNumber(left).compareTo(_semesterNumber(right)),
      );
  return values;
}

String _semesterFilterLabel(String semester, List<TranscriptRecord> records) {
  final term = records
      .where((record) => record.semester.trim() == semester)
      .map((record) => record.term.trim())
      .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  return term.isEmpty ? 'Kỳ $semester' : 'Kỳ $semester · ${_termLabel(term)}';
}

class ImportHero extends StatelessWidget {
  const ImportHero({
    super.key,
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
  const _EmptyTranscript({required this.onImport});

  final VoidCallback onImport;

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
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('transcript-import-button'),
              onPressed: onImport,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Chọn file Excel'),
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
    required this.existing,
    required this.preview,
    required this.importing,
    required this.mergeImport,
    required this.overwriteManual,
    required this.onMergeChanged,
    required this.onOverwriteChanged,
    required this.onConfirm,
    required this.onCancel,
  });

  final StudentTranscript transcript;
  final StudentTranscript? existing;
  final bool preview;
  final bool importing;
  final bool mergeImport;
  final bool overwriteManual;
  final ValueChanged<bool> onMergeChanged;
  final ValueChanged<bool> onOverwriteChanged;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final records = transcript.records;
    final matched = records.where((record) => record.matchesCurriculum).length;
    final passed = records.where((record) => record.isPassed).length;
    final unmatched = records.length - matched;
    final manualConflicts = preview && existing != null
        ? records.where((record) {
            return existing!
                    .latestBySubjectCode[record.subjectCode.toUpperCase()]
                    ?.isManual ??
                false;
          }).length
        : 0;
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
                  label: 'Chưa khớp curriculum',
                  value: '$unmatched',
                  warning: unmatched > 0,
                ),
                if (transcript.manualRecordCount > 0)
                  _SummaryMetric(
                    label: 'Điểm tự nhập',
                    value: '${transcript.manualRecordCount}',
                  ),
              ],
            ),
            if (preview && existing != null) ...[
              const SizedBox(height: 18),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ghép với bảng điểm đang có'),
                subtitle: const Text(
                  'Bật để giữ các môn cũ không có trong file mới. Tắt để bỏ các môn FAP cũ; điểm tự nhập được xử lý theo lựa chọn bên dưới.',
                ),
                value: mergeImport,
                onChanged: importing ? null : onMergeChanged,
              ),
              if (existing!.manualRecordCount > 0)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Ghi đè điểm tự nhập'),
                  subtitle: Text(
                    'Có $manualConflicts môn tự nhập trùng mã trong file mới. '
                    'Mặc định giữ điểm tự nhập; bật để dùng điểm FAP cho các môn trùng mã. '
                    'Khi tắt, điểm tự nhập không có trong file mới vẫn được giữ.',
                  ),
                  value: overwriteManual,
                  onChanged: importing ? null : onOverwriteChanged,
                ),
            ],
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

class _GradebookMetrics extends StatelessWidget {
  const _GradebookMetrics({required this.records});

  final List<TranscriptRecord> records;

  @override
  Widget build(BuildContext context) {
    final uniqueRecords = <String, TranscriptRecord>{
      for (final record in records)
        record.subjectCode.trim().toUpperCase(): record,
    }.values.toList();
    final scored = uniqueRecords
        .map((record) => double.tryParse(record.grade))
        .whereType<double>()
        .toList();
    final average = scored.isEmpty
        ? '—'
        : (scored.reduce((left, right) => left + right) / scored.length)
              .toStringAsFixed(1);
    final passed = uniqueRecords.where((record) => record.isPassed).length;
    final missing = uniqueRecords.length - scored.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 680 ? 2 : 4;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _GradeMetric(
              width: width,
              icon: Icons.library_books_outlined,
              label: 'Tổng số môn',
              value: '${uniqueRecords.length}',
              color: Theme.of(context).colorScheme.primary,
            ),
            _GradeMetric(
              width: width,
              icon: Icons.school_outlined,
              label: 'GPA',
              value: average,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            _GradeMetric(
              width: width,
              icon: Icons.check_circle_outline,
              label: 'Đã đạt',
              value: '$passed',
              color: Theme.of(context).extension<KnowledgeColors>()!.success,
            ),
            _GradeMetric(
              width: width,
              icon: Icons.warning_amber_rounded,
              label: 'Chưa có điểm',
              value: '$missing',
              color: Theme.of(context).extension<KnowledgeColors>()!.warning,
            ),
          ],
        );
      },
    );
  }
}

class _GradeMetric extends StatelessWidget {
  const _GradeMetric({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TranscriptRecords extends StatelessWidget {
  const _TranscriptRecords({
    required this.records,
    required this.allRecords,
    required this.importing,
    required this.onImport,
    required this.totalCount,
    required this.semesterFilter,
    required this.semesterOptions,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSemesterChanged,
    required this.editingEnabled,
    required this.canAdd,
    required this.onAdd,
    required this.onEdit,
    required this.onRestore,
  });
  final List<_GradeRecordEntry> records;
  final List<TranscriptRecord> allRecords;
  final bool importing;
  final VoidCallback onImport;
  final int totalCount;
  final String semesterFilter;
  final List<String> semesterOptions;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSemesterChanged;
  final bool editingEnabled;
  final bool canAdd;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRestore;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Bảng điểm',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
          ),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: importing ? null : onImport,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Import'),
              ),
              if (canAdd)
                OutlinedButton.icon(
                  key: const ValueKey('transcript-add-grade'),
                  onPressed: editingEnabled ? onAdd : null,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm môn'),
                ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 4),
      Text(
        '$totalCount môn học · Chọn một môn để xem hoặc chỉnh sửa chi tiết.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;
          final search = SizedBox(
            width: compact ? double.infinity : 260,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: const InputDecoration(
                hintText: 'Tìm môn học...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          );
          final filter = DropdownButtonFormField<String>(
            initialValue: semesterFilter,
            isExpanded: true,
            isDense: true,
            decoration: const InputDecoration(
              labelText: 'Học kỳ',
              prefixIcon: Icon(Icons.filter_list),
            ),
            items: [
              const DropdownMenuItem(
                value: 'Tất cả kỳ',
                child: Text('Tất cả kỳ'),
              ),
              for (final option in semesterOptions)
                DropdownMenuItem(
                  value: option,
                  child: Text(_semesterFilterLabel(option, allRecords)),
                ),
            ],
            onChanged: (value) {
              if (value != null) onSemesterChanged(value);
            },
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [search, const SizedBox(height: 10), filter],
            );
          }
          return Row(
            children: [
              search,
              const SizedBox(width: 10),
              SizedBox(width: 190, child: filter),
            ],
          );
        },
      ),
      const SizedBox(height: 14),
      _GradebookMetrics(records: allRecords),
      const SizedBox(height: 18),
      if (records.isEmpty)
        const _GradebookEmptyState()
      else
        _SemesterGradebook(
          records: records,
          editingEnabled: editingEnabled,
          onEdit: onEdit,
          onRestore: onRestore,
        ),
    ],
  );
}

class _SemesterGradebook extends StatelessWidget {
  const _SemesterGradebook({
    required this.records,
    required this.editingEnabled,
    required this.onEdit,
    required this.onRestore,
  });

  final List<_GradeRecordEntry> records;
  final bool editingEnabled;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRestore;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<_GradeRecordEntry>>{};
    for (final entry in records) {
      groups.putIfAbsent(entry.record.semester.trim(), () => []).add(entry);
    }
    final semesters = groups.keys.toList()
      ..sort(
        (left, right) =>
            _semesterNumber(left).compareTo(_semesterNumber(right)),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < semesters.length; index++) ...[
          _SemesterSection(
            semester: semesters[index],
            records: groups[semesters[index]]!,
            editingEnabled: editingEnabled,
            onEdit: onEdit,
            onRestore: onRestore,
          ),
          if (index != semesters.length - 1) const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _GradeRecordEntry {
  const _GradeRecordEntry({required this.record, required this.index});

  final TranscriptRecord record;
  final int index;
}

class _SemesterSection extends StatelessWidget {
  const _SemesterSection({
    required this.semester,
    required this.records,
    required this.editingEnabled,
    required this.onEdit,
    required this.onRestore,
  });

  final String semester;
  final List<_GradeRecordEntry> records;
  final bool editingEnabled;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRestore;

  @override
  Widget build(BuildContext context) {
    final term = records
        .map((entry) => entry.record.term.trim())
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Kỳ ${semester.isEmpty ? 'chưa xác định' : semester}${term.isEmpty ? '' : ' · ${_termLabel(term)}'}',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            Text(
              '${records.length} môn',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 700 ? 1 : 2;
            final gap = 14.0;
            final width =
                (constraints.maxWidth - (columns - 1) * gap) / columns;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final entry in records)
                  SizedBox(
                    width: width,
                    child: _GradebookCard(
                      record: entry.record,
                      editingEnabled: editingEnabled,
                      onEdit: () => onEdit(entry.index),
                      onRestore: () => onRestore(entry.index),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

int _semesterNumber(String value) => int.tryParse(value) ?? 999999;

String _termLabel(String term) {
  final match = RegExp(r'^(Fall|Spring|Summer|Winter)(\d{4})$')
      .firstMatch(term);
  if (match == null) return term;
  return '${match.group(1)} ${match.group(2)}';
}

class _GradebookCard extends StatelessWidget {
  const _GradebookCard({
    required this.record,
    required this.editingEnabled,
    required this.onEdit,
    required this.onRestore,
  });

  final TranscriptRecord record;
  final bool editingEnabled;
  final VoidCallback onEdit;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, record.status);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.subjectCode,
                          style: TextStyle(
                            color: scheme.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          record.subjectName.isEmpty
                              ? 'Chưa có tên môn'
                              : record.subjectName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  if (!record.matchesCurriculum)
                    Tooltip(
                      message: 'Môn chưa khớp curriculum',
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: scheme.error,
                        size: 19,
                      ),
                    ),
                  if (editingEnabled)
                    IconButton(
                      key: ValueKey('transcript-edit:${record.subjectCode}'),
                      tooltip: 'Sửa điểm ${record.subjectCode}',
                      onPressed: onEdit,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined, size: 19),
                    ),
                  if (editingEnabled && record.isManual)
                    IconButton(
                      key: ValueKey('transcript-restore:${record.subjectCode}'),
                      tooltip: record.hasFapOriginal
                          ? 'Khôi phục điểm FAP ${record.subjectCode}'
                          : 'Xóa điểm tự nhập ${record.subjectCode}',
                      onPressed: onRestore,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        record.hasFapOriginal
                            ? Icons.restore_outlined
                            : Icons.delete_outline,
                        size: 19,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                [
                  record.semester,
                  if (record.credit.isNotEmpty) '${record.credit} tín chỉ',
                ].where((value) => value.isNotEmpty).join(' · '),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(),
                  _GradeValue(
                    record: record,
                    color: record.grade.isEmpty ? scheme.outline : color,
                  ),
                  const SizedBox(width: 10),
                  _TranscriptStatus(record: record, color: color),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.sourceLabel,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradebookEmptyState extends StatelessWidget {
  const _GradebookEmptyState();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(36),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    child: Column(
      children: [
        Icon(
          Icons.search_off_outlined,
          size: 34,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(height: 10),
        const Text(
          'Không tìm thấy môn học',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Thử đổi từ khóa hoặc chọn lại học kỳ.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _GradeValue extends StatelessWidget {
  const _GradeValue({required this.record, required this.color});

  final TranscriptRecord record;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Điểm ${record.grade.isEmpty ? 'chưa có' : record.grade}',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Text(
        '${record.grade.isEmpty ? '—' : record.grade}\n/10',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 17,
          height: 1.05,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _TranscriptStatus extends StatelessWidget {
  const _TranscriptStatus({required this.record, required this.color});

  final TranscriptRecord record;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final studying = record.status.trim().toLowerCase() == 'studying';
    final label = record.status.isEmpty ? 'Chưa rõ' : record.status;
    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: studying ? 8 : 10,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: studying
              ? Icon(Icons.schedule_outlined, size: 18, color: color)
              : Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w800),
                ),
        ),
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

class _TranscriptEdit {
  const _TranscriptEdit({
    required this.course,
    required this.grade,
    required this.status,
  });

  final CurriculumCourse? course;
  final String grade;
  final String status;
}

class _TranscriptEditDialog extends StatefulWidget {
  const _TranscriptEditDialog({this.record, this.availableCourses = const []});

  final TranscriptRecord? record;
  final List<CurriculumCourse> availableCourses;

  @override
  State<_TranscriptEditDialog> createState() => _TranscriptEditDialogState();
}

class _TranscriptEditDialogState extends State<_TranscriptEditDialog> {
  static const _statuses = ['Passed', 'Not passed', 'Studying', 'Not started'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _gradeController;
  CurriculumCourse? _course;
  late String _status;

  @override
  void initState() {
    super.initState();
    _gradeController = TextEditingController(text: widget.record?.grade ?? '');
    final currentStatus = widget.record?.status ?? '';
    _status = currentStatus.isEmpty ? 'Studying' : currentStatus;
  }

  @override
  void dispose() {
    _gradeController.dispose();
    super.dispose();
  }

  String? _validateGrade(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (const {'P', 'F'}.contains(text.toUpperCase())) return null;
    final score = double.tryParse(text.replaceAll(',', '.'));
    if (score == null || score < 0 || score > 10) {
      return 'Nhập điểm từ 0 đến 10, P hoặc F.';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _TranscriptEdit(
        course: _course,
        grade: _gradeController.text.trim().replaceAll(',', '.'),
        status: _status,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.record == null
          ? 'Thêm môn tự nhập'
          : 'Sửa điểm ${widget.record!.subjectCode}',
    ),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Điểm tự nhập không phải dữ liệu chính thức từ FAP.'),
            const SizedBox(height: 16),
            if (widget.record == null) ...[
              DropdownButtonFormField<CurriculumCourse>(
                key: const ValueKey('transcript-course-input'),
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Môn học'),
                items: [
                  for (final course in widget.availableCourses)
                    DropdownMenuItem(
                      value: course,
                      child: Text(
                        '${course.code} · ${course.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                validator: (value) => value == null ? 'Chọn môn học.' : null,
                onChanged: (value) => _course = value,
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              key: const ValueKey('transcript-grade-input'),
              controller: _gradeController,
              decoration: const InputDecoration(
                labelText: 'Điểm',
                hintText: '0–10, P/F hoặc để trống',
              ),
              validator: _validateGrade,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const ValueKey('transcript-status-input'),
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Trạng thái'),
              items: [
                for (final status in {
                  ..._statuses,
                  if (!_statuses.contains(_status)) _status,
                })
                  DropdownMenuItem(value: status, child: Text(status)),
              ],
              onChanged: (value) {
                if (value != null) _status = value;
              },
            ),
            if (widget.record?.hasFapOriginal ?? false) ...[
              const SizedBox(height: 12),
              Text(
                'FAP gốc: ${widget.record!.isManual ? widget.record!.importedGrade : widget.record!.grade} · '
                '${widget.record!.isManual ? widget.record!.importedStatus : widget.record!.status}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        key: const ValueKey('transcript-save-grade'),
        onPressed: _submit,
        child: const Text('Lưu điểm'),
      ),
    ],
  );
}
