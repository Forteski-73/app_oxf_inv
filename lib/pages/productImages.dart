import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
//import 'package:path_provider/path_provider.dart';
import 'package:reorderables/reorderables.dart';
import 'package:app_oxf_inv/operator/db_product.dart';
import '../models/product_image.dart';
import '../models/product_tag.dart';
import '../models/product_all.dart';
import '../ftp/ftp.dart';
import 'package:app_oxf_inv/services/remote/oxfordonlineAPI.dart';

class ProductImagesPage extends StatefulWidget {
  final ProductAll product;

  const ProductImagesPage({super.key, required this.product});

  @override
  _ProductImagesPageState createState() => _ProductImagesPageState();
}

class _ProductImagesPageState extends State<ProductImagesPage> with TickerProviderStateMixin {
  Map<String, bool> expandedStates = {};
  List<ProductTag> tag = [];
  final TextEditingController _caracteristicaController = TextEditingController();
  List<File> imagens = [];
  int? imagemPrincipalIndex;
  bool isLoading = false;
  bool isZoomed = false;
  int zoomedIndex = -1;
  late final AnimationController _controller;

  final ImagePicker picker = ImagePicker();

  void setLoading(bool stat) {
    setState(() {
      isLoading = stat;
    });
  }

  void removerImagem(int index) {
    setState(() {
      imagens.removeAt(index);
      if (imagemPrincipalIndex == index) {
        imagemPrincipalIndex = null;
      }
    });
  }

  void definirImagemPrincipal(int index) {
    setState(() {
      imagemPrincipalIndex = index;
    });
  }

