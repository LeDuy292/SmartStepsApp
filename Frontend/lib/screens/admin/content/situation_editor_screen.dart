import 'package:flutter/material.dart';

import '../../../services/admin_api_service.dart';
import '../../../theme/duo_theme.dart';
import '../admin_components.dart';

class SituationEditorScreen extends StatefulWidget {
  const SituationEditorScreen({super.key, required this.situationId});

  final int situationId;

  @override
  State<SituationEditorScreen> createState() => _SituationEditorScreenState();
}

class _SituationEditorScreenState extends State<SituationEditorScreen> {
  final AdminApiService _api = AdminApiService();
  Map<String, dynamic>? _situation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSituation();
  }

  Future<void> _fetchSituation() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.getSituation(widget.situationId);
      setState(() {
        _situation = res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _showStepDialog([Map<String, dynamic>? step]) async {
    final isEditing = step != null;
    final orderController = TextEditingController(
      text: isEditing ? step['orderIndex']?.toString() : '1',
    );
    final contentController = TextEditingController(
      text: isEditing ? step['content']?.toString() : '',
    );
    final mediaUrlController = TextEditingController(
      text: isEditing ? step['mediaUrl']?.toString() : '',
    );
    String stepType = isEditing ? (step['stepType'] ?? 'Story') : 'Story';
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.format_list_numbered_rounded,
                    color: AdminColors.teal,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(isEditing ? 'Sửa step' : 'Thêm step')),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: (MediaQuery.of(context).size.width * 0.9).clamp(
                    280.0,
                    520.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: stepType,
                        decoration: const InputDecoration(
                          labelText: 'Loại step',
                          prefixIcon: Icon(Icons.category_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Intro',
                            child: Text('Intro'),
                          ),
                          DropdownMenuItem(
                            value: 'Story',
                            child: Text('Story'),
                          ),
                          DropdownMenuItem(
                            value: 'Flashcard',
                            child: Text('Flashcard'),
                          ),
                          DropdownMenuItem(
                            value: 'Result',
                            child: Text('Result'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => stepType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: orderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Thứ tự',
                          prefixIcon: Icon(Icons.sort_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: contentController,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung',
                          prefixIcon: Icon(Icons.notes_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: mediaUrlController,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: 'Video URL hoặc Cloudinary ID',
                          helperText:
                              'Có thể nhập link https://... hoặc public ID.',
                          prefixIcon: const Icon(Icons.ondemand_video_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.visibility_rounded),
                            tooltip: 'Xem URL video',
                            onPressed: () {
                              final text = mediaUrlController.text.trim();
                              if (text.isEmpty) return;
                              final url = text.startsWith('http')
                                  ? text
                                  : 'https://res.cloudinary.com/dtm5a4bwr/video/upload/$text';

                              showDialog<void>(
                                context: dialogContext,
                                builder: (_) => AlertDialog(
                                  title: const Text('URL video'),
                                  content: SelectableText(url),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(),
                                      child: const Text('Đóng'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          try {
                            final payload = {
                              'stepType': stepType,
                              'orderIndex':
                                  int.tryParse(orderController.text.trim()) ??
                                  1,
                              'content': contentController.text.trim(),
                              'mediaUrl': mediaUrlController.text.trim().isEmpty
                                  ? null
                                  : mediaUrlController.text.trim(),
                            };

                            if (isEditing) {
                              await _api.updateStep(step['stepId'], payload);
                            } else {
                              await _api.createStep(
                                widget.situationId,
                                payload,
                              );
                            }

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            await _fetchSituation();
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: $e')),
                              );
                            }
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    isSaving ? 'Đang lưu' : (isEditing ? 'Lưu' : 'Thêm'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    orderController.dispose();
    contentController.dispose();
    mediaUrlController.dispose();
  }

  Future<void> _deleteStep(int stepId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa step'),
        content: const Text('Bạn có chắc muốn xóa step này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminColors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.deleteStep(stepId);
      await _fetchSituation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xóa step: $e')));
      }
    }
  }

  Future<void> _showFlashcardDialog([Map<String, dynamic>? fc]) async {
    final isEditing = fc != null;
    final questionController = TextEditingController(
      text: isEditing ? fc['question']?.toString() : '',
    );
    final optionAController = TextEditingController(
      text: isEditing ? fc['optionA']?.toString() : '',
    );
    final optionBController = TextEditingController(
      text: isEditing ? fc['optionB']?.toString() : '',
    );
    final correctFeedbackController = TextEditingController(
      text: isEditing ? fc['correctFeedback']?.toString() : '',
    );
    final wrongFeedbackController = TextEditingController(
      text: isEditing ? fc['wrongFeedback']?.toString() : '',
    );
    String correctAnswer = isEditing ? (fc['correctAnswer'] ?? 'A') : 'A';
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  const Icon(Icons.quiz_rounded, color: AdminColors.violet),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(isEditing ? 'Sửa flashcard' : 'Thêm flashcard'),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: (MediaQuery.of(context).size.width * 0.9).clamp(
                    280.0,
                    520.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: questionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Câu hỏi',
                          prefixIcon: Icon(Icons.help_outline_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: optionAController,
                        decoration: const InputDecoration(
                          labelText: 'Đáp án A',
                          prefixIcon: Icon(Icons.looks_one_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: optionBController,
                        decoration: const InputDecoration(
                          labelText: 'Đáp án B',
                          prefixIcon: Icon(Icons.looks_two_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: correctAnswer,
                        decoration: const InputDecoration(
                          labelText: 'Đáp án đúng',
                          prefixIcon: Icon(Icons.check_circle_outline_rounded),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'A', child: Text('Đáp án A')),
                          DropdownMenuItem(value: 'B', child: Text('Đáp án B')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => correctAnswer = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: correctFeedbackController,
                        decoration: const InputDecoration(
                          labelText: 'Phản hồi khi đúng',
                          prefixIcon: Icon(Icons.thumb_up_alt_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: wrongFeedbackController,
                        decoration: const InputDecoration(
                          labelText: 'Phản hồi khi sai',
                          prefixIcon: Icon(Icons.tips_and_updates_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          try {
                            final payload = {
                              'question': questionController.text.trim(),
                              'optionA': optionAController.text.trim(),
                              'optionB': optionBController.text.trim(),
                              'correctAnswer': correctAnswer,
                              'correctFeedback': correctFeedbackController.text
                                  .trim(),
                              'wrongFeedback': wrongFeedbackController.text
                                  .trim(),
                            };

                            if (isEditing) {
                              await _api.updateFlashcard(
                                fc['flashcardId'],
                                payload,
                              );
                            } else {
                              await _api.createFlashcard(
                                widget.situationId,
                                payload,
                              );
                            }

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            await _fetchSituation();
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: $e')),
                              );
                            }
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    isSaving ? 'Đang lưu' : (isEditing ? 'Lưu' : 'Thêm'),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    wrongFeedbackController.dispose();
    correctFeedbackController.dispose();
    optionBController.dispose();
    optionAController.dispose();
    questionController.dispose();
  }

  Future<void> _deleteFlashcard(int fcId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa flashcard'),
        content: const Text('Bạn có chắc muốn xóa flashcard này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminColors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.deleteFlashcard(fcId);
      await _fetchSituation();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xóa flashcard: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: DuoColors.background,
        body: AdminLoadingState(label: 'Đang tải trình soạn thảo...'),
      );
    }

    if (_situation == null) {
      return const Scaffold(
        backgroundColor: DuoColors.background,
        body: AdminEmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Không tìm thấy bài học',
          message: 'Bài học có thể đã bị xóa hoặc bạn không có quyền truy cập.',
        ),
      );
    }

    final steps = _situation!['steps'] as List<dynamic>? ?? [];
    final flashcards = _situation!['flashcards'] as List<dynamic>? ?? [];
    final title = _situation!['title']?.toString() ?? 'Bài học';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (!isWide) {
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              backgroundColor: DuoColors.background,
              appBar: AppBar(
                title: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                backgroundColor: DuoColors.background,
                scrolledUnderElevation: 0,
                bottom: const TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.format_list_numbered_rounded),
                      text: 'Steps',
                    ),
                    Tab(icon: Icon(Icons.quiz_rounded), text: 'Flashcards'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _buildStepsSection(steps),
                  _buildFlashcardsSection(flashcards),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: DuoColors.background,
          appBar: AppBar(
            title: Text('Soạn bài học: $title'),
            backgroundColor: DuoColors.background,
            scrolledUnderElevation: 0,
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildStepsSection(steps)),
              Expanded(child: _buildFlashcardsSection(flashcards)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepsSection(List<dynamic> steps) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AdminPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminSectionTitle(
              icon: Icons.format_list_numbered_rounded,
              title: 'Các bước học',
              trailing: AdminActionIcon(
                icon: Icons.add_rounded,
                tooltip: 'Thêm step',
                onPressed: () => _showStepDialog(),
                color: AdminColors.green,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: steps.isEmpty
                  ? const AdminEmptyState(
                      icon: Icons.playlist_add_rounded,
                      title: 'Chưa có step',
                      message:
                          'Thêm step đầu tiên để bắt đầu dựng nội dung bài học.',
                    )
                  : ListView.separated(
                      itemCount: steps.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final step = steps[index];
                        final hasVideo =
                            step['mediaUrl'] != null &&
                            step['mediaUrl'].toString().isNotEmpty;
                        return _StepCard(
                          step: step,
                          hasVideo: hasVideo,
                          onEdit: () => _showStepDialog(step),
                          onDelete: () => _deleteStep(step['stepId']),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcardsSection(List<dynamic> flashcards) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AdminPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminSectionTitle(
              icon: Icons.quiz_rounded,
              title: 'Flashcards',
              trailing: AdminActionIcon(
                icon: Icons.add_rounded,
                tooltip: 'Thêm flashcard',
                onPressed: () => _showFlashcardDialog(),
                color: AdminColors.green,
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: flashcards.isEmpty
                  ? const AdminEmptyState(
                      icon: Icons.quiz_outlined,
                      title: 'Chưa có flashcard',
                      message:
                          'Thêm câu hỏi để kiểm tra hiểu bài sau mỗi tình huống.',
                    )
                  : ListView.separated(
                      itemCount: flashcards.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final fc = flashcards[index];
                        return _FlashcardCard(
                          flashcard: fc,
                          onEdit: () => _showFlashcardDialog(fc),
                          onDelete: () => _deleteFlashcard(fc['flashcardId']),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.hasVideo,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> step;
  final bool hasVideo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.teal.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AdminColors.teal.withValues(alpha: 0.14),
                child: Text(
                  '${step['orderIndex'] ?? '-'}',
                  style: const TextStyle(
                    color: AdminColors.teal,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step['stepType'] ?? 'Step',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (hasVideo)
                const Icon(
                  Icons.ondemand_video_rounded,
                  color: AdminColors.blue,
                ),
            ],
          ),
          if (step['content'] != null &&
              step['content'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              step['content'],
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AdminColors.ink,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (hasVideo) ...[
            const SizedBox(height: 8),
            Text(
              'Media: ${step['mediaUrl']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AdminColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              AdminActionIcon(
                icon: Icons.edit_rounded,
                tooltip: 'Sửa step',
                onPressed: onEdit,
                color: AdminColors.blue,
              ),
              const Spacer(),
              AdminActionIcon(
                icon: Icons.delete_rounded,
                tooltip: 'Xóa step',
                onPressed: onDelete,
                color: AdminColors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlashcardCard extends StatelessWidget {
  const _FlashcardCard({
    required this.flashcard,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> flashcard;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final correct = flashcard['correctAnswer']?.toString() ?? 'A';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.violet.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminColors.violet.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            flashcard['question'] ?? 'Chưa nhập câu hỏi',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdminColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          _AnswerLine(
            label: 'A',
            text: flashcard['optionA'],
            isCorrect: correct == 'A',
          ),
          const SizedBox(height: 6),
          _AnswerLine(
            label: 'B',
            text: flashcard['optionB'],
            isCorrect: correct == 'B',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              AdminActionIcon(
                icon: Icons.edit_rounded,
                tooltip: 'Sửa flashcard',
                onPressed: onEdit,
                color: AdminColors.blue,
              ),
              const Spacer(),
              AdminActionIcon(
                icon: Icons.delete_rounded,
                tooltip: 'Xóa flashcard',
                onPressed: onDelete,
                color: AdminColors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerLine extends StatelessWidget {
  const _AnswerLine({
    required this.label,
    required this.text,
    required this.isCorrect,
  });

  final String label;
  final dynamic text;
  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AdminColors.green : AdminColors.muted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${text ?? ''}${isCorrect ? '  (đúng)' : ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: isCorrect ? FontWeight.w900 : FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
