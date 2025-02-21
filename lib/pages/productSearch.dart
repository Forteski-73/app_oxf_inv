import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_oxf_inv/operator/db_product.dart';
import '../models/product.dart';
import 'productDetail.dart';
import 'dart:io';

class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({super.key});

  @override
  _ProductSearchPage createState() => _ProductSearchPage();
}

class _ProductSearchPage extends State<ProductSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allProducts       = [];
  List<Map<String, dynamic>> _filteredProducts  = [];
  final String _apiUrl  = "http://wsintegrador.oxfordporcelanas.com.br:90/api/produtoEstrutura/";
  //final String _apiUrl  = "http://wsintegradordev.oxfordporcelanas.com.br:92/v1/produtos/GetAPIProdutos?familia=0002&marca=oxford&linha=FLAMINGO&decoracao=FLAMINGO&situacao=FORA&ordem=0&pagina=0&qtpagina=1";
  final String _token   = "4d24e4ff-85d62cca-d0cad84f-440e706e";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts(); 
  }

  /// Carregar todos os produtos
  Future<void> _loadProducts() async {
    try {
      final products = await DBItems.instance.getAllProducts1();
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // Caso haja erro, também para o carregamento
      });
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
            //DBItems.columnImageUrl:                     data['ImageUrl'],
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
            flex: 2, // Quanto de espaço por rótulo
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3, // Ocupa o restante do espaço
            child: Text(value),
          ),
        ],
      ),
    );
  }

  /*@override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {}); // Recarrega os dados ao voltar
  }*/
  
  // Função para exibir a popup de informações
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Informações"),
          content: const Text(
            "Oxford Porcelanas \n\n"
            "Versão: 1.0\n",
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Fechar", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
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
            Text('Aplicativo de Consulta de Estrutura de Produtos. ACEP',
              style: TextStyle(color: Colors.white,fontSize: 12,),
            ),
            SizedBox(height: 2),
            Text('Pesquisar Produtos',
              style: TextStyle(color: Colors.white, fontSize: 20, ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'Informações',
          ),
        ],
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

          _isLoading
          ? const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
            )
          : Expanded(
              child: ListView.builder(
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: product['path'] != null && product['path'].isNotEmpty
                                ? product['path'].startsWith('http')
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
                          /*
                          ***************USAR ESSE QUANDO O CAMINHO DA IMAGEM FOR HTTP OU HTTPS .... IMAGEM DE SERVER WEB ******************
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: product['path'] != null && product['path'].isNotEmpty
                                ? Image.network(
                                    product['path'],
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                                    },
                                  )
                                : const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                          ),
                          */
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 110,
                                      child: Text(
                                        'Cód. de Barras:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        product['ItemBarCode'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 110,
                                      child: Text(
                                        'Item:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        product['ItemID'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 110,
                                      child: Text(
                                        'Linha:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${product['ProdLinesId'] ?? ''} - ${product['ProdLinesDescriptionId'] ?? ''}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 110,
                                      child: Text(
                                        'Decoração:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        product['ProdDecorationDescriptionId'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () async {
                        final productObj = Product(
                          itemBarCode: product['ItemBarCode'],
                          itemId: product['ItemID'],
                          name: product['Name'],
                          prodLinesId: product['ProdLinesId'],
                          prodLinesDescriptionId: product['ProdLinesDescriptionId'],
                          prodDecorationDescriptionId: product['ProdDecorationDescriptionId'],
                          unitVolumeML: product['UnitVolumeML'],
                          itemNetWeight: product['ItemNetWeight'],
                          prodFamilyId: product['ProdFamilyId'],
                          prodFamilyDescription: product['ProdFamilyDescription'],
                          prodBrandDescriptionId: product['ProdBrandDescriptionId'],
                        );
                        
                        final updatedProduct = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsPage(product: productObj),
                          ),
                        );

                        if (updatedProduct != null) {
                          setState(() {
                            // Encontra o índice do produto na lista
                            int index = _filteredProducts.indexWhere((p) => p['ItemID'] == product['ItemID']);
                            if (index != -1) {
                              setState(() {
                                _filteredProducts = List.from(_filteredProducts); // Copia o objeto pra não ficar dando pau de ReadOnly
                                _filteredProducts[index] = Map.from(_filteredProducts[index])..['path'] = updatedProduct.path;
                              });
                            }
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        height: 64, // Altura
        child: IconButton(
          icon: const Icon(Icons.home, size: 30),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(), // Remove restrições de tamanho extra
          onPressed: () {
            Navigator.pushNamed(context, '/');
          },
        ),
      ),
    );
  }
}