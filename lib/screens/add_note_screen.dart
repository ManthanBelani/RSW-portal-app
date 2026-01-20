import 'package:dashboard_clone/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:file_picker/file_picker.dart';
import '../services/client_list.dart';
import '../services/notes_service.dart';
import '../widgets/searchable_dropdown.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  late List<Map<String, dynamic>> _clients = [];

  Future<void> _getProjectList() async {
    try {
      final result = await ClientList.getProjectUserList();
      if (!mounted) return;

      if (result != null && result['success'] == true) {
        final clientData = result['data'] as List<dynamic>;
        setState(() {
          _clients = clientData
              .map(
                (client) => {
                  'id': client['id']?.toString() ?? '',
                  'name': client['project_name'] ?? client['name'] ?? '',
                },
              )
              .toList();
        });
      }
    } catch (e) {
      print(e);
    }
  }

  final QuillController _controller = QuillController.basic();

  String? _selectedClients;
  List<PlatformFile> _attachments = [];

  @override
  void initState() {
    super.initState();
    _getProjectList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _attachments.addAll(result.files);
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  String _convertDeltaToHtml() {
    final delta = _controller.document.toDelta();
    final buffer = StringBuffer();
    
    for (var op in delta.toList()) {
      if (op.data is String) {
        String text = op.data as String;
        final attributes = op.attributes;
        
        if (attributes != null) {
          if (attributes['bold'] == true) {
            text = '<strong>$text</strong>';
          }
          if (attributes['italic'] == true) {
            text = '<em>$text</em>';
          }
          if (attributes['underline'] == true) {
            text = '<u>$text</u>';
          }
          if (attributes['strike'] == true) {
            text = '<s>$text</s>';
          }
          if (attributes['header'] != null) {
            final level = attributes['header'];
            text = '<h$level>$text</h$level>';
          }
        }
        
        buffer.write(text.replaceAll('\n', '<br>'));
      }
    }
    
    return '<p>${buffer.toString()}</p>';
  }

  Future<void> _submitNote() async {
    if (_selectedClients == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a project')),
      );
      return;
    }

    try {
      final html = _convertDeltaToHtml();
      final result = await NotesService.createNote(
        projectId: _selectedClients!,
        editorHtml: html,
        attachments: _attachments.isNotEmpty ? _attachments : null,
      );
      if (!mounted) return;

      if (result != null && result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Note created successfully'),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['message'] ?? 'Failed to create note'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Note',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Back',
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
                padding: const EdgeInsets.all(32),
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
                    // Project Dropdown
                    SearchableDropdown(
                      value: _selectedClients,
                      hint: 'Select Project',
                      items: _clients,
                      onChanged: (value) {
                        setState(() {
                          _selectedClients = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    // Notes Label
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          QuillSimpleToolbar(
                            controller: _controller,
                            config: const QuillSimpleToolbarConfig(
                              sectionDividerColor: Colors.black,
                              axis: Axis.horizontal,
                              dialogTheme: QuillDialogTheme(
                                dialogBackgroundColor: Colors.white,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.grey,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 250,
                            child: QuillEditor.basic(
                              controller: _controller,
                              config: const QuillEditorConfig(
                                dialogTheme: QuillDialogTheme(
                                  dialogBackgroundColor: Colors.white,
                                ),
                                scrollable: true,
                                padding: EdgeInsets.all(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Attachments Section
                    const Text(
                      'Attachments',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // File Upload Area
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text: 'Drag & drop your file or ',
                                    ),
                                    TextSpan(
                                      text: 'Browse',
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _pickFiles,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text(
                              'Browse',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Display selected files
                    if (_attachments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _attachments.asMap().entries.map((entry) {
                          return Chip(
                            label: Text(entry.value.name),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeAttachment(entry.key),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Submit Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton(
                        onPressed: _submitNote,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
