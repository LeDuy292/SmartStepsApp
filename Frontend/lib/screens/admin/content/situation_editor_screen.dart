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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
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
        title: Text('Soạn thảo: ${_situation!['title']}'),
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
                          onPressed: () {
                            // TODO: Add Step Dialog
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng thêm Step đang phát triển')));
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm'),
                        )
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: steps.length,
                        itemBuilder: (context, index) {
                          final step = steps[index];
                          return ListTile(
                            leading: CircleAvatar(child: Text(step['orderIndex'].toString())),
                            title: Text(step['stepType'] ?? ''),
                            subtitle: Text(step['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // TODO: Delete step
                              },
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
                          onPressed: () {
                            // TODO: Add Flashcard Dialog
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng thêm Flashcard đang phát triển')));
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm'),
                          style: FilledButton.styleFrom(backgroundColor: DuoColors.primaryYellow, foregroundColor: Colors.black),
                        )
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: flashcards.length,
                        itemBuilder: (context, index) {
                          final fc = flashcards[index];
                          return Card(
                            color: Colors.grey[50],
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
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      label: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                      onPressed: () {},
                                    ),
                                  )
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
