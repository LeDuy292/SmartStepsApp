import 'package:flutter/material.dart';
import 'package:smartsteps/data/offline_situation_catalog.dart';
import 'package:smartsteps/theme/duo_theme.dart';
import 'package:smartsteps/widgets/duo_components.dart';

class QuickReviewScreen extends StatelessWidget {
  const QuickReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final questions = getQuickReviewQuestions(limit: 5);

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        appBar: AppBar(
          title: const Text(
            'Ôn bài nhanh',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: DuoColors.primaryYellow,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            'Chưa có câu hỏi để ôn tập',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFFF7F7F7,
      ), // Nền xám nhạt sáng sủa toàn màn hình
      appBar: AppBar(
        title: const Text(
          'Ôn bài nhanh',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: DuoColors.primaryYellow,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DuoCard(
          color: Colors
              .white, // Đổi sang nền trắng giúp các câu hỏi nổi bật rõ ràng hơn
          borderColor: Colors.black.withValues(alpha: 0.08),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header thân thiện với biểu tượng gợi ý thông minh
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DuoColors.primaryYellow.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lightbulb_rounded,
                      color: DuoColors.darkYellow,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Gợi ý hôm nay',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Lời nhắn nhủ nhẹ nhàng, thay thế cho câu dẫn cũ bị giới hạn bối cảnh ngoài đường
              Text(
                'Bố mẹ hãy cùng trò chuyện và đặt các câu hỏi thực tế này để giúp bé ghi nhớ bài học sâu hơn nhé:',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Danh sách các khối câu hỏi được phân tách trực quan
              ...List.generate(questions.length, (index) {
                final isLast = index == questions.length - 1;
                return Container(
                  margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.04),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sticker vòng tròn số thứ tự đồng điệu thiết kế Duo
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: DuoColors.primaryYellow,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Nội dung câu hỏi ngắn gọn gọn gàng
                      Expanded(
                        child: Text(
                          questions[index].questionText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
