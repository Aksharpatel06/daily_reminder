import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import '../provider/auth_provider.dart';
import '../utils/custom_color.dart';
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
      backgroundColor: CustomColor.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SizedBox(child: Image.asset("assets/img/bg.png")),
            Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.55,
                          decoration: BoxDecoration(
                            color: CustomColor.primaryColor,
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0)),
                          ),
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
                                        _isSignUp ? 'Sign Up' : 'Sign In',
                                        style: GoogleFonts.afacad(fontWeight: FontWeight.w600, fontSize: 28, color: CustomColor.textColor),
                                      ),
                                      const SizedBox(height: 24),

                                      if (_isSignUp) ...[
                                        TextFormField(
                                          controller: _usernameController,
                                          style: GoogleFonts.afacad(color: CustomColor.textColor),
                                          decoration: InputDecoration(
                                            labelText: 'UserName',
                                            fillColor: CustomColor.primaryColor,
                                            prefixIcon: Icon(Icons.person_outline, color: CustomColor.subTextColor),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(10)),
                                              borderSide: BorderSide(color: CustomColor.subTextColor, width: 0.5),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(Radius.circular(10)),
                                              borderSide: BorderSide(color: CustomColor.subTextColor, width: 0.5),
                                            ),
                                            labelStyle: GoogleFonts.afacad(color: CustomColor.subTextColor, fontSize: 20),
                                          ),
                                          validator: _isSignUp ? (value) => value == null || value.isEmpty ? 'Please enter a username' : null : null,
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedArea,
                                        focusColor: CustomColor.primaryColor,
                                        dropdownColor: CustomColor.primaryColor,
                                        decoration: InputDecoration(
                                          labelText: 'Area',
                                          fillColor: CustomColor.primaryColor,
                                          prefixIcon: Icon(Icons.location_on_outlined, color: CustomColor.subTextColor),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                            borderSide: BorderSide(color: CustomColor.subTextColor, width: 0.5),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                            borderSide: BorderSide(color: CustomColor.subTextColor, width: 0.5),
                                          ),
                                          labelStyle: GoogleFonts.afacad(color: CustomColor.subTextColor, fontSize: 20),
                                        ),
                                        items: _areas.map((String area) {
                                          return DropdownMenuItem<String>(
                                            value: area,

                                            child: Text(area, style: TextStyle(color: CustomColor.textColor)),
                                          );
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
                                        style: GoogleFonts.afacad(color: CustomColor.textColor),
                                        decoration: InputDecoration(
                                          labelText: 'Email',
                                          fillColor: CustomColor.primaryColor,
                                          prefixIcon: Icon(Icons.email_outlined, color: CustomColor.subTextColor),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                            borderSide: BorderSide(color: CustomColor.subTextColor, width: 0.5),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                            borderSide: BorderSide(color: CustomColor.subTextColor, width: 0.5),
                                          ),
                                          labelStyle: GoogleFonts.afacad(color: CustomColor.subTextColor, fontSize: 20),
                                        ),
                                        validator: (value) => value == null || !value.contains('@') ? 'Please enter a valid email' : null,
                                      ),
                                      const SizedBox(height: 30),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: authProvider.isLoading ? null : () => _submit(context),
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            backgroundColor: CustomColor.textColor,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          ),
                                          child: authProvider.isLoading
                                              ? SizedBox(width: 20, height: 20, child: const CircularProgressIndicator(color: Colors.white))
                                              : Text(
                                                  _isSignUp ? 'Sign Up' : 'Sign In',
                                                  style: GoogleFonts.afacad(fontSize: 20, color: CustomColor.backgroundColor),
                                                ),
                                        ),
                                      ),

                                      TextButton(
                                        onPressed: _toggleMode,
                                        child: Text(
                                          _isSignUp ? 'Already have an account? Sign In' : 'Don\'t have an account? Sign Up',
                                          style: GoogleFonts.afacad(fontSize: 18, color: CustomColor.subTextColor),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(alignment: Alignment.topCenter, child: Image.asset('assets/img/logo.png', width: 70, height: 70)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
