import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';

import 'package:app_oxf_inv/widgets/customSnackBar.dart';
import 'package:app_oxf_inv/operator/db_product.dart';
import '../controller/product_search.dart';
import '../ftp/ftp.dart';
import '../models/product_all.dart';
import '../models/product_image.dart';
import '../models/product_tag.dart';
import '../utils/globals.dart' as globals;
import 'package:path/path.dart' as p;

class ProductImagesPage extends StatefulWidget {
  final ProductAll product;

  const ProductImagesPage({super.key, required this.product});

  @override
  _ProductImagesPageState createState() => _ProductImagesPageState();
}

class _ProductImagesPageState extends State<ProductImagesPage> with TickerProviderStateMixin {
  final TextEditingController _caracteristicaController = TextEditingController();
  bool isLoading = false;
  late final AnimationController _controller;
  final ImagePicker picker = ImagePicker();

  bool isZoomed = false;
  int zoomedIndex = -1;
  int imagemPrincipalIndex = 0;

  void setLoading(bool stat) {
    setState(() {
      isLoading = stat;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  void selecionarOrigemImagem(ProductSearchController productSearchController) {
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
                  productSearchController.addImages(pickedFiles.map((file) => ProductImage(
                    imagePath: file.path,
                    imageSequence: productSearchController.imagesData.length + 1,
                    productId: widget.product.itemId,
                  )).toList());
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
                  productSearchController.addImages([
                    ProductImage(
                      imagePath: photo.path,
                      imageSequence: productSearchController.imagesData.length + 1,
                      productId: widget.product.itemId,
                    ),
                  ]);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> saveTagsImages(ProductSearchController productSearchController) async {
    final dbprod = DBItems.instance;
    try {
      setLoading(true);
      final productToSave = productSearchController.selectedProduct ?? widget.product;

      // Atualiza imageSequence com base na ordem atual
      for (int i = 0; i < productSearchController.imagesData.length; i++) {
        productSearchController.imagesData[i].imageSequence = i;
      }

      await dbprod.saveCompleteProduct(productToSave, productSearchController.imagesData);

      if (globals.isOnline) {
        await saveTagsImagesDirFTP(productSearchController);
      }

      Navigator.pop(context, productSearchController.imagesData);
    } catch (e) {
      CustomSnackBar.show(
        context,
        message: 'Erro ao salvar imagens e tags: $e',
        duration: const Duration(seconds: 4),
        type: SnackBarType.error,
      );
    } finally {
      setLoading(false);
    }
  }

  Future<void> saveTagsImagesDirFTP(ProductSearchController productSearchController) async {
    FTPUploader ftpUploader = FTPUploader();
    String remoteDir =
        '${widget.product.prodFamilyDescriptionId}/${widget.product.prodBrandDescriptionId}/'
        '${widget.product.prodLinesDescriptionId}/${widget.product.prodDecorationDescriptionId}/${widget.product.itemId}';

    await ftpUploader.saveTagsImagesFTP(
      remoteDir,
      widget.product.itemId,
      productSearchController.imagesData,
      productSearchController.tags,
    );
  }

  void removerImagem(ProductSearchController productSearchController, int index) {
    productSearchController.removeImageAtIndex(index);
  }

  void definirImagemPrincipal(ProductSearchController productSearchController, int index) {
    final currentImages = productSearchController.imagesData;
    if (index < 0 || index >= currentImages.length) return;

    // Traz a imagem selecionada para o início
    final imgPrincipal = currentImages.removeAt(index);
    currentImages.insert(0, imgPrincipal);

    // Atualiza sequências
    for (int i = 0; i < currentImages.length; i++) {
      currentImages[i].imageSequence = i;
    }

    //productSearchController.setImages(List<ProductImage>.from(currentImages));
  }

  void adicionarTag(ProductSearchController controller, String novaCaracteristica) {
    if (novaCaracteristica.isNotEmpty) {
      controller.addTag(ProductTag(
        tag: novaCaracteristica,
        productId: widget.product.itemId,
      ));
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Informações"),
          content: const Text("Oxford Porcelanas \n\nVersão: 1.0\n"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Fechar", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _caracteristicaController.dispose();
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ProductSearchController>();
    final product = controller.selectedProduct ?? widget.product;
    final images = controller.imagesData;
    final tags = controller.tags;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aplicativo de Consulta de Estrutura de Produtos. ACEP', style: TextStyle(fontSize: 12)),
            SizedBox(height: 2),
            Text('Editar Produto', style: TextStyle(fontSize: 20)),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              children: [
                // Info Produto
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CÓDIGO: ${product.itemId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('DESCRIÇÃO: ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Características
Card(
  elevation: 2,
  child: Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Características', style: TextStyle(fontWeight: FontWeight.bold)),
        TextField(
          controller: _caracteristicaController,
          decoration: const InputDecoration(
            hintText: 'Digite uma característica...',
            border: UnderlineInputBorder(),
          ),
          onChanged: (value) {
            if (value.endsWith(' ')) {
              final novaCaracteristica = value.trim();
              if (novaCaracteristica.isNotEmpty && !tags.any((t) => t.tag == novaCaracteristica)) {
                setState(() {
                  tags.add(ProductTag(tag: novaCaracteristica));
                });
              }
              _caracteristicaController.clear();
            }
          },
          onSubmitted: (value) {
            final novaCaracteristica = value.trim();
            if (novaCaracteristica.isNotEmpty && !tags.any((t) => t.tag == novaCaracteristica)) {
              setState(() {
                tags.add(ProductTag(tag: novaCaracteristica));
              });
            }
            _caracteristicaController.clear();
          },
          onEditingComplete: () {
            final novaCaracteristica = _caracteristicaController.text.trim();
            if (novaCaracteristica.isNotEmpty && !tags.any((t) => t.tag == novaCaracteristica)) {
              setState(() {
                tags.add(ProductTag(tag: novaCaracteristica));
              });
            }
            _caracteristicaController.clear();
          },
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: tags.map((caract) {
            return Chip(
              label: Text(caract.tag, style: const TextStyle(fontSize: 16)),
              deleteIcon: const Icon(Icons.highlight_off_outlined, color: Colors.red, size: 20),
              onDeleted: () {
                setState(() {
                  tags.remove(caract);
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
                // Imagens
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Imagens', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    images.isEmpty
                        ? const Text('Nenhuma imagem disponível.')
                        : SizedBox(
                            width: double.infinity,
                            child: ReorderableWrap(
                              spacing: 8,
                              runSpacing: 8,
                              scrollDirection: Axis.horizontal,
                              needsLongPressDraggable: false,
                              onReorder: (oldIndex, newIndex) =>
                                  controller.reorderImages(oldIndex, newIndex),
                              children: List.generate(images.length, (index) {
                                final img = images[index];
                                final isSelected = isZoomed && zoomedIndex == index;
                                final isPrincipal = index == 0 || (imagemPrincipalIndex == index);

                                final fullImagePath = p.join(globals.tempDir.path, img.imagePath);
                                final imageFile = File(fullImagePath);

                                return Stack(
                                  key: ValueKey(fullImagePath),
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
                                        duration: const Duration(milliseconds: 300),
                                        margin: const EdgeInsets.all(4),
                                        width: isSelected ? 250 : 80,
                                        height: isSelected ? 250 : 80,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isPrincipal
                                                ? Colors.amber
                                                : (imagemPrincipalIndex == index
                                                    ? Colors.orange
                                                    : Colors.grey),
                                            width: 3,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                          image: DecorationImage(
                                            image: FileImage(imageFile),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isPrincipal)
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Container(
                                          decoration: const BoxDecoration(
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
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => removerImagem(controller, index),
                                        child: const Icon(Icons.cancel, color: Colors.red),
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

                const SizedBox(height: 16),
              ],
            ),
          ),

          // Carregamento
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
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
              onPressed: isLoading ? null : () => saveTagsImages(controller),
            ),
            IconButton(
              icon: const Icon(Icons.add_a_photo, size: 30),
              onPressed: () => selecionarOrigemImagem(controller),
            ),
          ],
        ),
      ),
    );
  }

}


/*import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:app_oxf_inv/widgets/customSnackBar.dart';
import 'package:reorderables/reorderables.dart';
import 'package:app_oxf_inv/operator/db_product.dart';
import '../models/product_image.dart';
import '../models/product_tag.dart';
import '../models/product_all.dart';
import '../utils/globals.dart' as globals;
import '../ftp/ftp.dart';
import '../controller/product_search.dart';
import 'package:provider/provider.dart';

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
  //List<File> imagens = [];
  //List<ProductImage> imagens = [];
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
      globals.imagesData.removeAt(index);
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
                    globals.imagesData.addAll(pickedFiles.map((file) => ProductImage(
                      imagePath: file.path,
                      imageSequence: globals.imagesData.length + 1,
                      productId: widget.product.itemId,
                    )));
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
                    globals.imagesData.add(
                      ProductImage(
                        imagePath: photo.path,
                        imageSequence: globals.imagesData.length + 1,
                        productId: widget.product.itemId,
                      ),
                    );
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
    final dbprod = DBItems.instance;
    
    try {

      setLoading(true);

      await dbprod.saveCompleteProduct(widget.product, globals.imagesData); 

      if (globals.isOnline) {
        await saveTagsImagesDirFTP();
      }

      Navigator.pop(context, globals.imagesData); // Retorna true para a tela anterior

    } catch (e) {
      CustomSnackBar.show(context, message: 'Erro ao salvar imagens e tags: $e',
        duration: const Duration(seconds: 4),type: SnackBarType.error,
      );
    } finally {
      setLoading(false);
    }
  }
  
  Future<void> saveTagsImagesDirFTP() async {
    FTPUploader ftpUploader = FTPUploader();
    
    String remoteDir = '${widget.product.prodFamilyDescriptionId}/${widget.product.prodBrandDescriptionId}/'+
    '${widget.product.prodLinesDescriptionId}/${widget.product.prodDecorationDescriptionId}/${widget.product.itemId}';
    await ftpUploader.saveTagsImagesFTP(remoteDir, widget.product.itemId, globals.imagesData, tag); 
    //await ftpUploader.saveTagsImagesFTP(remoteDir, widget.product.itemId, imagens, tag, context); //ProductAll productAll
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
        globals.imagesData = imagensData.map((imageData) {
          return ProductImage(
            imageId: imageData['id'] ?? 0,
            imagePath: imageData[DBItems.columnImagePath],
            imageSequence: imageData[DBItems.columnImageSequence] ?? 0,
            productId: imageData[DBItems.columnProductId],
          );
        }).toList();
      });
      
    } catch (e) {
      CustomSnackBar.show(context, message: 'Erro ao carregar imagens: $e',
        duration: const Duration(seconds: 4),type: SnackBarType.error,
      );
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
      CustomSnackBar.show(context, message: 'Erro ao carregar características: $e',
        duration: const Duration(seconds: 4),type: SnackBarType.error,
      );
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
                                        final imagem = globals.imagesData.removeAt(oldIndex);
                                        globals.imagesData.insert(newIndex, imagem);
                                      });
                                    },
                                    scrollDirection: Axis.horizontal,
                                    children: List.generate(globals.imagesData.length, (index) {
                                      File imagem = File(globals.imagesData[index].imagePath);
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
*/