import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_oxf_inv/operator/db_product.dart';

class SearchProduct extends StatefulWidget {
  final Function(String) onProductSelected;

  const SearchProduct({Key? key, required this.onProductSelected}) : super(key: key);

  @override
  _SearchProductState createState() => _SearchProductState();
}

class _SearchProductState extends State<SearchProduct> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allProducts       = [];
  List<Map<String, dynamic>> _filteredProducts  = [];
  final String _apiUrl  = "http://wsintegrador.oxfordporcelanas.com.br:90/api/produtoEstrutura/";
  //final String _apiUrl  = "http://wsintegradordev.oxfordporcelanas.com.br:92/v1/produtos/GetAPIProdutos?familia=0002&marca=oxford&linha=FLAMINGO&decoracao=FLAMINGO&situacao=FORA&ordem=0&pagina=0&qtpagina=1";
  final String _token   = "4d24e4ff-85d62cca-d0cad84f-440e706e";

  @override
  void initState() {
    super.initState();
    _loadProducts(); 
  }

  /// Carregar todos os produtos
  Future<void> _loadProducts() async {
    try {
      final products = await DBItems.instance.getAllProducts();
      setState(() {
        _allProducts = products;
        _filteredProducts = products; // Exibe todos os produtos.
      });
    } catch (e) {
      _showError('Erro ao carregar produtos do banco de dados: $e');
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // Expressão regular
        final regex = RegExp(query, caseSensitive: false);

        return regex.hasMatch(product['ItemBarCode'].toString()) ||
              regex.hasMatch(product['ItemID'].toString()) ||
              regex.hasMatch(product['Name'].toString());
      }).toList();
    });
  }

  Future<void> _searchAndSaveProduct(String productId) async {
    if (productId.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('$_apiUrl$productId'),
          //Uri.parse(_apiUrl),

          headers: {
            'Authorization': 'Bearer $_token',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          
          final Map<String, dynamic> product = {
            DBItems.columnItemBarCode:                  data['ItemBarCode'],
            DBItems.columnProdBrandId:                  data['ProdBrandId'],
            DBItems.columnProdBrandDescriptionId:       data['ProdBrandDescriptionId'],
            DBItems.columnProdLinesId:                  data['ProdLinesId'],
            DBItems.columnProdLinesDescriptionId:       data['EditProdLinesDescription'],
            DBItems.columnProdDecorationId:             data['ProdDecorationId'],
            DBItems.columnProdDecorationDescriptionId:  data['EditProdDecorationDescription'],
            DBItems.columnItemId:                       data['ItemID'],
            DBItems.columnName:                         data['Name'],
            DBItems.columnUnitVolumeML:                 data['UnitVolumeML'],
            DBItems.columnItemNetWeight:                data['ItemNetWeight'],
            DBItems.columnProdFamilyId:                 data['ProdFamilyId'],
            DBItems.columnProdFamilyDescription:        data['ProdFamilyDescription'],
          };

          // Salvar o produto no banco
          await DBItems.instance.insertProduct(product);

          setState(() {
            _allProducts.add(product); // Adiciona o produto à lista local
            _filteredProducts = _allProducts;
          });

        } else {
          _showError('Erro ao buscar produto. Código: ${response.statusCode}');
        }
      } catch (e) {
        _showError('Erro ao buscar produto: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _searchProduct(String productId) {
    String searchText = _searchController.text.trim();
    if (searchText.isNotEmpty) {
      _filterProducts(searchText);
      if(_filteredProducts.isEmpty)
      {
        _searchAndSaveProduct(productId);
        _filterProducts(searchText);
      }
    }
  }

  Widget _alignRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        children: [
          Expanded(
            flex: 2, // Quanto de espaço por rótulo
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3, // Oupa o restante do espaço
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesquisar Produtos', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _filterProducts(value);
              },
              decoration: InputDecoration(
                labelText: 'Pesquisar',
                border: const OutlineInputBorder(),
                prefixIcon: InkWell(
                  onTap: () {
                    _searchProduct(_searchController.text);
                  },
                  child: const Icon(Icons.search),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,  // Sombra para o card
                  child: ListTile(
                    title: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        product['Name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _alignRow('Código de Barras:',  product['ItemBarCode']),
                        _alignRow('Item:',              product['ItemID']),
                        _alignRow('Linha:',             '${product['ProdLinesId'] ?? ''} - ${product['ProdLinesDescriptionId'] ?? ''}'),
                        _alignRow('Decoração:',         product['ProdDecorationDescriptionId'] ?? ''),
                      ],
                    ),
                    onTap: () {
                      // Retorna o produto selecionado para a página chamadora
                      widget.onProductSelected(product['ItemBarCode']);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Oxford Porcelanas", style: TextStyle(fontSize: 14)),
            Text("Versão: 1.0", style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
