import 'package:flutter/material.dart';
import 'package:unfold_ai/features/features.dart';

class RangeSelector extends StatelessWidget {
  final DataRange selectedRange;
  final Function(DataRange) onRangeChanged;

  const RangeSelector({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildRangeButton(context, '7D', DataRange.sevenDays),
          _buildRangeButton(context, '30D', DataRange.thirtyDays),
          _buildRangeButton(context, '90D', DataRange.ninetyDays),
        ],
      ),
    );
  }

  Widget _buildRangeButton(
    BuildContext context,
    String label,
    DataRange range,
  ) {
    final isSelected = selectedRange == range;

    return Expanded(
      child: GestureDetector(
        onTap: () => onRangeChanged(range),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
