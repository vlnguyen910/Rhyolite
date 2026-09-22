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
                  existing: _saved,
                  preview: _preview != null,
                  importing: _importing,
                  mergeImport: _mergeImport,
                  overwriteManual: _overwriteManual,
                  onMergeChanged: (value) =>
                      setState(() => _mergeImport = value),
                  onOverwriteChanged: (value) =>
                      setState(() => _overwriteManual = value),
                  onConfirm: _confirmImport,
                  onCancel: () => setState(() => _preview = null),
                ),
                const SizedBox(height: AppSpacing.lg),
                _TranscriptRecords(
                  transcript: transcript,
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

class _TranscriptRecords extends StatelessWidget {
  const _TranscriptRecords({
    required this.transcript,
    required this.editingEnabled,
    required this.canAdd,
    required this.onAdd,
    required this.onEdit,
    required this.onRestore,
  });
  final StudentTranscript transcript;
  final bool editingEnabled;
  final bool canAdd;
  final VoidCallback onAdd;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onRestore;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chi tiết môn học',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
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
          const SizedBox(height: 4),
          Text(
            'Các môn không có trong curriculum đang chọn vẫn được giữ để bạn kiểm tra.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < transcript.records.length; index++) ...[
            _TranscriptRecordTile(
              record: transcript.records[index],
              editingEnabled: editingEnabled,
              onEdit: () => onEdit(index),
              onRestore: () => onRestore(index),
            ),
            if (index != transcript.records.length - 1)
              const Divider(height: 1),
          ],
        ],
      ),
    ),
  );
}

class _TranscriptRecordTile extends StatelessWidget {
  const _TranscriptRecordTile({
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
                Text(
                  record.sourceLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: record.isManual
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
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
          if (editingEnabled) ...[
            IconButton(
              key: ValueKey('transcript-edit:${record.subjectCode}'),
              tooltip: 'Sửa điểm ${record.subjectCode}',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            if (record.isManual)
              IconButton(
                key: ValueKey('transcript-restore:${record.subjectCode}'),
                tooltip: record.hasFapOriginal
                    ? 'Khôi phục điểm FAP ${record.subjectCode}'
                    : 'Xóa điểm tự nhập ${record.subjectCode}',
                onPressed: onRestore,
                icon: Icon(
                  record.hasFapOriginal
                      ? Icons.restore_outlined
                      : Icons.delete_outline,
                ),
              ),
          ],
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
