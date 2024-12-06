import 'package:flutter/material.dart';
import 'menu/menu.dart'; // Importe a página de dashboard

void main() {
  runApp(MaterialApp(
    theme: ThemeData.dark(), // Tema escuro global
    home: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

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
          // Logo centralizada com ação de clique
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