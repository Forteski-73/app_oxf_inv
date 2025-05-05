import 'package:flutter/material.dart';
import '../models/product.dart';
import 'dart:io';
import 'package:app_oxf_inv/operator/db_product.dart';
import 'productImages.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final PageController _pageController = PageController();
  String? imagePath;
  List<File> imagens = [];

  @override
  void initState() {
    super.initState();
    _loadProductImage();
  }

  Future<void> _loadProductImage() async {
    try {
      // Busca imagens do produto pelo seu ID
      final List<Map<String, dynamic>> imagensData = await DBItems.instance.getProductImages(widget.product.itemId);

      // Ordena as imagens pelo campo 'columnImageSequence' de forma crescente
      imagensData.sort((a, b) => a[DBItems.columnImageSequence].compareTo(b[DBItems.columnImageSequence]));

      setState(() {
        imagens = imagensData.map((imageData) {
          // Converte o caminho da imagem para um arquivo
          return File(imageData[DBItems.columnImagePath]);
        }).toList();

        // Exibe a primeira imagem, se houver
        if (imagens.isNotEmpty) {
          imagePath = imagens[0].path;
          widget.product.setPath(imagePath.toString());
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao carregar imagens: $e'),
      ));
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
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Stack(
                children: [
Container(
  width: double.infinity,
  constraints: const BoxConstraints(minHeight: 250),
  child: Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Imagens do Produto',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          // Carregamento das imagens em um PageView com Stack
          imagens.isNotEmpty
              ? SizedBox(
                  height: 260, // Define a altura do carousel
                  child: Stack(
                    children: [
                      // O PageView com as imagens
                      PageView.builder(
                        controller: _pageController,  // Controller do PageView
                        itemCount: imagens.length,
                        itemBuilder: (context, index) {
                          return Image.file(
                            imagens[index],
                            fit: BoxFit.cover,
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
                      // As bolinhas de navegação no rodapé (sobre a imagem)
                      Positioned(
                        bottom: 10, // Distância do rodapé
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SmoothPageIndicator(
                            controller: _pageController,  // Controller do PageView
                            count: imagens.length,
                            effect: const WormEffect(
                              dotColor: Colors.grey, // Cor das bolinhas inativas
                              activeDotColor: Colors.blueAccent, // Cor da bolinha ativa
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
        ],
      ),
    ),
  ),
),

                  // Ícone de edição posicionado no topo direito, sobre o PageView
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap:  () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductImagesPage(product: widget.product),
                          ),
                        );
                        
                        // Recarrega as imagens do banco de dados
                        _loadProductImage();
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent, // black54
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              FutureBuilder<Map<String, dynamic>>(
                future: DBItems.instance.getProductDetails(widget.product.itemId), // Recupere os detalhes do produto
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(); // Exibe o carregando enquanto aguarda a resposta
                  } else if (snapshot.hasError) {
                    return Text('Erro: ${snapshot.error}');
                  } else if (!snapshot.hasData) {
                    return const Text('Produto não encontrado');
                  } else {
                    final product = snapshot.data!;

                    return Column(
                      children: [
                        buildExpansionTile("Informações do Produto", [
                          textRow("Código",     product[DBItems.columnItemId]),
                          textRow("Descrição",  product[DBItems.columnName] ?? ''),
                        ]),
                        buildExpansionTile("Dimensões e Peso", [
                          textRow("Peso Bruto",       "${product[DBItems.columnGrossWeight]   ?? ''} kg"),
                          textRow("Peso Líquido",     "${product[DBItems.columnItemNetWeight] ?? ''} kg"),
                          textRow("Tara",             "${product[DBItems.columnTaraWeight]    ?? ''} kg"),
                          textRow("Profundidade",     "${product[DBItems.columnGrossDepth]    ?? ''} m"),
                          textRow("Largura",          "${product[DBItems.columnGrossWidth]    ?? ''} m"),
                          textRow("Altura",           "${product[DBItems.columnGrossHeight]   ?? ''} m"),
                          textRow("Volume",           "${product[DBItems.columnUnitVolumeML]  ?? ''} m³"),
                          textRow("Qt Peças Interna", "${product[DBItems.columnNrOfItems]     ?? ''}"),
                        ]),
                        buildExpansionTile("Código de Barras", [
                          textRow("Master", product[DBItems.columnItemBarCode] ?? ''),
                        ]),
                        buildExpansionTile("Classificação Fiscal", [
                          textRow("Classificação Fiscal", product[DBItems.columnTaxFiscalClassification] ?? ''),
                        ]),
                        buildExpansionTile("Família e Marca", [
                          textRow("Família",    product[DBItems.columnProdFamilyDescription]        ?? ''),
                          textRow("Marca",      product[DBItems.columnProdBrandDescriptionId]       ?? ''),
                          textRow("Linha",      product[DBItems.columnProdLinesDescriptionId]       ?? ''),
                          textRow("Decoração",  product[DBItems.columnProdDecorationDescriptionId]  ?? ''),
                        ]),
                        buildExpansionTile("Características", [
                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: DBItems.instance.getProductTags(product[DBItems.columnItemId]), // Buscar as tags do produto
                            builder: (context, tagsSnapshot) {
                              if (tagsSnapshot.connectionState == ConnectionState.waiting) {
                                return const CircularProgressIndicator(); // Exibe o carregando enquanto aguarda as tags
                              } else if (tagsSnapshot.hasError) {
                                return Text('Erro: ${tagsSnapshot.error}');
                              } else if (!tagsSnapshot.hasData || tagsSnapshot.data!.isEmpty) {
                                return const Text('Sem características');
                              } else {
                                final tags = tagsSnapshot.data!;
                                return (tags != null && tags.isNotEmpty) 
                                    ? Column(
                                        children: tags.map((tag) => textRow("Características", tag[DBItems.columnTag])).toList(),
                                      ) : SizedBox.shrink();
                              }
                            },
                          ),
                        ]),
                      ],
                    );
                  }
                },
              )

              /*buildExpansionTile("Informações do Produto", [ // buscar da tabela tableProducts
                textRow("Código", "139600"), // columnItemId
                textRow("Descrição", "PRATO RASO 26CM - JARDIM SECRETO - A02D-5953"), // columnName
              ]),
              buildExpansionTile("Dimensões e Peso", [ // buscar da tabela tableProducts
                textRow("Peso Bruto", "9,14 kg"),   // columnGrossWeight
                textRow("Peso Líquido", "8,88 kg"), // columnItemNetWeight
                textRow("Tara", "0,26 kg"),         // columnTaraWeight
                textRow("Profundidade", "0,266 m"), // columnGrossDepth
                textRow("Largura", "0,180 m"),      // columnGrossWidth
                textRow("Altura", "0,288 m"),       // columnGrossHeight
                textRow("Volume", "0,014 m³"),      // columnUnitVolumeML
                textRow("Qt Peças Interna", "12"),  // columnNrOfItems
              ]),
              buildExpansionTile("Código de Barras", [ // buscar da tabela tableProducts
                textRow("Master", "7891361391387"), // columnItemBarCode
              ]),
              buildExpansionTile("Classificação Fiscal", [ // buscar da tabela tableProducts
                textRow("Classificação Fiscal", "123456789"), // columnTaxFiscalClassification
              ]),
              buildExpansionTile("Família e Marca", [ // buscar da tabela tableProducts
                textRow("Família", "0002 - PRODUTO ACABADO"), // columnProdFamilyDescription
                textRow("Marca", "OXFORD DAILY"),             // columnProdBrandDescriptionId
                textRow("Linha", "UNNI"),                     // columnProdLinesDescriptionId
                textRow("Decoração", "JARDIM SECRETO"),       // columnProdDecorationDescriptionId
              ]),

              buildExpansionTile("Características", [
                textRow("Características", "Borboleta, Flor, Verde, Laranja, Rosa"),
                // Buscar da tabela tableProductTags
              ]),*/
            ],
          ),
        ),
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

  Widget buildExpansionTile(String title, List<Widget> children) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
