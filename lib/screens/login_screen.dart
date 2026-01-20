import 'package:dashboard_clone/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import '../widgets/elevated_button.dart';
import '../widgets/text_field.dart';
import '../constants/constants.dart';
import '../services/auth_service.dart';
import '../services/login_service.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await LoginService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result != null && result['success'] == true) {
        final userEmail =
            result['data']?['email'] ?? _emailController.text.trim();
        print('Login successful for email: $userEmail');

        await AuthService.storeTokenAfterLogin();
        // // Extract user permission data from the login response
        // final userPermissionData = result['data']?['user_designation_permission'];

        _showMessage('Login successful!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(
              result: result,
            ),
          ),
        );
      } else {
        final errorMessage = result?['message'] ?? 'Login failed';
        print('Login failed: $errorMessage');
        _showMessage(errorMessage);
      }
    } catch (e) {
      print('Login error: $e');
      _showMessage('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        // Right side - Login form
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Sign in to RSW',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      EmailTextField(
                        hintText: 'Enter your email',
                        controller: _emailController,
                      ),
                      const SizedBox(height: 20),
                      PasswordTextField(
                        labelText: 'Password',
                        showSuffixIcon: true,
                        controller: _passwordController,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(color: primaryColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ReusableButton(
                        text: 'Login',
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ),
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
        child: Form(
          key: _formKey,
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
              const Text(
                'Sign in to RSW',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              EmailTextField(
                hintText: 'Enter your email',
                controller: _emailController,
              ),
              const SizedBox(height: 20),
              PasswordTextField(
                labelText: 'Password',
                showSuffixIcon: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ReusableButton(
                text: 'Login',
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
