import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:app_oxf_inv/menu/menu.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar o databaseFactory para sqflite_common_ffi
  if (kIsWeb || !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS)) {
    // Inicialize para desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(MaterialApp(
    theme: ThemeData.dark(), // Tema escuro global
    home: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagem de fundo
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/oxf_background.png'), // Imagem de fundo
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {
                // Navega para o menu
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MenuPage(),
                  ),
                );
              },
              child: Image.asset(
                'assets/images/oxf_logo.png', // Logo
                width: 150,
                height: 150,
              ),
            ),
          ),
        ],
      ),
    );
  }
}