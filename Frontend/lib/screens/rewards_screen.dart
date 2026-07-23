import 'package:flutter/material.dart';
import '../models/reward_model.dart';
import '../services/task_reward_service.dart';

class RewardsScreen extends StatefulWidget {
  final int childId;
  final int currentPoints;
  final ValueChanged<int>? onPointsChanged;

  const RewardsScreen({
    super.key,
    required this.childId,
    this.currentPoints = 1250,
    this.onPointsChanged,
  });

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final TaskRewardService _service = TaskRewardService();
  bool _isLoading = true;
  List<RewardItemModel> _rewards = [];
  int _points = 0;
  String _selectedCategory = 'Tất cả';

  final List<String> _categories = [
    'Tất cả',
    'Đặc quyền',
    'Đồ dùng học tập',
    'Đồ chơi',
    'Giải trí',
    'Quà tặng',
  ];

  @override
  void initState() {
    super.initState();
    _points = widget.currentPoints;
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    setState(() => _isLoading = true);
    final list = await _service.getRewards();
    if (mounted) {
      setState(() {
        _rewards = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _redeem(RewardItemModel reward) async {
    if (_points < reward.costPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bé chưa đủ Coin rồi! Cần thêm ${reward.costPoints - _points} Coin nữa.',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }

    final newPoints = _points - reward.costPoints;

    await _service.redeemReward(
      rewardId: reward.rewardId,
      childId: widget.childId,
    );

    if (mounted) {
      setState(() {
        _points = newPoints;
      });
      widget.onPointsChanged?.call(newPoints);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF201B12), width: 2.5),
          ),
          backgroundColor: Colors.white,
          title: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC83D),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF201B12), width: 2),
                ),
                child: const Center(
                  child: Text('🎉', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Đã Gửi Yêu Cầu Đổi Quà!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: Color(0xFF201B12),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Chúc mừng bé đã chọn đổi món quà "${reward.title}"!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF201B12)),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0B8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFECC55A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: Color(0xFFB45309), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Đã trừ: -${reward.costPoints} Xu  |  Còn lại: $newPoints Xu',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        color: Color(0xFF785A00),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Yêu cầu đổi quà đã được gửi tới Bố Mẹ. Bố Mẹ sẽ nhận được thông báo để phê duyệt và trao quà cho bé nhé! 🎁',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF4F4634)),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFC83D),
                  foregroundColor: const Color(0xFF715400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFF201B12), width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Tuyệt vời! 🚀',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9E9),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF785A00)))
            : RefreshIndicator(
                onRefresh: _loadRewards,
                color: const Color(0xFF785A00),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      // Top App Header
                      _buildTopAppBar(),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            // Coin Balance Hero Card
                            _buildCoinBalanceHero(),

                            const SizedBox(height: 20),
                            // Category Horizontal Chips
                            _buildCategoryChips(),

                            const SizedBox(height: 24),
                            // Target Goal Section (Dynamic from API rewards)
                            _buildTargetGoalSection(),

                            const SizedBox(height: 24),
                            // Featured Gifts Grid from Backend
                            _buildFeaturedGiftsGrid(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // 1. Top Header Bar
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFC83D), width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xFF785A00),
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🎁', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cửa Hàng Quà Tặng 🎁',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF785A00),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Đổi Xu tích lũy nhận vô vàn quà hay!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Coin Balance Hero Card
  Widget _buildCoinBalanceHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC83D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF201B12), width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF201B12),
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KHO XU TÍCH LŨY CỦA BÉ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF715400),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 8),
                    Text(
                      '$_points',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF201B12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Xu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF715400),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🏆', style: TextStyle(fontSize: 42)),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Category Horizontal Scroll Chips
  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFC83D) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF201B12) : const Color(0xFFD2C5AD),
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? const [BoxShadow(color: Color(0xFF201B12), offset: Offset(0, 3))]
                      : null,
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF715400) : const Color(0xFF4F4634),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // 4. Target Goal Section (Dynamic from API rewards)
  Widget _buildTargetGoalSection() {
    if (_rewards.isEmpty) return const SizedBox.shrink();

    // Pick highest cost reward as the target goal
    final target = _rewards.reduce((curr, next) => curr.costPoints > next.costPoints ? curr : next);
    final currentPts = _points;
    final targetPts = target.costPoints;
    final double progressFactor = (currentPts / targetPts).clamp(0.0, 1.0);
    final remaining = (targetPts - currentPts).clamp(0, targetPts);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.gps_fixed_rounded, color: Color(0xFFFD8A3C), size: 22),
            SizedBox(width: 8),
            Text(
              'Mục tiêu quà tặng lớn nhất',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF201B12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF201B12), width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF201B12),
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7ECDD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD2C5AD)),
                ),
                child: Center(
                  child: _buildRewardIcon(target),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            target.title,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF201B12),
                            ),
                          ),
                        ),
                        Text(
                          '$targetPts Xu',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFD8A3C),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Stack(
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7ECDD),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD2C5AD)),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: progressFactor,
                          child: Container(
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFD8A3C),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      remaining > 0 ? 'Còn thiếu $remaining Xu nữa để đổi quà!' : 'Bé đã đủ Xu để đổi quà này!',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF817661)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Featured Gifts Grid from Backend API (Responsive with maxCrossAxisExtent)
  Widget _buildFeaturedGiftsGrid() {
    List<RewardItemModel> filtered = _rewards;
    if (_selectedCategory != 'Tất cả') {
      filtered = _rewards.where((r) => r.rewardType == _selectedCategory).toList();
    }

    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD2C5AD), width: 2),
        ),
        child: Column(
          children: [
            const Text('🎁', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Chưa có phần thưởng nào!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4F4634)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bé hãy nhờ Bố Mẹ thêm phần thưởng mới trong danh mục này nhé.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF817661)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisExtent: 250,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final reward = filtered[index];
        final canAfford = _points >= reward.costPoints;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF201B12), width: 2.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFF201B12),
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 85,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2E3),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: _buildRewardIcon(reward),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reward.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF201B12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFC83D), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${reward.costPoints} Xu',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            color: Color(0xFF4F4634),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _redeem(reward),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford ? const Color(0xFFFFC83D) : const Color(0xFFEBE1D2),
                    foregroundColor: canAfford ? const Color(0xFF715400) : const Color(0xFF4F4634),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: canAfford ? const Color(0xFF785A00) : const Color(0xFFD2C5AD),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    canAfford ? 'Đổi ngay' : 'Thiếu Xu',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewardIcon(RewardItemModel reward) {
    final url = reward.iconUrl;
    if (url != null && (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('data:image/'))) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          url,
          width: double.infinity,
          height: 85,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text(_getRewardEmoji(reward.title), style: const TextStyle(fontSize: 38)),
        ),
      );
    }
    if (url != null && url.isNotEmpty) {
      return Text(url, style: const TextStyle(fontSize: 38));
    }
    return Text(_getRewardEmoji(reward.title), style: const TextStyle(fontSize: 38));
  }

  String _getRewardEmoji(String title) {
    if (title.contains('bút')) return '✏️';
    if (title.contains('hoạt hình') || title.contains('TV')) return '📺';
    if (title.contains('Kem')) return '🍦';
    if (title.contains('Pizza') || title.contains('Gà')) return '🍕';
    if (title.contains('Game') || title.contains('iPad')) return '🎮';
    if (title.contains('công viên')) return '🎡';
    if (title.contains('màu')) return '🎨';
    if (title.contains('Đồ chơi') || title.contains('Gấu')) return '🧸';
    if (title.contains('sách') || title.contains('truyện')) return '📚';
    return '🎁';
  }
}
