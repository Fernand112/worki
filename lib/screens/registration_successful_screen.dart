import 'package:flutter/material.dart';
import 'package:worki/models/auth_state.dart';
import 'package:worki/main_screen.dart';
import 'package:worki/constants/app_constants.dart';

class RegistrationSuccessfulScreen extends StatelessWidget {
  const RegistrationSuccessfulScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                '¡Registro Exitoso!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tu cuenta ha sido creada exitosamente. ¡Bienvenido a ${AppConstants.appName}!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  // Desactivar el flag para que no se muestre esta pantalla de nuevo
                  AuthStateManager.clearState();
                  // Navegar a la pantalla principal con la pestaña de trabajos seleccionada
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(initialIndex: 1),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continuar a la Aplicación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}