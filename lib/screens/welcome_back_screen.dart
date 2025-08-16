import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:worki/main_screen.dart';
import 'package:worki/models/auth_state.dart';
import 'package:worki/constants/app_constants.dart';

class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({Key? key}) : super(key: key);

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen> {
  String _userName = '';
  String _userLastName = '';
  bool _isLoading = true;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          setState(() {
            _userName = data?['name'] ?? '';
            _userLastName = data?['lastName'] ?? '';
            _isLoading = false;
          });
        } else {
          setState(() {
            _userName = '';
            _userLastName = '';
            _isLoading = false;
          });
        }
      } catch (e) {
        String errorMessage = AppConstants.unknownError;
        
        if (e.toString().contains('permission-denied')) {
          errorMessage = AppConstants.permissionDenied;
        } else if (e.toString().contains('unavailable')) {
          errorMessage = AppConstants.firestoreUnavailable;
        }
        
        setState(() {
          _userName = '';
          _userLastName = '';
          _isLoading = false;
        });
        
        // Mostrar mensaje de error al usuario
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ $errorMessage'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } else {
      setState(() {
        _userName = '';
        _userLastName = '';
        _isLoading = false;
      });
    }
  }

  String get _displayName {
    if (_userName.isNotEmpty && _userLastName.isNotEmpty) {
      return '$_userName $_userLastName';
    } else if (_userName.isNotEmpty) {
      return _userName;
    } else {
      return AppConstants.defaultUserName;
    }
  }

  void _goToMainScreen() {
    AuthStateManager.clearState();
    Navigator.of(context).pushReplacementNamed('/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.waving_hand,
                size: 80,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    Text(
                      'Hola bienvenido $_displayName',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '¡Nos alegra verte de vuelta en ${AppConstants.appName}!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 40),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.work,
                        size: 50,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        AppConstants.newJobsAvailable,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        AppConstants.exploreOpportunities,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _goToMainScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '¡Empezar a trabajar!',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Botón para ir directamente a la lista de trabajos
                      ElevatedButton(
                        onPressed: () {
                          AuthStateManager.clearState();
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const MainScreen(initialIndex: 1),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          AppConstants.viewJobsList,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
