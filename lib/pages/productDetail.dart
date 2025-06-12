import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_all.dart';
import '../models/product_image.dart';
import '../services/local/oxfordLocalLite.dart';
import '../utils/globals.dart' as globals;
import '../controller/product_search.dart';
import 'productImages.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:app_oxf_inv/main.dart';
import 'package:path/path.dart' as p;

class ProductDetailsPage extends StatefulWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> with RouteAware {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductSearchController>().loadProductDetails(widget.productId);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<ProductSearchController>().loadProductDetails(widget.productId);
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Informações"),
        content: const Text("Oxford Porcelanas \n\nVersão: 1.0\n"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductSearchController>(
      builder: (context, controller, child) {
        final product = controller.selectedProduct;

        // Proteção contra nulo
        if (product == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Obter a lista de imagens ProductImage
        final images = product.productImages;

        // Converter List<ProductImage> para List<File>
        final imagens = images.map((img) => File(img.imagePath)).toList();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aplicativo de Consulta de Estrutura de Produtos. ACEP',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Estrutura do Produto ${product.itemId}',
                  style: const TextStyle(color: Colors.white, fontSize: 20),
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
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              children: [
                if (imagens.isNotEmpty)
                  SizedBox(
                    height: 260,
                    child: Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      child: Stack(
                        children: [
                          PageView.builder(
                            controller: _pageController,
                            itemCount: imagens.length,
                            itemBuilder: (context, index) => Image.file(
                              File(p.join(globals.tempDir.path, imagens[index].path)),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => const Center(
                                child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            left: 1,
                            right: 1,
                            child: Container(
                              color: Colors.black.withAlpha(179),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SmoothPageIndicator(
                                controller: _pageController,
                                count: imagens.length,
                                effect: const WormEffect(
                                  dotColor: Colors.white54,
                                  activeDotColor: Colors.blueAccent,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                buildExpansionTile("Informações do Produto", [
                  textRow("Código", product.itemId),
                  textRow("Descrição", product.name),
                ]),
                buildExpansionTile("Dimensões e Peso", [
                  textRow("Peso Bruto", "${product.prodGrossWeight} kg"),
                  textRow("Peso Líquido", "${product.itemNetWeight} kg"),
                  textRow("Tara", "${product.prodTaraWeight} kg"),
                  textRow("Profundidade", "${product.prodGrossDepth} m"),
                  textRow("Largura", "${product.prodGrossWidth} m"),
                  textRow("Altura", "${product.prodGrossHeight} m"),
                  textRow("Volume", "${product.unitVolumeML} m³"),
                  textRow("Qt Peças Interna", "${product.prodNrOfItems}"),
                ]),
                buildExpansionTile("Código de Barras", [
                  textRow("Master", product.itemBarCode),
                ]),
                buildExpansionTile("Classificação Fiscal", [
                  textRow("Classificação Fiscal", product.prodTaxFiscalClassification),
                ]),
                buildExpansionTile("Família e Marca", [
                  textRow("Família", product.prodFamilyDescriptionId),
                  textRow("Marca", product.prodBrandDescriptionId),
                  textRow("Linha", product.prodLinesDescriptionId),
                  textRow("Decoração", product.prodDecorationDescriptionId),
                ]),

                // Usar product.productTags para mostrar características
                buildExpansionTile(
                  "Características",
                  product.productTags != null && product.productTags!.isNotEmpty
                      ? product.productTags!
                          .map((tag) => textRow("Características", tag.tag))
                          .toList()
                      : [const Text('Sem características')],
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomAppBar(
            color: Colors.white,
            shape: const CircularNotchedRectangle(),
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: const Icon(Icons.home, size: 30),
                  onPressed: () => Navigator.pushNamed(context, '/'),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 30, color: Colors.blueAccent),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductImagesPage(product: product),
                      ),
                    );

                    /*if (result is List<ProductImage>) {
                      context.read<ProductSearchController>().refreshImages(result);
                    }*/
                  },
                  tooltip: 'Editar imagens',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildExpansionTile(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: ExpansionTile(
        title: Text(' $title', style: const TextStyle(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(runSpacing: 3, children: children),
          ),
        ],
      ),
    );
  }

  Widget textRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 3.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}


/*
import 'package:flutter/material.dart';
import 'package:app_oxf_inv/main.dart'; 
import '../models/product.dart';
import '../models/product_all.dart';
import 'dart:io';
import 'package:app_oxf_inv/widgets/customSnackBar.dart';
import 'productImages.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:app_oxf_inv/services/local/oxfordLocalLite.dart';
import 'package:app_oxf_inv/services/remote/oxfordonlineAPI.dart';
import 'package:app_oxf_inv/models/product_image.dart';
import 'package:app_oxf_inv/models/product_tag.dart';
import 'package:app_oxf_inv/models/product.dart';
import '../utils/globals.dart' as globals;
import 'package:path/path.dart' as path;
import '../ftp/ftp.dart';
import 'package:image/image.dart' as img;

class ProductDetailsPage extends StatefulWidget {
  final ProductAll product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> with RouteAware {
  final PageController _pageController = PageController();
  String? imagePath;
  List<File> imagens = [];
  //List<ProductImage> imagensData = [];

  @override
  void initState() {
    super.initState();
    _loadProductImage();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this); // se estiver usando routeObserver
    super.dispose();
  }

  @override
  void didPopNext() {
    // Página voltou ao foco (ex: após editar imagens)
    _loadProductImage(); // Atualiza as imagens
  }

  Future<void> _loadProductImage() async {
    try {
      bool status = true;
      FTPUploader ftpUploader = FTPUploader();
      List<File> ImagesFromFTP = [];

      if (globals.isOnline) {
        //final directory = path.dirname(widget.product.path);
        //List<ProductImage> imgs = await ftpUploader.fetchImagesFromFTP(directory,widget.product.itemId);
        
    
      }

      // Busca imagens do produto pelo seu ID usando OxfordLocalLite.dart
      globals.imagesData = await OxfordLocalLite().getProductImages(widget.product.itemId);
      

      setState(() {
        imagens = globals.imagesData.map((image) {
          final file = File(image.imagePath);

          return file;
        }).toList();
      });

    } catch (e) {
      CustomSnackBar.show(context, message: 'Erro ao carregar imagens: $e',
        duration: const Duration(seconds: 4),type: SnackBarType.error,
      );
    }
  }

  Future<Map<String, dynamic>> getProductDetails(String productId) async {
  try {
    // Usa OxfordLocalLite para buscar os detalhes como objeto Product
    Product? product = await OxfordLocalLite().getProductDetails(productId);

    if (product != null) {
      // Converte o objeto Product para Map<String, dynamic>
      return product.toMap();
    } else {
      throw Exception('Produto não encontrado');
    }
  } catch (e) {
    throw Exception('Erro ao obter detalhes do produto: $e');
  }
}

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
    final product = widget.product;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aplicativo de Consulta de Estrutura de Produtos. ACEP',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            SizedBox(height: 2),
            Text(
              'Estrutura do Produto ${widget.product.itemId}', // Use widget.product dentro do build
              style: TextStyle(color: Colors.white, fontSize: 20),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 250),
                    child: Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias, // Para recorte do conteúdo pelo borderRadius
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            // Fundo com imagens
                            PageView.builder(
                              controller: _pageController,
                              itemCount: imagens.length,
                              itemBuilder: (context, index) {
                                return Image.file(
                                  imagens[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(
                                        Icons.image_not_supported,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),

                            // Texto do nome do produto
                            Positioned(
                              top: 0,
                              left: 1,
                              right: 1,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Container(
                                  color: Colors.black.withAlpha(179), // Fundo preto com transparência opcional
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    widget.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.visible,
                                    softWrap: false,
                                  ),
                                ),
                              ),
                            ),

                            // Indicadores (bolinhas) na parte inferior
                            Positioned(
                              bottom: 10,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: SmoothPageIndicator(
                                  controller: _pageController,
                                  count: imagens.length,
                                  effect: const WormEffect(
                                    dotColor: Colors.white54,
                                    activeDotColor: Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ),
                ],
              ),
              //FutureBuilder<Product?>(
                //future: OxfordLocalLite().getProductDetails(widget.product.itemId), // agora retorna Product
              

              Column(
                children: [
                  buildExpansionTile("Informações do Produto", [
                    textRow("Código",     product.itemId),
                    textRow("Descrição",  product.name),
                  ]),
                  buildExpansionTile("Dimensões e Peso", [
                    textRow("Peso Bruto",       "${product.prodGrossWeight} kg"),
                    textRow("Peso Líquido",     "${product.itemNetWeight} kg"),
                    textRow("Tara",             "${product.prodTaraWeight} kg"),
                    textRow("Profundidade",     "${product.prodGrossDepth} m"),
                    textRow("Largura",          "${product.prodGrossWidth} m"),
                    textRow("Altura",           "${product.prodGrossHeight} m"),
                    textRow("Volume",           "${product.unitVolumeML} m³"),
                    textRow("Qt Peças Interna", "${product.prodNrOfItems}"),
                  ]),
                  buildExpansionTile("Código de Barras", [
                    textRow("Master", product.itemBarCode),
                  ]),
                  buildExpansionTile("Classificação Fiscal", [
                    textRow("Classificação Fiscal", product.prodTaxFiscalClassification),
                  ]),
                  buildExpansionTile("Família e Marca", [
                    textRow("Família",    product.prodFamilyDescriptionId),
                    textRow("Marca",      product.prodBrandDescriptionId),
                    textRow("Linha",      product.prodLinesDescriptionId),
                    textRow("Decoração",  product.prodDecorationDescriptionId),
                  ]),
                  buildExpansionTile("Características", [
                    FutureBuilder<List<ProductTag>>(
                      future: OxfordLocalLite().getProductTags(product.itemId),
                      builder: (context, tagsSnapshot) {
                        if (tagsSnapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (tagsSnapshot.hasError) {
                          return Text('Erro: ${tagsSnapshot.error}');
                        } else if (!tagsSnapshot.hasData || tagsSnapshot.data!.isEmpty) {
                          return const Text('Sem características');
                        } else {
                          final tags = tagsSnapshot.data!;
                          return Column(
                            children: tags.map((tag) => textRow("Características", tag.tag)).toList(),
                          );
                        }
                      },
                    ),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home, size: 30),
              onPressed: () {
                Navigator.pushNamed(context, '/');
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 30, color: Colors.blueAccent),
              onPressed: () async {
                final imagensAtualizadas = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductImagesPage(product: widget.product),
                  ),
                );

                if (imagensAtualizadas != null && imagensAtualizadas is List<ProductImage>) {
                  setState(() {
                    imagens = imagensAtualizadas.map((img) => File(img.imagePath)).toList();
                  });
                }
              },
              tooltip: 'Editar imagens',
            ),
          ],
        ),
      ),

    );
  }

  Widget buildExpansionTile(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      elevation: 2, 
      child: ExpansionTile(
        title: Container(
          width: double.infinity,
          child: Text(
            ' $title',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              //spacing: 5, // Espaçamento entre os widgets
              runSpacing: 3, // Espaçamento entre as linhas quando quebrar
              children: children,
            ),
          ),
        ],
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        initiallyExpanded: false,
        shape: Border.all(style: BorderStyle.none), // Remove a borda
      ),
    );
  }

  Widget textRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Label com negrito
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true, // Quebra de linha automática
              overflow: TextOverflow.visible,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

}
*/