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

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isWhiteLogo = false; // controla a exibição da logo

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/oxf_background.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topLeft,
              ),
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isWhiteLogo = true;
                });
                Future.delayed(const Duration(milliseconds: 500), () {
                  setState(() {
                    _isWhiteLogo = false;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MenuPage(),
                    ),
                  );
                });
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Image.asset(
                  _isWhiteLogo
                      ? 'assets/images/oxf_logo_branco.png'
                      : 'assets/images/oxf_logo.png',
                  key: ValueKey<bool>(_isWhiteLogo),
                  width: 155,
                  height: 155,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
