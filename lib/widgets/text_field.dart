
import 'package:flutter/material.dart';

import '../constants/constants.dart';

class ReusableTextField extends StatelessWidget {
  final String labelText;
  final String? hintText;
  final TextEditingController? controller;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool enabled;
  final int maxLines;
  final TextStyle Tstyle;
  final String? initialValue;

  const ReusableTextField({
    super.key,
    required this.labelText,
    this.hintText,
    this.controller,
    this.isPassword = false,
    this.validator,
    this.keyboardType,
    this.Tstyle = const TextStyle(color: Colors.black87), // Default text color to grey/black
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.initialValue,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          style: Tstyle,
          controller: controller,
          initialValue: initialValue,
          obscureText: isPassword,
          validator: validator,
          keyboardType: keyboardType,
          enabled: enabled,
          maxLines: maxLines,
          decoration: InputDecoration(
            focusColor: primaryColor,
            fillColor: primaryColor,
            labelText: labelText,
            labelStyle: TextStyle(color: Colors.grey), // Set label text to grey
            // hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey), // Set hint text to grey
            suffixIcon: suffixIcon,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.grey, // This sets the non-focus color to grey
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: primaryColor, // This ensures focus color is primaryColor
                width: 2.0,
              ),
            ),
            prefixIcon: prefixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

// Email text field with built-in validation
class EmailTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool enabled;

  const EmailTextField({
    Key? key,
    this.controller,
    this.hintText = 'Enter your email',
    this.validator,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ReusableTextField(
      labelText: 'Email',
      hintText: hintText,
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      enabled: enabled,
      validator: validator ??
              (value) {
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          }, 
      Tstyle: TextStyle(color: Colors.black87), // Set default text color to grey/black
    );
  }
}

// Password text field with built-in validation
class PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool showSuffixIcon;
  final TextStyle? Tstyle;

  const PasswordTextField({
    super.key,
    this.controller,
    this.hintText = 'Enter your password',
    this.validator,
    this.enabled = true,
    this.showSuffixIcon = true,
    this.Tstyle,
    this.labelText,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return ReusableTextField(
      labelText: '${widget.labelText}',
      hintText: widget.hintText,
      controller: widget.controller,
      isPassword: !_isPasswordVisible, // Show password when _isPasswordVisible is true
      enabled: widget.enabled,
      validator: widget.validator ??
              (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
      suffixIcon: widget.showSuffixIcon
          ? IconButton(
        icon: Icon(
          _isPasswordVisible
              ? Icons.visibility_off
              : Icons.visibility,
        ),
        onPressed: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
      )
          : null,
      Tstyle: widget.Tstyle ?? const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
    );
  }
}