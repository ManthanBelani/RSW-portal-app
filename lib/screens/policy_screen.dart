import 'package:dashboard_clone/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/policy_service.dart';

class PolicyScreen extends StatefulWidget {
  const PolicyScreen({super.key});

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  bool _isDownloading = false;

  Future<void> _downloadPolicy() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final policyText = companyPolicy;

      final result = await PolicyService.postDownloadPolicyPDF(
        context: context,
        privacy_policy: policyText,
      );

      if (!mounted) return;

      if (result != null && result['success'] == true) {
        // Check if we got direct PDF bytes
        if (result['is_direct_pdf'] == true && result['pdf_bytes'] != null) {
          await _savePdfFile(result['pdf_bytes']);
        } else if (result['pdf_url'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF URL: ${result['pdf_url']}'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Policy downloaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading policy: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _savePdfFile(List<int> pdfBytes) async {
    try {
      if (kIsWeb) {
        // For web, trigger download
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF downloaded successfully'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // Get the appropriate directory based on platform
      Directory? directory;

      if (Platform.isAndroid) {
        // Try to use Downloads folder first
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          // Fallback to external storage directory
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access downloads directory');
      }

      // Create file with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/company_policy_$timestamp.pdf';
      final file = File(filePath);

      // Write the PDF bytes to file
      await file.writeAsBytes(pdfBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Policy saved to: $filePath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Company Policy',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isDownloading ? null : _downloadPolicy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isDownloading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Download Policy',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.08),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Image.asset(
                          'assets/images/rsLogo167-1.png',
                          height: 50,
                        ),
                        const SizedBox(width: 8),
                        Image.asset('assets/images/namedlogo1.png', height: 50),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: companyPolicy.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Icon(
                                      Icons.arrow_right_alt,
                                      color: Colors.grey[700],
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      companyPolicy[index],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                            ],
                          ),
                        );
                      },
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

  static const companyPolicy = [
    "Smoking and Tobacco use are not allowed in the entire office premises.",
    "Chatting, Talking on mobile phones, Surfing social network websites are not allowed inside the office.",
    "Employees are not allowed to do any freelancing or non-company project related work inside office. Anyone found will directly result in termination of employment.",
    'No employee is allowed to call other employee with pronouncing as "sir", "madam", "bhai", "bahen" etc. Everyone must be called with their first name only.',
    "If any employee is not performing well then senior employee can report direct to management. No employee is allowed to bully other employee even if any employee is not performing as per expectations.",
    "Pendrive, External Harddisk, attaching mobile, taking personal laptop without prior permission is not allowed inside office.",
    "Use of personal email is not allowed. Company email should be used in all project related work. Along with this, You are not allowed to push any company project code to public Git repositories or any personal Git repositories.",
    "Employees need to submit National Id & Address proof before they join the company. Company should be aware of the Employee's criminal record if any in the past.",
    "Experienced employees need to submit their last 3 month salary slip with an experienced letter from the previous company.",
    "Office timing will be from 10:00 AM to 07:30 PM. Employees will be required to work \nMinimum 8.5 hours a day.\nMinimum 4.5 working hours are required for half leave",
    "All Saturdays are off. Company may ask to work on Saturday only in case of any Emergency for which you will also get paid.",
    "Employees are required to give notice prior to 1 day for half and full leave. We appreciate early notice.",
    "Employees are required to give notice prior to a week for more than 1 day leave.",
    "Employees are required to fill up daily billable hours in the company account portal before they leave the office.",
    "In/Out time punching is mandatory for all Employees.",
    "Lunch / snacks must be taken within the lunch room. Taking it on a workstation is strictly prohibited except Tea.",
    "Employees are allowed to leave early if they have completed their working hours, time entry and given an update to the supervisor.",
    "If employees require to leave early from 30 minutes to 2 hours then they need to adjust working hours and make sure it gets completed by not taking a break or start work early in the morning.",
    "Salary will get credited in the bank account from 1st to 5th day of the month.",
    "Yearly 10 to 12 holidays will be scheduled by the company depending upon the date of public holidays in the ongoing year.",
    "Employees shall be on probation for a period of 3 months from the date of their joining duty. The probation period will be deemed to have been extended for a further period of 6 months unless you are informed about its successful completion in writing.",
    "You shall be bound by the service rules and regulations of the company in force from time to time and any statutory acts applicable to the company, which includes 15 months bond with the company.",
    "1 monthly leave will be provided by the company. Taking more than one leave will result in a deduction of salary.",
    "Unused one leave will be carried forward next month. Balanced leave will get encashed in the December month's salary. Employees who are leaving the company before December will not get any leave encashment.",
    "45 business days [Around 2 months] of the notice period is mandatory after giving resignation in the company. This time period is required for transferring knowledge to another employee. Company may release employees early if there is no dependency of the employee in any running project.",
    "Company may give a Diwali bonus depending upon last year's profit of the company. Amount may differ depending upon Employee salary and how long the employee is working with the company.",
    "Company can release any employee by giving less than 1 month prior notice in case of not being able to match the required output.",
    "Company can terminate the contract immediately in case of inappropriate behavior.",
    "Employees are not allowed to contact any of the company's clients outside the office while working with the company or after resigning from the company. Company may take legal action for such incidents.",
    "Employees are not allowed to take any leave while their probation or notice period is going on. Taking leave in both of these period will result in direct deduction of salary as well as extending the notice period for those number of days.",
    "Salary increment will be done on a yearly basis. 1 year will be calculated based on the Employee's joining date of the company. For freshers it will be after the start of the salary. Amount of increment will depend upon last year's performance by the Employee.",
    "Monthly salary will be calculated based on the number of(business) working days in that month.",
  ];
}
