import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart'; // ✅ import your home screen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://lnybxilouatjribioujv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxueWJ4aWxvdWF0anJpYmlvdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkyMDU4MTksImV4cCI6MjA2NDc4MTgxOX0.86A7FEkUHsmphPS8LyHoOr3ZtkGlaGw1sQJrOoWI1LQ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Health Bharat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C56F5),
          primary: const Color(0xFF6C56F5),
          secondary: const Color(0xFFF5A56C),
        ),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  bool isLogin = true;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

  final supabase = Supabase.instance.client;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuint));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void toggleAuthMode() {
    setState(() {
      isLogin = !isLogin;
      _controller.reset();
      _controller.forward();
    });
  }

  void _signIn() async {
    setState(() => isLoading = true);
    try {
      final email = _emailController.text;
      final password = _passwordController.text;

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        _showSnackBar('Invalid credentials');
      }
    } catch (e) {
      _showSnackBar('Login error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _signUp() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (response.user != null) {
        _showSnackBar('Check your email to confirm sign-up');
      }
    } catch (e) {
      _showSnackBar('Signup error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _resendConfirmationEmail() {
    _showSnackBar("Resend email link not implemented yet");
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Forgot Password'),
        content: const Text('Password reset flow coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            "https://i.ibb.co/G37yb3Hs/bg.jpg",
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.3)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _opacityAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: isLogin
                                ? _buildLoginForm()
                                : _buildSignupForm(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: toggleAuthMode,
                      child: Text(
                        isLogin
                            ? "Don't have an account? Sign Up"
                            : "Already have an account? Log In",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildTitle('Welcome Back'),
        _buildTextField(_emailController, 'Email', Icons.email_outlined),
        const SizedBox(height: 16),
        _buildTextField(_passwordController, 'Password', Icons.lock_outline, obscure: true),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _showForgotPasswordDialog,
              child: const Text('Forgot Password?', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: _resendConfirmationEmail,
              child: const Text('Resend Verification', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSubmitButton('Login', _signIn, Icons.login),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      children: [
        _buildTitle('Create Account'),
        _buildTextField(_usernameController, 'Username', Icons.person_outline),
        const SizedBox(height: 16),
        _buildTextField(_emailController, 'Email', Icons.email_outlined),
        const SizedBox(height: 16),
        _buildTextField(_phoneController, 'Phone Number', Icons.phone_outlined),
        const SizedBox(height: 16),
        _buildTextField(_passwordController, 'Password', Icons.lock_outline, obscure: true),
        const SizedBox(height: 24),
        _buildSubmitButton('Sign Up', _signUp, Icons.person_add),
      ],
    );
  }

  Widget _buildTitle(String text) {
    return Column(
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your journey to better health starts here.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool obscure = false}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(String text, Function() onPressed, IconData icon) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurpleAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(double.infinity, 50),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
