import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
export 'package:unfold_ai/features/features.dart';
import 'package:unfold_ai/ui/ui.dart';

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
                            'Large dataset mode enabled - Data decimation applied for optimal performance',
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
                ),

                const SizedBox(height: 24),

                _buildChartSection(
                  context,
                  'Resting Heart Rate (RHR)',
                  ChartType.rhr,
                  state,
                ),

                const SizedBox(height: 24),

                _buildChartSection(
                  context,
                  'Daily Steps',
                  ChartType.steps,
                  state,
                ),

                const SizedBox(height: 24),

                // Journal Entries
                _buildJournalSection(context, state),
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
    DashboardState state,
  ) {
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
          ),
        ),
      ],
    );
  }

  Widget _buildJournalSection(BuildContext context, DashboardState state) {
    // For demo purposes, show all journal entries regardless of date range
    final relevantEntries = state.journalEntries.toList();

    if (relevantEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Journal Entries',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...relevantEntries.map((entry) => _buildJournalEntry(context, entry)),
      ],
    );
  }

  Widget _buildJournalEntry(BuildContext context, journalEntry) {
    final moodEmoji = _getMoodEmoji(journalEntry.mood);
    final moodColor = _getMoodColor(journalEntry.mood);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: moodColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Text(moodEmoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  journalEntry.note,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  journalEntry.date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
