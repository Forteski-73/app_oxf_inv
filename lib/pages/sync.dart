import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_oxf_inv/operator/db_product.dart';

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
    
    await Future.delayed(const Duration(seconds: 3));

    // Parâmetros da API
    String familia = '0002';
    String marca = 'oxford porcelanas';
    String linha = 'FLAMINGO';
    String decoracao = 'FLAMINGO DIANA';
    String situacao = 'FORA DE LINHA';
    String ordem = '0';
    String pagina = '0';
    String qtpagina = '10';
    String token = '4d24e4ff-85d62cca-d0cad84f-440e706e';  // Token
    String baseUrl = 'http://wsintegradordev.oxfordporcelanas.com.br:92/v1/produtos/GetAPIProdutos';

    // Passando o token como um parâmetro de URL
    final String url = '$baseUrl?familia=$familia&marca=$marca&linha=$linha&decoracao=$decoracao&situacao=$situacao&ordem=$ordem&pagina=$pagina&qtpagina=$qtpagina';

    try {

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Auth-Token': token,
        },
      );

      print('_......Status Code: ${response.statusCode}');
      print('_......Response Body: ${response.body}');
      print('_......Headers: ${response.headers}');
      print('_......url: ${url}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        for (var product in data) {
          Map<String, dynamic> productData = {
            DBItems.columnItemId: product['ItemId'],
            DBItems.columnItemBarCode: product['ItemBarCode'],
            DBItems.columnMSBProdBrandDescriptionId: product['MSBProdBrandDescriptionId'],
            DBItems.columnMSBProdBrandId: product['MSBProdBrandId'],
            DBItems.columnMSBProdDecorationCodeId: product['MSBProdDecorationCodeId'],
            DBItems.columnMSBProdDecorationDescriptionId: product['MSBProdDecorationDescriptionId'],
            DBItems.columnMSBProdFamilyDescriptionId: product['MSBProdFamilyDescriptionId'],
            DBItems.columnMSBProdFamilyId: product['MSBProdFamilyId'],
            DBItems.columnMSBProdLinesDescriptionId: product['MSBProdLinesDescriptionId'],
            DBItems.columnMSBProdLinesId: product['MSBProdLinesId'],
            DBItems.columnMSBProdQualityDescriptionId: product['MSBProdQualityDescriptionId'],
            DBItems.columnMSBProdQualityId: product['MSBProdQualityId'],
            DBItems.columnMSBProdSituationDescriptionId: product['MSBProdSituationDescriptionId'],
            DBItems.columnMSBProdSituationId: product['MSBProdSituationId'],
            DBItems.columnGrossHeight: product['GrossHeight'],
            DBItems.columnGrossWidth: product['GrossWidth'],
            DBItems.columnGrossDepth: product['GrossDepth'],
            DBItems.columnNameAlias: product['NameAlias'],
            DBItems.columnNetWeight: product['NetWeight'],
          };

          await DBItems.instance.insertProduct(productData);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados sincronizados com sucesso!')),
        );
      } else {
        throw Exception('Falha ao sincronizar os dados.');
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
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
