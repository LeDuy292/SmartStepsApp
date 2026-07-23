import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/admin_service.dart';
import '../../theme/duo_theme.dart';
import 'admin_components.dart';

class FeedbackListView extends StatefulWidget {
  const FeedbackListView({super.key, this.onLogout});

  final VoidCallback? onLogout;

  @override
  State<FeedbackListView> createState() => _FeedbackListViewState();
}

class _FeedbackListViewState extends State<FeedbackListView> {
  final AdminService _service = AdminService();
  AdminDashboardData? _data;
  bool _isLoading = true;
  String _searchQuery = '';
  int _ratingFilter = 0;
  String _sort = 'newest';
  int _page = 1;
  static const int _pageSize = 4;

  @override
  void initState() {
    super.initState();
    _fetchFeedback();
  }

  Future<void> _fetchFeedback() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getDashboard();
      if (mounted) {
        setState(() => _data = data);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tải được phản hồi: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<AdminFeedback> get _visibleFeedback {
    final feedback = [...?_data?.feedback];
    final query = _searchQuery.trim().toLowerCase();

    feedback.removeWhere((item) {
      final ratingMismatch =
          _ratingFilter > 0 && item.experienceRating != _ratingFilter;
      final searchable = [
        item.email,
        item.note,
        item.source,
        item.ageFit,
      ].join(' ').toLowerCase();
      final queryMismatch = query.isNotEmpty && !searchable.contains(query);
      return ratingMismatch || queryMismatch;
    });

    feedback.sort((a, b) {
      return switch (_sort) {
        'oldest' => _dateValue(a).compareTo(_dateValue(b)),
        'rating_high' => b.experienceRating.compareTo(a.experienceRating),
        'rating_low' => a.experienceRating.compareTo(b.experienceRating),
        _ => _dateValue(b).compareTo(_dateValue(a)),
      };
    });

    return feedback;
  }

  int get _feedbackTotalPages {
    return math.max(1, (_visibleFeedback.length / _pageSize).ceil());
  }

  List<AdminFeedback> get _pagedFeedback {
    final safePage = math.min(_page, _feedbackTotalPages);
    final start = (safePage - 1) * _pageSize;
    final feedback = _visibleFeedback;
    if (start >= feedback.length) {
      return const [];
    }
    final end = math.min(start + _pageSize, feedback.length);
    return feedback.sublist(start, end);
  }

  int _dateValue(AdminFeedback item) {
    return item.submittedAt?.millisecondsSinceEpoch ?? 0;
  }

  double get _averageRating {
    final feedback = _data?.feedback ?? const <AdminFeedback>[];
    if (feedback.isEmpty) {
      return 0;
    }
    final total = feedback.fold<int>(
      0,
      (sum, item) => sum + item.experienceRating,
    );
    return total / feedback.length;
  }

  void _showFilters() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AdminColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Bộ lọc phản hồi',
                    style: TextStyle(
                      color: AdminColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: _ratingFilter,
                    decoration: const InputDecoration(
                      labelText: 'Số sao',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Tất cả sao')),
                      DropdownMenuItem(value: 5, child: Text('5 sao')),
                      DropdownMenuItem(value: 4, child: Text('4 sao')),
                      DropdownMenuItem(value: 3, child: Text('3 sao')),
                      DropdownMenuItem(value: 2, child: Text('2 sao')),
                      DropdownMenuItem(value: 1, child: Text('1 sao')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => _ratingFilter = value);
                        setState(() {
                          _ratingFilter = value;
                          _page = 1;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _sort,
                    decoration: const InputDecoration(
                      labelText: 'Sắp xếp',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'newest',
                        child: Text('Mới nhất'),
                      ),
                      DropdownMenuItem(value: 'oldest', child: Text('Cũ nhất')),
                      DropdownMenuItem(
                        value: 'rating_high',
                        child: Text('Đánh giá cao'),
                      ),
                      DropdownMenuItem(
                        value: 'rating_low',
                        child: Text('Đánh giá thấp'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setSheetState(() => _sort = value);
                        setState(() {
                          _sort = value;
                          _page = 1;
                        });
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final visibleFeedback = _visibleFeedback;
    final pagedFeedback = _pagedFeedback;

    return AdminPageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminTopBar(
            title: 'Phản hồi người dùng',
            secondaryAction: AdminCircleButton(
              icon: Icons.notifications_none_rounded,
              tooltip: 'Thông báo',
              onPressed: () {},
              backgroundColor: Colors.white,
            ),
            primaryAction: adminLogoutAction(widget.onLogout),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: RefreshIndicator(
              color: DuoColors.darkYellow,
              onRefresh: _fetchFeedback,
              child: _isLoading
                  ? const AdminLoadingState(label: 'Đang tải phản hồi...')
                  : data == null
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        AdminEmptyState(
                          icon: Icons.rate_review_outlined,
                          title: 'Chưa tải được phản hồi',
                          message: 'Kéo xuống để thử tải lại dữ liệu.',
                        ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _FeedbackSummaryRow(
                          total: data.feedbackCount,
                          average: _averageRating,
                        ),
                        const SizedBox(height: 12),
                        _RatingDistributionPanel(feedback: data.feedback),
                        const SizedBox(height: 12),
                        _RatingQuickFilters(
                          selectedRating: _ratingFilter,
                          onChanged: (rating) {
                            setState(() {
                              _ratingFilter = rating;
                              _page = 1;
                            });
                          },
                        ),
                        const SizedBox(height: 10),
                        AdminSearchBar(
                          hintText: 'Tìm kiếm theo tên hoặc nội dung...',
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                              _page = 1;
                            });
                          },
                          onFilter: _showFilters,
                        ),
                        const SizedBox(height: 14),
                        AdminSectionTitle(
                          icon: Icons.rate_review_rounded,
                          title: 'Phản hồi gần đây',
                          trailing: _FeedbackPill(
                            label: '${visibleFeedback.length} mục',
                            color: AdminColors.amber,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (visibleFeedback.isEmpty)
                          const AdminEmptyState(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'Không có phản hồi phù hợp',
                            message: 'Thử đổi bộ lọc hoặc từ khóa tìm kiếm.',
                          )
                        else
                          ...pagedFeedback.map(
                            (feedback) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _FeedbackCard(item: feedback),
                            ),
                          ),
                        if (visibleFeedback.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          AdminPagination(
                            page: _page,
                            totalPages: _feedbackTotalPages,
                            onPrevious: _page > 1
                                ? () => setState(() => _page--)
                                : null,
                            onNext: _page < _feedbackTotalPages
                                ? () => setState(() => _page++)
                                : null,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackSummaryRow extends StatelessWidget {
  const _FeedbackSummaryRow({required this.total, required this.average});

  final int total;
  final double average;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Tổng số phản hồi',
            value: _formatNumber(total),
            icon: Icons.forum_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Đánh giá trung bình',
            value: average == 0 ? '0.0 ★' : '${average.toStringAsFixed(1)} ★',
            icon: Icons.star_rounded,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0D77A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ),
              Icon(icon, color: AdminColors.amber, size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdminColors.amber,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingDistributionPanel extends StatelessWidget {
  const _RatingDistributionPanel({required this.feedback});

  final List<AdminFeedback> feedback;

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (var rating = 1; rating <= 5; rating++)
        rating: feedback
            .where((item) => item.experienceRating == rating)
            .length,
    };
    final total = math.max(1, feedback.length);

    return AdminPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Phân bổ đánh giá',
            style: TextStyle(
              color: AdminColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          for (final rating in [5, 4, 3, 2, 1]) ...[
            _RatingBar(
              rating: rating,
              percent: counts[rating]! / total,
              color: switch (rating) {
                5 => const Color(0xFFFFD45A),
                4 => const Color(0xFF78C7FF),
                3 => const Color(0xFF62D6A4),
                2 => const Color(0xFFF3B1C2),
                _ => const Color(0xFFE0D7B9),
              },
            ),
            if (rating != 1) const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.rating,
    required this.percent,
    required this.color,
  });

  final int rating;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final displayPercent = (percent * 100).round();

    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(
            '$rating',
            style: const TextStyle(
              color: AdminColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent.clamp(0, 1),
              minHeight: 10,
              color: color,
              backgroundColor: const Color(0xFFF0EBDD),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 36,
          child: Text(
            '$displayPercent%',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: AdminColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingQuickFilters extends StatelessWidget {
  const _RatingQuickFilters({
    required this.selectedRating,
    required this.onChanged,
  });

  final int selectedRating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: 'Tất cả',
          selected: selectedRating == 0,
          onTap: () => onChanged(0),
        ),
        for (final rating in [5, 4, 3, 2, 1])
          _FilterChip(
            label: '$rating sao',
            selected: selectedRating == rating,
            onTap: () => onChanged(rating),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? DuoColors.primaryYellow : AdminColors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 76,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? DuoColors.darkYellow : AdminColors.line,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? AdminColors.ink : AdminColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackPill extends StatelessWidget {
  const _FeedbackPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.item});

  final AdminFeedback item;

  @override
  Widget build(BuildContext context) {
    final name = _displayName(item.email);
    final note = item.note.isNotEmpty
        ? item.note
        : 'Người dùng chưa để lại nội dung chi tiết.';

    return AdminPanel(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: DuoColors.primaryYellow.withValues(
                  alpha: 0.75,
                ),
                child: Text(
                  adminInitial(name),
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AdminColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _Stars(value: item.experienceRating),
              const SizedBox(width: 8),
              Text(
                _relativeTime(item.submittedAt),
                style: const TextStyle(
                  color: AdminColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AdminColors.ink,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (item.source.isNotEmpty || item.ageFit.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (item.source.isNotEmpty)
                  _FeedbackPill(label: item.source, color: AdminColors.blue),
                if (item.ageFit.isNotEmpty)
                  _FeedbackPill(label: item.ageFit, color: AdminColors.green),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: const TextStyle(
            color: AdminColors.amber,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 2),
        const Icon(Icons.star_rounded, size: 15, color: AdminColors.amber),
      ],
    );
  }
}

String _formatNumber(int value) {
  return value.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}

String _displayName(String email) {
  if (email.trim().isEmpty) {
    return 'Người dùng ẩn danh';
  }
  final local = email.split('@').first.replaceAll(RegExp(r'[._-]+'), ' ');
  final words = local.split(' ').where((part) => part.trim().isNotEmpty);
  final name = words
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
  return name.isEmpty ? email : name;
}

String _relativeTime(DateTime? date) {
  if (date == null) {
    return 'vừa xong';
  }
  final diff = DateTime.now().difference(date.toLocal());
  if (diff.inMinutes < 1) {
    return 'vừa xong';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes} phút trước';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours} giờ trước';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays} ngày trước';
  }
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
