import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:provider/provider.dart';  // <-- importe o provider

import 'pages/importProduct.dart';
import 'pages/management.dart';
import 'pages/productSearch.dart';
import 'pages/SearchProduct.dart';
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
import 'models/product_all.dart';
import 'package:flutter/widgets.dart';
import 'pages/teste.dart';
import 'pages/texte2.dart';
import 'package:app_oxf_inv/utils/network.dart';
import 'package:app_oxf_inv/controller/product_search.dart';
import 'package:app_oxf_inv/services/remote/oxfordonlineAPI.dart';
import 'package:app_oxf_inv/services/local/oxfordLocalLite.dart';
import '../utils/globals.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>(); // <-- Global

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await checkInternetConnection();

  await initGlobals();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProductSearchController(
            api: OxfordOnlineAPI(),
            db: OxfordLocalLite(),
          ),
        ),
        // Caso queira adicionar outros providers, coloque aqui
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      navigatorObservers: [routeObserver], 
      routes: {
        '/':                (context) => const HomePage(),
        '/menu':            (context) => const MenuPage(),
        '/management':      (context) => const InventoryManagementPage(),
        '/inventoryExport': (context) => const InventoryHistory(),
        '/importProduct':   (context) => ImportProduct(),
        '/sync':            (context) => const SyncPage(),
        '/productSearch':   (context) => const ProductSearchPage(),
        '/searchProduct':   (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final Function(String) onProductSelected = 
              (args is Function(String)) ? args : (String _) {};
          return SearchProduct(onProductSelected: onProductSelected);
        },
        '/ProductImages':   (context) {
          ProductAll product = ProductAll();
          return ProductImagesPage(product: product);
        },
        '/productDetails':  (context) {
          ProductAll product = ProductAll();
          return ProductDetailsPage(product: product);
        },
        '/settingsProfile':         (context) => const SettingsProfilePage(),
        '/inventory':               (context) => const InventoryPage(),
        '/inventoryHistory':        (context) => const InventoryHistory(),
        '/inventoryHistoryDetail':  (context) {
          final int inventoryId = ModalRoute.of(context)?.settings.arguments as int;
          return InventoryHistoryDetail(inventoryId: inventoryId);
        },
        '/inventoryRecord': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return InventoryRecordsPage(
            selectedProfile: args['selectedProfile'],
            inventoryId: args['inventoryId'],
          );
        },
        //'/teste': (context) => const PaginaComAcoesFlutuantes(),
        //'/texte2': (context) => ExpandableNestedCards(),
      },
    );
  }
}


/*import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'pages/importProduct.dart';
import 'pages/management.dart';
import 'pages/productSearch.dart';
import 'pages/SearchProduct.dart';
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
import 'models/product_all.dart';
import 'package:flutter/widgets.dart';
import 'pages/teste.dart';
import 'pages/texte2.dart';
import 'package:app_oxf_inv/utils/network.dart';


final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>(); // <-- Global


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await checkInternetConnection();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      navigatorObservers: [routeObserver], 
      routes: {
        '/':                (context) => const HomePage(),                // Página inicial (HomePage)
        '/menu':            (context) => const MenuPage(),                // Página inicial (Menu)
        '/management':      (context) => const InventoryManagementPage(), // Rota para Gerenciamento de Inventário
        '/inventoryExport': (context) => const InventoryHistory(),        // Rota para Exportação de Dados
        '/importProduct':   (context) => ImportProduct(),                 // Rota para Importação de Produtos
        '/sync':            (context) => const SyncPage(),                // Rota para Sincronização
        '/productSearch':   (context) => const ProductSearchPage(),       // Rota para Pesquisar Produtos
        '/searchProduct':   (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final Function(String) onProductSelected = 
              (args is Function(String)) ? args : (String _) {}; // Função vazia por padrão
          
          return SearchProduct(onProductSelected: onProductSelected);
        },
        '/ProductImages':   (context) {
          ProductAll product = ProductAll();
          return ProductImagesPage(product: product);  // Passe o produto para o construtor
        },
        '/productDetails':  (context) {                // Rota para Consultar Detalhes do Inventário
          ProductAll product = ProductAll();
          return ProductDetailsPage(product: product); // Passe o produto para o construtor
        },
        '/settingsProfile':         (context) => const SettingsProfilePage(), // Rota para Configurações
        '/inventory':               (context) => const InventoryPage(),       // Rota para Consultar Inventários
        '/inventoryHistory':        (context) => const InventoryHistory(),    // Rota para Consultar Histórico
        '/inventoryHistoryDetail':  (context) {                               // Rota para Consultar Detalhes do Inventário
          final int inventoryId = ModalRoute.of(context)?.settings.arguments as int;  // Recuperar o argumento passado na navegação
          return InventoryHistoryDetail(inventoryId: inventoryId);            // Passar o argumento para o construtor da página
        },
        '/inventoryRecord': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
          return InventoryRecordsPage(
            selectedProfile: args['selectedProfile'],
            inventoryId: args['inventoryId'],
          );
        },
        //'/teste': (context) => const PaginaComAcoesFlutuantes(),
        //'/texte2': (context) => ExpandableNestedCards(),
      },
    );
  }
}*/