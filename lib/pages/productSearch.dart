import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_oxf_inv/widgets/customSnackBar.dart';
import 'package:app_oxf_inv/services/local/oxfordLocalLite.dart';
import 'package:app_oxf_inv/services/remote/oxfordonlineAPI.dart';
import 'package:app_oxf_inv/operator/db_product.dart';
import '../models/product.dart';
import '../models/product_all.dart';
import 'productDetail.dart';
import '../utils/globals.dart' as globals;

// RouteObserver para detectar retorno da tela de detalhes
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({Key? key}) : super(key: key);

  @override
  State<ProductSearchPage> createState() => _ProductSearchPageState();
}

class _ProductSearchPageState extends State<ProductSearchPage>
    with RouteAware, SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<ProductAll> _allProducts = [];
  List<ProductAll> _filteredProducts = [];

  final String _apiUrl = "http://wsintegrador.oxfordporcelanas.com.br:90/api/produtoEstrutura/";
  final String _token = "4d24e4ff-85d62cca-d0cad84f-440e706e";

  bool _isLoading = true;
  late AnimationController _controller;

  String _selectedSearchField = 'Name';

  final Map<String, String> _searchFields = {
    'itemID'      : 'Código do Produto',
    'itemBarCode' : 'Código de Barras do Produto',
    'name'        : 'Nome do Produto',
  };

  @override
  void initState() {
    super.initState();
    //_loadProducts();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _loadProducts();
  }

  @override
  void didPush() {
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      List<ProductAll> products = [];

      if (globals.isOnline) {
        products = await OxfordOnlineAPI.getProducts();

        await OxfordLocalLite().saveAllProductsLocally(products, context);

        products = await DBItems.instance.getAllProducts1();
        
      } else {
        products = await DBItems.instance.getAllProducts1();
      }
      
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError('Erro ao carregar produtos do banco de dados: $e');
    }
  }

  void _filterProducts(String query) {
    setState(() {
      final regex = RegExp(query, caseSensitive: false);

      _filteredProducts = _allProducts.where((product) {
        String fieldValue;
        switch (_selectedSearchField) {
          case 'itemID':
            fieldValue = product.itemId?.toString() ?? '';
            break;
          case 'itemBarCode':
            fieldValue = product.itemBarCode ?? '';
            break;
          case 'name':
          default:
            fieldValue = product.name ?? '';
            break;
        }
        return regex.hasMatch(fieldValue);
      }).toList();
    });
  }

  Future<void> _searchAndSaveProduct(String productId) async {
    if (productId.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('$_apiUrl$productId'),
          headers: {
            'Authorization': 'Bearer $_token',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);

          final newProduct = ProductAll.fromMap(data);

          await DBItems.instance.insertProduct(newProduct.toMap());

          setState(() {
            _allProducts.add(newProduct);
            _filteredProducts = List.from(_allProducts);
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
    CustomSnackBar.show(context, message: message,
      duration: const Duration(seconds: 4),type: SnackBarType.error,
    );
  }

  void _searchProduct(String productId) {
    String searchText = _searchController.text.trim();
    if (searchText.isNotEmpty) {
      _filterProducts(searchText);
      if (_filteredProducts.isEmpty) {
        _searchAndSaveProduct(productId);
        _filterProducts(searchText);
      }
    }
  }

  Widget _buildInfoRow(String label, String? value) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Text(value ?? '', overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Informações'),
          content: const Text(
            'Digite o código do produto ou parte do nome para pesquisar.\n'
            'Use o filtro para mudar o campo de busca.\n'
            'Caso o produto não esteja no banco local, será consultado no servidor online.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _showFullWidthFilterMenu() async {
    final selected = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: "FilterMenu",
      transitionDuration: const Duration(milliseconds: 500), // Mais devagar
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink(); // não precisa do child aqui
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic, // Animação suave
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1), // Começa fora do topo
            end: Offset.zero,
          ).animate(curved),
          child: Material(
            color: Colors.transparent,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: kToolbarHeight + 32), // Mais margem no topo
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: Colors.white,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _searchFields.entries.map((entry) {
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pop(entry.key);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.tune, color: Colors.cyan.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(entry.value),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selected != null && selected != _selectedSearchField) {
      setState(() {
        _selectedSearchField = selected;
        _searchController.clear();
        _filteredProducts = _allProducts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('',
                style: TextStyle(color: Colors.white, fontSize: 12)),
            SizedBox(height: 2),
            Text('Pesquisar Produtos',
                style: TextStyle(color: Colors.white, fontSize: 20)),
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
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => _filterProducts(value),
                  decoration: InputDecoration(
                    labelText: _searchFields[_selectedSearchField],
                    border: const OutlineInputBorder(),
                    prefixIcon: InkWell(
                      onTap: _showFullWidthFilterMenu,
                      child: const Icon(Icons.filter_alt_outlined),
                    ),
                    suffixIcon: InkWell(
                      onTap: () => _searchProduct(_searchController.text),
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
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 4,
                      child: ListTile(
                        contentPadding: const EdgeInsets.only(
                            left: 8.0, right: 8.0, bottom: 8.0),
                        title: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            product.name ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        subtitle: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: (product.path != null &&
                                      product.path!.isNotEmpty)
                                  ? (product.path!.startsWith('http')
                                      ? Image.network(
                                          product.path!,
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image,
                                                  size: 100,
                                                  color: Colors.grey),
                                        )
                                      : Image.file(
                                          File(product.path!),
                                          height: 100,
                                          width: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.broken_image,
                                                  size: 100,
                                                  color: Colors.grey),
                                        ))
                                  : const Icon(Icons.broken_image,
                                      size: 100, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInfoRow('Código:', product.itemId?.toString()),
                                  _buildInfoRow('Código de Barras:', product.itemBarCode),
                                  _buildInfoRow('Desc. Linha:', product.prodLinesDescriptionId),
                                  _buildInfoRow('Desc. Decoração:', product.prodDecorationDescriptionId),
                                ],
                              ),
                            ),
                          ],
                        ),
                        onTap: () async {
                          
                          ProductAll productSelect = product;

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsPage(product: productSelect),
                            ),
                          );

                          if (result != null && result is Product) {
                            final index =
                                _allProducts.indexWhere((p) => p.itemId == result.itemId);
                            if (index != -1) {
                              setState(() {
                                _allProducts[index] = ProductAll.fromMap(result.toMap());
                                _filteredProducts = List.from(_allProducts);
                              });
                            }
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (_isLoading)
            Center(
              child: RotationTransition(
                turns: _controller,
                child: const Icon(Icons.refresh, size: 48),
              ),
            ),
        ],
      ),
    );
  }
}