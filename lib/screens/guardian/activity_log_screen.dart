/// SMARTCARE+ Activity Log Screen
///

/// Timeline of elderly activity and events — connected to /api/reports/activity-log

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';
import '../../providers/connection_provider.dart';
import '../../widgets/common/glassmorphic_card.dart';

class ActivityLogScreen extends ConsumerStatefulWidget {
  final String elderlyId;
  final String elderlyName;

  const ActivityLogScreen({
    super.key,
    this.elderlyId = '',
    this.elderlyName = '',
  });

  @override
  ConsumerState<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends ConsumerState<ActivityLogScreen> {
  int _selectedDays = 1;
  bool _isLoading = true;
  List<Map<String, dynamic>> _activities = [];
  Map<String, dynamic> _summary = {};

  String get _elderlyId {hyuy6
    if (widget.elderlyId.isNotEmpty) return widget.elderlyId;
    final elderly = ref.read(connectionProvider).myElderly;
    return elderly.isNotEmpty ? elderly.first.id : '';
  }

  String get _elderlyName {
    if (widget.elderlyName.isNotEmpty) return widget.elderlyName;
    final elderly = ref.read(connectionProvider).myElderly;
    return elderly.isNotEmpty ? elderly.first.name : 'Patient';
  }

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final eid = _elderlyId;
    if (eid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      final response = await api.get<Map<String, dynamic>>(
        '/api/reports/activity-log/$eid?days=$_selectedDays',
        requireAuth: false,
      );
      if (response.success && response.data != null && mounted) {
        setState(() {
          _activities = List<Map<String, dynamic>>.from(
            (response.data!['activities'] as List?)?.map((a) => Map<String, dynamic>.from(a as Map)) ?? [],
          );
          _summary = Map<String, dynamic>.from(response.data!['summary'] as Map? ?? {});
        });
      }
    } catch (e) {
      debugPrint('Error loading activities: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.backgroundGradient),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.arrow_back, color: AppColors.textPrimary)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Activity Log', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          Text(_elderlyName, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _loadActivities,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.refresh, color: AppColors.textSecondary, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              // Date Selector
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildDateChip('Today', 1),
                    _buildDateChip('3 Days', 3),
                    _buildDateChip('7 Days', 7),
                    _buildDateChip('14 Days', 14),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Summary Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GlassmorphicCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('Meals', '${_summary['meals'] ?? 0}', AppColors.neonOrange),
                      Container(width: 1, height: 40, color: AppColors.glassBorder),
                      _buildSummaryItem('Exercises', '${_summary['exercises'] ?? 0}', AppColors.neonGreen),
                      Container(width: 1, height: 40, color: AppColors.glassBorder),
                      _buildSummaryItem('Alerts', '${_summary['alerts'] ?? 0}', AppColors.neonRed),
                      Container(width: 1, height: 40, color: AppColors.glassBorder),
                      _buildSummaryItem('Hydration', '${_summary['hydration_entries'] ?? 0}', AppColors.neonCyan),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Activity Timeline
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.neonCyan))
                    : _activities.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timeline, color: AppColors.textSecondary.withOpacity(0.3), size: 48),
                                const SizedBox(height: 12),
                                const Text('No activity recorded', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                                const SizedBox(height: 4),
                                const Text('Activities will appear here as they are logged', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadActivities,
                            color: AppColors.neonCyan,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _activities.length,
                              itemBuilder: (context, index) {
                                final activity = _activities[index];
                                final isLast = index == _activities.length - 1;
                                return _buildTimelineItem(activity, isLast);
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, int days) {
    final isSelected = _selectedDays == days;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedDays = days);
          _loadActivities();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.neonCyan.withOpacity(0.15) : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.neonCyan : Colors.transparent),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? AppColors.neonCyan : AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'nutrition': return AppColors.neonOrange;
      case 'hydration': return AppColors.neonCyan;
      case 'exercise': return AppColors.neonGreen;
      case 'alert': return AppColors.neonRed;
      default: return AppColors.neonPurple;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'nutrition': return Icons.restaurant;
      case 'hydration': return Icons.water_drop;
      case 'exercise': return Icons.fitness_center;
      case 'alert': return Icons.warning;
      default: return Icons.circle;
    }
  }

  Widget _buildTimelineItem(Map<String, dynamic> activity, bool isLast) {
    final category = activity['category'] ?? '';
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: AppColors.glassBorder)),
            ],
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassmorphicCard(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(activity['event'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                        Text(activity['time'] ?? '', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    if ((activity['detail'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(activity['detail'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                    if ((activity['date'] ?? '').toString().isNotEmpty && _selectedDays > 1) ...[
                      const SizedBox(height: 4),
                      Text(activity['date'], style: TextStyle(fontSize: 10, color: AppColors.textSecondary.withOpacity(0.6))),
                    ],
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
