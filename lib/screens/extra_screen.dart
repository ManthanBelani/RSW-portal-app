import 'package:dashboard_clone/widgets/reusable_data_table.dart';
import 'package:flutter/material.dart';

class ExtraScreen extends StatefulWidget {
  const ExtraScreen({super.key});

  @override
  State<ExtraScreen> createState() => _ExtraScreenState();
}

class _ExtraScreenState extends State<ExtraScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        ReusableDataTable(columns: [
          TableColumnConfig(title: 'User', builder: (data, index) {
            return Column(children: [
              Text('Name'),
              Container(

                child: Text('Designation'),
              ),
            ],);
          },)
        ], data: [])

      ]),
    );
  }
}
