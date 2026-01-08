import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../provider/auth_provider.dart';
import 'home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();

  String? _selectedArea;
  final List<String> _areas = ['Dindoli'];
  bool _isSignUp = true;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (_isSignUp) {
        if (_selectedArea == null) {
          toastification.show(
            context: context,
            title: const Text('Error'),
            description: const Text('Please select an area'),
            type: ToastificationType.error,
            autoCloseDuration: const Duration(seconds: 3),
          );
          return;
        }

        final success = await authProvider.signUp(
          email: _emailController.text.trim(),
          username: _usernameController.text.trim(),
          area: _selectedArea!,
        );

        if (success && context.mounted) {
          toastification.show(
            context: context,
            title: const Text('Success'),
            description: const Text('Registration successful!'),
            type: ToastificationType.success,
            autoCloseDuration: const Duration(seconds: 3),
          );
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      } else {
        final success = await authProvider.signIn(area: _selectedArea ?? '', email: _emailController.text.trim());

        if (success && context.mounted) {
          toastification.show(
            context: context,
            title: const Text('Success'),
            description: const Text('Login successful!'),
            type: ToastificationType.success,
            autoCloseDuration: const Duration(seconds: 3),
          );
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      }

      if (!authProvider.isLoading && authProvider.errorMessage != null && context.mounted) {
        toastification.show(
          context: context,
          title: const Text('Error'),
          description: Text(authProvider.errorMessage!),
          type: ToastificationType.error,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      if (!_isSignUp) {
        _usernameController.clear();
        _selectedArea = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authentication')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isSignUp ? 'Create Account' : 'Welcome',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                        ),
                        const SizedBox(height: 24),

                        if (_isSignUp) ...[
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline),
                              border: OutlineInputBorder(),
                            ),
                            validator: _isSignUp ? (value) => value == null || value.isEmpty ? 'Please enter a username' : null : null,
                          ),
                          const SizedBox(height: 16),
                        ],

                        DropdownButtonFormField<String>(
                          value: _selectedArea,
                          decoration: const InputDecoration(
                            labelText: 'Area',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            border: OutlineInputBorder(),
                          ),
                          items: _areas.map((String area) {
                            return DropdownMenuItem<String>(value: area, child: Text(area));
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedArea = newValue;
                            });
                          },
                          validator: _isSignUp ? (value) => value == null || value.isEmpty ? 'Please select an area' : null : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                          validator: (value) => value == null || !value.contains('@') ? 'Please enter a valid email' : null,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ? null : () => _submit(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: authProvider.isLoading
                                ? SizedBox(width: 20, height: 20, child: const CircularProgressIndicator(color: Colors.white))
                                : Text(_isSignUp ? 'Sign Up' : 'Sign In', style: const TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),

                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _toggleMode,
                          child: Text(_isSignUp ? 'Already have an account? Sign In' : 'Don\'t have an account? Sign Up'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
