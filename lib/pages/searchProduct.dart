import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_oxf_inv/operator/db_product.dart';
import 'dart:io';

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
  bool isLoading = false;
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
    
    //await DBItems.instance.deleteAllProducts();
    setState(() {
      isLoading = true; // Inicia o carregamento
    });

    try {
      final products = await DBItems.instance.getAllProducts();
      setState(() {
        _allProducts = products;
        _filteredProducts = products; // Exibe todos os produtos.
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showError('Erro ao carregar produtos do banco de dados: $e');
    }
  }

  void _filterProducts(String query) {
    if (query.length < 3) return; // ignora pesquisas com menos de 3 caracteres

    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // Expressão regular para buscar apenas do início
        final regex = RegExp('^${RegExp.escape(query)}', caseSensitive: false);

        // Expressão regular
        //final regex = RegExp(query, caseSensitive: false);

              // Obtendo os valores para comparação
        /*String itemBarCode = product['ItemBarCode'].toString();
        String itemID = product['ItemID'].toString();
        String name = product['Name'].toString();*/


        return regex.hasMatch(product['itemBarCode'].toString()) ||
              regex.hasMatch(product['itemID'].toString()) ||
              regex.hasMatch(product['name'].toString());
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
            DBItems.columnItemBarCode:                  data['itemBarCode'],
            DBItems.columnProdBrandId:                  data['prodBrandId'],
            DBItems.columnProdBrandDescriptionId:       data['prodBrandDescriptionId'],
            DBItems.columnProdLinesId:                  data['prodLinesId'],
            DBItems.columnProdLinesDescriptionId:       data['editProdLinesDescription'],
            DBItems.columnProdDecorationId:             data['prodDecorationId'],
            DBItems.columnProdDecorationDescriptionId:  data['editProdDecorationDescription'],
            DBItems.columnItemId:                       data['itemID'],
            DBItems.columnName:                         data['name'],
            DBItems.columnUnitVolumeML:                 data['unitVolumeML'],
            DBItems.columnItemNetWeight:                data['itemNetWeight'],
            DBItems.columnProdFamilyId:                 data['prodFamilyId'],
            DBItems.columnProdFamilyDescriptionId:        data['prodFamilyDescriptionId'],
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: const TextStyle(fontSize: 18))));
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
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            SizedBox(height: 2),
            Text('Pesquisar Produtos', style: TextStyle(color: Colors.white)), //Pesquisa rápida
          ],
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Column(
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
                      margin: const EdgeInsets.symmetric(vertical:6.0, horizontal: 10.0),
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
                        subtitle: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Transform.scale(
                              scale: 1.2, // Aumenta a imagem visualmente em 20%
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: product['path'] != null && product['path'].isNotEmpty
                                    ? product['path'].toString().startsWith('http')
                                        ? Image.network(
                                            product['path'],
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                                            },
                                          )
                                        : Image.file(
                                            File(product['path']),
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                                            },
                                          )
                                    : const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _alignRow('Código de Barras:',  product['itemBarCode'] ?? ''),
                                  _alignRow('Item:',              product['itemID'] ?? ''),
                                  _alignRow('Linha:',             '${product['prodLinesId'] ?? ''} - ${product['prodLinesDescriptionId'] ?? ''}'),
                                  _alignRow('Decoração:',         product['prodDecorationDescriptionId'] ?? ''),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Retorna o produto selecionado para a página requisitante
                          widget.onProductSelected(product['itemBarCode']);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.black,
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
