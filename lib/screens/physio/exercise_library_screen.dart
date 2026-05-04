/// SMARTCARE+ Exercise Library Screen
///
/// Owner: Neelaka
/// Browse and start exercises from the prescribed library
/// Loads exercises from backend API (persisted per user)
library;

import 'package:flutter/material.dart';
import '../../core/config/theme.dart';
import '../../core/config/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/glassmorphic_card.dart';

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() =>
      _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String? _error;

  final List<String> _categories = [
    'All',
    'Balance',
    'Strength',
    'Flexibility',
    'Gait'
  ];

  List<Map<String, dynamic>> _exercises = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final authState = ref.read(authProvider);
      final userId = authState.firebaseUser?.uid ?? 'current_user';

      // First try to get user's generated exercise plan
      final planResponse = await apiService.get<Map<String, dynamic>>(
        '${ApiConfig.physio}/plan/$userId/current',
        requireAuth: false,
      );

      if (planResponse.success &&
          planResponse.data != null &&
          planResponse.data!['exercises'] != null) {
        // User has a generated plan - use those exercises
        final planExercises = planResponse.data!['exercises'] as List;
        setState(() {
          _exercises = planExercises
              .map((e) {
                return {
                  'id': e['id'] ?? e['exercise_id'] ?? '',
                  'name': e['name'] ?? e['exercise_name'] ?? 'Exercise',
                  'category': e['category'] ?? 'Strength',
                  'duration':
                      e['duration'] ?? '${e['duration_minutes'] ?? 10} min',
                  'difficulty': e['difficulty'] ?? 'Easy',
                  'reps': e['reps'] ??
                      '${e['sets'] ?? 3} sets x ${e['repetitions'] ?? 10} reps',
                  'description': e['description'] ?? e['instructions'] ?? '',
                  'isPrescribed': true, // All plan exercises are prescribed
                  'exercise_type':
                      e['exercise_type'] ?? _getExerciseType(e['name'] ?? ''),
                };
              })
              .toList()
              .cast<Map<String, dynamic>>();
          _isLoading = false;
        });
      } else {
        // No plan yet - load from general exercise library
        final response = await apiService.get<Map<String, dynamic>>(
          '${ApiConfig.physio}/exercises',
          requireAuth: false,
        );

        if (response.success && response.data != null) {
          final exerciseList = response.data!['exercises'] as List? ?? [];
          setState(() {
            _exercises = exerciseList
                .map((e) {
                  return {
                    'id': e['id'] ?? '',
                    'name': e['name'] ?? 'Exercise',
                    'category': e['category'] ?? 'Strength',
                    'duration': e['duration'] ?? '10 min',
                    'difficulty': e['difficulty'] ?? 'Easy',
                    'reps': e['reps'] ?? '3 sets x 10 reps',
                    'description': e['description'] ?? '',
                    'isPrescribed': e['is_prescribed'] ?? false,
                    'exercise_type':
                        e['exercise_type'] ?? _getExerciseType(e['name'] ?? ''),
                  };
                })
                .toList()
                .cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = response.error ?? 'Failed to load exercises';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredExercises {
    if (_selectedCategory == 'All') {
      return _exercises;
    }
    return _exercises.where((e) => e['category'] == _selectedCategory).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Balance':
        return AppColors.neonPurple;
      case 'Strength':
        return AppColors.neonRed;
      case 'Flexibility':
        return AppColors.neonGreen;
      case 'Gait':
        return AppColors.neonCyan;
      default:
        return AppColors.neonCyan;
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return AppColors.neonGreen;
      case 'Medium':
        return AppColors.neonOrange;
      case 'Hard':
        return AppColors.neonRed;
      default:
        return context.palette.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prescribedExercises =
        _filteredExercises.where((e) => e['isPrescribed']).toList();
    final otherExercises =
        _filteredExercises.where((e) => !e['isPrescribed']).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: context.palette.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.palette.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.arrow_back,
                            color: context.palette.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Exercise Library',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: context.palette.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.palette.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.search,
                          color: context.palette.textSecondary),
                    ),
                  ],
                ),
              ),

              // Category Filters
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedCategory = category),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.neonCyan.withValues(alpha: 0.15)
                                : context.palette.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.neonCyan
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 13,
                              color: isSelected
                                  ? AppColors.neonCyan
                                  : context.palette.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Exercise List
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.neonCyan),
                      )
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.neonRed, size: 48),
                                const SizedBox(height: 16),
                                Text(_error!,
                                    style: TextStyle(
                                        color: context.palette.textSecondary)),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadExercises,
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.neonCyan),
                                  child: const Text('Retry',
                                      style: TextStyle(color: Colors.black)),
                                ),
                              ],
                            ),
                          )
                        : _exercises.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.fitness_center,
                                        color: context.palette.textSecondary,
                                        size: 48),
                                    const SizedBox(height: 16),
                                    Text('No exercises found',
                                        style: TextStyle(
                                            color:
                                                context.palette.textSecondary)),
                                    const SizedBox(height: 8),
                                    Text(
                                        'Complete your profile to get personalized exercises',
                                        style: TextStyle(
                                            color:
                                                context.palette.textSecondary,
                                            fontSize: 12)),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadExercises,
                                color: AppColors.neonCyan,
                                child: ListView(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  children: [
                                    if (prescribedExercises.isNotEmpty) ...[
                                      Row(
                                        children: [
                                          const Icon(Icons.star,
                                              color: AppColors.neonOrange,
                                              size: 18),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Prescribed for You',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  context.palette.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      ...prescribedExercises
                                          .map((exercise) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10),
                                                child: _buildExerciseCard(
                                                    exercise,
                                                    isPrescribed: true),
                                              )),
                                      const SizedBox(height: 16),
                                    ],
                                    if (otherExercises.isNotEmpty) ...[
                                      Text(
                                        'More Exercises',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: context.palette.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...otherExercises
                                          .map((exercise) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10),
                                                child: _buildExerciseCard(
                                                    exercise,
                                                    isPrescribed: false),
                                              )),
                                    ],
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

  Widget _buildExerciseCard(Map<String, dynamic> exercise,
      {required bool isPrescribed}) {
    final categoryColor = _getCategoryColor(exercise['category']);
    final difficultyColor = _getDifficultyColor(exercise['difficulty']);

    return GestureDetector(
      onTap: () => _showExerciseDetail(exercise),
      child: GlassmorphicCard(
        glowColor: isPrescribed ? categoryColor : null,
        glowIntensity: 0.1,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.fitness_center, color: categoryColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exercise['name'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.palette.textPrimary,
                          ),
                        ),
                      ),
                      if (isPrescribed)
                        const Icon(Icons.star,
                            color: AppColors.neonOrange, size: 16),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 12, color: context.palette.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        exercise['duration'],
                        style: TextStyle(
                            fontSize: 11, color: context.palette.textSecondary),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          exercise['category'],
                          style: TextStyle(fontSize: 9, color: categoryColor),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: difficultyColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          exercise['difficulty'],
                          style: TextStyle(fontSize: 9, color: difficultyColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.palette.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showExerciseDetail(Map<String, dynamic> exercise) {
    final categoryColor = _getCategoryColor(exercise['category']);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.palette.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Exercise Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: categoryColor, width: 2),
                ),
                child:
                    Icon(Icons.fitness_center, color: categoryColor, size: 40),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Center(
              child: Text(
                exercise['name'],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.palette.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Tags
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTag(exercise['category'], categoryColor),
                  const SizedBox(width: 8),
                  _buildTag(exercise['difficulty'],
                      _getDifficultyColor(exercise['difficulty'])),
                  const SizedBox(width: 8),
                  _buildTag(
                      exercise['duration'], context.palette.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              exercise['description'],
              style: TextStyle(
                fontSize: 14,
                color: context.palette.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // Reps
            GlassmorphicCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.repeat, color: categoryColor),
                  const SizedBox(width: 12),
                  Text(
                    'Repetitions: ',
                    style: TextStyle(color: context.palette.textSecondary),
                  ),
                  Text(
                    exercise['reps'],
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate to exercise monitor screen
                  Navigator.pushNamed(
                    context,
                    AppRoutes.exerciseMonitor,
                    arguments: {
                      'exerciseName': exercise['name'],
                      'exerciseType': exercise['exercise_type'] ??
                          _getExerciseType(exercise['name']),
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: categoryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow),
                    SizedBox(width: 8),
                    Text(
                      'Start Exercise',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
        ),
      ),
    );
  }

  /// Convert exercise name to backend exercise type enum
  String _getExerciseType(String name) {
    final typeMap = {
      'Chair Stand': 'chair_stand',
      'Heel-to-Toe Walk': 'heel_toe_walk',
      'Single Leg Stand': 'single_leg_stand',
      'Ankle Circles': 'ankle_circles',
      'Wall Push-ups': 'wall_pushup',
      'Tandem Stand': 'tandem_stand',
      'Marching in Place': 'marching',
      'Seated Leg Raises': 'leg_raise',
      'Arm Raises': 'arm_raise',
      'Squats': 'squat',
    };
    return typeMap[name] ?? 'chair_stand';
  }
}
