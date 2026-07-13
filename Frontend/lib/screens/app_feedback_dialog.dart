import 'dart:async';

import 'package:flutter/material.dart';

import '../models/app_feedback.dart';
import '../services/local_profile_storage.dart';
import '../theme/duo_theme.dart';

Future<bool?> showAppFeedbackDialog(
  BuildContext context, {
  required LocalProfileStorage profileStorage,
  required String source,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (_) =>
        AppFeedbackDialog(profileStorage: profileStorage, source: source),
  );
}

class AppFeedbackDialog extends StatefulWidget {
  const AppFeedbackDialog({
    super.key,
    required this.profileStorage,
    required this.source,
  });

  final LocalProfileStorage profileStorage;
  final String source;

  @override
  State<AppFeedbackDialog> createState() => _AppFeedbackDialogState();
}

class _AppFeedbackDialogState extends State<AppFeedbackDialog> {
  final TextEditingController _improvementController = TextEditingController();
  int _experienceRating = 4;
  int _childEngagementRating = 4;
  int _effectivenessRating = 4;
  String _ageFit = 'Phù hợp';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _improvementController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final submittedAt = DateTime.now();
    final feedback = AppFeedbackEntry(
      id: 'feedback-${submittedAt.microsecondsSinceEpoch}',
      source: widget.source,
      submittedAt: submittedAt,
      experienceRating: _experienceRating,
      childEngagementRating: _childEngagementRating,
      effectivenessRating: _effectivenessRating,
      ageFit: _ageFit,
      improvementNote: _improvementController.text.trim(),
    );

    try {
      await widget.profileStorage.saveAppFeedback(feedback);
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('SmartSteps feedback save failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa lưu được đánh giá. Vui lòng thử lại.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: size.height * 0.86,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: DuoColors.softYellow,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.rate_review_rounded,
                      color: DuoColors.darkYellow,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Đánh giá SmartSteps',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Giúp tụi tôi hiểu app có dễ dùng và có hiệu quả với bé không.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _RatingQuestion(
                label: 'Phụ huynh thấy app dễ dùng không?',
                value: _experienceRating,
                onChanged: (value) {
                  setState(() => _experienceRating = value);
                },
              ),
              const SizedBox(height: 14),
              _RatingQuestion(
                label: 'Bé có hào hứng khi học không?',
                value: _childEngagementRating,
                onChanged: (value) {
                  setState(() => _childEngagementRating = value);
                },
              ),
              const SizedBox(height: 14),
              _RatingQuestion(
                label: 'Bé có nhớ kỹ năng an toàn sau bài học không?',
                value: _effectivenessRating,
                onChanged: (value) {
                  setState(() => _effectivenessRating = value);
                },
              ),
              const SizedBox(height: 14),
              Text(
                'Nội dung có phù hợp độ tuổi của bé không?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 9),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in _ageFitOptions)
                    ChoiceChip(
                      label: Text(option),
                      selected: _ageFit == option,
                      onSelected: (_) {
                        setState(() => _ageFit = option);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _improvementController,
                maxLines: 3,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Một điều muốn cải thiện',
                  hintText: 'Ví dụ: thêm giọng đọc, thêm bài, nút rõ hơn...',
                  filled: true,
                  fillColor: DuoColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: DuoColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: DuoColors.border,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: DuoColors.darkYellow,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Để sau'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSubmitting
                          ? null
                          : () => unawaited(_submit()),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text('Gửi'),
                    ),
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

class _RatingQuestion extends StatelessWidget {
  const _RatingQuestion({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 9),
        Row(
          children: [
            for (var rating = 1; rating <= 5; rating++) ...[
              Expanded(
                child: _RatingChip(
                  rating: rating,
                  isSelected: rating == value,
                  onTap: () => onChanged(rating),
                ),
              ),
              if (rating != 5) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }
}

class _RatingChip extends StatelessWidget {
  const _RatingChip({
    required this.rating,
    required this.isSelected,
    required this.onTap,
  });

  final int rating;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? DuoColors.primaryYellow : DuoColors.background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? DuoColors.darkYellow : DuoColors.border,
              width: 2,
            ),
          ),
          child: Text(
            '$rating',
            style: const TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

const _ageFitOptions = ['Phù hợp', 'Cần dễ hơn', 'Cần khó hơn'];
