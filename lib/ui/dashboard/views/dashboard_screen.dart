import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
export 'package:unfold_ai/features/features.dart';
import 'package:unfold_ai/ui/ui.dart';
import 'package:unfold_ai/core/core.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc()..loadData(),
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometrics Dashboard'),
        actions: [
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              return Switch(
                value: state.isLargeDataset,
                onChanged: (_) {
                  context.read<DashboardBloc>().toggleLargeDataset();
                },
                activeThumbColor: Theme.of(context).colorScheme.primary,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const LoadingWidget();
          }

          if (state.error != null) {
            return CustomErrorWidget(
              error: state.error!,
              onRetry: () {
                context.read<DashboardBloc>().retry();
              },
            );
          }

          if (state.biometricData.isEmpty) {
            return const EmptyStateWidget();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Range Selector
                RangeSelector(
                  selectedRange: state.selectedRange,
                  onRangeChanged: (range) {
                    context.read<DashboardBloc>().selectRange(range);
                  },
                ),

                const SizedBox(height: 24),

                // Performance Info
                if (state.isLargeDataset)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Large dataset mode (10k+ points) - LTTB decimation active for 60 FPS performance',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Charts
                _buildChartSection(
                  context,
                  'Heart Rate Variability (HRV)',
                  ChartType.hrv,
                  state,
                  onJournalTapped: (entry) =>
                      context.read<DashboardBloc>().selectJournalEntry(entry),
                ),

                const SizedBox(height: 24),

                _buildChartSection(
                  context,
                  'Resting Heart Rate (RHR)',
                  ChartType.rhr,
                  state,
                  onJournalTapped: (entry) =>
                      context.read<DashboardBloc>().selectJournalEntry(entry),
                ),

                const SizedBox(height: 24),

                _buildChartSection(
                  context,
                  'Daily Steps',
                  ChartType.steps,
                  state,
                  onJournalTapped: (entry) =>
                      context.read<DashboardBloc>().selectJournalEntry(entry),
                ),

                const SizedBox(height: 24),

                // Selected Date Summary Card
                if (state.selectedDate != null)
                  _buildSelectedDateCard(context, state),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChartSection(
    BuildContext context,
    String title,
    ChartType chartType,
    DashboardState state, {
    void Function(JournalEntry?)? onJournalTapped,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: BiometricChart(
            data: state.biometricData,
            journalEntries: state.journalEntries,
            selectedRange: state.selectedRange,
            selectedDate: state.selectedDate,
            isLargeDataset: state.isLargeDataset,
            chartType: chartType,
            onDateSelected: (date) {
              context.read<DashboardBloc>().selectDate(date);
            },
            onJournalTapped: onJournalTapped,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedDateCard(BuildContext context, DashboardState state) {
    final selectedDate = state.selectedDate!;

    // Find biometric data for selected date
    final biometricData = state.biometricData.firstWhere(
      (data) =>
          data.dateTime.year == selectedDate.year &&
          data.dateTime.month == selectedDate.month &&
          data.dateTime.day == selectedDate.day,
      orElse: () => const BiometricData(
        date: '',
        hrv: 0,
        rhr: 0,
        steps: 0,
        sleepScore: 0,
      ),
    );

    // Find journal entry for selected date
    final journalEntry = state.journalEntries.firstWhere((entry) {
      final entryDate = entry.dateTime;
      return entryDate.year == selectedDate.year &&
          entryDate.month == selectedDate.month &&
          entryDate.day == selectedDate.day;
    }, orElse: () => const JournalEntry(date: '', mood: 0, note: ''));

    final hasJournalEntry = journalEntry.mood > 0;
    final moodEmoji = _getMoodEmoji(journalEntry.mood);
    final moodColor = _getMoodColor(journalEntry.mood);
    final moodIcon = _getMoodIcon(journalEntry.mood);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasJournalEntry
              ? [
                  moodColor.withValues(alpha: 0.2),
                  moodColor.withValues(alpha: 0.05),
                ]
              : [
                  Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  Theme.of(context).colorScheme.surface,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasJournalEntry
              ? moodColor.withValues(alpha: 0.4)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: hasJournalEntry
                ? moodColor.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with date and mood
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (hasJournalEntry) ...[
                      Text(moodEmoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 12),
                      Icon(moodIcon, color: moodColor, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(selectedDate),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: moodColor,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.calendar_today,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(selectedDate),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (hasJournalEntry)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: moodColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: moodColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getMoodText(journalEntry.mood),
                    style: TextStyle(
                      color: moodColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),

          // Journal note if available
          if (hasJournalEntry && journalEntry.note.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: moodColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.note, color: moodColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      journalEntry.note,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(height: 1),

          // Biometric values
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBiometricValue(
                context,
                icon: Icons.favorite,
                color: Colors.blue,
                label: 'HRV',
                value: biometricData.hrv.toStringAsFixed(1),
              ),
              const SizedBox(width: 16),
              _buildBiometricValue(
                context,
                icon: Icons.monitor_heart,
                color: Colors.red,
                label: 'RHR',
                value: '${biometricData.rhr} bpm',
              ),
              const SizedBox(width: 16),
              _buildBiometricValue(
                context,
                icon: Icons.directions_walk,
                color: Colors.green,
                label: 'Steps',
                value: '${biometricData.steps}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricValue(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  IconData _getMoodIcon(int mood) {
    switch (mood) {
      case 1:
        return Icons.sentiment_very_dissatisfied;
      case 2:
        return Icons.sentiment_dissatisfied;
      case 3:
        return Icons.sentiment_neutral;
      case 4:
        return Icons.sentiment_satisfied;
      case 5:
        return Icons.sentiment_very_satisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  String _getMoodEmoji(int mood) {
    switch (mood) {
      case 1:
        return '😞';
      case 2:
        return '😕';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  Color _getMoodColor(int mood) {
    switch (mood) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getMoodText(int mood) {
    switch (mood) {
      case 1:
        return 'Very Poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Neutral';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }
}

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No biometric data available',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try refreshing or check your data source',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
