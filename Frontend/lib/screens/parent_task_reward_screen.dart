import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/reward_model.dart';
import '../models/task_model.dart';
import '../services/family_service.dart';
import '../services/task_reward_service.dart';

class PresetTaskTemplate {
  final String title;
  final String description;
  final int defaultPoints;
  final String category;
  final String icon;

  const PresetTaskTemplate({
    required this.title,
    required this.description,
    required this.defaultPoints,
    required this.category,
    required this.icon,
  });
}

class PresetRewardTemplate {
  final String title;
  final String description;
  final int defaultCost;
  final String category;
  final String icon;

  const PresetRewardTemplate({
    required this.title,
    required this.description,
    required this.defaultCost,
    required this.category,
    required this.icon,
  });
}

class ParentTaskRewardScreen extends StatefulWidget {
  final int parentId;
  final int childId;

  const ParentTaskRewardScreen({
    super.key,
    required this.parentId,
    required this.childId,
  });

  @override
  State<ParentTaskRewardScreen> createState() => _ParentTaskRewardScreenState();
}

class _ParentTaskRewardScreenState extends State<ParentTaskRewardScreen> {
  final TaskRewardService _taskService = TaskRewardService();
  final FamilyService _familyService = FamilyService();
  final ImagePicker _picker = ImagePicker();

  // Task controllers
  final _taskTitleController = TextEditingController();
  final _taskDescController = TextEditingController();
  final _taskPointsController = TextEditingController(text: '20');

  // Reward controllers
  final _rewardTitleController = TextEditingController();
  final _rewardDescController = TextEditingController();
  final _rewardCostController = TextEditingController(text: '50');
  final _rewardIconUrlController = TextEditingController();
  String _selectedRewardCategory = 'Đặc quyền';

  List<Map<String, dynamic>> _childrenList = [];
  late int _selectedChildId;

  List<ChildTaskModel> _tasks = [];
  List<RewardItemModel> _rewards = [];
  List<RewardRedemptionModel> _redemptions = [];
  Map<String, dynamic>? _childOverview;
  bool _isLoading = true;
  int _selectedMainTab = 0; // 0: Nhiệm Vụ, 1: Phần Thưởng
  String _selectedFilter = 'Tất cả';
  String _selectedPresetCategory = 'Tất cả';

  final List<String> _filters = [
    'Tất cả',
    'Chưa hoàn thành',
    'Đã hoàn thành',
  ];

  final List<String> _rewardCategories = [
    'Đặc quyền',
    'Đồ dùng học tập',
    'Đồ chơi',
    'Giải trí',
    'Quà tặng',
  ];

