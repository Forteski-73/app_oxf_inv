import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'pages/importProduct.dart';
import 'pages/management.dart';
import 'pages/productSearch.dart';
import 'pages/productDetail.dart';
import 'pages/productImages.dart';
//import 'pages/settings.dart';
import 'pages/SettingsProfile.dart';
import 'pages/InventoryHistory.dart';
import 'pages/InventRecordsHistory.dart';
import 'pages/sync.dart';
import 'menu/menu.dart'; 
import 'pages/home.dart';
import 'pages/inventory.dart';
import 'pages/inventRecords.dart';
import 'models/product.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar o databaseFactory para sqflite_common_ffi
  if (kIsWeb || !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS)) {
    // Inicialize para desktop
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',  // Página inicial (HomePage)
      routes: {
        '/': (context) => const HomePage(),                           // Página inicial (HomePage)
        '/menu': (context) => const MenuPage(),                       // Página inicial (Menu)
        '/management': (context) => const InventoryManagementPage(),  // Rota para Gerenciamento de Inventário
        '/inventoryExport': (context) => const InventoryHistory(),    // Rota para Exportação de Dados
        '/importProduct': (context) => ImportProduct(),               // Rota para Importação de Produtos
        '/sync': (context) => const SyncPage(),                       // Rota para Sincronização
        '/productSearch': (context) => const ProductSearchPage(),     // Rota para Pesquisar Produtos
        //'/ProductDetails': (context) => const ProductDetailsPage(),   // Rota para Pesquisar Produtos
        '/ProductImages': (context) {
          //final Product product = ModalRoute.of(context)?.settings.arguments as Product;
          Product product = Product();
          return ProductImagesPage(product: product); // Passe o produto para o construtor
        },
        '/productDetails': (context) {                        // Rota para Consultar Detalhes do Inventário
          Product product = Product();
          return ProductDetailsPage(product: product); // Passe o produto para o construtor
        },
        //'/settings': (context) => const SettingsPage(),             // Rota para Configurações
        '/settingsProfile': (context) => const SettingsProfilePage(), // Rota para Configurações
        '/inventory': (context) => const InventoryPage(),             // Rota para Consultar Inventários
        '/inventoryHistory': (context) => const InventoryHistory(),   // Rota para Consultar Histórico
        '/inventoryHistoryDetail': (context) {                        // Rota para Consultar Detalhes do Inventário
          final int inventoryId = ModalRoute.of(context)?.settings.arguments as int;  // Recuperar o argumento passado na navegação
          return InventoryHistoryDetail(inventoryId: inventoryId);  // Passar o argumento para o construtor da página
        },
        '/inventoryRecord': (context) => InventoryRecordsPage(),
      },
    );
  }
}