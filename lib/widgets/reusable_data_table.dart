import 'package:flutter/material.dart';

class TableColumnConfig {
  final String title;
  final int flex;
  final double? fixedWidth;
  final Widget Function(dynamic data, int index) builder;

  TableColumnConfig({
    required this.title,
    this.flex = 1,
    this.fixedWidth,
    required this.builder,
  });
}

class ReusableDataTable extends StatelessWidget {
  final List<TableColumnConfig> columns;
  final List<dynamic> data;
  final bool isMobile;

  const ReusableDataTable({
    super.key,
    required this.columns,
    required this.data,
    this.isMobile = false,
  });

  Widget _buildTableHeader() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: columns.map((col) {
          if (col.fixedWidth != null) {
            return SizedBox(
              width: col.fixedWidth,
              child: _buildHeaderCell(col.title),
            );
          }
          return Expanded(flex: col.flex, child: _buildHeaderCell(col.title));
        }).toList(),
      ),
    );
  }

  Widget _buildHeaderCell(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.centerLeft,
      child: title.isEmpty
          ? Checkbox(
              value: false,
              onChanged: (value) {},
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            )
          : Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
    );
  }

  Widget _buildTableRow(int index) {
    final rowData = data[index];

    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 1),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: columns.map((col) {
              if (col.fixedWidth != null) {
                return SizedBox(
                  width: col.fixedWidth,
                  child: _buildDataCell(col.builder(rowData, index)),
                );
              }
              return Expanded(
                flex: col.flex,
                child: _buildDataCell(col.builder(rowData, index)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDataCell(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.centerLeft,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTableHeader(),
                    ...List.generate(
                      data.length,
                      (index) => _buildTableRow(index),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
