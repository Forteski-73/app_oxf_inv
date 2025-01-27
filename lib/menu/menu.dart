import 'package:flutter/material.dart';
/*import '../pages/InventoryHistory.dart'; // Adicionando a importação das páginas
import '../pages/ImportProduct.dart';
import '../pages/InventorySearch.dart';
import '../pages/Settings.dart';
import '../pages/sync.dart';
import '../pages/management.dart';*/


class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aplicativo de Consulta de Estrutura de Produtos. ACEP',
              style: TextStyle(color: Colors.white,fontSize: 12,),
            ),
            SizedBox(height: 2),
            Text('Menu',
              style: TextStyle(color: Colors.white, fontSize: 20, ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              _menuItem(
                context,
                icon: Icons.inventory_2_outlined,
                label: "Gerenciamento de Inventário",
                routeName: '/management', // Rota para Gerenciamento de Inventário
              ),
              _menuItem(
                context,
                icon: Icons.upload_outlined,
                label: "Exportação de Dados",
                routeName: '/inventoryExport', // Rota para Exportação de Dados
              ),
              _menuItem(
                context,
                icon: Icons.download_outlined,
                label: "Importação de Produtos",
                routeName: '/importProduct', // Rota para Importação de Produtos
              ),
              _menuItem(
                context,
                icon: Icons.sync_outlined,
                label: "Sincronização",
                routeName: '/sync', // Rota para Sincronização
              ),
              _menuItem(
                context,
                icon: Icons.search,
                label: "Pesquisar Produtos",
                routeName: '/inventorySearch', // Rota para Pesquisar Produtos
              ),
              _menuItem(
                context,
                icon: Icons.settings_outlined,
                label: "Configurações",
                routeName: '/settings', // Rota para Configurações
              ),
            ],
          ),

          // Rodapé
          Container(
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
        ],
      ),
    );
  }

  Widget _menuItem(BuildContext context, {
    required IconData icon,
    required String label,
    required String routeName, // Alterado para receber a rota como string
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(label, style: const TextStyle(color: Colors.black)),
      onTap: () {
        // Usando Navigator.pushNamed para navegar para as rotas definidas
        Navigator.pushNamed(context, routeName); 
      },
    );
  }
}