  // Preset tasks library
  final List<PresetTaskTemplate> _presetTasks = const [
    PresetTaskTemplate(
      title: 'Tự gấp chăn sau khi ngủ dậy',
      description: 'Gấp chăn gối gọn gàng ngay khi thức dậy',
      defaultPoints: 20,
      category: 'Việc nhà',
      icon: '🛏️',
    ),
    PresetTaskTemplate(
      title: 'Thu dọn đồ chơi ngăn nắp',
      description: 'Xếp đồ chơi vào thùng gọn gàng sau khi chơi',
      defaultPoints: 15,
      category: 'Việc nhà',
      icon: '🧸',
    ),
    PresetTaskTemplate(
      title: 'Tự gấp và xếp quần áo',
      description: 'Gấp quần áo sạch và cất vào tủ đồ',
      defaultPoints: 25,
      category: 'Việc nhà',
      icon: '👕',
    ),
    PresetTaskTemplate(
      title: 'Lau bàn ăn sau bữa tối',
      description: 'Dùng khăn sạch lau bàn ăn gọn gàng',
      defaultPoints: 15,
      category: 'Việc nhà',
      icon: '🍽️',
    ),
    PresetTaskTemplate(
      title: 'Tự rửa ly uống nước',
      description: 'Rửa sạch ly uống nước sau khi dùng xong',
      defaultPoints: 10,
      category: 'Việc nhà',
      icon: '🥛',
    ),
    PresetTaskTemplate(
      title: 'Đọc sách 15 phút',
      description: 'Đọc sách truyện hoặc sách bài học tự chọn',
      defaultPoints: 20,
      category: 'Học tập',
      icon: '📖',
    ),
    PresetTaskTemplate(
      title: 'Hoàn thành bài tập về nhà',
      description: 'Hoàn thành bài tập trường giao đúng giờ',
      defaultPoints: 30,
      category: 'Học tập',
      icon: '✍️',
    ),
    PresetTaskTemplate(
      title: 'Ôn tập Tiếng Anh 10 phút',
      description: 'Mở ứng dụng học từ mới hoặc nghe tiếng Anh',
      defaultPoints: 20,
      category: 'Học tập',
      icon: '🔤',
    ),
    PresetTaskTemplate(
      title: 'Soạn sách vở theo thời khóa biểu',
      description: 'Chuẩn bị cặp sách đầy đủ cho ngày mai',
      defaultPoints: 15,
      category: 'Học tập',
      icon: '🎒',
    ),
    PresetTaskTemplate(
      title: 'Đánh răng đúng giờ (Sáng & Tối)',
      description: 'Đánh răng sạch trong 2 phút mỗi buổi',
      defaultPoints: 15,
      category: 'Thói quen tốt',
      icon: '🪥',
    ),
    PresetTaskTemplate(
      title: 'Đi ngủ đúng 9 giờ tối',
      description: 'Tắt đèn và lên giường đi ngủ đúng giờ',
      defaultPoints: 25,
      category: 'Thói quen tốt',
      icon: '🌙',
    ),
    PresetTaskTemplate(
      title: 'Uống đủ 1 lít nước trong ngày',
      description: 'Uống nước đều đặn suốt cả ngày',
      defaultPoints: 15,
      category: 'Thói quen tốt',
      icon: '💧',
    ),
    PresetTaskTemplate(
      title: 'Tập thể dục / Vận động 20 phút',
      description: 'Chạy nhảy, tập thể dục nhẹ nhàng nâng cao sức khỏe',
      defaultPoints: 20,
      category: 'Thói quen tốt',
      icon: '🏃',
    ),
  ];

