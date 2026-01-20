import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:rsw_portal/widgets/elevated_button.dart';
import 'dart:io' show File;

class ResuableDashboardContainer extends StatefulWidget {
  final BuildContext parentContext;

  const ResuableDashboardContainer(this.parentContext, {super.key});

  @override
  State<ResuableDashboardContainer> createState() =>
      _ResuableDashboardContainerState();
}

class _ResuableDashboardContainerState extends State<ResuableDashboardContainer> {
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
            children: [
              
            ],
          ),
        ),
      ),
    );
  }
}
