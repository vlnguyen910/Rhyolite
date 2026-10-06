import 'package:flutter/material.dart';

import '../../design_system/app_theme.dart';

class HomeLoadError extends StatelessWidget {
  const HomeLoadError({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    ),
  );
}

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.title,
    required this.description,
    required this.showSearch,
    required this.controller,
    required this.onSearch,
    required this.onRefresh,
    required this.onInfo,
  });

  final String title;
  final String description;
  final bool showSearch;
  final TextEditingController controller;
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.md,
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (showSearch) ...[
          SizedBox(
            width: 280,
            height: 48,
            child: TextField(
              key: const ValueKey('course-search'),
              controller: controller,
              onChanged: onSearch,
              decoration: const InputDecoration(
                hintText: 'Tìm mã hoặc tên môn',
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        IconButton(
          tooltip: 'Tải lại dữ liệu',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
        ),
        IconButton(
          tooltip: 'Thông tin ứng dụng',
          onPressed: onInfo,
          icon: const Icon(Icons.info_outline),
        ),
      ],
    ),
  );
}

class HomeStatusBar extends StatelessWidget {
  const HomeStatusBar({super.key, required this.version});
  final String version;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: Row(
        children: [
          Icon(
            Icons.offline_bolt_outlined,
            size: 16,
            color: Theme.of(context).extension<KnowledgeColors>()!.success,
          ),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              'Local-first · Curriculum bundled offline',
              style: TextStyle(fontSize: 12),
            ),
          ),
          Text(
            'v$version',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}