  // Preset rewards library
  final List<PresetRewardTemplate> _presetRewards = const [
    PresetRewardTemplate(
      title: 'Xem TV / Phim hoạt hình 30 phút',
      description: 'Được xem chương trình bé yêu thích thêm 30 phút',
      defaultCost: 30,
      category: 'Đặc quyền',
      icon: '📺',
    ),
    PresetRewardTemplate(
      title: 'Được thức muộn thêm 30 phút buổi tối',
      description: 'Đặc quyền thức chơi thêm 30 phút tối cuối tuần',
      defaultCost: 50,
      category: 'Đặc quyền',
      icon: '🌙',
    ),
    PresetRewardTemplate(
      title: 'Chơi Game / iPad 20 phút',
      description: 'Thời gian giải trí chơi game bé thích trên máy tính bảng',
      defaultCost: 40,
      category: 'Giải trí',
      icon: '🎮',
    ),
    PresetRewardTemplate(
      title: 'Một cây kem lạnh tự chọn',
      description: 'Thưởng 1 cây kem ngon tuyệt vị bé thích',
      defaultCost: 20,
      category: 'Quà tặng',
      icon: '🍦',
    ),
    PresetRewardTemplate(
      title: 'Một bữa ăn Pizza / Gà rán tự chọn',
      description: 'Bố mẹ thưởng bữa ăn cuối tuần bé yêu thích',
      defaultCost: 120,
      category: 'Quà tặng',
      icon: '🍕',
    ),
    PresetRewardTemplate(
      title: 'Đi chơi công viên / Khu vui chơi',
      description: 'Một buổi chiều vui chơi thỏa thích cùng bố mẹ',
      defaultCost: 100,
      category: 'Hoạt động',
      icon: '🎡',
    ),
    PresetRewardTemplate(
      title: 'Bộ màu vẽ 24 màu mới',
      description: 'Dụng cụ học tập tô màu sáng tạo dành cho bé',
      defaultCost: 80,
      category: 'Đồ dùng học tập',
      icon: '🎨',
    ),
    PresetRewardTemplate(
      title: 'Gấu bông / Đồ chơi bé thích',
      description: 'Phần thưởng lớn cho chuỗi ngày hoàn thành nhiệm vụ xuất sắc',
      defaultCost: 150,
      category: 'Đồ chơi',
      icon: '🧸',
    ),
    PresetRewardTemplate(
      title: 'Cuốn sách truyện tranh mới',
      description: 'Cuốn sách truyện tranh hoặc sách khám phá bé chọn',
      defaultCost: 60,
      category: 'Đồ dùng học tập',
      icon: '📚',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.childId;
    _loadData();
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    _taskDescController.dispose();
    _taskPointsController.dispose();
    _rewardTitleController.dispose();
    _rewardDescController.dispose();
    _rewardCostController.dispose();
    _rewardIconUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final children = await _familyService.getChildren();
      List<Map<String, dynamic>> parsedChildren = children;
      if (parsedChildren.isEmpty) {
        parsedChildren = [
          {'id': widget.childId, 'name': 'Bé SmartSteps (ID: ${widget.childId})'},
          {'id': widget.childId == 1 ? 2 : 1, 'name': 'Bé Nam'},
        ];
      }

      final tasks = await _taskService.getTasksForChild(_selectedChildId);
      final rewards = await _taskService.getRewards(parentId: widget.parentId);
      final redemptions = await _taskService.getRedemptions(childId: _selectedChildId);
      Map<String, dynamic>? overview;
      try {
        overview = await _familyService.getOverview(_selectedChildId);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _childrenList = parsedChildren;
          _tasks = tasks;
          _rewards = rewards;
          _redemptions = redemptions;
          _childOverview = overview;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Pick image from local computer/device ---
  Future<void> _pickRewardImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final mimeType = pickedFile.mimeType ?? 'image/jpeg';
        final base64String = base64Encode(bytes);
        final dataUrl = 'data:$mimeType;base64,$base64String';

        setState(() {
          _rewardIconUrlController.text = dataUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🖼️ Đã chọn file ảnh thành công!'),
              backgroundColor: const Color(0xFF006C52),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking reward image: $e');
    }
  }

  // --- Task Approval (Phê duyệt nhiệm vụ) ---
  Future<void> _approveTask(ChildTaskModel task) async {
    final messenger = ScaffoldMessenger.of(context);
    final success = await _taskService.approveTaskDirect(task.taskId);
    if (success && mounted) {
      _loadData();
      messenger.showSnackBar(
        SnackBar(
          content: Text('🎉 Đã phê duyệt nhiệm vụ "${task.title}"! Bé được cộng +${task.rewardPoints} Xu.'),
          backgroundColor: const Color(0xFF006C52),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // --- Approve / Reject Child Redemption Requests ---
  Future<void> _approveRedemption(RewardRedemptionModel redemption) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _taskService.approveRedemption(redemption.redemptionId);
    if (ok && mounted) {
      _loadData();
      messenger.showSnackBar(
        SnackBar(
          content: Text('🎉 Đã phê duyệt yêu cầu đổi quà "${redemption.rewardTitle}" cho bé!'),
          backgroundColor: const Color(0xFF006C52),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _rejectRedemption(RewardRedemptionModel redemption) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _taskService.rejectRedemption(redemption.redemptionId);
    if (ok && mounted) {
      _loadData();
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Đã từ chối yêu cầu đổi quà "${redemption.rewardTitle}".'),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // --- Assign Preset Task directly ---
  Future<void> _assignPresetTask(PresetTaskTemplate preset) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    await _taskService.createTask(
      parentId: widget.parentId,
      childId: _selectedChildId,
      title: preset.title,
      description: preset.description,
      rewardPoints: preset.defaultPoints,
    );

    if (mounted) {
      nav.pop();
      _loadData();
      messenger.showSnackBar(
        SnackBar(
          content: Text('✨ Đã giao nhiệm vụ "${preset.title}" (+${preset.defaultPoints} Xu) cho bé!'),
          backgroundColor: const Color(0xFF006C52),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // --- Create Preset Reward directly ---
  Future<void> _createPresetReward(PresetRewardTemplate preset) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final created = await _taskService.createReward(
      parentId: widget.parentId,
      title: preset.title,
      description: preset.description,
      costPoints: preset.defaultCost,
      rewardType: preset.category,
      iconUrl: preset.icon,
    );

    if (mounted && created != null) {
      nav.pop();
      _loadData();
      messenger.showSnackBar(
        SnackBar(
          content: Text('🎁 Đã tạo phần thưởng "${preset.title}" (${preset.defaultCost} Xu)!'),
          backgroundColor: const Color(0xFF006C52),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không thể tạo phần thưởng. Vui lòng thử lại.')),
      );
    }
  }

  // --- Create Custom Task ---
  Future<void> _createNewCustomTask() async {
    if (_taskTitleController.text.trim().isEmpty) return;

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final points = int.tryParse(_taskPointsController.text) ?? 20;

    await _taskService.createTask(
      parentId: widget.parentId,
      childId: _selectedChildId,
      title: _taskTitleController.text.trim(),
      description: _taskDescController.text.trim(),
      rewardPoints: points,
    );

    if (mounted) {
      _taskTitleController.clear();
      _taskDescController.clear();
      nav.pop();
      _loadData();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('✨ Đã tạo và giao nhiệm vụ mới thành công!'),
          backgroundColor: const Color(0xFF006C52),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // --- Create Custom Reward (Phần Thưởng) ---
  Future<void> _createNewCustomReward() async {
    if (_rewardTitleController.text.trim().isEmpty) return;

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final cost = int.tryParse(_rewardCostController.text) ?? 50;

    final created = await _taskService.createReward(
      parentId: widget.parentId,
      title: _rewardTitleController.text.trim(),
      description: _rewardDescController.text.trim(),
      costPoints: cost,
      rewardType: _selectedRewardCategory,
      iconUrl: _rewardIconUrlController.text.trim().isNotEmpty ? _rewardIconUrlController.text.trim() : '🎁',
    );

    if (mounted && created != null) {
      _rewardTitleController.clear();
      _rewardDescController.clear();
      _rewardCostController.text = '50';
      _rewardIconUrlController.clear();
      nav.pop();
      _loadData();
      messenger.showSnackBar(
        SnackBar(
          content: Text('🎁 Đã tạo phần thưởng "$cost Xu" thành công!'),
          backgroundColor: const Color(0xFF006C52),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else if (mounted) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Không thể tạo phần thưởng. Vui lòng thử lại.')),
      );
    }
  }

  // --- Edit Task ---
  Future<void> _updateTask(ChildTaskModel task) async {
    if (_taskTitleController.text.trim().isEmpty) return;

    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final points = int.tryParse(_taskPointsController.text) ?? task.rewardPoints;

    await _taskService.updateTask(
      taskId: task.taskId,
      title: _taskTitleController.text.trim(),
      description: _taskDescController.text.trim(),
      rewardPoints: points,
    );

    if (mounted) {
      _taskTitleController.clear();
      _taskDescController.clear();
      nav.pop();
      _loadData();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('✏️ Đã cập nhật nhiệm vụ thành công!'),
          backgroundColor: const Color(0xFF785A00),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // --- Delete Task ---
  Future<void> _confirmDeleteTask(ChildTaskModel task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận xóa nhiệm vụ', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa nhiệm vụ "${task.title}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBA1A1A)),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _taskService.deleteTask(task.taskId);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🗑️ Đã xóa nhiệm vụ thành công'),
            backgroundColor: const Color(0xFFBA1A1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // --- Modals ---
  void _showEditTaskModal(ChildTaskModel task) {
    _taskTitleController.text = task.title;
    _taskDescController.text = task.description ?? '';
    _taskPointsController.text = task.rewardPoints.toString();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chỉnh Sửa Nhiệm Vụ ✏️', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _taskTitleController,
                decoration: InputDecoration(
                  labelText: 'Tên nhiệm vụ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taskDescController,
                decoration: InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taskPointsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Số Xu thưởng (+Xu)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _updateTask(task),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC83D),
                    foregroundColor: const Color(0xFF715400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Cập Nhật Nhiệm Vụ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTaskModal() {
    _taskTitleController.clear();
    _taskDescController.clear();
    _taskPointsController.text = '20';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Container(
          width: 650,
          constraints: const BoxConstraints(maxHeight: 650),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Giao Nhiệm Vụ Cho Bé ⚡', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7ECDD),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const TabBar(
                          labelColor: Color(0xFF785A00),
                          unselectedLabelColor: Color(0xFF817661),
                          indicatorColor: Color(0xFFFFC83D),
                          indicatorWeight: 3,
                          tabs: [
                            Tab(text: '📚 Thư viện mẫu'),
                            Tab(text: '✏️ Tạo nhiệm vụ mới'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          children: [
                            // Tab 1: Preset Tasks Library
                            Column(
                              children: [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: ['Tất cả', 'Việc nhà', 'Học tập', 'Thói quen tốt'].map((cat) {
                                      final isSel = _selectedPresetCategory == cat;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: FilterChip(
                                          selected: isSel,
                                          label: Text(cat),
                                          selectedColor: const Color(0xFFFFC83D),
                                          onSelected: (_) => setState(() => _selectedPresetCategory = cat),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: ListView(
                                    children: _presetTasks
                                        .where((p) => _selectedPresetCategory == 'Tất cả' || p.category == _selectedPresetCategory)
                                        .map((preset) => Card(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                              child: ListTile(
                                                leading: Text(preset.icon, style: const TextStyle(fontSize: 28)),
                                                title: Text(preset.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                subtitle: Text(preset.description),
                                                trailing: ElevatedButton.icon(
                                                  onPressed: () => _assignPresetTask(preset),
                                                  icon: const Icon(Icons.add_task_rounded, size: 16),
                                                  label: Text('Giao ngay (+${preset.defaultPoints} Xu)'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFFFFC83D),
                                                    foregroundColor: const Color(0xFF715400),
                                                    elevation: 0,
                                                  ),
                                                ),
                                              ),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                            // Tab 2: Custom Task Form
                            SingleChildScrollView(
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _taskTitleController,
                                    decoration: InputDecoration(
                                      labelText: 'Tên nhiệm vụ',
                                      hintText: 'VD: Tưới cây ban công, Rửa chén...',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _taskDescController,
                                    decoration: InputDecoration(
                                      labelText: 'Mô tả chi tiết',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _taskPointsController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Số Xu thưởng (+Xu)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: _createNewCustomTask,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFFC83D),
                                        foregroundColor: const Color(0xFF715400),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: const Text('Tạo Nhiệm Vụ ⚡', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddRewardModal() {
    _rewardTitleController.clear();
    _rewardDescController.clear();
    _rewardCostController.text = '50';
    _rewardIconUrlController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: Container(
              width: 650,
              constraints: const BoxConstraints(maxHeight: 650),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tạo Phần Thưởng Mới 🎁', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7ECDD),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const TabBar(
                              labelColor: Color(0xFF785A00),
                              unselectedLabelColor: Color(0xFF817661),
                              indicatorColor: Color(0xFFFFC83D),
                              indicatorWeight: 3,
                              tabs: [
                                Tab(text: '🎁 Thư viện quà mẫu'),
                                Tab(text: '✏️ Tự tạo quà & Chọn ảnh'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: TabBarView(
                              children: [
                                // Tab 1: Preset Rewards Library
                                Column(
                                  children: [
                                    Expanded(
                                      child: ListView(
                                        children: _presetRewards
                                            .map((preset) => Card(
                                                  margin: const EdgeInsets.only(bottom: 8),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                  child: ListTile(
                                                    leading: Text(preset.icon, style: const TextStyle(fontSize: 28)),
                                                    title: Text(preset.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                                    subtitle: Text(preset.description),
                                                    trailing: ElevatedButton.icon(
                                                      onPressed: () => _createPresetReward(preset),
                                                      icon: const Icon(Icons.card_giftcard_rounded, size: 16),
                                                      label: Text('Tạo quà (${preset.defaultCost} Xu)'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFFFFC83D),
                                                        foregroundColor: const Color(0xFF715400),
                                                        elevation: 0,
                                                      ),
                                                    ),
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                  ],
                                ),
                                // Tab 2: Custom Reward Form with File Picker & Image URL
                                SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      TextField(
                                        controller: _rewardTitleController,
                                        decoration: InputDecoration(
                                          labelText: 'Tên phần thưởng',
                                          hintText: 'VD: Đi công viên đầm sen, Xem TV 30 phút...',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _rewardDescController,
                                        decoration: InputDecoration(
                                          labelText: 'Mô tả chi tiết phần thưởng',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      TextField(
                                        controller: _rewardCostController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: 'Số Coin / Xu bé cần đổi (VD: 50, 100)',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _rewardIconUrlController,
                                              decoration: InputDecoration(
                                                labelText: 'Ảnh minh họa (Link Web / Emoji / File đã chọn)',
                                                hintText: 'Dán link web, emoji hoặc bấm chọn file...',
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              await _pickRewardImage();
                                              setModalState(() {});
                                            },
                                            icon: const Icon(Icons.photo_library_rounded, size: 20),
                                            label: const Text('Chọn ảnh'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFFFFC83D),
                                              foregroundColor: const Color(0xFF715400),
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<String>(
                                        value: _selectedRewardCategory,
                                        decoration: InputDecoration(
                                          labelText: 'Loại phần thưởng',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        items: _rewardCategories
                                            .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                                            .toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _selectedRewardCategory = val);
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: _createNewCustomReward,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFFFFC83D),
                                            foregroundColor: const Color(0xFF715400),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                          child: const Text('Lưu & Tạo Phần Thưởng 🎁', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRewardIcon(String? iconUrl, {double size = 28}) {
    if (iconUrl != null && (iconUrl.startsWith('http://') || iconUrl.startsWith('https://') || iconUrl.startsWith('data:image/'))) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          iconUrl,
          width: size * 1.6,
          height: size * 1.6,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text('🎁', style: TextStyle(fontSize: size)),
        ),
      );
    }
    return Text(
      iconUrl != null && iconUrl.isNotEmpty ? iconUrl : '🎁',
      style: TextStyle(fontSize: size),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF201B12)),
        title: const Text(
          'Quản Lý Nhiệm Vụ & Phê Duyệt Quà',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            color: Color(0xFF785A00),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF785A00)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Child Selector Header
                    _buildChildSelectorHeader(),

                    // Dynamic Child Overview Banner
                    _buildDynamicChildOverviewCard(),
                    const SizedBox(height: 16),

                    // Main Tab Switcher (Nhiệm vụ ⚡ | Cửa hàng quà 🎁)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7ECDD),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedMainTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedMainTab == 0 ? const Color(0xFFFFC83D) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Nhiệm Vụ Cho Bé ⚡',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: _selectedMainTab == 0 ? const Color(0xFF715400) : const Color(0xFF817661),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedMainTab = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedMainTab == 1 ? const Color(0xFFFFC83D) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'Cửa Hàng Quà Tặng 🎁',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: _selectedMainTab == 1 ? const Color(0xFF715400) : const Color(0xFF817661),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    if (_selectedMainTab == 0) ...[
                      // Filter Chips
                      _buildFilterChips(),
                      const SizedBox(height: 20),
                      // Tasks List
                      _buildTasksListSection(),
                    ] else ...[
                      // Rewards Section
                      _buildRewardsSection(),
                    ],
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedMainTab == 0 ? _showAddTaskModal : _showAddRewardModal,
        backgroundColor: const Color(0xFFFFC83D),
        foregroundColor: const Color(0xFF715400),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF201B12), width: 2.5),
        ),
        icon: Icon(_selectedMainTab == 0 ? Icons.add_rounded : Icons.card_giftcard_rounded, size: 28),
        label: Text(
          _selectedMainTab == 0 ? 'Giao Nhiệm Vụ' : 'Tạo Phần Thưởng',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        ),
      ),
    );
  }

  // 0. Child Selector Header
  Widget _buildChildSelectorHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFC83D), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFFFFC83D), offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.child_care_rounded, color: Color(0xFF785A00), size: 26),
          const SizedBox(width: 10),
          const Text(
            'Đang xem bé:',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 15,
              color: Color(0xFF785A00),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _childrenList.map((child) {
                  final int cId = child['id'] ?? child['userId'] ?? 1;
                  final String cName = child['name'] ?? child['fullName'] ?? 'Bé $cId';
                  final bool isSelected = _selectedChildId == cId;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(cName, style: TextStyle(fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold)),
                      avatar: CircleAvatar(
                        backgroundColor: isSelected ? const Color(0xFF785A00) : Colors.amber.shade100,
                        child: const Text('👦', style: TextStyle(fontSize: 14)),
                      ),
                      selectedColor: const Color(0xFFFFC83D),
                      backgroundColor: const Color(0xFFFFF8F2),
                      onSelected: (selected) {
                        if (selected && _selectedChildId != cId) {
                          setState(() {
                            _selectedChildId = cId;
                          });
                          _loadData();
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Dynamic Child Overview Banner
  Widget _buildDynamicChildOverviewCard() {
    final completed = _childOverview?['completedLessons'] ?? 0;
    final totalStarted = _childOverview?['startedLessons'] ?? 0;
    final accuracy = _childOverview?['accuracy'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF817661), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFF817661), offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFFFFDF9C),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFC83D), width: 3),
            ),
            child: const Center(
              child: Text('👦', style: TextStyle(fontSize: 38)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng Quan Bài Học & Xu Thưởng (Bé ID: $_selectedChildId)',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF201B12),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildOverviewBadge('📚 Bài làm: $completed/$totalStarted'),
                    const SizedBox(width: 8),
                    _buildOverviewBadge('🎯 Chính xác: $accuracy%'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF7ECDD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEBE1D2)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF672D00),
        ),
      ),
    );
  }

  // 2. Filter Chips
  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFC83D) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF785A00) : const Color(0xFFD2C5AD),
                    width: 2,
                  ),
                  boxShadow: isSelected
                      ? const [BoxShadow(color: Color(0xFF785A00), offset: Offset(0, 3))]
                      : null,
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
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

  // 3. Tasks List Section (With Approve Action)
  Widget _buildTasksListSection() {
    List<ChildTaskModel> filteredTasks = _tasks;
    if (_selectedFilter == 'Chưa hoàn thành') {
      filteredTasks = _tasks.where((t) => t.status != 'Approved').toList();
    } else if (_selectedFilter == 'Đã hoàn thành') {
      filteredTasks = _tasks.where((t) => t.status == 'Approved' || t.status == 'Completed').toList();
    }

    if (filteredTasks.isEmpty) {
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
            const Icon(Icons.assignment_turned_in_outlined, size: 48, color: Color(0xFF817661)),
            const SizedBox(height: 12),
            Text(
              'Chưa có nhiệm vụ nào cho bé (ID: $_selectedChildId)!',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4F4634)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bấm nút "Giao Nhiệm Vụ" bên dưới để chọn nhiệm vụ mẫu hoặc tạo mới.',
              style: TextStyle(fontSize: 12, color: Color(0xFF817661)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: filteredTasks.map((task) {
        final isApproved = task.status == 'Approved';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isApproved ? const Color(0xFF006C52) : const Color(0xFF201B12),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isApproved ? const Color(0xFF006C52) : const Color(0xFF201B12),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isApproved ? const Color(0xFF55E7BA) : const Color(0xFFFFDF9C),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isApproved ? const Color(0xFF006C52) : const Color(0xFF785A00),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isApproved ? '✅' : '📋',
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF201B12),
                            decoration: isApproved ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        if (task.description != null && task.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            task.description!,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF4F4634)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isApproved ? const Color(0xFF55E7BA) : const Color(0xFFFFDF9C),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isApproved ? const Color(0xFF006C52) : const Color(0xFF785A00),
                      ),
                    ),
                    child: Text(
                      isApproved ? 'Đã phê duyệt' : 'Chưa duyệt',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: isApproved ? const Color(0xFF00654D) : const Color(0xFF715400),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1E7D8)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '+${task.rewardPoints} Xu thưởng',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Approve Button if not approved yet
                      if (!isApproved) ...[
                        ElevatedButton.icon(
                          onPressed: () => _approveTask(task),
                          icon: const Icon(Icons.check_circle_rounded, size: 16),
                          label: Text('Phê duyệt (+${task.rewardPoints} Xu)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF006C52),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        onPressed: () => _showEditTaskModal(task),
                        icon: const Icon(Icons.edit_rounded, color: Color(0xFF785A00), size: 22),
                        tooltip: 'Chỉnh sửa nhiệm vụ',
                      ),
                      IconButton(
                        onPressed: () => _confirmDeleteTask(task),
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFBA1A1A), size: 22),
                        tooltip: 'Xóa nhiệm vụ',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 4. Pending Child Redemptions Section (Yêu cầu đổi quà từ bé chờ duyệt)
  Widget _buildPendingRedemptionsSection() {
    final pendingList = _redemptions.where((r) => r.status == 'Pending').toList();
    if (pendingList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.notifications_active_rounded, color: Color(0xFFE86D1F), size: 22),
            const SizedBox(width: 8),
            Text(
              'Yêu Cầu Đổi Quà Từ Bé (ID: $_selectedChildId) (${pendingList.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF201B12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...pendingList.map((redemption) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0B8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFECC55A), width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0xFFECC55A), offset: Offset(0, 3)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('👦', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bé (ID: $_selectedChildId) yêu cầu đổi quà: ${redemption.rewardTitle}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF201B12),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Đã dùng ${redemption.pointsSpent} Xu để yêu cầu đổi quà',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF785A00)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => _rejectRedemption(redemption),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFBA1A1A),
                        side: const BorderSide(color: Color(0xFFBA1A1A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _approveRedemption(redemption),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('Duyệt trao quà ✅'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006C52),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }

  // 5. Rewards List Section (Parent Rewards Management)
  Widget _buildRewardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPendingRedemptionsSection(),
        if (_rewards.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD2C5AD), width: 2),
            ),
            child: Column(
              children: [
                const Icon(Icons.card_giftcard_rounded, size: 48, color: Color(0xFF817661)),
                const SizedBox(height: 12),
                const Text(
                  'Chưa có phần thưởng nào!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF4F4634)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Nhấn nút "Tạo Phần Thưởng" bên dưới để chọn phần thưởng mẫu hoặc chọn ảnh từ máy.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF817661)),
                ),
              ],
            ),
          ),
        ] else ...[
          ..._rewards.map((reward) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFFC83D), width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF785A00), offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDF9C),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: _buildRewardIcon(reward.iconUrl, size: 28),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reward.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF201B12),
                          ),
                        ),
                        if (reward.description != null && reward.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            reward.description!,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF4F4634)),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0B8),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFECC55A)),
                          ),
                          child: Text(
                            '💰 Giá đổi: ${reward.costPoints} Xu',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF785A00),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}
