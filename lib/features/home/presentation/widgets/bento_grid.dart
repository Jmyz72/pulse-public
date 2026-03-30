import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimensions.dart';

/// A single item in the bento grid with optional column spanning
class BentoGridItem {
  final Widget child;

  /// Number of columns this item spans (1 or 2)
  final int columnSpan;

  const BentoGridItem({
    required this.child,
    this.columnSpan = 1,
  });
}

/// A responsive bento-style grid layout
///
/// Arranges items in rows, handling column spanning.
/// Items that span 2 columns take the full row width.
/// Single-column items are packed 2 per row (on mobile).
///
/// Responsive columns:
/// - Mobile (<600px): 2 columns
/// - Tablet (600-900px): 4 columns
/// - Desktop (>900px): 6 columns
class BentoGrid extends StatelessWidget {
  final List<BentoGridItem> items;
  final double spacing;

  const BentoGrid({
    super.key,
    required this.items,
    this.spacing = AppDimensions.spacingMd,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columns = _getColumns(screenWidth);

    return Column(
      children: _buildRows(columns),
    );
  }

  int _getColumns(double width) {
    if (width >= 900) return 6;
    if (width >= 600) return 4;
    return 2;
  }

  /// Build rows by packing items according to their column spans
  List<Widget> _buildRows(int maxColumns) {
    final List<Widget> rows = [];
    int i = 0;

    while (i < items.length) {
      final item = items[i];
      final span = item.columnSpan.clamp(1, maxColumns);

      if (span >= maxColumns) {
        // Full-width item gets its own row
        if (rows.isNotEmpty) {
          rows.add(SizedBox(height: spacing));
        }
        rows.add(item.child);
        i++;
      } else {
        // Pack single-span items into a row
        final List<BentoGridItem> rowItems = [];
        int usedColumns = 0;

        while (i < items.length && usedColumns + items[i].columnSpan.clamp(1, maxColumns) <= maxColumns) {
          final nextSpan = items[i].columnSpan.clamp(1, maxColumns);
          if (nextSpan >= maxColumns) break; // Full-width items go to their own row
          rowItems.add(items[i]);
          usedColumns += nextSpan;
          i++;
        }

        if (rowItems.isNotEmpty) {
          if (rows.isNotEmpty) {
            rows.add(SizedBox(height: spacing));
          }
          rows.add(_buildRow(rowItems, maxColumns));
        }
      }
    }

    return rows;
  }

  /// Build a single row of items with proper flex proportions
  Widget _buildRow(List<BentoGridItem> rowItems, int maxColumns) {
    if (rowItems.length == 1 && rowItems.first.columnSpan == 1) {
      // Single item in a row that doesn't span full - still give it full width
      // unless there are supposed to be more columns
      return Row(
        children: [
          Expanded(child: rowItems.first.child),
          SizedBox(width: spacing),
          const Expanded(child: SizedBox()),
        ],
      );
    }

    final List<Widget> children = [];
    for (int j = 0; j < rowItems.length; j++) {
      if (j > 0) {
        children.add(SizedBox(width: spacing));
      }
      children.add(
        Expanded(
          flex: rowItems[j].columnSpan,
          child: rowItems[j].child,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
