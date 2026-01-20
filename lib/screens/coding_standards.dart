import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../constants/constants.dart';
import '../services/coding_standard_service.dart';

class CodingStandards extends StatefulWidget {
  const CodingStandards({super.key});

  @override
  State<CodingStandards> createState() => _CodingStandardsState();
}

class _CodingStandardsState extends State<CodingStandards> {
  @override
  void initState() {
    super.initState();
    _loadCodingStandards();
  }

  bool _isLoading = false;
  bool _isLoadingDetails = false;
  List<Map<String, dynamic>> _codingStandards = [];
  String? _selectedStandard;
  String? _htmlContent;
  late WebViewController _webViewController;

  Future<void> _loadCodingStandards() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await CodingStandardService.getCodingStandardList();

      if (response != null && response['success'] == true) {
        setState(() {
          _codingStandards = List<Map<String, dynamic>>.from(
            response['data'] ?? [],
          );
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response?['message'] ?? 'Failed to load coding standards',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading coding standards: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCodingStandardDetails(String id) async {
    print('=== Loading Coding Standard Details ===');
    print('Selected ID: $id');

    setState(() {
      _isLoadingDetails = true;
      _htmlContent = null;
    });

    try {
      final response = await CodingStandardService.getCodingStandardDetails(
        coding_standard_id: int.parse(id),
      );

      print('Details Response: $response');

      if (response != null && response['success'] == true) {
        print('Response data: ${response['data']}');
        final description = response['data']?['description'] ?? '';

        print('Description length: ${description.length}');

        if (description.isEmpty) {
          print('WARNING: Description is empty!');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No description found for this standard'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Create a complete HTML document with styling
        final fullHtml =
            '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body {
      font-family: Arial, sans-serif;
      padding: 16px;
      margin: 0;
      background-color: #f9f9f9;
    }
    .card {
      background: white;
      border-radius: 8px;
      padding: 16px;
      margin-bottom: 16px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .row {
      display: flex;
      flex-wrap: wrap;
      margin: -8px;
    }
    .col-6 {
      flex: 0 0 50%;
      padding: 8px;
      box-sizing: border-box;
    }
    .col-12 {
      flex: 0 0 100%;
      padding: 8px;
      box-sizing: border-box;
    }
    h6 {
      color: #333;
      font-size: 18px;
      margin: 16px 0 8px 0;
      font-weight: 600;
    }
    .benifit {
      color: #666;
      font-size: 14px;
      line-height: 1.6;
      margin: 8px 0;
    }
    .dontheader {
      background-color: #dc3545;
      color: white;
      padding: 8px 12px;
      border-radius: 4px;
      font-weight: 600;
      margin-bottom: 8px;
    }
    .doheader {
      background-color: #28a745;
      color: white;
      padding: 8px 12px;
      border-radius: 4px;
      font-weight: 600;
      margin-bottom: 8px;
    }
    code {
      display: block;
      background-color: #f4f4f4;
      border: 1px solid #ddd;
      border-radius: 4px;
      padding: 12px;
      font-family: 'Courier New', monospace;
      font-size: 13px;
      line-height: 1.5;
      overflow-x: auto;
      white-space: pre-wrap;
      word-wrap: break-word;
    }
    hr {
      border: none;
      border-top: 1px solid #e0e0e0;
      margin: 24px 0;
    }
    @media (max-width: 768px) {
      .col-6 {
        flex: 0 0 100%;
      }
    }
  </style>
</head>
<body>
  $description
</body>
</html>
''';

        print('Creating HTML with ${fullHtml.length} characters');

        setState(() {
          _htmlContent = fullHtml;
        });

        // Initialize WebView controller
        _webViewController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadHtmlString(_htmlContent!);

        print('WebView initialized successfully');
      } else {
        print('API call failed or returned success: false');
        print('Response: $response');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response?['message'] ?? 'Failed to load details'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('Error loading details: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() {
        _isLoadingDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Coding Standard',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              // Dropdown Section
              Container(
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Coding Standard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_codingStandards.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: const Center(
                          child: Text(
                            'No coding standards available',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<String>(
                        borderRadius: BorderRadius.circular(10),
                        dropdownColor: Colors.white,
                        value: _selectedStandard,
                        decoration: InputDecoration(
                          hintText: 'Choose a coding standard',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: _codingStandards.map((standard) {
                          return DropdownMenuItem<String>(
                            value:
                            standard['id']?.toString() ??
                                standard['techn_name'],
                            child: Text(
                              standard['techn_name'] ?? 'Unknown',
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedStandard = value;
                          });
                          if (value != null) {
                            _loadCodingStandardDetails(value);
                          }
                        },
                      ),
                    const SizedBox(height: 30),

                    // Display HTML content in WebView
                    if (_isLoadingDetails)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_htmlContent != null)
                      Container(
                        height: 600,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: WebViewWidget(
                            controller: _webViewController,
                          ),
                        ),
                      )
                    else if (_selectedStandard != null)
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: const Center(
                            child: Text(
                              'No content available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
