import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:worki/models/auth_state.dart';
import 'package:worki/constants/app_constants.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLoginMode = false;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _submitAuthForm() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isLoginMode) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // Activar el flag para mostrar pantalla de bienvenida para usuarios que regresan
        AuthStateManager.setWelcomeBack();
      } else {
        if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
          setState(() {
            _errorMessage = AppConstants.passwordsDontMatch;
            _isLoading = false;
          });
          return;
        }
        
        // Activar el flag para mostrar pantalla de registro exitoso
        AuthStateManager.setRegistrationSuccess();
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        User? newUser = userCredential.user;
        if (newUser != null) {
          try {
            await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set({
              'name': _nameController.text.trim(),
              'lastName': _lastNameController.text.trim(),
              'email': _emailController.text.trim(),
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (firestoreError) {
            // Continuar con el flujo aunque falle Firestore
            // El usuario puede completar su perfil más tarde
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? AppConstants.unknownError;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      User? newUser = userCredential.user;
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(newUser!.uid).get();

      if (!userDoc.exists) {
        String name = googleUser.displayName?.split(' ')[0] ?? '';
        String lastName = googleUser.displayName?.split(' ').sublist(1).join(' ') ?? '';

        // Activar el flag para mostrar pantalla de registro exitoso
        AuthStateManager.setRegistrationSuccess();

        await FirebaseFirestore.instance.collection('users').doc(newUser.uid).set({
          'name': name,
          'lastName': lastName,
          'email': googleUser.email,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // No necesitamos navegar manualmente, el AuthenticationWrapper se encargará
      } else {
        // Si el usuario ya existe, activar el flag para mostrar pantalla de bienvenida
        AuthStateManager.setWelcomeBack();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? AppConstants.googleAuthError;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isLoginMode ? AppConstants.signIn : 'Registro'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isLoginMode ? AppConstants.welcomeBackTitle : AppConstants.createAccount,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: AppConstants.email,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              if (!_isLoginMode) ...[
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppConstants.name,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: AppConstants.lastName,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: AppConstants.password,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              if (!_isLoginMode) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: AppConstants.confirmPassword,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
              ],
              const SizedBox(height: 24),
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 16),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _submitAuthForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _isLoginMode ? AppConstants.signIn : AppConstants.register,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              const SizedBox(height: 20),
              const Text('O'),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _signInWithGoogle,
                icon: const Icon(Icons.g_mobiledata),
                label: const Text(AppConstants.continueWithGoogle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLoginMode = !_isLoginMode;
                    _errorMessage = '';
                  });
                },
                child: Text(
                  _isLoginMode
                      ? AppConstants.noAccount
                      : AppConstants.hasAccount,
                  style: TextStyle(color: Colors.blue.shade600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}