import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_product.dart';
import 'package:dio/dio.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(); // Repetir a animação de rotação
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> integrateData(BuildContext context) async {
  setState(() {
    _isSyncing = true;
  });

  try {
    const String baseUrl = 'http://wsintegradordev.oxfordporcelanas.com.br:92/v1/produtos/GetAPIProdutos';
    const String familia = '0002';
    const String marca = 'oxford porcelanas';
    const String linha = 'FLAMINGO';
    const String decoracao = 'FLAMINGO DIANA';
    const String situacao = 'FORA DE LINHA';
    const int ordem = 0;
    const int pagina = 0;
    const int qtdPagina = 20;

    const String url = '$baseUrl?familia=$familia&marca=$marca&linha=$linha&decoracao=$decoracao'
                        '&situacao=$situacao&ordem=$ordem&pagina=$pagina&qtpagina=$qtdPagina';
    var headers = {'token': '4d24e4ff-85d62cca-d0cad84f-440e706e'};
    
    var dio = Dio();
    var response = await dio.request(
      url,
      options: Options(
        method: 'GET',
        headers: headers,
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final resultados = data['resultados'] as List<dynamic>;

      for (var item in resultados) {
        final productData = {
          DBItems.columnProdBrandId:                  item['MSBProdBrandId'],
          DBItems.columnProdBrandDescriptionId:       item['MSBProdBrandDescriptionId'],
          DBItems.columnProdLinesId:                  item['MSBProdLinesId'],
          DBItems.columnProdLinesDescriptionId:       item['MSBProdLinesDescriptionId'],
          DBItems.columnProdDecorationId:             item['MSBProdDecorationCodeId'],
          DBItems.columnProdDecorationDescriptionId:  item['MSBProdDecorationDescriptionId'],
          DBItems.columnItemId:                       item['ItemId'],
          DBItems.columnName:                         item['NameAlias'],
          DBItems.columnUnitVolumeML:                 item['UnitVolumeML'] ?? 0,
          DBItems.columnProdFamilyId:                 item['MSBProdFamilyId'],
          DBItems.columnProdFamilyDescription:        item['MSBProdFamilyDescriptionId'],
          DBItems.columnItemBarCode:                  item['ItemBarCode'],
          DBItems.columnItemNetWeight:                item['NetWeight'],
        };
        
        await DBItems.instance.insertProduct(productData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados sincronizados com sucesso!', style: TextStyle(fontSize: 18))),
      );
    } else {
      throw Exception('Falha ao sincronizar os dados. Código: ${response.statusCode} - ${response.statusMessage}');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro: $e', style: const TextStyle(fontSize: 18))),
    );
  } finally {
    setState(() {
      _isSyncing = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronização', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _isSyncing ? null : () => integrateData(context),
              icon: _isSyncing
                  ? AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: -_controller.value * 2 * 3.1416, // Rotação em radianos
                          child: const Icon(Icons.sync, color: Colors.white, size: 35),
                        );
                      },
                    )
                  : const Icon(Icons.sync, color: Colors.white, size: 35),
              label: const Text('Sincronizar', style: TextStyle(color: Colors.white, fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
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

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: const SyncPage(),
  ));
}
