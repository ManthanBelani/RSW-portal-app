import 'package:dashboard_clone/constants/constants.dart';
import 'package:dashboard_clone/services/change_password_service.dart';
import 'package:dashboard_clone/services/auth_service.dart';
import 'package:dashboard_clone/screens/login_screen.dart';
import 'package:flutter/material.dart';

import '../widgets/text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  String _passwordStrength = 'Too Weak';
  double _strengthProgress = 0.25;
  Color _strengthColor = Colors.red;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    String password = _passwordController.text;
    int score = 0;

    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    setState(() {
      if (score <= 1) {
        _passwordStrength = 'Too Weak';
        _strengthProgress = 0.25;
        _strengthColor = Colors.red;
      } else if (score == 2) {
        _passwordStrength = 'Weak';
        _strengthProgress = 0.5;
        _strengthColor = Colors.orange;
      } else if (score == 3) {
        _passwordStrength = 'Medium';
        _strengthProgress = 0.75;
        _strengthColor = Colors.yellow;
      } else {
        _passwordStrength = 'Strong';
        _strengthProgress = 1.0;
        _strengthColor = Colors.green;
      }
    });
  }

  bool _isFormValid() {
    return _oldPasswordController.text.isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text.length >= 8 &&
        _passwordController.text == _confirmPasswordController.text;
  }

  Future<void> _handleSubmit() async {
    // Trigger form validation to show errors on invalid fields
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      // Form is not valid, validation messages will be shown
      return;
    }

    // If the form is valid, proceed with the password change
    if (_isFormValid()) {
      await _handleChangePassword();
    } else {
      // Show general error message if form is valid but the validation check fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all fields correctly')),
        );
      }
    }
  }

  Future<void> _handleChangePassword() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await ChangePasswordService.changePassword(
        _oldPasswordController.text,
        _passwordController.text,
        _confirmPasswordController.text,
      );

      if (result['success'] == true) {
        // Clear form
        _oldPasswordController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _showSuccessDialogWithRedirect(
          result['message'] ?? 'Password changed successfully',
        );
      } else {
        _showErrorDialog(result['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      _showErrorDialog('An error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialogWithRedirect(String message) {
    showDialog(
      barrierColor: Colors.white,
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              const Text(
                'You will be redirected to the login screen to sign in with your new password.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await AuthService.clearToken();
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              child: const Text('Continue to Login'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),

            LayoutBuilder(
              builder: (context, constraints) {
                bool isDesktop = constraints.maxWidth > 800;

                if (isDesktop) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side - Password Fields
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            margin: EdgeInsets.all(25),
                            child: Column(
                              children: [
                                PasswordTextField(
                                  controller: _oldPasswordController,
                                  labelText: 'Old Password',
                                  showSuffixIcon: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Old password is required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                PasswordTextField(
                                  controller: _passwordController,
                                  labelText: 'Password',
                                  showSuffixIcon: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.length < 8) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                PasswordTextField(
                                  controller: _confirmPasswordController,
                                  labelText: 'Confirm Password',
                                  showSuffixIcon: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Confirm password is required';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Right side - Password Strength & Requirements
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            margin: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Password Strength Indicator
                                Row(
                                  children: [
                                    Expanded(
                                      child: LinearProgressIndicator(
                                        value: _strengthProgress,
                                        backgroundColor: Colors.grey.shade200,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              _strengthColor,
                                            ),
                                        minHeight: 4,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Strength Labels
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildStrengthLabel('Too Weak', 'Too Weak'),
                                    _buildStrengthLabel('Weak', 'Weak'),
                                    _buildStrengthLabel('Medium', 'Medium'),
                                    _buildStrengthLabel('Strong', 'Strong'),
                                  ],
                                ),
                                const SizedBox(height: 30),

                                // Password Requirements
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  // decoration: BoxDecoration(
                                  //   color: Colors.grey.shade50,
                                  //   borderRadius: BorderRadius.circular(8),
                                  //   border: Border.all(color: Colors.grey.shade200),
                                  // ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildRequirement(
                                        'At least 1 upper case letter (A-Z)',
                                        RegExp(
                                          r'[A-Z]',
                                        ).hasMatch(_passwordController.text),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildRequirement(
                                        'At least 1 number (0-9)',
                                        RegExp(
                                          r'[0-9]',
                                        ).hasMatch(_passwordController.text),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildRequirement(
                                        'At least 1 lower case letter (a-z)',
                                        RegExp(
                                          r'[a-z]',
                                        ).hasMatch(_passwordController.text),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildRequirement(
                                        'At least 1 symbol',
                                        RegExp(
                                          r'[!@#$%^&*(),.?":{}|<>]',
                                        ).hasMatch(_passwordController.text),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildRequirement(
                                        'A minimum of 8 to a maximum of 72 characters',
                                        _passwordController.text.length >= 8 &&
                                            _passwordController.text.length <=
                                                72,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Mobile Layout - Stacked
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        PasswordTextField(
                          controller: _oldPasswordController,
                          labelText: 'Old Password',
                          showSuffixIcon: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Old password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        PasswordTextField(
                          controller: _passwordController,
                          labelText: 'Password',
                          showSuffixIcon: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        PasswordTextField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm Password',
                          showSuffixIcon: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirm password is required';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30),

                        // Password Strength Indicator
                        Container(
                          margin: EdgeInsets.all(10),
                          child: Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: _strengthProgress,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _strengthColor,
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Strength Labels
                        Container(
                          margin: EdgeInsets.all(10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStrengthLabel('Too Weak', 'Too Weak'),
                              _buildStrengthLabel('Weak', 'Weak'),
                              _buildStrengthLabel('Medium', 'Medium'),
                              _buildStrengthLabel('Strong', 'Strong'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Password Requirements
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRequirement(
                                'At least 1 upper case letter (A-Z)',
                                RegExp(
                                  r'[A-Z]',
                                ).hasMatch(_passwordController.text),
                              ),
                              const SizedBox(height: 8),
                              _buildRequirement(
                                'At least 1 number (0-9)',
                                RegExp(
                                  r'[0-9]',
                                ).hasMatch(_passwordController.text),
                              ),
                              const SizedBox(height: 8),
                              _buildRequirement(
                                'At least 1 lower case letter (a-z)',
                                RegExp(
                                  r'[a-z]',
                                ).hasMatch(_passwordController.text),
                              ),
                              const SizedBox(height: 8),
                              _buildRequirement(
                                'At least 1 symbol',
                                RegExp(
                                  r'[!@#$%^&*(),.?":{}|<>]',
                                ).hasMatch(_passwordController.text),
                              ),
                              const SizedBox(height: 8),
                              _buildRequirement(
                                'A minimum of 8 to a maximum of 72 characters',
                                _passwordController.text.length >= 8 &&
                                    _passwordController.text.length <= 72,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading
                      ? Colors.grey.shade300
                      : (_isFormValid() ? primaryColor : Colors.grey.shade300),
                  foregroundColor: _isLoading
                      ? Colors.grey.shade600
                      : (_isFormValid() ? Colors.white : Colors.grey.shade600),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey,
                          ),
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthLabel(String text, String strengthType) {
    Color color;
    FontWeight fontWeight = FontWeight.normal;

    if (_passwordStrength == strengthType) {
      fontWeight = FontWeight.bold;
      switch (strengthType) {
        case 'Too Weak':
          color = Colors.red;
          break;
        case 'Weak':
          color = Colors.orange;
          break;
        case 'Medium':
          color = Colors.yellow.shade700;
          break;
        case 'Strong':
          color = Colors.green;
          break;
        default:
          color = Colors.grey;
      }
    } else {
      color = Colors.grey;
    }

    return Text(
      text,
      style: TextStyle(fontSize: 12, color: color, fontWeight: fontWeight),
    );
  }

  Widget _buildRequirement(String text, bool isMet) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              decoration: isMet
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: Colors.grey.shade600,
              fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
