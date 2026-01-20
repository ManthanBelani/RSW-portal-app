import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/constants.dart';

class InvoicePreviewAndDownloadScreen extends StatefulWidget {
  final Map<String, dynamic> invoiceData;
  final Map<String, dynamic>? clientData;
  final Map<String, dynamic>? selectedClient;
  final Map<String, dynamic>? selectedCurrency;
  final Map<String, dynamic>? values;

  const InvoicePreviewAndDownloadScreen({
    super.key,
    required this.invoiceData,
    this.clientData,
    this.selectedClient,
    this.selectedCurrency,
    this.values,
  });

  @override
  State<InvoicePreviewAndDownloadScreen> createState() =>
      _InvoicePreviewAndDownloadScreenState();
}

class _InvoicePreviewAndDownloadScreenState
    extends State<InvoicePreviewAndDownloadScreen> {
  String _htmlInvoice = '';
  bool _isGenerating = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoiceHtml();
  }

  Future<void> _loadInvoiceHtml() async {
    final html = await _generateInvoiceHtml();
    setState(() {
      _htmlInvoice = html;
      _isLoading = false;
    });
  }

  String _capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text
        .split(' ')
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _isGenerating ? null : _downloadPDF,
            tooltip: 'Download PDF',
          ),
        ],
      ),
      body: _isLoading || _isGenerating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text(_isGenerating ? 'Generating PDF...' : 'Loading...'),
                ],
              ),
            )
          : PdfPreview(
              build: (format) async {
                return await Printing.convertHtml(
                  format: format,
                  html: _htmlInvoice,
                );
              },
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              pdfFileName:
                  'Invoice_${widget.invoiceData['invoice_no'] ?? 'document'}.pdf',
            ),
    );
  }

  Future<String> _generateInvoiceHtml() async {
    final currencyCode = widget.selectedCurrency?['currency_code'] ?? '';
    final clientName = widget.selectedClient?['client_name'] ?? 'N/A';
    final clientAddress = widget.values?['client_address'] ?? '';
    final tasks = (widget.invoiceData['tasks'] as List?) ?? [];
    final logoData = await rootBundle.load('assets/images/namedlogo1.png');
    final logoBase64 = base64Encode(logoData.buffer.asUint8List());

    final itemsHtml = tasks
        .map((task) {
          final desc = task['description'] ?? '';
          final amount = (task['amount'] ?? 0).toString();
          return '''
      <tr>
        <td class="desc">$desc</td>
        <td class="amt">$currencyCode $amount</td>
      </tr>
    ''';
        })
        .join('');

    final discount = widget.invoiceData['discount'];
    final discountLabel = widget.invoiceData['discount_label'] ?? 'Discount';
    final totalDue =
        widget.invoiceData['total_due'] ??
        widget.invoiceData['subtotal'] ??
        '0';

    final notice =
        widget.values?['notice'] != null &&
            widget.values!['notice'].toString().isNotEmpty
        ? '''
        <div class="notice-section">
          <span class="notice-label">NOTICE:</span> ${widget.values!['notice']}
        </div>
      '''
        : '';

    // Bank details section
    final bankInfo = widget.invoiceData['bank_info'];
    String bankDetailsHtml = '';

    if (bankInfo != null && bankInfo is Map) {
      final accountName = bankInfo['account_name'];
      final accountNumber = bankInfo['account_number'];
      final country = bankInfo['country'];
      final bankInfoList = bankInfo['bank_info'] as List?;

      if (accountName != null ||
          accountNumber != null ||
          (bankInfoList != null && bankInfoList.isNotEmpty) ||
          country != null) {
        final details = <String>[];

        if (accountName != null && accountName.toString().isNotEmpty) {
          details.add(
            '<div class="bank-row"><span class="bank-label">Account Name</span><span class="bank-colon">:</span><span class="bank-value">$accountName</span></div>',
          );
        }

        if (accountNumber != null && accountNumber.toString().isNotEmpty) {
          details.add(
            '<div class="bank-row"><span class="bank-label">Account Number</span><span class="bank-colon">:</span><span class="bank-value">$accountNumber</span></div>',
          );
        }

        if (bankInfoList != null) {
          for (var item in bankInfoList) {
            if (item is Map &&
                item['value'] != null &&
                item['label'] != null &&
                item['value'].toString().isNotEmpty) {
              final label = _capitalizeWords(item['label'].toString());
              final value = item['value'].toString();
              details.add(
                '<div class="bank-row"><span class="bank-label">$label</span><span class="bank-colon">:</span><span class="bank-value">$value</span></div>',
              );
            }
          }
        }

        if (country != null && country.toString().isNotEmpty) {
          details.add(
            '<div class="bank-row"><span class="bank-label">Country Name</span><span class="bank-colon">:</span><span class="bank-value">$country</span></div>',
          );
        }

        if (details.isNotEmpty) {
          bankDetailsHtml =
              '''
          <div class="bank-details-section">
            <div class="label">BANK DETAILS:</div>
            <div class="bank-details-content">
              ${details.join('\n')}
            </div>
          </div>
          ''';
        }
      }
    }

    return '''  
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Invoice #${widget.invoiceData['invoice_no'] ?? 'N/A'}</title>
  <style>
    @page { size: A4; margin: 0; }

    * { margin: 0; padding: 0; box-sizing: border-box; }

    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: #fafafa;
      width: 210mm;
      height: 297mm;
      margin: 0 auto;
    }

    .page {
      width: 210mm;
      height: 297mm;
      background: white;
      position: relative;
      overflow: hidden;
      padding: 50px;
    }

    /* Large pink curved shape - exactly like image */
    // .pink-shape {
    //   position: absolute;
    //   top: -100px;
    //   right: -100px;
    //   width: 700px;
    //   height: 700px;
    //   background: linear-gradient(225deg, rgba(255,143,163,0.25) 0%, rgba(252,51,66,0.15) 100%);
    //   border-radius: 0 0 0 500px;
    //   z-index: 0;
    // }

    .main-content {
      position: relative;
      z-index: 1;
    }

    /* Header */
    .header {
      display: table;
      width: 100%;
      margin-bottom: 70px;
    }

    .left-col {
      display: table-cell;
      width: 50%;
      vertical-align: top;
    }

    .right-col {
      display: table-cell;
      width: 30%;
      vertical-align: top;
      text-align: right;
    }

    .logo {
      width: 220px;
      height: auto;
      margin-bottom: 35px;
      display: block;
    }

    .label {
      color: #FC3342;
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 1.2px;
      margin-bottom: 10px;
    }

    .issuer-info {
      font-size: 11px;
      line-height: 1.9;
      color: #666;
    }

    .issuer-info .name {
      color: #1a1a1a;
      font-weight: 600;
      margin-bottom: 3px;
    }

    /* Invoice badge */
    .invoice-badge {
      display: inline-block;
      background: linear-gradient(135deg, #FF8FA3 0%, #FC3342 100%);
      padding: 30px 50px;
      border-radius: 0 0 0 100px;
      box-shadow: 0 8px 25px rgba(252,51,66,0.25);
    }

    .invoice-badge h1 {
      color: white;
      font-size: 38px;
      font-weight: 700;
      letter-spacing: 5px;
      margin-bottom: 20px;
    }

    .invoice-badge .details {
      color: white;
      font-size: 11px;
      line-height: 2;
      text-align: right;
    }

    /* Customer */
    .customer-section {
      margin-bottom: 50px;
    }

    .customer-info {
      font-size: 11px;
      line-height: 1.8;
      color: #666;
    }

    .customer-info .name {
      color: #1a1a1a;
      font-weight: 600;
      margin-bottom: 5px;
    }

    /* Table */
    .items-table {
      width: 100%;
      margin: 40px 0;
      border-radius: 40px;
      overflow: hidden;
      box-shadow: 0 2px 12px rgba(0,0,0,0.08);
    }

    .items-table table {
      width: 100%;
      border-collapse: collapse;
    }

    .items-table thead {
      background: linear-gradient(135deg, #FF8FA3 0%, #FC3342 100%);
    }

    .items-table th {
      color: white;
      font-size: 11px;
      font-weight: 600;
      letter-spacing: 1.5px;
      padding: 18px 35px;
      text-align: left;
    }

    .items-table th:last-child {
      text-align: right;
    }

    .items-table td {
      padding: 20px 35px;
      font-size: 12px;
      color: #555;
      border-bottom: 1px solid #f5f5f5;
    }

    .items-table tbody tr:last-child td {
      border-bottom: none;
    }

    .items-table td:last-child {
      text-align: right;
      font-weight: 600;
      color: #1a1a1a;
    }

    /* Total and Bank Details Container */
    .bottom-section {
      display: table;
      width: 100%;
      margin: 35px 0 50px;
    }

    .bottom-left {
      display: table-cell;
      width: 50%;
      vertical-align: top;
      padding-right: 30px;
    }

    .bottom-right {
      display: table-cell;
      width: 50%;
      vertical-align: top;
      text-align: right;
    }

    /* Total */
    .total-section p {
      font-size: 13px;
      color: #666;
      margin: 8px 0;
    }

    .total-section .amount {
      font-size: 18px;
      font-weight: 700;
      color: #1a1a1a;
    }

    /* Notice */
    .notice-section {
      margin: 50px 0;
      font-size: 11px;
      color: #666;
      line-height: 1.8;
    }

    .notice-section .notice-label {
      color: #FC3342;
      font-weight: 700;
      letter-spacing: 0.5px;
    }

    /* Bank Details */
    .bank-details-section {
      margin-top: 0;
    }

    .bank-details-content {
      margin-top: 10px;
    }

    .bank-row {
      margin: 6px 0;
      font-size: 11px;
      line-height: 1.6;
    }

    .bank-label {
      display: inline-block;
      min-width: 140px;
      color: #666;
    }

    .bank-colon {
      display: inline-block;
      color: #1a1a1a;
      margin: 0 8px;
    }

    .bank-value {
      display: inline-block;
      color: #1a1a1a;
      font-weight: 600;
    }

    /* Thank you */
    .thank-you-section {
      text-align: right;
      margin: 70px 0 50px;
    }

    .thank-you-btn {
      display: inline-block;
      background: linear-gradient(135deg, #FF8FA3 0%, #FC3342 100%);
      color: white;
      padding: 14px 70px;
      border-radius: 50px;
      font-size: 13px;
      font-weight: 600;
      box-shadow: 0 6px 20px rgba(252,51,66,0.3);
      letter-spacing: 0.5px;
    }

    /* Footer */
    .footer {
      position: absolute;
      bottom: 0;
      left: 0;
      right: 0;
      background: linear-gradient(135deg, #FF8FA3 0%, #FC3342 100%);
      padding: 35px 50px;
    }

    .footer-inner {
      background: white;
      padding: 18px 50px;
      border-radius: 60px;
      display: table;
      width: 100%;
    }

    .footer-item {
      display: table-cell;
      text-align: center;
      font-size: 11px;
      color: #555;
      font-weight: 500;
    }

    .footer-item .icon {
      color: #FC3342;
      margin-right: 6px;
      font-size: 13px;
    }
  </style>
</head>
<body>
  <div class="page">
    <div class="pink-shape"></div>

    <div class="main-content">
      <!-- Header -->
      <div class="header">
        <div class="left-col">
          <img src="data:image/png;base64,$logoBase64" alt="Logo" class="logo">

          <div class="label">ISSUER:</div>
          <div class="issuer-info">
            <div class="name">Rainstream Technologies</div>
            1111, Anam 2, Ambli Bopal,<br>
            Junction, Nr. Bopal Flyover,<br>
            Ambli, Ahmedabad, Gujarat 380058<br>
            ✉ rainstreamweb@gmail.com<br>
            📞 +91 9512566601<br>
            GSTIN: 24AOLPJ1440C1ZI
          </div>
        </div>

        <div class="right-col">
          <div class="invoice-badge">
            <h1>INVOICE</h1>
          </div>
          <div class="invoice-badge-details">
          <div class="details">
              Invoice No: ${widget.invoiceData['invoice_no'] ?? ''}<br>
              Invoice Date: ${widget.invoiceData['invoice_date'] ?? ''}<br>
              Due Date: ${widget.invoiceData['due_date'] ?? ''}
            </div>
          </div>
        </div>
      </div>

      <!-- Customer -->
      <div class="customer-section">
        <div class="label">CUSTOMER:</div>
        <div class="customer-info">
          <div class="name">$clientName</div>
          $clientAddress
        </div>
      </div>

      <!-- Items Table -->
      <div class="items-table">
        <table>
          <thead>
            <tr>
              <th>DESCRIPTION</th>
              <th>AMOUNT</th>
            </tr>
          </thead>
          <tbody>
            $itemsHtml
          </tbody>
        </table>
      </div>

      <!-- Total and Bank Details Side by Side -->
      <div class="bottom-section">
        <div class="bottom-left">
          $bankDetailsHtml
        </div>
        <div class="bottom-right">
          <div class="total-section">
            ${discount != null && discount != '0' ? '<p>$discountLabel: -$discount $currencyCode</p>' : ''}
            <p class="amount">Total Amount: $currencyCode $totalDue</p>
          </div>
        </div>
      </div>

      <!-- Notice -->
      $notice

      <!-- Thank You -->
      <div class="thank-you-section">
        <span class="thank-you-btn">Thank You</span>
      </div>
    </div>

    <!-- Footer -->
    <div class="footer">
      <div class="footer-inner">
        <div class="footer-item">
          <span class="icon">🌐</span> https://rainstreamweb.com
        </div>
        <div class="footer-item">
          <span class="icon">📞</span> +91 951 256 6601
        </div>
        <div class="footer-item">
          <span class="icon">✉</span> info@rainstreamweb.com
        </div>
      </div>
    </div>
  </div>
</body>
</html>
''';
  }

  Future<void> _downloadPDF() async {
    setState(() => _isGenerating = true);

    try {
      final pdf = await Printing.convertHtml(
        format: PdfPageFormat.a4,
        html: _htmlInvoice,
      );

      // Save to file
      final dir = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();

      final fileName =
          'Invoice_${widget.invoiceData['invoice_no'] ?? DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${dir?.path}/$fileName');
      await file.writeAsBytes(pdf);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ PDF saved: $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Share',
              textColor: Colors.white,
              onPressed: () async {
                await Printing.sharePdf(bytes: pdf, filename: fileName);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ PDF Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }
}
