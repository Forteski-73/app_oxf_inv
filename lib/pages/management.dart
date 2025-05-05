import 'package:flutter/material.dart';
import 'package:app_oxf_inv/widgets/footer.dart';

void main() {
  runApp(const InventoryManagementPage());
}

class InventoryManagementPage extends StatelessWidget {
  const InventoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplicativo de Consulta de Estrutura de Produtos. ACEP',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            SizedBox(height: 2),
            Text(
              'Gerenciamento de Inventário',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Volta para a rota inicial (menu)
            Navigator.popUntil(context, ModalRoute.withName('/menu')); // Rota do menu principal
          },
        ),
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
                        Navigator.pushNamed(context, '/inventory');
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
                            child: Text('INVENTÁRIO', style: TextStyle(fontSize: 16)),
                          ),
                          Icon(Icons.navigate_next_sharp, size: 30, color: Colors.black,),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {

                        Navigator.pushNamed(context, '/inventoryHistory');
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
                            child: Text('HISTÓRICO DE INVENTÁRIOS', style: TextStyle(fontSize: 16)),
                          ),
                          Icon(Icons.navigate_next_sharp, size: 30, color: Colors.black,),
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
      bottomNavigationBar: const Footer(),
    );
  }
}