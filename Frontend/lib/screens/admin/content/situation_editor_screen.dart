import 'package:flutter/material.dart';
import '../../../services/admin_api_service.dart';
import '../../../theme/duo_theme.dart';

class SituationEditorScreen extends StatefulWidget {
  final int situationId;

  const SituationEditorScreen({super.key, required this.situationId});

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
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
              title: Text(isEditing ? 'Sửa Bước (Step)' : 'Thêm Bước Mới'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: stepType,
                        decoration: const InputDecoration(
                          labelText: 'Loại bước (Step Type)',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Intro', child: Text('Intro')),
                          DropdownMenuItem(value: 'Story', child: Text('Story')),
                          DropdownMenuItem(value: 'Question', child: Text('Question')),
                          DropdownMenuItem(value: 'Outro', child: Text('Outro')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => stepType = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: orderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Thứ tự (Order Index)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: contentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung (Content)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: mediaUrlController,
                        decoration: InputDecoration(
                          labelText: 'Link Video / Public ID (MediaUrl)',
                          border: const OutlineInputBorder(),
                          helperText: 'Nhập link direct (https://...) hoặc Cloudinary ID (vd: Safety_smallitems_intro_cw1tlh.mp4)',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.preview),
                            tooltip: 'Xem thử video URL',
                            onPressed: () {
                              final text = mediaUrlController.text.trim();
                              if (text.isEmpty) return;
                              final url = text.startsWith('http')
                                  ? text
                                  : 'https://res.cloudinary.com/dtm5a4bwr/video/upload/$text';
                              
                              showDialog<void>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Xem thử URL Video'),
                                  content: SelectableText(url),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
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
                  onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          try {
                            final payload = {
                              'stepType': stepType,
                              'orderIndex': int.tryParse(orderController.text.trim()) ?? 1,
                              'content': contentController.text.trim(),
                              'mediaUrl': mediaUrlController.text.trim().isEmpty
                                  ? null
                                  : mediaUrlController.text.trim(),
                            };

                            if (isEditing) {
                              await _api.updateStep(step['stepId'], payload);
                            } else {
                              await _api.createStep(widget.situationId, payload);
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
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Lưu' : 'Thêm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteStep(int stepId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa bước này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa step: $e')),
        );
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
              title: Text(isEditing ? 'Sửa Flashcard' : 'Thêm Flashcard Mới'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: questionController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Câu hỏi (Question)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: optionAController,
                        decoration: const InputDecoration(
                          labelText: 'Đáp án A (Option A)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: optionBController,
                        decoration: const InputDecoration(
                          labelText: 'Đáp án B (Option B)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: correctAnswer,
                        decoration: const InputDecoration(
                          labelText: 'Đáp án đúng (Correct Answer)',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'A', child: Text('Đáp án A')),
                          DropdownMenuItem(value: 'B', child: Text('Đáp án B')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => correctAnswer = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: correctFeedbackController,
                        decoration: const InputDecoration(
                          labelText: 'Phản hồi khi chọn ĐÚNG',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: wrongFeedbackController,
                        decoration: const InputDecoration(
                          labelText: 'Phản hồi khi chọn SAI',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: DuoColors.primaryYellow, foregroundColor: Colors.black),
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
                              'correctFeedback': correctFeedbackController.text.trim(),
                              'wrongFeedback': wrongFeedbackController.text.trim(),
                            };

                            if (isEditing) {
                              await _api.updateFlashcard(fc['flashcardId'], payload);
                            } else {
                              await _api.createFlashcard(widget.situationId, payload);
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
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Lưu' : 'Thêm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteFlashcard(int fcId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa Flashcard này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa flashcard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_situation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lỗi')),
        body: const Center(child: Text('Không tìm thấy bài học')),
      );
    }

    final steps = _situation!['steps'] as List<dynamic>? ?? [];
    final flashcards = _situation!['flashcards'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Soạn thảo bài học: ${_situation!['title']}'),
        backgroundColor: DuoColors.background,
        scrolledUnderElevation: 0,
      ),
      backgroundColor: DuoColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // STEPS COLUMN
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Các Bước (Steps)', style: Theme.of(context).textTheme.titleLarge),
                        FilledButton.icon(
                          onPressed: () => _showStepDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm Step'),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: steps.isEmpty
                          ? const Center(child: Text('Chưa có bước nào trong bài học'))
                          : ListView.builder(
                              itemCount: steps.length,
                              itemBuilder: (context, index) {
                                final step = steps[index];
                                final hasVideo = step['mediaUrl'] != null && step['mediaUrl'].toString().isNotEmpty;
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(child: Text(step['orderIndex'].toString())),
                                    title: Row(
                                      children: [
                                        Text(
                                          step['stepType'] ?? 'Step',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        if (hasVideo) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.ondemand_video, size: 18, color: Colors.blue),
                                        ],
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (step['content'] != null && step['content'].toString().isNotEmpty)
                                          Text(step['content'], maxLines: 2, overflow: TextOverflow.ellipsis),
                                        if (hasVideo)
                                          Text(
                                            'Media: ${step['mediaUrl']}',
                                            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _showStepDialog(step),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteStep(step['stepId']),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // FLASHCARDS COLUMN
          Expanded(
            child: Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Câu hỏi (Flashcards)', style: Theme.of(context).textTheme.titleLarge),
                        FilledButton.icon(
                          onPressed: () => _showFlashcardDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm Câu Hỏi'),
                          style: FilledButton.styleFrom(backgroundColor: DuoColors.primaryYellow, foregroundColor: Colors.black),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: flashcards.isEmpty
                          ? const Center(child: Text('Chưa có câu hỏi nào'))
                          : ListView.builder(
                              itemCount: flashcards.length,
                              itemBuilder: (context, index) {
                                final fc = flashcards[index];
                                return Card(
                                  color: Colors.grey[50],
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Q: ${fc['question']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 8),
                                        Text('A: ${fc['optionA']} ${fc['correctAnswer'] == 'A' ? '(Đúng)' : ''}',
                                            style: TextStyle(color: fc['correctAnswer'] == 'A' ? Colors.green : Colors.black)),
                                        Text('B: ${fc['optionB']} ${fc['correctAnswer'] == 'B' ? '(Đúng)' : ''}',
                                            style: TextStyle(color: fc['correctAnswer'] == 'B' ? Colors.green : Colors.black)),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton.icon(
                                              icon: const Icon(Icons.edit, color: Colors.blue),
                                              label: const Text('Sửa'),
                                              onPressed: () => _showFlashcardDialog(fc),
                                            ),
                                            TextButton.icon(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                              onPressed: () => _deleteFlashcard(fc['flashcardId']),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
