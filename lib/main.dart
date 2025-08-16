import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:worki/screens/registration_screen.dart';
import 'package:worki/screens/registration_successful_screen.dart';
import 'package:worki/screens/welcome_back_screen.dart';
import 'package:worki/main_screen.dart';
import 'package:worki/models/auth_state.dart';
import 'package:worki/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthenticationWrapper(),
      routes: {
        '/main': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as int?;
          return MainScreen(initialIndex: args ?? 0);
        },
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData) {
          // Si el flag está activo, mostrar pantalla de registro exitoso
          if (AuthStateManager.showRegistrationSuccess) {
            return const RegistrationSuccessfulScreen();
          }
          // Si es un usuario que regresa (ya estaba registrado), mostrar pantalla de bienvenida
          if (AuthStateManager.showWelcomeBack) {
            return const WelcomeBackScreen();
          }
          // Si no, ir a la pantalla principal (índice 0 - Home)
          return const MainScreen(initialIndex: 0);
        } else {
          return const RegistrationScreen();
        }
      },
    );
  }
}