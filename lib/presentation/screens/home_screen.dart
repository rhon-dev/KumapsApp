import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kumpas/presentation/providers/app_state_provider.dart';
import 'package:kumpas/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, _) {
        final progress = appState.userProgress;
        if (progress == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return CustomScrollView(
          slivers: [
            // App Bar with greeting
            SliverAppBar(
              pinned: true,
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Text(
                'Kumpas',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Main content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting and motivation
                    Text(
                      'Good morning!',
                      style: AppTypography.headlineMedium(context),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to learn Filipino Sign Language today?',
                      style: AppTypography.bodyMedium(context).copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Streak and XP Card
                    _buildStatsCard(context, progress),
                    const SizedBox(height: 24),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: AppTypography.titleMedium(context),
                    ),
                    const SizedBox(height: 12),
                    _buildActionButtons(context),
                    const SizedBox(height: 24),

                    // Progress by Category
                    Text(
                      'Your Progress',
                      style: AppTypography.titleMedium(context),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryProgress(context, progress),
                    const SizedBox(height: 24),

                    // Continue Learning
                    Text(
                      'Continue Learning',
                      style: AppTypography.titleMedium(context),
                    ),
                    const SizedBox(height: 12),
                    _buildContinueCard(context, appState),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsCard(BuildContext context, dynamic progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'Lessons',
            value: progress.totalLessonsCompleted.toString(),
            icon: Icons.school,
          ),
          _buildStatItem(
            label: 'Streak',
            value: progress.currentStreak.toString(),
            icon: Icons.local_fire_department,
          ),
          _buildStatItem(
            label: 'XP',
            value: (progress.totalXP / 100).toStringAsFixed(1) + 'K',
            icon: Icons.stars,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'Practice',
            icon: Icons.videocam,
            color: AppColors.primary,
            onTap: () {
              context.read<AppStateProvider>().selectTab(3);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            label: 'Translate',
            icon: Icons.g_translate,
            color: AppColors.secondary,
            onTap: () {
              context.read<AppStateProvider>().selectTab(1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryProgress(BuildContext context, dynamic progress) {
    return Column(
      children: progress.categoryProgress.entries.map<Widget>((entry) {
        final category = entry.key;
        final percent = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    category,
                    style: AppTypography.bodyMedium(context).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: AppTypography.labelMedium(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 8,
                  backgroundColor: AppColors.borderLight,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getProgressColor(percent),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContinueCard(BuildContext context, AppStateProvider appState) {
    final lessons = appState.currentLessons;
    if (lessons.isEmpty) {
      return const SizedBox();
    }

    final currentLesson = lessons.firstWhere(
      (l) => !l.isCompleted,
      orElse: () => lessons.first,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentLesson.title,
                style: AppTypography.titleMedium(context),
              ),
              Text(
                currentLesson.difficulty,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getDifficultyColor(currentLesson.difficulty),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currentLesson.description,
            style: AppTypography.bodySmall(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (currentLesson.progress ?? 0) / 100,
              minHeight: 6,
              backgroundColor: AppColors.borderLight,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<AppStateProvider>().selectTab(3);
              },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Color _getProgressColor(int percent) {
    if (percent >= 80) return AppColors.success;
    if (percent >= 50) return AppColors.primary;
    return AppColors.warning;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return AppColors.success;
      case 'intermediate':
        return AppColors.warning;
      case 'advanced':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
