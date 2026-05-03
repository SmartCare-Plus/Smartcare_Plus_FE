/// SMARTCARE+ Dashboard Screen
///
/// Main dashboard with bottom navigation to Physio, Nutrition, Guardian
library;

import 'package:flutter/material.dart';

import '../../core/config/theme.dart';
import '../../core/constants/colors.dart';
import '../../widgets/common/glassmorphic_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const _HomeTab(),
    const _PhysioTab(),
    const _NutritionTab(),
    const _GuardianTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: context.palette.backgroundGradient,
          ),
        ),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: context.palette.surface.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: context.palette.glassBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonCyan.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home',
                  AppColors.neonCyan),
              _buildNavItem(1, Icons.accessibility_new_outlined,
                  Icons.accessibility_new, 'Physio', AppColors.neonGreen),
              _buildNavItem(2, Icons.restaurant_menu_outlined,
                  Icons.restaurant_menu, 'Nutrition', AppColors.neonOrange),
              _buildNavItem(3, Icons.shield_outlined, Icons.shield, 'Guardian',
                  AppColors.neonPurple),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon,
      String label, Color color) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? color : context.palette.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : context.palette.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= Home Tab =============

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: context.palette.textPrimary,
                      ),
                    ),
                  ],
                ),
                // Profile avatar with glow
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.neonCyan, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.neonCyan.withValues(alpha: 0.3),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: context.palette.surface,
                    child: const Icon(Icons.person, color: AppColors.neonCyan),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Quick Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    icon: Icons.directions_walk,
                    value: '2,456',
                    label: 'Steps Today',
                    color: AppColors.neonCyan,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    icon: Icons.local_fire_department,
                    value: '1,280',
                    label: 'Calories',
                    color: AppColors.neonOrange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    icon: Icons.water_drop,
                    value: '6/8',
                    label: 'Glasses',
                    color: AppColors.neonBlue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context: context,
                    icon: Icons.favorite,
                    value: '72',
                    label: 'Heart Rate',
                    color: AppColors.neonRed,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Service Cards
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.palette.textPrimary,
              ),
            ),

            const SizedBox(height: 16),

            _buildServiceCard(
              context: context,
              icon: Icons.accessibility_new,
              title: 'Physio Analysis',
              subtitle: 'Check your gait and mobility',
              color: AppColors.neonCyan,
              onTap: () {},
            ),

            const SizedBox(height: 12),

            _buildServiceCard(
              context: context,
              icon: Icons.restaurant_menu,
              title: 'Log Meal',
              subtitle: 'Scan or log your food',
              color: AppColors.neonGreen,
              onTap: () {},
            ),

            const SizedBox(height: 12),

            _buildServiceCard(
              context: context,
              icon: Icons.videocam,
              title: 'Live Monitor',
              subtitle: 'Watch guardian stream',
              color: AppColors.neonOrange,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return GlassmorphicCard(
      glowColor: color,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: context.palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}

// ============= Placeholder Tabs =============

class _PhysioTab extends StatelessWidget {
  const _PhysioTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.accessibility_new,
              size: 64, color: AppColors.neonCyan),
          const SizedBox(height: 16),
          const Text(
            'Physio Service',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Owner: Neelaka',
            style: TextStyle(color: context.palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _NutritionTab extends StatelessWidget {
  const _NutritionTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu,
              size: 64, color: AppColors.neonGreen),
          const SizedBox(height: 16),
          const Text(
            'Nutrition Service',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Owner: Kulasekara',
            style: TextStyle(color: context.palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _GuardianTab extends StatelessWidget {
  const _GuardianTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield, size: 64, color: AppColors.neonOrange),
          const SizedBox(height: 16),
          const Text(
            'Guardian Service',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Owner: Madhushani',
            style: TextStyle(color: context.palette.textSecondary),
          ),
        ],
      ),
    );
  }
}
