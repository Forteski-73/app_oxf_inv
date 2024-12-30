import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isWhiteLogo = false; // Controla a exibição da logo

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fundo com a imagem
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/oxf_background.png'),
                fit: BoxFit.cover,
                alignment: Alignment.topLeft,
              ),
            ),
          ),
          // Centraliza a logo
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
                  // Navega para o menu ao clicar na logo
                  Navigator.pushNamed(context, '/menu');
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
