import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import 'column_chart.dart';

/// Thẻ chứa một [ColumnChart] kèm tiêu đề và nút chuyển biểu đồ ↔ bảng.
class ChartCard extends StatefulWidget {
  const ChartCard({
    required this.title,
    required this.columns,
    this.subtitle,
    this.headline,
    this.headerActions = const <Widget>[],
    super.key,
  });

  final String title;
  final String? subtitle;

  /// Dòng số liệu chính phía trên biểu đồ (ví dụ "5 ghi chú").
  final Widget? headline;
  final List<Widget> headerActions;
  final List<ChartColumn> columns;

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  bool _showTable = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(widget.title, style: theme.textTheme.titleMedium),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                ...widget.headerActions,
              ],
            ),
            if (widget.headline != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              widget.headline!,
            ],
            const SizedBox(height: AppSpacing.lg),
            ColumnChart(columns: widget.columns, showTable: _showTable),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _showTable = !_showTable),
                icon: Icon(
                  _showTable ? Icons.bar_chart : Icons.table_rows_outlined,
                  size: 18,
                ),
                label: Text(_showTable ? 'Xem biểu đồ' : 'Xem dạng bảng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
