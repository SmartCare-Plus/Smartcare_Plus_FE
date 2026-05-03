/// SMARTCARE+ Role-Based Dashboard Router
///
/// Routes users to appropriate dashboard based on their role
/// (Elderly, Guardian, or Caregiver)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/colors.dart';
import '../../core/config/theme.dart';
import 'elderly_dashboard.dart';
import 'guardian_dashboard.dart';
import 'caregiver_dashboard.dart';

class RoleBasedDashboard extends ConsumerWidget {
  const RoleBasedDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;

    // If still loading profile, show loading screen
    if (authState.isLoading) {
      return _buildLoadingScreen(context);
    }

    // If no profile yet, show loading (will be loaded by auth state)
    if (profile == null) {
      return _buildLoadingScreen(context);
    }

    // Route based on user role
    switch (profile.role) {
      case UserRole.elderly:
        return const ElderlyDashboard();
      case UserRole.guardian:
        return const GuardianDashboard();
      case UserRole.caregiver:
        return const CaregiverDashboard();
      case UserRole.admin:
        // Admins see guardian dashboard with full access
        return const GuardianDashboard();
    }
  }

  Widget _buildLoadingScreen(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.backgroundGradient,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading your dashboard...',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