  void selecionarOrigemImagem() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Selecionar múltiplas da galeria'),
              onTap: () async {
                Navigator.pop(context);
                final List<XFile>? pickedFiles = await picker.pickMultiImage();
                if (pickedFiles != null && pickedFiles.isNotEmpty) {
                  setState(() {
                    imagens.addAll(pickedFiles.map((file) => File(file.path)));
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar uma foto'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await picker.pickImage(source: ImageSource.camera);
                if (photo != null) {
                  setState(() {
                    imagens.add(File(photo.path));
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> saveTagsImages() async {
    try {
      //final directory = await getTemporaryDirectory();
      setLoading(true);
      // Excluir as imagens e tags antigas
      await DBItems.instance.deleteProductImagesByProduct(widget.product.itemId);
      await DBItems.instance.deleteProductTagsByProduct(widget.product.itemId);

      List<ProductImage> imagesForAPI = [];

      // Salvar as imagens no banco de dados e preparar para envio à API
      for (int i = 0; i < imagens.length; i++) {
        final imagePath = imagens[i].path;

        await DBItems.instance.insertProductImage({
          DBItems.columnImagePath: imagePath,
          DBItems.columnImageSequence: i + 1,
          DBItems.columnProductId: widget.product.itemId,
        });

      }

      // Salvar as tags no banco de dados
      for (ProductTag t in tag) {
        await DBItems.instance.insertProductTag({
          DBItems.columnTag: t.tag,
          DBItems.columnTagProductId: widget.product.itemId,
        });
      }


      // Executar rotina adicional
      await saveTagsImagesDirFTP();

      // Mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Imagens e tags salvas com sucesso no banco de dados.'),
      ));
    } catch (e) {
      // Mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao salvar imagens e tags: $e'),
      ));
    } finally {
      setLoading(false);
    }

    
  }
  
  Future<void> saveTagsImagesDirFTP() async {
    FTPUploader ftpUploader = FTPUploader();
    
    String remoteDir = '${widget.product.prodFamilyDescriptionId}/${widget.product.prodBrandDescriptionId}/'+
    '${widget.product.prodLinesDescriptionId}/${widget.product.prodDecorationDescriptionId}/${widget.product.itemId}';
    await ftpUploader.saveTagsImagesFTP(remoteDir, widget.product.itemId, imagens, tag, context);
  } 
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    
    carregarImagens();
    carregarTags();
  }

  Future<void> carregarImagens() async {
    try {
      final List<Map<String, dynamic>> imagensData = await DBItems.instance.getProductImages(widget.product.itemId);

      // Ordena as imagens pelo campo 'columnImageSequence' em ordem crescente
      imagensData.sort((a, b) => a[DBItems.columnImageSequence].compareTo(b[DBItems.columnImageSequence]));

      setState(() {
        imagens = imagensData.map((imageData) {
          // Converte o caminho da imagem para um arquivo
          return File(imageData[DBItems.columnImagePath]);
        }).toList();
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao carregar imagens: $e'),
      ));
    }
  }

  Future<void> carregarTags() async {
    try {
      
      final List<Map<String, dynamic>> tagsData = await DBItems.instance.getProductTags(widget.product.itemId);

      setState(() {
        tag = tagsData.map((tagData) => ProductTag(
          tag: tagData[DBItems.columnTag],
          productId: tagData[DBItems.columnTagProductId],
        )).toList();
      });

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar características: $e'),
      ));
    }
  }

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
            Text(
              'Aplicativo de Consulta de Estrutura de Produtos. ACEP',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            SizedBox(height: 2),
            Text(
              'Editar Produto',
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
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card para o código e descrição
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'CÓDIGO: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(widget.product.itemId,
                                  style: const TextStyle(fontSize: 15)),
                            ],
                          ),
                          Wrap(
                            children: [
                              const Text(
                                'DESCRIÇÃO: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(widget.product.name),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card para as características
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Características',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextField(
                            controller: _caracteristicaController,
                            decoration: const InputDecoration(
                              hintText: 'Digite uma característica..',
                              border: UnderlineInputBorder(),
                            ),
                            onChanged: (value) {
                              if (value.endsWith(' ')) {
                                String novaCaracteristica = value.trim();
                                if (novaCaracteristica.isNotEmpty &&
                                    !tag.any((t) => t.tag == novaCaracteristica)) {
                                  setState(() {
                                    tag.add(ProductTag(
                                        tag: novaCaracteristica,
                                        productId: widget.product.itemId));
                                  });
                                }
                                _caracteristicaController.clear();
                              }
                            },
                            onSubmitted: (value) {
                              String novaCaracteristica = value.trim();
                              if (novaCaracteristica.isNotEmpty &&
                                  !tag.any((t) => t.tag == novaCaracteristica)) {
                                setState(() {
                                  tag.add(ProductTag(
                                      tag: novaCaracteristica,
                                      productId: widget.product.itemId));
                                });
                              }
                              _caracteristicaController.clear();
                            },
                            onEditingComplete: () {
                              String novaCaracteristica =
                                  _caracteristicaController.text.trim();
                              if (novaCaracteristica.isNotEmpty &&
                                  !tag.any((t) => t.tag == novaCaracteristica)) {
                                setState(() {
                                  tag.add(ProductTag(
                                      tag: novaCaracteristica,
                                      productId: widget.product.itemId));
                                });
                              }
                              _caracteristicaController.clear();
                            },
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: tag.map((caract) {
                              return Chip(
                                label: Text(caract.tag,
                                    style: const TextStyle(fontSize: 16)),
                                deleteIcon: const Icon(Icons.highlight_off_outlined,
                                    color: Colors.red, size: 20),
                                onDeleted: () {
                                  setState(() {
                                    tag.remove(caract);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 80),
                        child: Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Imagens',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: ReorderableWrap(
                                    onReorder: (oldIndex, newIndex) {
                                      setState(() {
                                        final imagem = imagens.removeAt(oldIndex);
                                        imagens.insert(newIndex, imagem);
                                      });
                                    },
                                    scrollDirection: Axis.horizontal,
                                    children:
                                        List.generate(imagens.length, (index) {
                                      File imagem = imagens[index];
                                      bool isSelected =
                                          isZoomed && zoomedIndex == index;
                                      return Stack(
                                        key: ValueKey(index),
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                if (isSelected) {
                                                  isZoomed = false;
                                                  zoomedIndex = -1;
                                                } else {
                                                  isZoomed = true;
                                                  zoomedIndex = index;
                                                }
                                              });
                                            },
                                            child: AnimatedContainer(
                                              duration:
                                                  const Duration(milliseconds: 300),
                                              margin: const EdgeInsets.all(4),
                                              width: isSelected ? 250 : 80,
                                              height: isSelected ? 250 : 80,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: index == 0
                                                      ? Colors.amber
                                                      : (imagemPrincipalIndex ==
                                                              index
                                                          ? Colors.orange
                                                          : Colors.grey),
                                                  width: 3,
                                                ),
                                                image: DecorationImage(
                                                  image: FileImage(imagem),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (index == 0)
                                            Positioned(
                                              bottom: 4,
                                              left: 4,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  shape: BoxShape.circle,
                                                ),
                                                padding: const EdgeInsets.all(4),
                                                child: const Icon(
                                                  Icons.star,
                                                  color: Colors.amber,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          Positioned(
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: () => removerImagem(index),
                                              child:
                                                  const Icon(Icons.cancel, color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      );
                                    }),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Ícone girando com fundo escuro quando isLoading == true
          if (isLoading)
            Container(
              color: Colors.black.withAlpha((0.6 * 255).round()),
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _controller.value * 2 * 3.1416,
                      child: child,
                    );
                  },
                  child: const Icon(Icons.rotate_right, size: 50, color: Colors.white),
                ),
              ),
            ),
        ],
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
              tooltip: 'Salvar',
              icon: const Icon(Icons.save_rounded, size: 28),
              onPressed: isLoading ? null : saveTagsImages,
            ),
            IconButton(
              icon: const Icon(Icons.add_a_photo, size: 30),
              onPressed: selecionarOrigemImagem,
            ),
          ],
        ),
      ),
    );
  }

}
