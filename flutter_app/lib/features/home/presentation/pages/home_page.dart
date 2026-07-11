import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:code_card_ai/core/routes/route_names.dart';
import 'package:code_card_ai/core/theme/app_colors.dart';
import 'package:code_card_ai/core/theme/app_text_styles.dart';
import 'package:code_card_ai/core/utils/extensions.dart';
import 'package:code_card_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:code_card_ai/features/auth/presentation/bloc/auth_event.dart';
import 'package:code_card_ai/features/auth/presentation/bloc/auth_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          context.showSnackBar('Logged out successfully.');
          context.goNamed(RouteNames.loginName);
        } else if (state is AuthFailure) {
          context.showSnackBar(state.message, isError: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // User Greeting Section
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  String name = 'User';
                  String email = 'user@example.com';
                  if (state is AuthSuccess) {
                    name = state.user.name;
                    email = state.user.email;
                  }
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.12),
                          theme.colorScheme.secondary.withOpacity(0.08),
                        ],
                      ),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: theme.colorScheme.primary,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: AppTextStyles.heading2.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $name!',
                                style: AppTextStyles.heading3.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Overview',
                style: AppTextStyles.heading3,
              ),
              const SizedBox(height: 16),
              // Grid of cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildStatCard(
                    context: context,
                    title: 'Active Cards',
                    value: '12',
                    icon: Icons.credit_card_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  _buildStatCard(
                    context: context,
                    title: 'Integrations',
                    value: '5',
                    icon: Icons.integration_instructions_outlined,
                    color: theme.colorScheme.secondary,
                  ),
                  _buildStatCard(
                    context: context,
                    title: 'Alerts',
                    value: '2',
                    icon: Icons.notifications_active_outlined,
                    color: AppColors.warning,
                  ),
                  _buildStatCard(
                    context: context,
                    title: 'Sync Status',
                    value: 'Healthy',
                    icon: Icons.cloud_done_outlined,
                    color: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: AppTextStyles.subtitle.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      _buildActivityItem(
                        context: context,
                        title: 'Logged in successfully',
                        time: 'Just now',
                        icon: Icons.login_rounded,
                      ),
                      const Divider(height: 24),
                      _buildActivityItem(
                        context: context,
                        title: 'Card sync completed',
                        time: '1 hour ago',
                        icon: Icons.sync_rounded,
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

  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = context.theme;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required BuildContext context,
    required String title,
    required String time,
    required IconData icon,
  }) {
    final theme = context.theme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withOpacity(0.08),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.bodyFormat),
              const SizedBox(height: 2),
              Text(
                time,
                style: AppTextStyles.bodySmall.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
