import 'package:flutter/material.dart';
import '../pages/InventoryHistory.dart';
import 'inventory.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(), 
    home: const InventoryManagementPage(),
  ));
}

class InventoryManagementPage extends StatelessWidget {
  const InventoryManagementPage({super.key});

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Inventário', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/oxf_background.png',
              fit: BoxFit.cover, // tela toda
              alignment: Alignment.topLeft,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // Logo
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/oxf_logo.png',
                      height: 100,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              // Título
              const Text(
                'Selecione a ação desejada',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              // Botões
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Chamar criar Inventário
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => InventoryPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 25),
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 10), // Espaço de 5px antes do texto
                            child: Text('Criar Inventário', style: TextStyle(fontSize: 16)),
                          ),
                          Icon(Icons.navigate_next_sharp, size: 30,),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Chamar Histórico Inventários
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => InventoryHistory()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 25),
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(left: 10), // Espaço de 5px antes do texto
                            child: Text('Histórico de Inventários', style: TextStyle(fontSize: 16)),
                          ),
                          Icon(Icons.navigate_next_sharp, size: 30,),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      // Rodapé
      bottomNavigationBar: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Oxford Porcelanas",
              style: TextStyle(fontSize: 14),
            ),
            Text(
              "Versão: 1.0",
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

