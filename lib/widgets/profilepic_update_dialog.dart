import 'package:dashboard_clone/widgets/elevated_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:rsw_portal/widgets/elevated_button.dart';
import 'dart:io' show File;

class UpdateProfilePicturePopup extends StatefulWidget {
  final BuildContext parentContext;

  const UpdateProfilePicturePopup(this.parentContext, {super.key});

  @override
  State<UpdateProfilePicturePopup> createState() =>
      _UpdateProfilePicturePopupState();
}

class _UpdateProfilePicturePopupState extends State<UpdateProfilePicturePopup> {
  File? _selectedImage;
  String _fileName = '';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _fileName = pickedFile.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isMobile
            ? screenSize.width * 0.9
            : 400,
        constraints: BoxConstraints(
          maxHeight: screenSize.height * 0.8,
          maxWidth: isMobile ? screenSize.width * 0.9 : 500,
        ),
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Update Profile Picture',
                style: TextStyle(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'No file selected',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      controller: TextEditingController(text: _fileName),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ReusableButton(text: 'Browse', fontSize: 14,padding:kIsWeb ? EdgeInsets.all(20) : null,onPressed: _pickImage),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedImage = null;
                        _fileName = '';
                      });
                    },
                    icon: const Icon(Icons.download),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: isMobile ? 120 : 150,
                height: isMobile ? 120 : 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _selectedImage != null
                    ? Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover))
                    : const Center(
                        child: Icon(Icons.image, size: 40, color: Colors.grey),
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
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedImage == null
                        ? null
                        : () {
                            ScaffoldMessenger.of(
                              widget.parentContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text('Profile picture updated!'),
                              ),
                            );
                            Navigator.pop(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
