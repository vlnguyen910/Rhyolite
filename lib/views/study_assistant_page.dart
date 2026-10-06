import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../models/course_assistant_answer.dart';
import '../models/curriculum_catalog.dart';
import '../models/student_transcript.dart';
import '../services/course_assistant_service.dart';
import 'widgets/markdown_rendering.dart';

class StudyAssistantPage extends StatefulWidget {
  const StudyAssistantPage({
    super.key,
    required this.courses,
    required this.curriculumCode,
    required this.onOpenCourse,
    this.initialPrompt,
    this.promptRequestId = 0,
    this.service,
    this.transcript,
  });

  final List<CurriculumCourse> courses;
  final String curriculumCode;
  final ValueChanged<CurriculumCourse> onOpenCourse;
  final String? initialPrompt;
  final int promptRequestId;
  final ICourseAssistantService? service;
  final StudentTranscript? transcript;

  @override
  State<StudyAssistantPage> createState() => _StudyAssistantPageState();
}

class _StudyAssistantPageState extends State<StudyAssistantPage> {
  late final ICourseAssistantService _service;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatEntry>[
    const _ChatEntry(
      role: _ChatRole.assistant,
      markdown: 'Xin chào! Mình có thể đọc curriculum, syllabus và bảng điểm đã import. Hãy hỏi về **mô tả môn, tín chỉ, điểm số, môn đã qua, môn cần học lại hoặc tiến độ học tập**.',
    ),
  ];
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? CourseAssistantService();
    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _send(widget.initialPrompt);
      });
    }
  }

  @override
  void didUpdateWidget(covariant StudyAssistantPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.promptRequestId == widget.promptRequestId ||
        widget.initialPrompt == null) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _send(widget.initialPrompt);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send([String? prompt]) async {
    final question = (prompt ?? _controller.text).trim();
    if (question.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _messages.add(_ChatEntry(role: _ChatRole.user, markdown: question));
      _sending = true;
    });
    _scrollToEnd();
    final answer = await _service.answer(
      question,
      widget.courses,
      transcript: widget.transcript,
    );
    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatEntry(
          role: _ChatRole.assistant,
          markdown: answer.markdown,
          answer: answer,
        ),
      );
      _sending = false;
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      'Môn PRM393 học gì?',
      'PRM393 có bao nhiêu tín chỉ?',
      'Thời lượng của PRM393?',
      'Các môn tiên quyết của kỳ 8?',
      'Điểm PRM393 của tôi là bao nhiêu?',
      'Tôi còn môn nào chưa qua?',
    ];
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Row(
            children: [
              Icon(
                Icons.offline_bolt_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_service.providerLabel} · ${_curriculumLabel(widget.curriculumCode)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_service.providerLabel.startsWith('Groq'))
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Text(
              'Khi hỏi Groq, dữ liệu môn học và bảng điểm đã import được gửi làm ngữ cảnh trả lời.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 940),
              child: ListView.builder(
                key: const ValueKey('assistant-messages'),
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return const _ThinkingBubble();
                  }
                  final entry = _messages[index];
                  return _MessageBubble(
                    entry: entry,
                    onOpenCourse: entry.answer?.course == null
                        ? null
                        : () => widget.onOpenCourse(entry.answer!.course!),
                  );
                },
              ),
            ),
          ),
        ),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final suggestion in suggestions) ...[
                      ActionChip(
                        label: Text(suggestion),
                        onPressed: _sending ? null : () => _send(suggestion),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: TextField(
                key: const ValueKey('assistant-input'),
                controller: _controller,
                enabled: !_sending,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Hỏi về một môn học hoặc học kỳ…',
                  prefixIcon: const Icon(Icons.auto_awesome_outlined),
                  suffixIcon: IconButton(
                    key: const ValueKey('assistant-send'),
                    tooltip: 'Gửi câu hỏi',
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.entry, this.onOpenCourse});

  final _ChatEntry entry;
  final VoidCallback? onOpenCourse;

  @override
  Widget build(BuildContext context) {
    final user = entry.role == _ChatRole.user;
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .68,
        ),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: user ? scheme.primary : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(user ? 18 : 5),
            bottomRight: Radius.circular(user ? 5 : 18),
          ),
          border: user ? null : Border.all(color: scheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user)
              Text(entry.markdown, style: TextStyle(color: scheme.onPrimary))
            else
              MarkdownBody(
                selectable: true,
                data: renderableMarkdown(entry.markdown),
              ),
            if (!user &&
                (onOpenCourse != null || entry.answer?.sourceUrl != null)) ...[
              const SizedBox(height: 10),
              const Divider(),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (onOpenCourse != null)
                    TextButton.icon(
                      onPressed: onOpenCourse,
                      icon: const Icon(Icons.open_in_new, size: 17),
                      label: const Text('Mở chi tiết môn'),
                    ),
                  if (entry.answer?.sourceUrl != null)
                    Chip(
                      avatar: const Icon(Icons.link, size: 16),
                      label: const Text('Nguồn: syllabus FPT'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: SizedBox.square(
        dimension: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

enum _ChatRole { user, assistant }

class _ChatEntry {
  const _ChatEntry({required this.role, required this.markdown, this.answer});

  final _ChatRole role;
  final String markdown;
  final CourseAssistantAnswer? answer;
}

String _curriculumLabel(String code) =>
    code.replaceFirst('BIT_SE_', 'SE · ').replaceAll('_', '–');
