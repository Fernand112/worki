import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:worki/main_screen.dart';
import 'package:worki/constants/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _userLastName = '';
  bool _isLoading = true;
  final _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    // Escuchar cambios en la autenticación
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _fetchUserData();
      } else {
        setState(() {
          _userName = '';
          _userLastName = '';
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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
        
        if (e.toString().contains('unavailable')) {
          errorMessage = AppConstants.firestoreUnavailable;
        } else if (e.toString().contains('permission-denied')) {
          errorMessage = AppConstants.permissionDenied;
        } else if (e.toString().contains('not-found')) {
          errorMessage = AppConstants.databaseNotFound;
        }
        
        if (mounted) {
          setState(() {
            _userName = '';
            _userLastName = '';
            _isLoading = false;
          });
        }
        
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

  Future<void> _refreshUserData() async {
    await _fetchUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text(AppConstants.appTitle),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUserData,
            tooltip: AppConstants.refresh,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    Text(
                      '${AppConstants.welcomeBack}, $_displayName!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
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
                        onPressed: () {
                          // Navegar a la pestaña de trabajos (índice 1)
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const MainScreen(initialIndex: 1),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          AppConstants.viewJobsList,
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 15),
                      // Botón temporal para completar perfil si no hay datos
                      if (_userName.isEmpty && _userLastName.isEmpty)
                        ElevatedButton(
                          onPressed: () async {
                            // Mostrar diálogo para ingresar nombre y apellido
                            final TextEditingController nameController = TextEditingController();
                            final TextEditingController lastNameController = TextEditingController();
                            
                            final result = await showDialog<Map<String, String>>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text(AppConstants.completeYourProfile),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: nameController,
                                        decoration: const InputDecoration(
                                          labelText: AppConstants.name,
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextField(
                                        controller: lastNameController,
                                        decoration: const InputDecoration(
                                          labelText: AppConstants.lastName,
                                          border: OutlineInputBorder(),
                                        ),
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text(AppConstants.cancel),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        if (nameController.text.isNotEmpty && 
                                            lastNameController.text.isNotEmpty) {
                                          Navigator.of(context).pop({
                                            'name': nameController.text.trim(),
                                            'lastName': lastNameController.text.trim(),
                                          });
                                        }
                                      },
                                      child: const Text(AppConstants.save),
                                    ),
                                  ],
                                );
                              },
                            );
                            
                            if (result != null) {
                              try {
                                final user = _auth.currentUser;
                                if (user != null) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .set({
                                    'name': result['name']!,
                                    'lastName': result['lastName']!,
                                    'email': user.email,
                                    'createdAt': FieldValue.serverTimestamp(),
                                  });
                                  // Perfil completado exitosamente
                                  // Recargar los datos
                                  _fetchUserData();
                                }
                              } catch (e) {
                                // Error completando perfil - se puede manejar silenciosamente
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            AppConstants.completeProfile,
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