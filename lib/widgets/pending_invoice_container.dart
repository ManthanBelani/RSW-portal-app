import 'package:dashboard_clone/services/pending_work_service.dart';
import 'package:dashboard_clone/widgets/elevated_button.dart';
import 'package:dashboard_clone/widgets/text_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../constants/constants.dart';

class PendingInvoiceContainer extends StatefulWidget {
  const PendingInvoiceContainer({super.key});

  @override
  State<PendingInvoiceContainer> createState() =>
      _PendingInvoiceContainerState();
}

class _PendingInvoiceContainerState extends State<PendingInvoiceContainer> {
  var _invoiceData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoiceData();
  }

  void _showPaidDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Invoice As Paid'),
          content: Text('Are You Sure You want to Mark it as Paid'),
          actions: [
            TextButton(onPressed: () {
              Navigator.pop(context);
            }, child: Text('Cancel')),
            ReusableButton(
              text: 'Submit',
              onPressed: () {
                Navigator.of(context).pop();
              },
              fontSize: 15,
            ),
          ],
        );
      },
    );
  }
  void _showCompeleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Invoice As Completed'),
          content: Text('Are You Sure You want to Mark it as Compeleted'),
          actions: [
            TextButton(onPressed: () {
              Navigator.pop(context);
            }, child: Text('Cancel')),
            ReusableButton(
              text: 'Submit',
              onPressed: () {
                Navigator.of(context).pop();
              },
              fontSize: 15,
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Edit'),
          content: Text('Are you sure to edit data'),
          actions: [
            TextButton(onPressed: () {
              Navigator.pop(context);
            }, child: Text('Cancel')),
            ReusableButton(
              text: 'Submit',
              onPressed: () {
                Navigator.of(context).pop();
              },
              fontSize: 15,
            ),
          ],
        );
      },
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Delete Pending Invoice'),
          // title: Text('You Clicked On the Icon to Edit Details'),
          content: Text('Are you sure to delete this invoice ?'),
          actions: [
            TextButton(onPressed: () {
              Navigator.pop(context);
            }, child: Text('Cancel')),
            ReusableButton(
              text: 'Delete',
              onPressed: () {
                Navigator.of(context).pop();
                SnackBar(content: Text('Data Deleted Successfully!'));
              },
              fontSize: 15,
            ),
          ],
        );
      },
    );
  }

  void _showPaymentDialog(Map<String, dynamic> invoice) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController noteController = TextEditingController();
    final TextEditingController totalAmountController = TextEditingController();
    final TextEditingController dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Update Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReusableTextField(
                  labelText: 'Total Amount',
                  controller: totalAmountController,
                  enabled: true,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 12),
                ReusableTextField(
                  labelText: 'Paid Amount',
                  keyboardType: TextInputType.number,
                  controller: amountController,
                  enabled: true,
                ),
                SizedBox(height: 12),
                ReusableTextField(
                  controller: dateController,
                  labelText: 'Date',
                  suffixIcon: IconButton(
                    onPressed: () async {
                      final selectedDate = await showDatePicker(
                        context: context,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: primaryColor,
                              ),
                            ),
                            child: child!,
                          );
                        },
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2200),
                        initialDate: DateTime.now(),
                      );
                      if (selectedDate != null) {
                        final formattedDate = DateFormat(
                          'dd/MM/yyyy',
                        ).format(selectedDate);
                        dateController.text = formattedDate;
                      }
                    },
                    icon: Icon(Icons.calendar_today_rounded),
                  ),
                ),
                SizedBox(height: 12),
                ReusableTextField(
                  labelText: 'Note',
                  controller: noteController,
                  keyboardType: TextInputType.text,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            ReusableButton(
              text: 'Submit',
              onPressed: () {
                if (amountController.text.isNotEmpty) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Payment of ${invoice['currency']['currency'] ?? ''} ${amountController.text} updated',
                      ),
                    ),
                  );
                }
              },
              fontSize: 15,
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadInvoiceData() async {
    try {
      final result = await PendingWorkService.getPendingInvoiceData();
      if (mounted) {
        setState(() {
          final allInvoices = result?['data']['data'] ?? [];
          _invoiceData = allInvoices
              .where(
                (invoice) => invoice['is_paid'] == 0 || invoice['is_paid'] == 2,
              )
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _invoiceData = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 0),
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Center(
              child: Text(
                'Pending Invoice Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          // Header row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 200,
                    child: Text(
                      'Project Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 240,
                    child: Text(
                      'Action',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey[300]),
                    itemBuilder: (context, index) => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 120,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 80,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 100,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : _invoiceData.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No pending invoices',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _invoiceData.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey[300]),
                    itemBuilder: (context, index) {
                      final invoice = _invoiceData[index];
                      final projectName = invoice['project'] ?? 'N/A';
                      final clientName = invoice['client_name'] ?? '';
                      final dueDate = invoice['due_date'] ?? '';

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 200,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      projectName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (clientName.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        clientName,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    if (dueDate.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'Due: $dueDate',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Row(
                                children: [
                                  // Edit icon
                                  GestureDetector(
                                    onTap: _showEditDialog,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Icon(
                                        Icons.edit,
                                        size: 20,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                  // View icon
                                  GestureDetector(
                                    onTap: _showPaidDialog,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Icon(
                                        Icons.currency_exchange,
                                        size: 20,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  // Download icon
                                  GestureDetector(
                                    onTap: () {
                                      _showCompeleteDialog();
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Icon(
                                        Icons.done_all_outlined,
                                        size: 20,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                  // Payment icon
                                  GestureDetector(
                                    onTap: () => _showPaymentDialog(invoice),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Icon(
                                        Icons.attach_money,
                                        size: 20,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                  // Delete icon
                                  GestureDetector(
                                    onTap: _showDeleteDialog,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
