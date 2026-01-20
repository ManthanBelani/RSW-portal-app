import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/constants.dart';
import '../services/notes_service.dart';
import '../services/user_list_without_admin_service.dart';
import '../widgets/reusable_data_table.dart';
import 'edit_note_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _entriesPerPage = 50;
  bool _isLoading = false;
  List<Map<String, dynamic>> _notesData = [];

  @override
  void initState() {
    super.initState();
    _loadNotesData();
  }

  Future<void> _loadNotesData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await NotesService.getNotesList(
        perPage: _entriesPerPage,
        search: _searchController.text,
      );

      if (response != null && response['success'] == true) {
        final data = response['data']['data'] as List;

        setState(() {
          _notesData = data.map((note) {
            final accessibleUsers = note['accessible_users'] as List?;
            List<Map<String, String>> users = [];

            if (accessibleUsers != null && accessibleUsers.isNotEmpty) {
              users = accessibleUsers.map((user) {
                return {
                  'name': user['user_name']?.toString() ?? '',
                  'id': user['user_id']?.toString() ?? '',
                };
              }).toList();
            }

            return {
              'id': note['id']?.toString() ?? '',
              'name': note['project_name'] ?? '',
              'url': note['url'] ?? '',
              'users': users,
              'createdDate': note['created_at'] ?? '',
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading notes data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading notes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openNotesDetails(String noteId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await NotesService.getDetailsNotesList(noteId: noteId);

      if (!mounted) return;
      Navigator.pop(context);

      if (response != null && response['success'] == true) {
        final data = response['data'];
        _showNoteDetailsDialog(data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load note details'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showNoteDetailsDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            // width: MediaQuery.of(context).size.width * 0.2,
            constraints: const BoxConstraints(maxHeight: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'View Note',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Project Name
                          const Text(
                            'Project Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['project'] ?? '--',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const Divider(height: 32),
                          // URL
                          const Text(
                            'URL',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['url'] ?? '--',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  data['url'] != null &&
                                      data['url'].toString().isNotEmpty
                                  ? Colors.blue
                                  : Colors.black87,
                            ),
                          ),
                          const Divider(height: 32),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: _buildHtmlContent(data['note']),
                          ),
                          const Divider(height: 32),
                          const Text(
                            'Attachments',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (data['attachments'] != null &&
                              (data['attachments'] as List).isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: (data['attachments'] as List).map((
                                attachment,
                              ) {
                                return Chip(
                                  label: Text(attachment['name'] ?? 'File'),
                                  avatar: const Icon(
                                    Icons.attach_file,
                                    size: 16,
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            const Text(
                              'No attachments',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteNote(String noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this note?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(10),
                ),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteNote(noteId);
    }
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      final response = await NotesService.deleteNotes(noteId);

      if (!mounted) return;

      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Note deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadNotesData(); // Reload the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?['message'] ?? 'Failed to delete note'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmRemoveSpecificUser(
    String noteId,
    String userId,
    String userName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Confirm Remove User'),
          content: Text(
            'Are you sure you want to remove "$userName" from this note?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _removeSpecificUser(noteId, userId);
    }
  }

  Future<void> _removeSpecificUser(String noteId, String userId) async {
    try {
      final response = await NotesService.removeSpecificUserFromNote(
        noteId: noteId,
        userId: userId,
      );

      if (!mounted) return;

      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'User removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadNotesData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?['message'] ?? 'Failed to remove user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _confirmRemoveAllUsers(String noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Confirm Remove All Users'),
          content: const Text(
            'Are you sure you want to remove all users from the note?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Remove All'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _removeAllUsers(noteId);
    }
  }

  Future<void> _removeAllUsers(String noteId) async {
    try {
      final response = await NotesService.removeUsersNotes(noteId);

      if (!mounted) return;

      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'All users removed successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _loadNotesData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?['message'] ?? 'Failed to remove users'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _showNoteLogDialog(String noteId) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await NotesService.getLogOfNotes(noteId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (response != null && response['success'] == true) {
        final logData = response['data'] as List?;
        _displayLogDialog(logData ?? []);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load note log'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _displayLogDialog(List<dynamic> logData) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            // width: MediaQuery.of(context).size.width * 0.5,
            constraints: const BoxConstraints(maxHeight: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Note Log Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Content
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: logData.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Text(
                                'No log entries found',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                // Table Header
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(8),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          'User',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          'Updated Date Time',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Table Rows
                                ...logData.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final log = entry.value;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: index % 2 == 0
                                          ? Colors.white
                                          : Colors.grey[50],
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey[200]!,
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            log['updated_by'] ?? 'Unknown',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            log['updated_at'] ?? '--',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAccessUsersDialog(String noteId) async {
    // Fetch user list
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await UserListWithoutAdminService.getUserList();

      if (!mounted) return;
      Navigator.pop(context);

      if (response != null && response['success'] == true) {
        final users = response['data'] as List?;
        if (users != null) {
          // Get current note data to filter out existing users
          final currentNote = _notesData.firstWhere(
            (note) => note['id'] == noteId,
            orElse: () => {},
          );
          final existingUsers = currentNote['users'] as List<Map<String, String>>? ?? [];
          final existingUserIds = existingUsers.map((u) => u['id']).toSet();
          
          // Filter out users who already have access
          final availableUsers = users.where((user) {
            return !existingUserIds.contains(user['id']?.toString());
          }).toList();
          
          _showUserSelectionDialog(noteId, availableUsers, existingUsers);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load users'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showUserSelectionDialog(
    String noteId,
    List<dynamic> users,
    List<Map<String, String>> existingUsers,
  ) {
    List<String> selectedUserIds = [];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                width: 500,
                constraints: const BoxConstraints(
                  maxHeight: 600,
                  minWidth: 500,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Access Other Users',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Show existing users with access
                            if (existingUsers.isNotEmpty) ...[
                              const Text(
                                'Current Users with Access',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: existingUsers.map((user) {
                                    final userName = user['name'] ?? 'Unknown';
                                    return Chip(
                                      label: Text(userName),
                                      backgroundColor: Colors.green.shade50,
                                      avatar: const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            const Text(
                              'Select Users to Add Access',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFF1744),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFFF1744),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: selectedUserIds.isEmpty
                                    ? [
                                        const Text(
                                          'No users selected',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ]
                                    : selectedUserIds.map((userId) {
                                        final user = users.firstWhere(
                                          (u) => u['id'].toString() == userId,
                                        );
                                        final firstName = user['first_name']?.toString() ?? '';
                                        final lastName = user['last_name']?.toString() ?? '';
                                        final userName = '$firstName $lastName'.trim();
                                        final displayName = userName.isNotEmpty ? userName : 'Unknown';
                                        return Chip(
                                          label: Text(displayName),
                                          deleteIcon: const Icon(
                                            Icons.close,
                                            size: 16,
                                          ),
                                          onDeleted: () {
                                            setDialogState(() {
                                              selectedUserIds.remove(userId);
                                            });
                                          },
                                        );
                                      }).toList(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: users.isEmpty
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20.0),
                                          child: Text(
                                            'All users already have access to this note',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: users.length,
                                        itemBuilder: (context, index) {
                                          final user = users[index];
                                          final userId = user['id']?.toString() ?? '';
                                          final firstName = user['first_name']?.toString() ?? '';
                                          final lastName = user['last_name']?.toString() ?? '';
                                          final userName = '$firstName $lastName'.trim();
                                          final displayName = userName.isNotEmpty ? userName : 'Unknown User';
                                          final isSelected = selectedUserIds.contains(
                                            userId,
                                          );

                                          return ListTile(
                                            title: Text(
                                              displayName,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                            trailing: isSelected
                                                ? const Icon(
                                                    Icons.check_circle,
                                                    color: Color(0xFFFF1744),
                                                  )
                                                : const Icon(
                                                    Icons.circle_outlined,
                                                    color: Colors.grey,
                                                  ),
                                            onTap: () {
                                              setDialogState(() {
                                          if (isSelected) {
                                            selectedUserIds.remove(userId);
                                          } else {
                                            selectedUserIds.add(userId);
                                          }
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: selectedUserIds.isEmpty
                                      ? null
                                      : () async {
                                          Navigator.pop(context);
                                          await _addAccessToNote(
                                            noteId,
                                            selectedUserIds,
                                          );
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text('Add Access'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addAccessToNote(String noteId, List<String> userIds) async {
    try {
      final response = await NotesService.addAccessToNote(
        noteId: noteId,
        userIds: userIds,
      );

      if (!mounted) return;

      if (response != null && response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Access added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadNotesData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?['message'] ?? 'Failed to add access'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildHtmlContent(String? htmlContent) {
    if (htmlContent == null ||
        htmlContent.isEmpty ||
        htmlContent == '<p><br></p>') {
      return const Text(
        'No description',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      );
    }

    // Simple HTML rendering - convert common tags to styled text
    String content = htmlContent;

    // Remove <p> and </p> tags
    content = content.replaceAll('<p>', '').replaceAll('</p>', '\n');

    // Handle line breaks
    content = content
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<br />', '\n');

    // Remove other HTML tags for now
    content = content.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode HTML entities
    content = content
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    content = content.trim();

    if (content.isEmpty) {
      return const Text(
        'No description',
        style: TextStyle(fontSize: 14, color: Colors.grey),
      );
    }

    return Text(content, style: const TextStyle(fontSize: 14, height: 1.5));
  }

  Widget _buildSkeletonCell({required double height}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: 0.7,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonRow(int index) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            Expanded(flex: 3, child: _buildSkeletonCell(height: 16)),
            Expanded(flex: 2, child: _buildSkeletonCell(height: 24)),
            Expanded(flex: 2, child: _buildSkeletonCell(height: 16)),
            Expanded(flex: 2, child: _buildSkeletonCell(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTable() {
    if (_isLoading) {
      return Column(
        children: List.generate(5, (index) => _buildSkeletonRow(index)),
      );
    }

    if (_notesData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        child: Center(
          child: Text(
            'No notes found',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      );
    }

    return ReusableDataTable(
      columns: [
        TableColumnConfig(
          title: 'Name',
          flex: 1,
          builder: (data, index) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data['name'],
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (data['url'] != null && data['url'].toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  data['url'],
                  style: TextStyle(fontSize: 11, color: Colors.pink[400]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        TableColumnConfig(
          title: 'User',
          flex: 1,
          builder: (data, index) {
            final users = data['users'] as List<Map<String, String>>?;

            if (users == null || users.isEmpty) {
              return const Center(
                child: Text('--', style: TextStyle(fontSize: 16)),
              );
            }

            return Wrap(
              spacing: 4,
              runSpacing: 4,
              children: users.map((user) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1744),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          user['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          _confirmRemoveSpecificUser(
                            data['id'],
                            user['id'] ?? '',
                            user['name'] ?? '',
                          );
                        },
                        child: const Icon(
                          Icons.cancel,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        TableColumnConfig(
          title: 'Created Date',
          flex: 1,
          builder: (data, index) => Text(
            data['createdDate'],
            style: const TextStyle(fontSize: 13, color: Colors.black87),
          ),
        ),
        TableColumnConfig(
          title: 'Action',
          flex: 1,
          builder: (data, index) => Row(
            children: [
              IconButton(
                icon: Icon(Icons.visibility, color: Colors.blue[600], size: 18),
                onPressed: () {
                  _openNotesDetails(data['id']);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: Icon(Icons.edit, color: Colors.green[600], size: 18),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditNoteScreen(noteId: data['id']),
                    ),
                  );
                  if (result == true) {
                    _loadNotesData();
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: Icon(Icons.sticky_note_2, color: Colors.blue, size: 18),
                onPressed: () {
                  _showNoteLogDialog(data['id']);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: Icon(
                  Icons.accessibility,
                  color: Colors.amber[700],
                  size: 18,
                ),
                onPressed: () {
                  _showAccessUsersDialog(data['id']);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                onPressed: () {
                  _confirmDeleteNote(data['id']);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              IconButton(
                icon: Icon(
                  Icons.no_accounts,
                  color: Colors.grey[600],
                  size: 18,
                ),
                onPressed: () {
                  _confirmRemoveAllUsers(data['id']);
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ],
      data: _notesData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'View Notes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF1744),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      '+ Add Note',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
                  children: [
                    Row(
                      children: [
                        Row(
                          children: [
                            const Text('Show ', style: TextStyle(fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: DropdownButton<int>(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                dropdownColor: Colors.white,
                                value: _entriesPerPage,
                                underline: const SizedBox(),
                                items: [10, 25, 50, 100]
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text('$e'),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _entriesPerPage = value!;
                                  });
                                  _loadNotesData();
                                },
                              ),
                            ),
                            const Text(
                              ' entries',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 300,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          Future.delayed(const Duration(milliseconds: 500), () {
                            if (_searchController.text == value) {
                              _loadNotesData();
                            }
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildNotesTable(),
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
