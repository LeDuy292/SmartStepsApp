import 'dart:async';

import 'package:flutter/material.dart';

import '../models/child_profile.dart';
import '../models/learning_analysis.dart';
import '../models/situation.dart';
import '../services/learning_service.dart';
import '../services/local_profile_storage.dart';
import '../services/situation_service.dart';
import '../theme/duo_theme.dart';
import '../widgets/duo_components.dart';

class _LearnMascots {
  const _LearnMascots._();

  static const happyWave = 'assets/images/mascot/mascot-cat-happy-wave.webp';
  static const speaking = 'assets/images/mascot/mascot-cat-speaking.webp';
  static const confident = 'assets/images/mascot/mascot-cat-confident.webp';
  static const sulking = 'assets/images/mascot/mascot-cat-sulking.webp';
}

class ParentReportPage extends StatefulWidget {
  const ParentReportPage({
    super.key,
    required this.situationService,
    required this.profileStorage,
    required this.isActive,
    this.onStartLesson,
  });

  final SituationService situationService;
  final LocalProfileStorage profileStorage;
  final bool isActive;
  final void Function(int situationId, int islandId)? onStartLesson;

  @override
  State<ParentReportPage> createState() => _ParentReportPageState();
}

class _ParentReportPageState extends State<ParentReportPage> {
  List<_ParentReportEntry> _entries = _fallbackParentReportEntries;
  ChildProfile? _profile;
  LearningAnalysis? _analysis;
  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;
  int _activeSubTabIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      unawaited(_loadReport());
    }
  }

  @override
  void didUpdateWidget(covariant ParentReportPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.situationService != widget.situationService ||
        oldWidget.profileStorage != widget.profileStorage) {
      setState(() {
        _entries = _fallbackParentReportEntries;
        _profile = null;
        _analysis = null;
        _isLoading = false;
        _hasLoaded = false;
        _error = null;
      });
      if (widget.isActive) {
        unawaited(_loadReport(force: true));
      }
      return;
    }

    if (!oldWidget.isActive && widget.isActive && !_isLoading) {
      unawaited(_loadReport(force: true));
    }
  }

  Future<void> _loadReport({bool force = false}) async {
    if (_isLoading || (!force && _hasLoaded)) {
      return;
    }

    if (!widget.situationService.isEnabled) {
      final profile = await widget.profileStorage.readProfile();
      if (!mounted) {
        return;
      }
      setState(() {
        _entries = _fallbackParentReportEntries;
        _profile = profile;
        _isLoading = false;
        _hasLoaded = true;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await widget.profileStorage.readProfile();
      final entries = await _fetchReportEntries(profile);
      LearningAnalysis? analysis;
      String? analysisError;
      try {
        final learningService = LearningService();
        analysis = await learningService.generateReport();
        if (!analysis.hasEnoughData) {
          final locallyCompletedSituationIds = entries
              .where((entry) => entry.points > 0)
              .map((entry) => entry.situationId)
              .toSet();
          for (final situationId in locallyCompletedSituationIds) {
            await learningService.completeSituation(situationId);
          }
          if (locallyCompletedSituationIds.isNotEmpty) {
            analysis = await learningService.generateReport();
          }
        }
        if (!analysis.hasEnoughData) {
          analysisError = analysis.message;
        }
      } catch (error) {
        debugPrint('SmartSteps learning analysis failed: $error');
        analysisError =
            'Không tải được phân tích từ máy chủ; đang hiển thị tiến độ cục bộ.';
      }
      if (!mounted) {
        return;
      }

      setState(() {
        final baseEntries = entries.isEmpty
            ? _fallbackParentReportEntries
            : entries;
        _entries = _applyLearningAnalysis(baseEntries, analysis);
        _profile = profile;
        _analysis = analysis;
        _error = entries.isEmpty ? 'Chưa có dữ liệu báo cáo.' : analysisError;
        _isLoading = false;
        _hasLoaded = true;
      });
    } catch (error, stackTrace) {
      debugPrint('SmartSteps parent report failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }

      setState(() {
        _entries = _fallbackParentReportEntries;
        _analysis = null;
        _error = 'Đang hiển thị dữ liệu mẫu vì chưa tải được báo cáo.';
        _isLoading = false;
        _hasLoaded = true;
      });
    }
  }

  Future<List<_ParentReportEntry>> _fetchReportEntries(
    ChildProfile? profile,
  ) async {
    final islands = await widget.situationService.getIslands();
    final summariesByIsland = await Future.wait(
      islands.map(
        (island) =>
            widget.situationService.getIslandSituations(island.islandId),
      ),
    );
    final summaries = summariesByIsland
        .expand((items) => items)
        .toList(growable: false);

    if (summaries.isEmpty) {
      return const [];
    }

    final sortedSummaries = summaries.toList(growable: false)
      ..sort((a, b) {
        final islandCompare = a.islandId.compareTo(b.islandId);
        if (islandCompare != 0) {
          return islandCompare;
        }

        return a.orderIndex.compareTo(b.orderIndex);
      });
    final details = await Future.wait(
      sortedSummaries.map(
        (summary) =>
            widget.situationService.getSituationDetail(summary.situationId),
      ),
    );
    final progressBySituationId = {
      for (final progress in profile?.skillProgress ?? const <SkillProgress>[])
        progress.situationId: progress,
    };
    final entries =
        details
            .map(_ParentReportEntry.fromDetail)
            .map(
              (entry) =>
                  entry.withProgress(progressBySituationId[entry.situationId]),
            )
            .where((entry) => entry.skillName.trim().isNotEmpty)
            .toList(growable: false)
          ..sort((a, b) {
            final islandCompare = a.islandId.compareTo(b.islandId);
            if (islandCompare != 0) {
              return islandCompare;
            }

            return a.situationOrder.compareTo(b.situationOrder);
          });

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final displayEntries = _entries.isEmpty
        ? _fallbackParentReportEntries
        : _entries;
    final focusEntry = _preferredFocusEntry(displayEntries);
    final isInitialLoading =
        _isLoading && !_hasLoaded && widget.situationService.isEnabled;

    return ColoredBox(
      color: DuoColors.background,
      child: SafeArea(
        bottom: false,
        child: isInitialLoading
            ? const _ParentReportLoadingView()
            : RefreshIndicator(
                color: DuoColors.success,
                onRefresh: () => _loadReport(force: true),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = constraints.maxWidth > 520
                        ? 24.0
                        : 18.0;

                    return ListView(
                      key: const ValueKey('parent-report-page'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        16,
                        horizontalPadding,
                        24,
                      ),
                      children: [
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _LearnHeader(
                                  profile: _profile,
                                  entries: displayEntries,
                                  focusEntry: focusEntry,
                                  analysis: _analysis,
                                ),
                                const SizedBox(height: 18),
                                if (_error != null) ...[
                                  _ReportNotice(message: _error!),
                                  const SizedBox(height: 16),
                                ],
                                _ParentReportSegmentedControl(
                                  selectedIndex: _activeSubTabIndex,
                                  onChanged: (index) {
                                    setState(() {
                                      _activeSubTabIndex = index;
                                    });
                                  },
                                ),
                                const SizedBox(height: 18),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  transitionBuilder: (child, animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    );
                                  },
                                  child: _activeSubTabIndex == 0
                                      ? Column(
                                          key: const ValueKey('tab-progress'),
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            if (_analysis?.hasEnoughData ==
                                                true) ...[
                                              _AnalysisSummaryCard(
                                                analysis: _analysis!,
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                            _MascotInsightCard(
                                              focusEntry: focusEntry,
                                            ),
                                            const SizedBox(height: 16),
                                            _SkillScoreListCard(
                                              entries: displayEntries,
                                            ),
                                          ],
                                        )
                                      : Column(
                                          key: const ValueKey('tab-practice'),
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            _ForgottenFocusCard(
                                              focusEntry: focusEntry,
                                            ),
                                            const SizedBox(height: 16),
                                            _NextLessonSuggestionCard(
                                              focusEntry: focusEntry,
                                              entries: displayEntries,
                                              onStartLesson:
                                                  widget.onStartLesson,
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _LearnHeader extends StatelessWidget {
  const _LearnHeader({
    required this.profile,
    required this.entries,
    required this.focusEntry,
    this.analysis,
  });

  final ChildProfile? profile;
  final List<_ParentReportEntry> entries;
  final _ParentReportEntry focusEntry;
  final LearningAnalysis? analysis;

  @override
  Widget build(BuildContext context) {
    final totalPoints = entries.fold<int>(
      0,
      (total, entry) => total + entry.points,
    );
    final completedLessons = analysis?.hasEnoughData == true
        ? analysis!.completedLessons
        : entries.where((entry) => entry.points > 0).length;
    final totalLessons = analysis?.hasEnoughData == true
        ? (analysis!.totalLessons == 0 ? 1 : analysis!.totalLessons)
        : (entries.isEmpty ? 1 : entries.length);
    final level = (totalPoints ~/ 3) + 1;
    final childName = _displayChildName(profile);
    final progress = (completedLessons / totalLessons)
        .clamp(0.0, 1.0)
        .toDouble();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LearnMetricChip(
                icon: Icons.check_circle_rounded,
                label: '$completedLessons/$totalLessons bài',
                color: const Color(0xFFFF8A00),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _LearnMetricChip(
                icon: Icons.bolt_rounded,
                label: '$totalPoints điểm',
                color: DuoColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _LearnMetricChip(
                icon: Icons.military_tech_rounded,
                label: analysis?.hasEnoughData == true
                    ? '${(analysis!.correctRate * 100).round()}% đúng'
                    : 'Cấp $level',
                color: DuoColors.darkYellow,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        DuoCard(
          color: DuoColors.primaryYellow,
          borderColor: DuoColors.darkYellow.withValues(alpha: 0.32),
          padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
          child: Row(
            children: [
              Container(
                width: 82,
                height: 82,
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  _LearnMascots.happyWave,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report của bé',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontSize: 27,
                            height: 1,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalPoints == 0
                          ? '$childName chưa hoàn thành bài học nào.'
                          : '$childName đang mạnh nhất ở ${focusEntry.skillName}.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: DuoColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DuoProgressBar(value: progress, height: 12),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LearnMetricChip extends StatelessWidget {
  const _LearnMetricChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: DuoColors.border, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: DuoColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentReportLoadingView extends StatelessWidget {
  const _ParentReportLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _LearnHeader(
                  profile: null,
                  entries: _fallbackParentReportEntries,
                  focusEntry: _fallbackParentReportEntries.first,
                ),
                const SizedBox(height: 18),
                DuoCard(
                  child: Column(
                    children: [
                      const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 4,
                          color: DuoColors.success,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Đang tải báo cáo',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SmartSteps đang tổng hợp kỹ năng và câu hỏi cho phụ huynh.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _ContinueLearningCard extends StatelessWidget {
  const _ContinueLearningCard({required this.focusEntry});

  final _ParentReportEntry focusEntry;

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      color: Colors.white,
      borderColor: DuoColors.primaryYellow.withValues(alpha: 0.58),
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 18),
      child: Row(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: DuoColors.primaryYellow,
              borderRadius: BorderRadius.circular(26),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: DuoColors.textPrimary,
              size: 44,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('Tiếp tục học'),
                const SizedBox(height: 7),
                Text(
                  focusEntry.lessonTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  focusEntry.skillName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                const DuoProgressBar(value: 0.62, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisSummaryCard extends StatelessWidget {
  const _AnalysisSummaryCard({required this.analysis});

  final LearningAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final sourceLabel = analysis.narrativeSource == 'RuleBasedFallback'
        ? 'Phân tích theo quy tắc an toàn'
        : 'Nhận xét AI';

    return DuoCard(
      color: const Color(0xFFF4FFE8),
      borderColor: DuoColors.success.withValues(alpha: 0.32),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: DuoColors.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sourceLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${analysis.activeDays} ngày học',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(analysis.summary, style: Theme.of(context).textTheme.bodyMedium),
          if (analysis.parentAdvice.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              analysis.parentAdvice.first,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

class _MascotInsightCard extends StatelessWidget {
  const _MascotInsightCard({required this.focusEntry});

  final _ParentReportEntry focusEntry;

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      color: const Color(0xFFFFFDF4),
      borderColor: DuoColors.border,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(_LearnMascots.speaking, width: 84),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('Nhận xét'),
                const SizedBox(height: 8),
                Text(
                  focusEntry.points > 0
                      ? 'Kỹ năng vừa được cộng điểm'
                      : 'Chưa có điểm kỹ năng',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  focusEntry.points > 0
                      ? 'Bé đã có ${focusEntry.points} điểm ở ${_lowerFirst(focusEntry.skillName)} sau ${focusEntry.completedCount} lần hoàn thành.'
                      : 'Khi bé hoàn thành bài học, điểm kỹ năng sẽ tự động được lưu vào báo cáo này.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                _YellowReportRow(
                  icon: Icons.help_rounded,
                  text: focusEntry.realLifeQuestion,
                ),
                const SizedBox(height: 8),
                _YellowReportRow(
                  icon: Icons.lightbulb_rounded,
                  text: focusEntry.practicePrompt,
                ),
                const SizedBox(height: 8),
                _YellowReportRow(
                  icon: Icons.health_and_safety_rounded,
                  text: focusEntry.watchOut,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkillScoreListCard extends StatelessWidget {
  const _SkillScoreListCard({required this.entries});

  final List<_ParentReportEntry> entries;

  @override
  Widget build(BuildContext context) {
    return DuoCard(
      padding: const EdgeInsets.all(16),
      borderColor: DuoColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.insights_rounded,
                color: DuoColors.darkYellow,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Điểm kỹ năng',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in entries) ...[
            _SkillScoreRow(entry: entry),
            if (entry != entries.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SkillScoreRow extends StatelessWidget {
  const _SkillScoreRow({required this.entry});

  final _ParentReportEntry entry;

  @override
  Widget build(BuildContext context) {
    final progress = (entry.points / 3).clamp(0.0, 1.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: entry.points > 0
            ? const Color(0xFFF4FFE8)
            : DuoColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DuoColors.border.withValues(alpha: 0.72)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              entry.points > 0
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: entry.points > 0
                  ? DuoColors.success
                  : DuoColors.darkYellow,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.skillName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  entry.lessonTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                DuoProgressBar(value: progress, height: 9),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '+${entry.points}',
            style: const TextStyle(
              color: DuoColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForgottenFocusCard extends StatelessWidget {
  const _ForgottenFocusCard({required this.focusEntry});

  final _ParentReportEntry focusEntry;

  @override
  Widget build(BuildContext context) {
    final forgottenItems = _forgottenItemsFor(focusEntry);

    return DuoCard(
      padding: const EdgeInsets.all(16),
      borderColor: DuoColors.border,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(_LearnMascots.sulking, width: 70),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cần phụ huynh hỗ trợ',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                for (final item in forgottenItems) ...[
                  _YellowReportRow(icon: Icons.lightbulb_rounded, text: item),
                  const SizedBox(height: 8),
                ],
                Text(
                  focusEntry.realLifeQuestion,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextLessonSuggestionCard extends StatelessWidget {
  const _NextLessonSuggestionCard({
    required this.focusEntry,
    required this.entries,
    required this.onStartLesson,
  });

  final _ParentReportEntry focusEntry;
  final List<_ParentReportEntry> entries;
  final void Function(int situationId, int islandId)? onStartLesson;

  @override
  Widget build(BuildContext context) {
    final nextEntry = _nextSuggestedEntry(entries, focusEntry);
    final questions = _reportQuestionsFor(entries, nextEntry);

    return DuoCard(
      color: const Color(0xFFF4FFE8),
      borderColor: DuoColors.success.withValues(alpha: 0.32),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(_LearnMascots.confident, width: 72),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('Đề xuất bài học tiếp theo'),
                const SizedBox(height: 9),
                Text(
                  nextEntry.lessonTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 9),
                Text(
                  questions.isEmpty
                      ? nextEntry.practicePrompt
                      : questions.first,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: DuoColors.textSecondary,
                            size: 18,
                          ),
                          SizedBox(width: 5),
                          Text(
                            '5 phút',
                            style: TextStyle(
                              color: DuoColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DuoPrimaryButton(
                        label: 'Bắt đầu ngay',
                        icon: Icons.play_arrow_rounded,
                        onPressed: onStartLesson != null
                            ? () => onStartLesson!(
                                nextEntry.situationId,
                                nextEntry.islandId,
                              )
                            : null,
                        backgroundColor: DuoColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  nextEntry.practicePrompt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _YellowReportRow extends StatelessWidget {
  const _YellowReportRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: DuoColors.softYellow,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: DuoColors.darkYellow, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: DuoColors.darkYellow,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _ReportNotice extends StatelessWidget {
  const _ReportNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DuoColors.softYellow,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: DuoColors.border, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_rounded, color: DuoColors.darkYellow),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ParentReportEntry {
  const _ParentReportEntry({
    required this.situationId,
    required this.islandId,
    required this.situationOrder,
    required this.islandName,
    required this.lessonTitle,
    required this.skillName,
    required this.skillDescription,
    required this.realLifeQuestion,
    required this.practicePrompt,
    required this.watchOut,
    this.points = 0,
    this.completedCount = 0,
    this.lastCompletedAt,
    this.masteryLevel,
    this.analysisCorrectRate,
    this.recommendationReason,
    this.recommendationType,
    this.recommendationPriority = 0,
  });

  factory _ParentReportEntry.fromDetail(SituationDetail detail) {
    final skill = detail.skills.isNotEmpty ? detail.skills.first : null;
    final parentReview = detail.parentReview;

    return _ParentReportEntry(
      situationId: detail.situationId,
      islandId: detail.islandId,
      situationOrder: detail.orderIndex,
      islandName: detail.islandName,
      lessonTitle: detail.title,
      skillName: _firstNonEmpty([skill?.name, detail.title]),
      skillDescription: _firstNonEmpty([
        skill?.description,
        detail.intro,
        detail.title,
      ]),
      realLifeQuestion: _firstNonEmpty([
        detail.flashcard?.question,
        parentReview?.questionText,
        detail.intro,
      ]),
      practicePrompt: _firstNonEmpty([
        parentReview?.questionText,
        detail.flashcard?.correctFeedback,
        detail.intro,
      ]),
      watchOut: _firstNonEmpty([
        parentReview?.suggestedActivity,
        detail.flashcard?.wrongFeedback,
        detail.intro,
      ]),
    );
  }

  _ParentReportEntry withProgress(SkillProgress? progress) {
    if (progress == null) {
      return this;
    }

    return _ParentReportEntry(
      situationId: situationId,
      islandId: islandId,
      situationOrder: situationOrder,
      islandName: _firstNonEmpty([progress.islandName, islandName]),
      lessonTitle: _firstNonEmpty([progress.lessonTitle, lessonTitle]),
      skillName: _firstNonEmpty([progress.skillName, skillName]),
      skillDescription: _firstNonEmpty([
        progress.skillDescription,
        skillDescription,
      ]),
      realLifeQuestion: realLifeQuestion,
      practicePrompt: _firstNonEmpty([progress.practicePrompt, practicePrompt]),
      watchOut: _firstNonEmpty([progress.riskAlert, watchOut]),
      points: progress.points,
      completedCount: progress.completedCount,
      lastCompletedAt: progress.lastCompletedAt,
      masteryLevel: masteryLevel,
      analysisCorrectRate: analysisCorrectRate,
      recommendationReason: recommendationReason,
      recommendationType: recommendationType,
      recommendationPriority: recommendationPriority,
    );
  }

  _ParentReportEntry withAnalysis({
    LearningSkillAssessment? skill,
    LearningRecommendation? recommendation,
  }) {
    final analysisPoints = switch (skill?.masteryLevel) {
      'Mastered' => 3,
      'Achieved' => 2,
      'NeedsReview' => 1,
      'NotAchieved' => 0,
      _ => points,
    };

    return _ParentReportEntry(
      situationId: situationId,
      islandId: islandId,
      situationOrder: situationOrder,
      islandName: islandName,
      lessonTitle: lessonTitle,
      skillName: skill?.skillName ?? skillName,
      skillDescription: skillDescription,
      realLifeQuestion: realLifeQuestion,
      practicePrompt: practicePrompt,
      watchOut: recommendation?.reason ?? watchOut,
      points: analysisPoints,
      completedCount: skill?.totalAttempts ?? completedCount,
      lastCompletedAt: lastCompletedAt,
      masteryLevel: skill?.masteryLevel ?? masteryLevel,
      analysisCorrectRate: skill?.correctRate ?? analysisCorrectRate,
      recommendationReason: recommendation?.reason ?? recommendationReason,
      recommendationType:
          recommendation?.recommendationType ?? recommendationType,
      recommendationPriority:
          recommendation?.priority ?? recommendationPriority,
    );
  }

  final int situationId;
  final int islandId;
  final int situationOrder;
  final String islandName;
  final String lessonTitle;
  final String skillName;
  final String skillDescription;
  final String realLifeQuestion;
  final String practicePrompt;
  final String watchOut;
  final int points;
  final int completedCount;
  final DateTime? lastCompletedAt;
  final String? masteryLevel;
  final double? analysisCorrectRate;
  final String? recommendationReason;
  final String? recommendationType;
  final int recommendationPriority;
}

List<_ParentReportEntry> _applyLearningAnalysis(
  List<_ParentReportEntry> entries,
  LearningAnalysis? analysis,
) {
  if (analysis == null || !analysis.hasEnoughData) {
    return entries;
  }

  LearningSkillAssessment? skillFor(_ParentReportEntry entry) {
    for (final skill in analysis.skills) {
      if (skill.skillName.trim().toLowerCase() ==
          entry.skillName.trim().toLowerCase()) {
        return skill;
      }
    }
    return null;
  }

  LearningRecommendation? recommendationFor(_ParentReportEntry entry) {
    for (final recommendation in analysis.recommendations) {
      if (recommendation.situationId == entry.situationId) {
        return recommendation;
      }
    }
    return null;
  }

  return entries
      .map(
        (entry) => entry.withAnalysis(
          skill: skillFor(entry),
          recommendation: recommendationFor(entry),
        ),
      )
      .toList(growable: false);
}

String _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final text = value?.trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
  }

  return '';
}

_ParentReportEntry _preferredFocusEntry(List<_ParentReportEntry> entries) {
  final recommended =
      entries.where((entry) => entry.recommendationPriority > 0).toList()..sort(
        (a, b) => b.recommendationPriority.compareTo(a.recommendationPriority),
      );
  if (recommended.isNotEmpty) {
    return recommended.first;
  }

  final completed = entries.where((entry) => entry.points > 0).toList()
    ..sort((a, b) {
      final aTime = a.lastCompletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.lastCompletedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

  if (completed.isNotEmpty) {
    return completed.first;
  }

  for (final entry in entries) {
    if (entry.skillName.toLowerCase().contains('giao thông')) {
      return entry;
    }
  }

  return entries.first;
}

_ParentReportEntry _nextSuggestedEntry(
  List<_ParentReportEntry> entries,
  _ParentReportEntry focusEntry,
) {
  final recommended =
      entries.where((entry) => entry.recommendationPriority > 0).toList()..sort(
        (a, b) => b.recommendationPriority.compareTo(a.recommendationPriority),
      );
  if (recommended.isNotEmpty) {
    return recommended.first;
  }

  for (final entry in entries) {
    if (entry.points == 0) {
      return entry;
    }
  }

  return focusEntry;
}

List<String> _reportQuestionsFor(
  List<_ParentReportEntry> entries,
  _ParentReportEntry focusEntry,
) {
  final questions = <String>[];
  void add(String value) {
    final text = value.trim();
    if (text.isNotEmpty && !questions.contains(text)) {
      questions.add(text);
    }
  }

  add(focusEntry.realLifeQuestion);
  add(focusEntry.practicePrompt);
  for (final entry in entries) {
    if (entry.islandId == focusEntry.islandId) {
      add(entry.realLifeQuestion);
    }
  }
  for (final entry in entries) {
    add(entry.realLifeQuestion);
  }

  return questions.take(3).toList(growable: false);
}

List<String> _forgottenItemsFor(_ParentReportEntry entry) {
  return [
    if (entry.recommendationReason?.trim().isNotEmpty == true)
      _compactReportText(entry.recommendationReason!),
    _compactReportText(entry.watchOut),
    _compactReportText('Ôn lại ${entry.lessonTitle}'),
  ];
}

String _lowerFirst(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    return text;
  }

  return '${text[0].toLowerCase()}${text.substring(1)}';
}

String _compactReportText(String value) {
  final text = value.trim();
  if (text.length <= 78) {
    return text;
  }

  return '${text.substring(0, 75)}...';
}

String _displayChildName(ChildProfile? profile) {
  final name = profile?.childName.trim();
  if (name == null || name.isEmpty) {
    return 'Bé';
  }

  return name;
}

const _fallbackParentReportEntries = [
  _ParentReportEntry(
    situationId: 1,
    islandId: 1,
    situationOrder: 1,
    islandName: 'An toàn cá nhân',
    lessonTitle: 'Bài 1: Vật tròn lấp lánh',
    skillName: 'An toàn dị vật',
    skillDescription: 'Nhận biết đồ vật nhỏ có nguy cơ gây hóc hoặc nuốt phải.',
    realLifeQuestion:
        'Nếu con thấy một vật nhỏ lấp lánh trên sàn, con sẽ làm gì?',
    practicePrompt:
        'Cùng bé kiểm tra đồ chơi xem có chi tiết nhỏ bị rơi ra không.',
    watchOut: 'Giữ pin nút, nam châm và dị vật nhỏ xa tầm tay của bé.',
  ),
  _ParentReportEntry(
    situationId: 3,
    islandId: 2,
    situationOrder: 1,
    islandName: 'An toàn đường phố',
    lessonTitle: 'Bài 3: Nhận biết đèn giao thông',
    skillName: 'An toàn giao thông',
    skillDescription:
        'Nhận biết màu đèn và chờ người lớn trước khi sang đường.',
    realLifeQuestion:
        'Khi đèn đỏ bật lên, con cần dừng lại hay chạy qua đường?',
    practicePrompt: 'Chơi trò chỉ màu đèn giao thông và nói hành động đúng.',
    watchOut: 'Bé còn dễ nhầm giữa chờ đèn xanh và tự ý chạy qua đường.',
  ),
];

class _ParentReportSegmentedControl extends StatelessWidget {
  const _ParentReportSegmentedControl({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Kết quả học tập',
              icon: Icons.bar_chart_rounded,
              isSelected: selectedIndex == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Luyện tập tại nhà',
              icon: Icons.home_repair_service_rounded,
              isSelected: selectedIndex == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? DuoColors.success : DuoColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? DuoColors.textPrimary
                      : DuoColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
