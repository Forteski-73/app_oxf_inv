import 'package:flutter/material.dart';
import '../pages/export.dart';
import '../pages/import.dart';
import '../pages/management.dart';
import '../pages/settings.dart';
import '../pages/sync.dart';

void main() {
  runApp(MaterialApp(
    theme: ThemeData.dark(),
    home: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MenuPage(),
    );
  }
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) { 
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu', style: TextStyle(color: Colors.white)),
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
                page: const InventoryManagementPage(), // Página de Gerenciamento de Inventário
              ),
              _menuItem(
                context,
                icon: Icons.upload_outlined,
                label: "Exportação de Dados",
                page: const ExportPage(), // Página de Exportação de Dados
              ),
              _menuItem(
                context,
                icon: Icons.download_outlined,
                label: "Importação de Produtos",
                page: const ImportPage(), // Página de Importação de Produtos
              ),
              _menuItem(
                context,
                icon: Icons.sync_outlined,
                label: "Sincronização",
                page: const SyncPage(), // Página de Sincronização
              ),
              _menuItem(
                context,
                icon: Icons.settings_outlined,
                label: "Configurações",
                page: const SettingsPage(), // Página de Configurações
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
    required Widget page,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(label, style: const TextStyle(color: Colors.black)),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => page),
        );
      },
    );
  }

}