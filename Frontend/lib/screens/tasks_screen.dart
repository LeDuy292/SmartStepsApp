import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/task_reward_service.dart';

class TasksScreen extends StatefulWidget {
  final int childId;
  final int currentPoints;
  final ValueChanged<int>? onPointsChanged;

  const TasksScreen({
    super.key,
    required this.childId,
    this.currentPoints = 1250,
    this.onPointsChanged,
  });

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final TaskRewardService _service = TaskRewardService();
  bool _isLoading = true;
  List<ChildTaskModel> _tasks = [];
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _points = widget.currentPoints;
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final list = await _service.getTasksForChild(widget.childId);
    if (mounted) {
      setState(() {
        _tasks = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _completeTask(ChildTaskModel task) async {
    await _service.completeTask(
      taskId: task.taskId,
      childId: widget.childId,
    );

    if (mounted) {
      await _loadTasks();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Text('⭐', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tuyệt vời! Bé đã làm xong nhiệm vụ "${task.title}". Đang chờ Bố Mẹ duyệt để nhận +${task.rewardPoints} Xu!',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF006C52),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF201B12), width: 2),
          ),
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
                onRefresh: _loadTasks,
                color: const Color(0xFF785A00),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      // TopAppBar Header
                      _buildTopAppBar(),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            // Dynamic Hero Journey Banner
                            _buildHeroBanner(),

                            const SizedBox(height: 24),
                            // Tasks List from Backend
                            _buildTasksList(),
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
                  child: Text('👦', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nhiệm Vụ Siêu Anh Hùng ⚡',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF785A00),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sẵn sàng tích lũy Xu thưởng cùng Bố Mẹ!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Stars Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC83D),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF201B12), width: 2),
            ),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$_points Xu',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Color(0xFF715400),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Dynamic Hero Journey Banner
  Widget _buildHeroBanner() {
    final completedCount = _tasks.where((t) => t.status == 'Approved' || t.status == 'Completed').length;
    final totalCount = _tasks.length;
    final double progressFactor = totalCount > 0 ? (completedCount / totalCount).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF201B12), width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF201B12),
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFDF9C),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF785A00), width: 2),
                ),
                child: const Center(
                  child: Text('🦸‍♂️', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hành trình Siêu Anh Hùng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF201B12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ĐÃ HOÀN THÀNH $completedCount/$totalCount NHIỆM VỤ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Dynamic Progress Bar
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFFF7ECDD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD2C5AD)),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progressFactor,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF55E7BA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF006C52)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Tasks List
  Widget _buildTasksList() {
    if (_tasks.isEmpty) {
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
            const Text('⚡', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text(
              'Chưa có nhiệm vụ nào!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4F4634)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bé hãy nhờ Bố Mẹ giao nhiệm vụ mới để tích lũy Xu thưởng nhé.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF817661)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _tasks.map((task) {
        if (task.status == 'Approved' || task.status == 'Completed') {
          return _buildCompletedTaskCard(task);
        } else if (task.status == 'Pending') {
          return _buildPendingTaskCard(task);
        } else {
          return _buildActiveTaskCard(task);
        }
      }).toList(),
    );
  }

  // Task Card: Approved / Completed
  Widget _buildCompletedTaskCard(ChildTaskModel task) {
    final isApproved = task.status == 'Approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF006C52), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFF006C52), offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFF55E7BA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF006C52), width: 2),
            ),
            child: const Center(
              child: Text('✅', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.black54,
                  ),
                ),
                if (task.description != null && task.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.description!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, size: 14, color: Color(0xFF006C52)),
                    const SizedBox(width: 2),
                    Text(
                      '+${task.rewardPoints} Xu thưởng',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF006C52),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF006C52),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isApproved ? 'ĐÃ DUYỆT' : 'HOÀN THÀNH',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Task Card: Active / In Progress
  Widget _buildActiveTaskCard(ChildTaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF201B12), width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xFF201B12), offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFFDF9C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF785A00), width: 2),
            ),
            child: const Center(
              child: Text('📋', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF201B12),
                  ),
                ),
                if (task.description != null && task.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    task.description!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF4F4634)),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, size: 14, color: Color(0xFFB45309)),
                    const SizedBox(width: 2),
                    Text(
                      '+${task.rewardPoints} Xu thưởng',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _completeTask(task),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC83D),
              foregroundColor: const Color(0xFF715400),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFF785A00), width: 2),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Làm ngay',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Task Card: Pending Approval
  Widget _buildPendingTaskCard(ChildTaskModel task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2E3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD2C5AD), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEBE1D2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF817661), width: 2),
            ),
            child: const Center(
              child: Text('⏳', style: TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF201B12),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${task.rewardPoints} Xu · Đang chờ Bố Mẹ duyệt',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Column(
            children: const [
              Icon(Icons.pending_actions_rounded, color: Color(0xFF817661), size: 24),
              SizedBox(height: 2),
              Text(
                'CHỜ DUYỆT',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF817661)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
