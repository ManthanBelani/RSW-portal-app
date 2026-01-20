class InvoiceRecord {
  final String id;
  final String invoiceRef;
  final String createdBy;
  final String createdAt;
  final String client;
  final String project;
  final double amount;
  final double paidamount;
  final String currencyCode;
  final double expenseAmount;
  final double profitLoss;
  final String invoiceStatus; // Paid, Unpaid, Partially Paid
  final String workStatus; // Pending, Completed
  final String invoiceType; // task, invoice, etc.
  final DateTime workStartDate;
  final DateTime workEndDate;

  InvoiceRecord({
    required this.id,
    required this.createdAt,
    required this.invoiceRef,
    required this.createdBy,
    required this.client,
    required this.paidamount,
    required this.project,
    required this.amount,
    required this.currencyCode,
    required this.expenseAmount,
    required this.profitLoss,
    required this.invoiceStatus,
    required this.workStatus,
    required this.invoiceType,
    required this.workStartDate,
    required this.workEndDate,
  });

  factory InvoiceRecord.fromApiJson(Map<String, dynamic> json) {
    String invoiceStatus = 'Unpaid';
    final isPaid = json['is_paid'];
    if (isPaid == 1 || isPaid == '1') {
      invoiceStatus = 'Paid';
    } else if (isPaid == 2 || isPaid == '2') {
      invoiceStatus = 'Partially Paid';
    }

    final workInfo = json['work_info'] as Map<String, dynamic>?;

    String workStatus = 'Pending';
    if (workInfo != null) {
      final isCompleted = workInfo['is_completed'];
      if (isCompleted == 1 || isCompleted == '1') {
        workStatus = 'Completed';
      }
    }

    String? workStartDate = workInfo?['work_start_date'];
    String? workEndDate = workInfo?['work_end_date'];
    

    print('📅 Parsing dates for invoice ${json['id']}:');
    print('   work_info exists: ${workInfo != null}');
    print('   work_start_date from work_info: $workStartDate');
    print('   work_end_date from work_info: $workEndDate');
    print('   invoice_type: ${json['invoice_type']}');
    print('   expense_amount: ${json['expense_amount']}');

    final parsedStartDate = _parseWorkDate(workStartDate);
    final parsedEndDate = _parseWorkDate(workEndDate);
    
    print('   Parsed start date year: ${parsedStartDate.year}');
    print('   Parsed end date year: ${parsedEndDate.year}');

    return InvoiceRecord(
      id: json['id']?.toString() ?? '',
      invoiceRef: json['reference'] ?? '',
      createdBy: json['created_by'] ?? '',
      client: json['client_name'] ?? '',
      project: json['project'] ?? '',
      paidamount: double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      amount: double.tryParse(json['invoice_rate']?.toString() ?? '0') ?? 0.0,
      currencyCode: json['currency_code'] ?? 'USD',
      expenseAmount:
          double.tryParse(json['expense_amount']?.toString() ?? '0') ?? 0.0,
      profitLoss: _calculateProfitLoss(json),
      invoiceStatus: invoiceStatus,
      workStatus: workStatus,
      invoiceType: json['invoice_type']?.toString() ?? 'invoice',
      workStartDate: parsedStartDate,
      workEndDate: parsedEndDate,
      createdAt: json['created_at'],
    );
  }

  static double _calculateProfitLoss(Map<String, dynamic> json) {
    if (json['profit'] != null) {
      final profit = double.tryParse(json['profit']?.toString() ?? '0') ?? 0.0;
      if (profit != 0) return profit;
    }

    if (json['loss'] != null) {
      final loss = double.tryParse(json['loss']?.toString() ?? '0') ?? 0.0;
      return loss <= 0 ? loss : -loss;
    }
    
    final invoiceRate = double.tryParse(json['invoice_rate']?.toString() ?? '0') ?? 0.0;
    final expenseAmount = double.tryParse(json['expense_amount']?.toString() ?? '0') ?? 0.0;
    
    return invoiceRate - expenseAmount;
  }

  /// Parse work date - returns DateTime(1970) if date is invalid or missing
  /// This ensures dates are ONLY shown when they exist in work_info
  static DateTime _parseWorkDate(dynamic dateStr) {
    // Return 1970 for null, empty, or "null" strings
    if (dateStr == null || dateStr.toString().isEmpty || dateStr.toString() == 'null') {
      print('   ❌ Date is null/empty: returning 1970');
      return DateTime(1970);
    }
    
    final dateString = dateStr.toString().trim();
    
    // Check for invalid date strings
    if (dateString == '0000-00-00' || 
        dateString == '0000-00-00 00:00:00' ||
        dateString == '1970-01-01' ||
        dateString == '1900-01-01' ||
        dateString.startsWith('0000')) {
      print('   ❌ Date is invalid format ($dateString): returning 1970');
      return DateTime(1970);
    }
    
    try {
      final parsedDate = DateTime.parse(dateString);
      
      // Check if the parsed date is valid (not year 0, 1900, or 1970)
      if (parsedDate.year <= 1970 || parsedDate.year == 1900) {
        print('   ❌ Parsed date year is invalid (${parsedDate.year}): returning 1970');
        return DateTime(1970);
      }
      
      print('   ✅ Valid work date parsed: $parsedDate');
      return parsedDate;
    } catch (e) {
      print('   ❌ Error parsing date ($dateString): $e');
      return DateTime(1970);
    }
  }

  factory InvoiceRecord.fromJson(Map<String, dynamic> json) {
    return InvoiceRecord(
      id: json['id'] ?? '',
      createdAt: json['created_at'],
      invoiceRef: json['invoice_ref'] ?? '',
      createdBy: json['created_by'] ?? '',
      client: json['client'] ?? '',
      project: json['project'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currencyCode: json['currency_code'] ?? 'USD',
      expenseAmount: (json['expense_amount'] ?? 0).toDouble(),
      profitLoss: (json['profit_loss'] ?? 0).toDouble(),
      invoiceStatus: json['invoice_status'] ?? '',
      workStatus: json['work_status'] ?? '',
      invoiceType: json['invoice_type'] ?? 'invoice',
      workStartDate: DateTime.parse(json['work_start_date']),
      workEndDate: DateTime.parse(json['work_end_date']),
      paidamount:(json['paid_amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_ref': invoiceRef,
      'created_by': createdBy,
      'client': client,
      'project': project,
      'amount': amount,
      'currency_code': currencyCode,
      'expense_amount': expenseAmount,
      'profit_loss': profitLoss,
      'invoice_status': invoiceStatus,
      'work_status': workStatus,
      'invoice_type': invoiceType,
      'work_start_date': workStartDate.toIso8601String(),
      'work_end_date': workEndDate.toIso8601String(),
    };
  }
}
