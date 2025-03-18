import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:reorderables/reorderables.dart';
import 'package:app_oxf_inv/operator/db_product.dart';


class ProductImagesPage extends StatefulWidget {
  final Product product;

  const ProductImagesPage({super.key, required this.product});

  @override
  _ProductImagesPageState createState() => _ProductImagesPageState();
}

class _ProductImagesPageState extends State<ProductImagesPage> {
   Map<String, bool> expandedStates = {};
  List<String> tag = [];
  final TextEditingController _caracteristicaController = TextEditingController();
  List<File> imagens = [];
  int? imagemPrincipalIndex;

  bool isZoomed = false;
  int zoomedIndex = -1;

  final ImagePicker picker = ImagePicker();

  Future<void> selecionarImagem() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imagens.add(File(pickedFile.path));
      });
    }
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

  Future<void> saveTagsImages() async {
    try {
      final directory = await getTemporaryDirectory();

      // Excluir as imagens e tags antigas
      await DBItems.instance.deleteProductImagesByProduct(widget.product.itemId);
      await DBItems.instance.deleteProductTagsByProduct(widget.product.itemId);

      // Salvar as imagens no diretório temporário e no banco de dados
      for (int i = 0; i < imagens.length; i++) {
        //final file = imagens[i];
        //final path = '${directory.path}/imagem_${i + 1}.jpg';
        //await file.copy(path);

        // Inserir a imagem na tabela com a sequência correta
        await DBItems.instance.insertProductImage({
          DBItems.columnImagePath: imagens[i].path,
          DBItems.columnImageSequence: i + 1, // A sequência é 1-based
          DBItems.columnProductId: widget.product.itemId,
        });
      }

      // Agora, salvar as tags no banco de dados
      for (String tag in tag) {
        await DBItems.instance.insertProductTag({
          DBItems.columnTag: tag,
          DBItems.columnTagProductId: widget.product.itemId,
        });
      }

      // Exibir mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Imagens e tags salvas com sucesso no banco de dados.'),
      ));
    } catch (e) {
      // Exibir mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao salvar imagens e tags: $e'),
      ));
    }
  }

  /*
  Future<void> saveTagsImages() async {
    FTPUploader ftpUploader = FTPUploader();
    await ftpUploader.uploadImages(imagens, context);
  }
  */
  
  @override
  void initState() {
    super.initState();
    
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
        tag = tagsData.map((tagData) => tagData[DBItems.columnTag] as String).toList();
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
            Text('Aplicativo de Consulta de Estrutura de Produtos. ACEP',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            SizedBox(height: 2),
            Text('Editar Produto',
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
                            'CÓDIGO: ', style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(widget.product.itemId, style: const TextStyle(fontSize: 15)),
                        ],
                      ),
                      Wrap(
                        children: [
                          const Text(
                            'DESCRIÇÃO: ', style: TextStyle(fontWeight: FontWeight.bold),
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
                                !tag.contains(novaCaracteristica)) {
                              setState(() {
                                tag.add(novaCaracteristica);
                              });
                            }
                            _caracteristicaController.clear();
                          }
                        },
                        onSubmitted: (value) {
                          String novaCaracteristica = value.trim();
                          if (novaCaracteristica.isNotEmpty && !tag.contains(novaCaracteristica)) {
                            setState(() {
                              tag.add(novaCaracteristica);
                            });
                          }
                          _caracteristicaController.clear();
                        },
                        onEditingComplete: () {
                          String novaCaracteristica = _caracteristicaController.text.trim();
                          if (novaCaracteristica.isNotEmpty && !tag.contains(novaCaracteristica)) {
                            setState(() {
                              tag.add(novaCaracteristica);
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
                            label: Text(caract, style: const TextStyle(fontSize: 16)),
                            deleteIcon: const Icon(Icons.highlight_off_outlined, color: Colors.red, size: 20),
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

              // Card para as imagens
// Card para as imagens
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
                width: double.infinity, // Faz a ReorderableWrap ocupar toda a largura
                child: ReorderableWrap(
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      // Atualiza a lista de imagens para refletir a nova ordem
                      final imagem = imagens.removeAt(oldIndex);
                      imagens.insert(newIndex, imagem);
                    });
                  },
                  scrollDirection: Axis.horizontal,
                  children: List.generate(imagens.length, (index) {
                    File imagem = imagens[index];
                    bool isSelected = isZoomed && zoomedIndex == index;

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
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.all(4),
                            width: isSelected ? 250 : 80,
                            height: isSelected ? 250 : 80,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: index == 0 ? Colors.amber : 
                                       (imagemPrincipalIndex == index ? Colors.orange : Colors.grey),
                                width: 3,
                              ),
                              image: DecorationImage(
                                image: FileImage(imagem),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        // Ícone de estrela na primeira imagem
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
    ),
    Positioned(
      bottom: 1,
      right: 2,
      child: IconButton(
        icon: const Icon(Icons.add_a_photo, size: 50, color: Colors.black),
        onPressed: selecionarImagem,
      ),
    ),
  ],
),


              const SizedBox(height: 20),
              // Botão para salvar alterações com o ícone
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: saveTagsImages,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, color: Colors.white, size: 25),
                      SizedBox(width: 8),  // Espaçamento entre o ícone e o texto
                      Text('Salvar', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),
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

}
