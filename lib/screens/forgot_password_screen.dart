import 'package:flutter/material.dart';

import '../widgets/elevated_button.dart';
import '../widgets/text_field.dart';
import '../constants/constants.dart';
import '../services/forgot_password.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  String _successEmail = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Please enter your email address', isError: true);
      return;
    }

    if (!_isValidEmail(email)) {
      _showMessage('Please enter a valid email address', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ForgotPasswordService.forgetPassword(email);

      if (result['success'] == true) {
        setState(() {
          _isSuccess = true;
          _successEmail = email;
        });
      } else {
        String errorMessage = result['message'] ?? 'Failed to send reset email';
        print('Forgot password error: $errorMessage');
        _showMessage(errorMessage, isError: true);
      }
    } catch (e) {
      print('Forgot password exception: $e');
      _showMessage(
        'Network error: Please check your connection and try again.',
        isError: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildDesktopFormContainer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Forgot your password?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const Text(
          ' Please enter the email address associated with your account and We will email you a link to reset your password.',
          style: TextStyle(fontSize: 15, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 30),
        EmailTextField(
          hintText: 'Enter your email',
          controller: _emailController,
        ),
        const SizedBox(height: 20),
        ReusableButton(
          text: _isLoading ? 'Sending...' : 'Send',
          onPressed: _isLoading ? null : _handleForgotPassword,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            disabledBackgroundColor: Color(0xFFFC3342),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text('Back'),
        ),
      ],
    );
  }

  // Right side - Successful forgot password container
  Widget _buildDesktopSuccessContainer() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Image.asset('assets/images/paper_plane-removebg-preview.png'),
        ),
        const SizedBox(height: 40),
        const Text(
          'Request sent successfully',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Text(
              'We have sent a confirmation email to $_successEmail',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            Text(
              '$_successEmail',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Please check your email.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 50),
        ReusableButton(
          text: 'Back',
          backgroundColor: primaryColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 768;
          if (isDesktop) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(15)),
              color: const Color(0xFFF5F5F5),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/rsLogo167-1.png',
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(height: 20),
                  Image.asset('assets/images/namedlogo1.png', height: 60),
                ],
              ),
            ),
          ),
        ),
        // Right side - Forgot password form or Success container
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: _isSuccess
                    ? _buildDesktopSuccessContainer()
                    : _buildDesktopFormContainer(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 60),
            // Logo section for mobile
            Center(
              child: Padding(
                padding: const EdgeInsets.only(left: 25.0, top: 12),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/rsLogo167.png',
                      height: 70,
                      width: 70,
                    ),
                    const SizedBox(height: 15),
                    Image.asset('assets/images/namedlogo.png', height: 50),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            _isSuccess
                ? _buildMobileSuccessContainer()
                : _buildMobileFormContainer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileFormContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Forgot your password?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Please enter the email address associated with your account and We will email you a link to reset your password.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 30),
        EmailTextField(
          hintText: 'Enter your email',
          controller: _emailController,
        ),
        const SizedBox(height: 20),
        ReusableButton(
          text: _isLoading ? 'Sending...' : 'Send',
          backgroundColor: primaryColor,
          onPressed: _isLoading ? null : _handleForgotPassword,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: primaryColor,
            disabledBackgroundColor: Color(0xFFFC3342),
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text('Back'),
        ),
      ],
    );
  }

  Widget _buildMobileSuccessContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Image.asset('assets/images/paper_plane-removebg-preview.png'),
        ),
        const SizedBox(height: 30),
        const Text(
          'Request sent successfully',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        Text(
          'We have sent a confirmation email to',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        Text(
          '$_successEmail',
          style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'Please check your email.',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        ReusableButton(
          text: 'Back',
          backgroundColor: primaryColor,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
