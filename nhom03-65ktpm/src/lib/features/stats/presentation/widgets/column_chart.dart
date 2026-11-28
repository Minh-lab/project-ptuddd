import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Một cột của [ColumnChart].
class ChartColumn {
  const ChartColumn({
    required this.label,
    required this.value,
    required this.description,
    this.emphasized = false,
  });

  /// Nhãn trục ngang (ngắn).
  final String label;
  final int value;

  /// Câu đầy đủ cho tooltip, trình đọc màn hình và bảng số liệu.
  final String description;

  /// In đậm nhãn trục (ví dụ hôm nay, tuần này).
  final bool emphasized;
}

/// Biểu đồ cột một chuỗi số liệu, có chế độ xem dạng bảng.
///
/// Theo quy ước biểu đồ của nhóm: cột mảnh (tối đa 24dp), bo 4dp ở đầu cột,
/// mọc từ một đường đáy mảnh; chỉ ghi số trên cột lớn nhất, các cột khác xem
/// bằng cách chạm (tooltip) hoặc mở bảng. Một chuỗi nên không cần chú thích.
class ColumnChart extends StatelessWidget {
  const ColumnChart({
    required this.columns,
    this.plotHeight = 120,
    this.showTable = false,
    super.key,
  });

  final List<ChartColumn> columns;
  final double plotHeight;
  final bool showTable;

  @override
  Widget build(BuildContext context) {
    return showTable ? _table(context) : _chart(context);
  }

  Widget _chart(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxValue = columns.fold(
      0,
      (int m, ChartColumn c) => math.max(m, c.value),
    );
    final labelIndex = maxValue == 0
        ? -1
        : columns.indexWhere((ChartColumn c) => c.value == maxValue);
    final valueStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Column(
      children: <Widget>[
        SizedBox(
          height: plotHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (var i = 0; i < columns.length; i++)
                Expanded(
                  child: _ColumnSlot(
                    column: columns[i],
                    fraction: maxValue == 0 ? 0 : columns[i].value / maxValue,
                    showValue: i == labelIndex,
                    valueStyle: valueStyle,
                    color: scheme.primary,
                  ),
                ),
            ],
          ),
        ),
        // Đường đáy mảnh, lệch một bậc so với nền.
        Container(height: 1, color: scheme.outlineVariant),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: <Widget>[
            for (final column in columns)
              Expanded(
                child: Text(
                  column.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: column.emphasized
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                    fontWeight: column.emphasized ? FontWeight.w700 : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _table(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        for (final column in columns)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(column.label, style: theme.textTheme.bodyMedium),
                ),
                Text(
                  '${column.value}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ColumnSlot extends StatelessWidget {
  const _ColumnSlot({
    required this.column,
    required this.fraction,
    required this.showValue,
    required this.valueStyle,
    required this.color,
  });

  final ChartColumn column;
  final double fraction;
  final bool showValue;
  final TextStyle? valueStyle;
  final Color color;

  static const double _valueBand = 16;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: column.description,
      triggerMode: TooltipTriggerMode.tap,
      child: Semantics(
        container: true,
        label: column.description,
        excludeSemantics: true,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final barHeight = (constraints.maxHeight - _valueBand) * fraction;
            final barWidth = math.min(24.0, constraints.maxWidth - 4);
            // Cả ô (kể cả khoảng trống) là vùng chạm, không chỉ riêng cột.
            return ColoredBox(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  if (showValue)
                    SizedBox(
                      height: _valueBand,
                      child: Text('${column.value}', style: valueStyle),
                    ),
                  Container(
                    width: barWidth,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
