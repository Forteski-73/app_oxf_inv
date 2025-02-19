import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:reorderables/reorderables.dart';
import 'package:app_oxf_inv/operator/db_product.dart';
import 'productImages.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  _ProductDetailsPageState createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
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
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao carregar imagens: $e'),
      ));
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
            Text('Aplicativo de Consulta de Estrutura de Produtos. ACEP',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            SizedBox(height: 2),
            Text('Estrutura do Produto',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
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
                            // Carregamento das imagens em um PageView
                            imagens.isNotEmpty
                                ? SizedBox(
                                    height: 250, // Define a altura do carousel
                                    child: PageView.builder(
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
                          color: Colors.black54,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              buildExpansionTile("Informações do Produto", [
                textRow("Código", "139600"),
                textRow("Descrição", "PRATO RASO 26CM - JARDIM SECRETO - A02D-5953"),
              ]),
              buildExpansionTile("Dimensões e Peso", [
                textRow("Peso Bruto", "9,14 kg"),
                textRow("Peso Líquido", "8,88 kg"),
                textRow("Tara", "0,26 kg"),
                textRow("Profundidade", "0,266 m"),
                textRow("Largura", "0,180 m"),
                textRow("Altura", "0,288 m"),
                textRow("Volume", "0,014 m³"),
                textRow("Qt Peças Interna", "12"),
              ]),
              buildExpansionTile("Código de Barras", [
                textRow("Master", "7891361391387"),
              ]),
              buildExpansionTile("Classificação Fiscal", [
                textRow("Classificação Fiscal", "123456789"),
                textRow("Exceção", "123456789"),
              ]),
              buildExpansionTile("Família e Marca", [
                textRow("Família", "0002 - PRODUTO ACABADO"),
                textRow("Marca", "OXFORD DAILY"),
                textRow("Linha", "UNNI"),
                textRow("Decoração", "JARDIM SECRETO"),
              ]),
              buildExpansionTile("Características", [
                textRow("Características", "Borboleta, Flor, Verde, Laranja, Rosa"),
              ]),
            ],
          ),
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
          //const SizedBox(width: 8),
          // Texto alinhado à direita
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
