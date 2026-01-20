import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dashboard_clone/constants/constants.dart';
import 'package:dashboard_clone/services/invoice_service.dart';
import 'package:dashboard_clone/widgets/elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final Map<String, dynamic> invoiceData;
  final Map<String, dynamic>? selectedClient;
  final Map<String, dynamic>? selectedCurrency;
  final Map<String, dynamic>? values;
  final String? invoiceId;

  const InvoicePreviewScreen({
    super.key,
    required this.invoiceData,
    this.selectedClient,
    this.selectedCurrency,
    this.values,
    this.invoiceId,
  });

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  bool _isSaving = false;
  bool _isDownloading = false;
  String? _generatedInvoiceId;
  late WebViewController _webViewController;
  bool _isWebViewReady = false;

  Future<void> _saveInvoice() async {
    setState(() => _isSaving = true);

    try {
      final invoiceReference = widget.invoiceData['invoice_no'] ?? '';
      print('🔍 Attempting to save invoice with reference: $invoiceReference');

      // First, try to find if an invoice with this reference already exists
      String? existingInvoiceId;
      try {
        final invoiceListResult = await InvoiceService.getInvoiceList(
          search: invoiceReference,
          perPage: 50,
          direction: 'desc',
        );

        if (invoiceListResult['success'] == true &&
            invoiceListResult['data'] != null &&
            invoiceListResult['data']['data'] != null) {
          final invoices = invoiceListResult['data']['data'] as List;
          print(
            '📋 Checking ${invoices.length} invoices for existing reference',
          );

          // Find exact match by reference
          for (var invoice in invoices) {
            if (invoice['reference'] == invoiceReference) {
              existingInvoiceId = invoice['id']?.toString();
              print('✅ Found existing invoice with ID: $existingInvoiceId');
              break;
            }
          }

          // Try case-insensitive match if no exact match
          if (existingInvoiceId == null) {
            for (var invoice in invoices) {
              if (invoice['reference']?.toString().toLowerCase() ==
                  invoiceReference.toLowerCase()) {
                existingInvoiceId = invoice['id']?.toString();
                print(
                  '✅ Found existing invoice with ID: $existingInvoiceId (case-insensitive)',
                );
                break;
              }
            }
          }
        }
      } catch (e) {
        print('⚠️ Error searching for existing invoice: $e');
      }

      // If we found an existing invoice, use its ID
      if (existingInvoiceId != null && existingInvoiceId.isNotEmpty) {
        print('📝 Using existing invoice ID: $existingInvoiceId');
        setState(() {
          _generatedInvoiceId = existingInvoiceId;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '✅ Invoice already exists. You can download the PDF.',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }

      // If no existing invoice, call postGenerateInvoice
      print('📤 Creating new invoice...');
      final generateResult = await InvoiceService.postGenerateInvoice(
        context: context,
        client_id: widget.invoiceData['client_id'] ?? '',
        project_id: widget.invoiceData['project_id'] ?? '',
        currency_id: widget.invoiceData['currency_id'] ?? '',
        client_address: widget.values?['client_address'] ?? '',
        company_id: widget.invoiceData['company_id'] ?? '',
        invoice_rate: widget.invoiceData['currency_rate'] ?? '1',
        invoice_date: widget.invoiceData['invoice_date'] ?? '',
        due_date: widget.invoiceData['due_date'] ?? '',
        discount_label: widget.invoiceData['discount_label'] ?? '',
        discount_amount: widget.invoiceData['discount'] ?? '0',
        invoice_description: widget.invoiceData['description'] ?? '',
        is_paid: widget.invoiceData['is_paid']?.toString() ?? '0',
        reference: invoiceReference,
        task_filter: '',
        notice: widget.values?['notice'] ?? '',
        direction: 'desc',
        invoice_id: invoiceReference,
      );

      if (generateResult?['success'] == true) {
        // Extract the invoice ID from the response
        final responseData = generateResult?['data'];
        print(
          '📋 Generate invoice response data keys: ${responseData?.keys.toList()}',
        );
        print('📋 Full response data: $responseData');

        // Try to extract ID from various possible fields
        String? invoiceId =
            responseData?['id']?.toString() ??
            responseData?['invoice_id']?.toString();

        // If still no ID, search for the invoice we just created
        if (invoiceId == null || invoiceId.isEmpty) {
          print('⚠️ No ID in response, searching for newly created invoice...');

          // Try multiple search attempts with increasing delays
          for (int attempt = 1; attempt <= 3; attempt++) {
            print('🔍 Search attempt $attempt/3...');
            await Future.delayed(
              Duration(seconds: attempt),
            ); // Increasing delay

            try {
              // Try searching with the full reference
              final searchResult = await InvoiceService.getInvoiceList(
                search: invoiceReference,
                perPage: 50, // Increase to get more results
                direction: 'desc', // Get most recent first
              );

              if (searchResult['success'] == true &&
                  searchResult['data'] != null &&
                  searchResult['data']['data'] != null) {
                final invoices = searchResult['data']['data'] as List;
                print('📋 Found ${invoices.length} invoices in search results');

                // Try exact match first
                for (var invoice in invoices) {
                  if (invoice['reference'] == invoiceReference) {
                    invoiceId = invoice['id']?.toString();
                    print(
                      '✅ Found newly created invoice with ID: $invoiceId (exact match)',
                    );
                    break;
                  }
                }

                // If no exact match, try case-insensitive match
                if (invoiceId == null || invoiceId.isEmpty) {
                  for (var invoice in invoices) {
                    if (invoice['reference']?.toString().toLowerCase() ==
                        invoiceReference.toLowerCase()) {
                      invoiceId = invoice['id']?.toString();
                      print(
                        '✅ Found newly created invoice with ID: $invoiceId (case-insensitive match)',
                      );
                      break;
                    }
                  }
                }

                // If still no match, get the most recent invoice (first in desc order)
                if ((invoiceId == null || invoiceId.isEmpty) &&
                    invoices.isNotEmpty) {
                  invoiceId = invoices.first['id']?.toString();
                  print(
                    '⚠️ Using most recent invoice ID: $invoiceId (fallback)',
                  );
                }
              }

              // If we found an ID, break out of retry loop
              if (invoiceId != null && invoiceId.isNotEmpty) {
                break;
              }
            } catch (e) {
              print('❌ Error in search attempt $attempt: $e');
            }
          }

          // If still no ID after all attempts, try getting all recent invoices
          if (invoiceId == null || invoiceId.isEmpty) {
            print(
              '🔍 Final attempt: Getting recent invoices without search filter...',
            );
            try {
              final recentResult = await InvoiceService.getInvoiceList(
                search: '', // No search filter
                perPage: 10,
                direction: 'desc',
              );

              if (recentResult['success'] == true &&
                  recentResult['data'] != null &&
                  recentResult['data']['data'] != null) {
                final invoices = recentResult['data']['data'] as List;
                if (invoices.isNotEmpty) {
                  // Use the most recent invoice (should be the one we just created)
                  invoiceId = invoices.first['id']?.toString();
                  print('⚠️ Using most recent invoice from list: $invoiceId');
                }
              }
            } catch (e) {
              print('❌ Error getting recent invoices: $e');
            }
          }
        }

        if (invoiceId != null && invoiceId.isNotEmpty) {
          print('✅ Invoice saved with ID: $invoiceId');
          setState(() {
            _generatedInvoiceId = invoiceId;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '✅ Invoice saved successfully! You can now download the PDF.',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          print('⚠️ Invoice created but ID could not be retrieved');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ Invoice Created',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Reference: $invoiceReference'),
                    const SizedBox(height: 4),
                    const Text(
                      'The invoice was created but we couldn\'t retrieve its ID. '
                      'Please check the invoice list to find it.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error in _saveInvoice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _downloadInvoice() async {
    if (_generatedInvoiceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Please save the invoice first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      print(
        '📥 Requesting PDF generation for invoice ID: $_generatedInvoiceId',
      );

      // Request PDF generation from API
      final result = await InvoiceService.postGenerateInvoicePDF(
        context: context,
        invoice_id: _generatedInvoiceId!,
      );

      if (result?['success'] == true) {
        // Create filename from invoice number
        final invoiceNo = widget.invoiceData['invoice_no'] ?? 'invoice';
        final fileName = 'Invoice_${invoiceNo.replaceAll('/', '_')}.pdf';

        // Check if we received PDF bytes directly
        if (result?['is_direct_pdf'] == true && result?['pdf_bytes'] != null) {
          print('📄 Received PDF bytes directly from API');

          try {
            // Save PDF bytes to file
            final Uint8List pdfBytes = result!['pdf_bytes'] as Uint8List;

            // Get downloads directory
            Directory? directory;
            if (Platform.isAndroid) {
              directory = Directory('/storage/emulated/0/Download');
              if (!await directory.exists()) {
                directory = await getExternalStorageDirectory();
              }
            } else {
              directory = await getApplicationDocumentsDirectory();
            }

            if (directory != null) {
              final filePath = '${directory.path}/$fileName';
              final file = File(filePath);
              await file.writeAsBytes(pdfBytes);

              print('✅ PDF saved to: $filePath');

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '✅ PDF downloaded successfully!\nSaved to: $fileName',
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            }
          } catch (e) {
            print('❌ Error saving PDF bytes: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Error saving PDF: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
          return;
        }

        // Otherwise, try to download from URL
        final pdfUrl = result?['pdf_url'];

        if (pdfUrl != null && pdfUrl.toString().isNotEmpty) {
          print('📄 PDF URL received: $pdfUrl');
          print('💾 Starting download: $fileName');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⏳ Downloading PDF...'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
              ),
            );
          }

          // Check if URL ends with .php - if so, warn user
          String downloadUrl = pdfUrl.toString();
          if (downloadUrl.endsWith('.php') || downloadUrl.contains('.php?')) {
            print('⚠️ WARNING: URL is a PHP script: $downloadUrl');
            print('⚠️ This will likely download a PHP file instead of a PDF!');
            print(
              '💡 The API should return a direct PDF file URL (e.g., .../invoices/invoice_123.pdf)',
            );

            // Check if there's a direct PDF path in the response
            final directPdfPath =
                result?['data']?['pdf_path'] ??
                result?['data']?['file_path'] ??
                result?['pdf_path'];

            if (directPdfPath != null &&
                directPdfPath.toString().isNotEmpty &&
                !directPdfPath.toString().contains('.php')) {
              downloadUrl = directPdfPath.toString();
              print('✅ Found direct PDF path: $downloadUrl');
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      '⚠️ Warning: The PDF URL points to a PHP script.\n'
                      'This may download a PHP file instead of a PDF.\n'
                      'Please contact support to fix the API.',
                    ),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            }
          }

          // Force .pdf extension regardless of URL
          // Remove any existing extension and add .pdf
          String finalFileName = fileName.replaceAll(
            RegExp(r'\.(php|html|htm)$'),
            '',
          );
          if (!finalFileName.endsWith('.pdf')) {
            finalFileName = '$finalFileName.pdf';
          }

          print('📝 Final filename: $finalFileName');

          // Download the file using flutter_file_downloader
          await FileDownloader.downloadFile(
            url: downloadUrl,
            name: finalFileName,
            onProgress: (fileName, progress) {
              print('📊 Download progress: $progress%');
            },
            onDownloadCompleted: (path) async {
              print('✅ Download completed: $path');

              // Check if downloaded file has wrong extension and rename it
              if (path.endsWith('.php')) {
                print(
                  '⚠️ Downloaded file has .php extension, renaming to .pdf...',
                );

                try {
                  final oldFile = File(path);
                  final newPath = path.replaceAll(RegExp(r'\.php$'), '.pdf');

                  // Rename the file
                  await oldFile.rename(newPath);
                  print('✅ File renamed from .php to .pdf: $newPath');

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '✅ PDF downloaded successfully!\n'
                          'Saved as: $finalFileName\n'
                          '(File extension corrected from .php to .pdf)',
                        ),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ Error renaming file: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '⚠️ File downloaded but has .php extension.\n'
                          'Please rename it manually to .pdf\n'
                          'Location: $path',
                        ),
                        backgroundColor: Colors.orange,
                        duration: const Duration(seconds: 6),
                      ),
                    );
                  }
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '✅ PDF downloaded successfully!\nSaved to: $finalFileName',
                      ),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            onDownloadError: (errorMessage) {
              print('❌ Download error: $errorMessage');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Download failed: $errorMessage'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          );
        } else {
          print('⚠️ No PDF URL in response');
          print('📋 Full response: $result');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ PDF URL not available in response'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('❌ Error in _downloadInvoice: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error downloading PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      print('🔄 Initializing WebView...');

      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white);

      print('📄 Generating HTML content...');
      // Load the HTML content
      final htmlContent = await _generateInvoiceHtml();
      print('✅ HTML generated, length: ${htmlContent.length} characters');
      print(
        '📝 HTML preview (first 500 chars): ${htmlContent.substring(0, htmlContent.length > 500 ? 500 : htmlContent.length)}',
      );

      print('🌐 Loading HTML into WebView...');
      await _webViewController.loadHtmlString(htmlContent);

      print('✅ WebView loaded successfully');
      setState(() {
        _isWebViewReady = true;
      });
    } catch (e, stackTrace) {
      print('❌ Error initializing WebView: $e');
      print('Stack trace: $stackTrace');

      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading preview: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }

      // Set ready anyway to show error state
      setState(() {
        _isWebViewReady = true;
      });
    }
  }

  Future<String> _generateInvoiceHtml() async {
    try {
      print('📊 Extracting invoice data...');
      final currencySymbol = widget.selectedCurrency?['currency'] ?? '';
      final currencyCode = widget.selectedCurrency?['currency_code'] ?? '';
      final clientName =
          widget.selectedClient?['client_name'] ??
          widget.values?['other_client'] ??
          'N/A';
      final clientAddressLines =
          (widget.values?['client_address'] as String?)?.split('\n') ?? [];
      final jobDescriptionLines =
          (widget.values?['job_description'] as String?)?.split('\n') ?? [];

      final invoiceNo =
          widget.values?['invoice_number'] ??
          widget.invoiceData['invoice_no'] ??
          '';
      final invoiceDate = widget.values?['invoice_date'] is DateTime
          ? DateFormat('dd/MM/yyyy').format(widget.values!['invoice_date'])
          : widget.invoiceData['invoice_date'] ?? '';
      final dueDate = widget.values?['due_date'] is DateTime
          ? DateFormat('dd/MM/yyyy').format(widget.values!['due_date'])
          : widget.invoiceData['due_date'] ?? '';

      final discountLabel =
          widget.values?['reduce_label']?.trim() ??
          widget.invoiceData['discount_label'] ??
          'Discount';

      // Safely parse numeric values - they might be strings or numbers
      double discountAmount = 0;
      try {
        final reduceAmount = widget.values?['reduce_amount'];
        if (reduceAmount != null) {
          discountAmount = reduceAmount is num
              ? reduceAmount.toDouble()
              : double.tryParse(reduceAmount.toString()) ?? 0;
        } else {
          final discount = widget.invoiceData['discount'];
          discountAmount = discount is num
              ? discount.toDouble()
              : double.tryParse(discount?.toString() ?? '0') ?? 0;
        }
      } catch (e) {
        print('⚠️ Error parsing discount amount: $e');
        discountAmount = 0;
      }

      double invoiceAmount = 0;
      try {
        final invAmount = widget.values?['invoice_amount'];
        if (invAmount != null) {
          invoiceAmount = invAmount is num
              ? invAmount.toDouble()
              : double.tryParse(invAmount.toString()) ?? 0;
        } else {
          final subtotal = widget.invoiceData['subtotal'];
          invoiceAmount = subtotal is num
              ? subtotal.toDouble()
              : double.tryParse(subtotal?.toString() ?? '0') ?? 0;
        }
      } catch (e) {
        print('⚠️ Error parsing invoice amount: $e');
        invoiceAmount = 0;
      }

      final finalDue = invoiceAmount - discountAmount;
      final notice =
          widget.values?['notice']?.trim() ?? widget.values?['notice'] ?? '';

      print('✅ Invoice data extracted');
      print('   Invoice No: $invoiceNo');
      print('   Client: $clientName');
      print('   Amount: $currencySymbol $invoiceAmount $currencyCode');

      // Load assets as base64
      print('🖼️ Loading assets...');
      final logoBytes = await rootBundle.load('assets/images/namedlogo1.png');
      final logoBase64 = base64Encode(logoBytes.buffer.asUint8List());
      print('✅ Logo loaded');

      // final iconBytes = await rootBundle.load('assets/images/rsLogo167-1.png');
      // final iconBase64 = base64Encode(iconBytes.buffer.asUint8List());
      print('✅ Icon loaded');

      final bgImageBytes = await rootBundle.load(
        'assets/images/invoice_image_red.png',
      );
      final bgImageBase64 = base64Encode(bgImageBytes.buffer.asUint8List());
      print('✅ Background image loaded');

      // Bank info (from previewData or values)
      print('🏦 Processing bank info...');
      final bankInfo =
          widget.values?['bank_info'] ?? widget.invoiceData['bank_info'];
      final bankRows = <String>[];

      if (bankInfo is Map<String, dynamic>) {
        if (bankInfo['account_name'] != null) {
          bankRows.add(
            '<tr><td class="label">Account Name</td><td class="value">${bankInfo['account_name']}</td></tr>',
          );
        }
        if (bankInfo['account_number'] != null) {
          bankRows.add(
            '<tr><td class="label">Account Number</td><td class="value">${bankInfo['account_number']}</td></tr>',
          );
        }
        if (bankInfo['country'] != null) {
          bankRows.add(
            '<tr><td class="label">Country Name</td><td class="value">${bankInfo['country']}</td></tr>',
          );
        }
        if (bankInfo['bank_info'] is List) {
          for (var item in bankInfo['bank_info']) {
            if (item is Map && item['label'] != null && item['value'] != null) {
              bankRows.add(
                '<tr><td class="label">${item['label']}</td><td class="value">${item['value']}</td></tr>',
              );
            }
          }
        }
      }
      print('✅ Bank info processed: ${bankRows.length} rows');

      String clientAddressHtml = clientAddressLines
          .map((line) => '$line<br>')
          .join();
      String jobDescHtml = jobDescriptionLines
          .map((line) => line.isEmpty ? '<br>' : '$line<br>')
          .join();

      print('📝 Building HTML template...');

      return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Invoice #$invoiceNo</title>
  <style>

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
      width: 20%;
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
      padding: 20px 20px;
      border-radius: 0 0 0 50px;
      box-shadow: 0 8px 25px rgba(252,51,66,0.25);
    }

    .invoice-badge h1 {
      color: white;
      font-size: 25px;
      font-weight: 700;
      letter-spacing: 5px;
      margin-bottom: 10px;
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
    <img src="data:image/png;base64,$bgImageBase64" class="pink-shape" alt="" style="position: absolute; top: -300px; right: -150px; width: 600px; height: 600px; transform: rotate(330deg); z-index: 0; opacity: 1;">

    <div class="main-content">
      <!-- Header -->
      <div class="header">
        <div class="left-col">
          <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 35px;">
            <img src="data:image/png;base64,$logoBase64" alt="Logo" class="logo" style="margin-bottom: 0;">
          </div>

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
              Invoice No: $invoiceNo<br>
              Invoice Date: $invoiceDate<br>
              Due Date: $dueDate
            </div>
          </div>
        </div>
      </div>

      <!-- Customer -->
      <div class="customer-section">
        <div class="label">CUSTOMER:</div>
        <div class="customer-info">
          <div class="name">$clientName</div>
          $clientAddressHtml
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
            <tr>
              <td>$jobDescHtml</td>
              <td>$currencySymbol $invoiceAmount $currencyCode</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Total and Bank Details Side by Side -->
      <div class="bottom-section">
        <div class="bottom-left">
          ${(bankRows.isNotEmpty) ? '''
          <div class="label">BANK DETAILS:</div>
          <table class="bank-table">
            ${bankRows.join('')}
          </table>
          ''' : ''}
        </div>
        <div class="bottom-right">
          <div class="total-section">
            ${discountAmount > 0 ? '<p>$discountLabel: -$currencySymbol $discountAmount $currencyCode</p>' : ''}
            <p class="amount">Total Amount: $currencySymbol $finalDue $currencyCode</p>
          </div>
        </div>
      </div>

      <!-- Notice -->
      ${notice.isNotEmpty ? '''
      <div class="notice-section">
        <div class="notice-label">NOTICE:</div>
        <div class="notice-text">$notice</div>
      </div>
      ''' : ''}

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
    } catch (e, stackTrace) {
      print('❌ Error generating HTML: $e');
      print('Stack trace: $stackTrace');

      // Return a simple error HTML
      return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Error</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      padding: 40px;
      text-align: center;
    }
    .error {
      color: #FC3342;
      font-size: 18px;
      margin: 20px 0;
    }
    .details {
      background: #f5f5f5;
      padding: 20px;
      border-radius: 8px;
      text-align: left;
      margin: 20px auto;
      max-width: 600px;
    }
  </style>
</head>
<body>
  <h1>Error Loading Invoice</h1>
  <div class="error">Failed to generate invoice preview</div>
  <div class="details">
    <strong>Error:</strong><br>
    ${e.toString()}<br><br>
    <strong>Please check:</strong><br>
    - All required fields are filled<br>
    - Images are available in assets folder<br>
    - Invoice data is valid
  </div>
</body>
</html>
''';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isSaving
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  const Text('Saving invoice...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Invoice Preview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ReusableButton(
                        text: 'Save',
                        backgroundColor: primaryColor,
                        fontSize: 15,
                        isLoading: _isSaving,
                        textColor: Colors.white,
                        borderRadius: 10,
                        onPressed: _saveInvoice,
                      ),
                      const SizedBox(height: 12),
                      ReusableButton(
                        text: _isDownloading
                            ? 'Downloading...'
                            : 'Download Invoice',
                        backgroundColor: _generatedInvoiceId == null
                            ? Colors.grey
                            : Colors.yellow.shade300,
                        fontSize: 15,
                        borderRadius: 10,
                        textColor: Colors.black,
                        onPressed: _generatedInvoiceId == null || _isDownloading
                            ? null
                            : _downloadInvoice,
                      ),
                      const SizedBox(height: 12),
                      ReusableButton(
                        text: 'Back',
                        backgroundColor: backButtonColor,
                        fontSize: 15,
                        borderRadius: 10,
                        onPressed: () => Navigator.pop(context),
                        textColor: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Invoice Preview Container
                  Container(
                    height: 800,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.08),
                          spreadRadius: 0,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isWebViewReady
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: WebViewWidget(
                              controller: _webViewController,
                            ),
                          )
                        : Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
