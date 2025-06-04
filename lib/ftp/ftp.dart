import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/product_image.dart'; 
import 'package:app_oxf_inv/services/remote/oxfordonlineAPI.dart';
import '../models/product_tag.dart';
import 'package:app_oxf_inv/widgets/customSnackBar.dart';
import 'package:path/path.dart' as path;
import 'package:ftpconnect/ftpconnect.dart';

class FTPUploader {
  final FTPConnect ftpConnect = FTPConnect(
    "ftp.oxfordtec.com.br",
    user: "u700242432.oxfordftp",
    pass: "OxforEstrutur@25",
    timeout: 60,
  );

  Future<void> saveTagsImagesFTP(
    String remoteDir,
    String itemId,
    List<ProductImage> imagens,
    List<ProductTag> tags,
  ) async {
    List<ProductImage> imagesForAPI = [];

    try {
      // Conectar ao FTP e setar tipo binário
      bool changed = await ftpConnect.connect();
      await ftpConnect.setTransferType(TransferType.binary);

      // Ajustar remoteDir para não ter espaços
      remoteDir = remoteDir.replaceAll(" ", "_");
      final parts = remoteDir.split("/");
      String currentPath = "";

      // Tentar trocar para diretório remoto
      changed = await ftpConnect.changeDirectory(remoteDir);
      if (!changed) {
        // Se não existe, criar diretórios hierarquicamente
        for (var part in parts) {
          currentPath = currentPath.isNotEmpty ? "$currentPath/$part" : part;
          try {
            await ftpConnect.makeDirectory(currentPath);
          } catch (_) {
            // Ignorar erro se pasta já existir
          }
        }
        changed = await ftpConnect.changeDirectory(remoteDir);
      }

      // Deletar imagens obsoletas (supondo que esta função esteja correta)
      await deleteObsoleteImages(remoteDir, itemId, imagens);

      // Criar diretório temporário com código do produto
      final tempDir = await getTemporaryDirectory();
      final productTempDir = Directory('${tempDir.path}/$itemId');
      if (!await productTempDir.exists()) {
        await productTempDir.create(recursive: true);
      }

      for (int i = 0; i < imagens.length; i++) {
        File image = File(imagens[i].imagePath);
        File resizedImage = await _resizeImage(image);

        // Log para checar se o resize gerou arquivo válido
        int resizedLength = await resizedImage.length();
        print("Tamanho do arquivo redimensionado: $resizedLength bytes");
        if (resizedLength == 0) {
          throw Exception("Imagem redimensionada está vazia: ${resizedImage.path}");
        }

        String originalName = path.basenameWithoutExtension(resizedImage.path);
        String extension = path.extension(resizedImage.path);

        // Criar novo nome com o padrão correto
        String newFileName = originalName.toUpperCase().startsWith("${itemId}_".toUpperCase())
            ? "$originalName$extension"
            : "${itemId}_${originalName.toUpperCase()}$extension";

        // Copiar arquivo para o diretório temporário específico do produto
        final renamedImage = await resizedImage.copy('${productTempDir.path}/$newFileName');

        int renamedLength = await renamedImage.length();
        
        print("Arquivo temporário criado em: ${renamedImage.path} - tamanho: $renamedLength bytes");
        
        if (renamedLength == 0) {
          throw Exception("Arquivo temporário criado está vazio: ${renamedImage.path}");
        }

        String imagePath = "$remoteDir/$newFileName";

        // Fazer upload para o FTP
        bool uploaded = await ftpConnect.uploadFile(renamedImage);
        if (!uploaded) {
          throw Exception("Falha ao enviar a imagem: $newFileName");
        }

        imagesForAPI.add(
          ProductImage(
            imagePath: imagePath,
            imageSequence: i + 1,
            productId: itemId,
          ),
        );
      }

      // Enviar lista de imagens para API, se houver
      if (imagesForAPI.isNotEmpty) {
        final response = await OxfordOnlineAPI.postImages(imagesForAPI);

        if (response.statusCode == 200) {
          // sucesso
        } else {
          throw Exception('Erro ao enviar imagens para a API: ${response.statusCode}');
        }
      }

      // Enviar tags para API, se houver
      if (tags.isNotEmpty) {
        final tagResponse = await OxfordOnlineAPI.postTags(tags);
        if (tagResponse.statusCode == 200 || tagResponse.statusCode == 201) {
          /*CustomSnackBar.show(
            context,
            message: 'Imagens enviadas com sucesso!',
            duration: const Duration(seconds: 3),
            type: SnackBarType.success,
          );*/
        } else {
          throw Exception("Erro ao enviar tags para a API: ${tagResponse.statusCode}");
        }
      }
    } catch (e) {
      /*CustomSnackBar.show(
        context,
        message: 'Erro ao salvar: $e',
        duration: const Duration(seconds: 4),
        type: SnackBarType.error,
      );*/
      throw Exception("Erro ao salvar: $e");
    } finally {
      await ftpConnect.disconnect();
    }
  }

  Future<void> deleteObsoleteImages(String remoteDir, String itemId, List<ProductImage> images) async {
    /*final changed = await ftpConnect.changeDirectory(remoteDir);
    if (!changed) {
      throw Exception("Diretório remoto $remoteDir não encontrado ou não acessível.");
    }*/

    final remoteFiles = await ftpConnect.listDirectoryContent();

    final expectedNames = images.map((img) {
      String name = path.basename(img.imagePath);
      return name.toUpperCase().startsWith("${itemId}_".toUpperCase())
          ? name
          : "${itemId}_${name.toUpperCase()}";
    }).toList();

    for (var file in remoteFiles) {
      final fileName = file.name ?? '';
      
      if (file.type.toString() == 'FTPEntryType.FILE' && !expectedNames.contains(fileName)) {
        await ftpConnect.deleteFile(fileName);
      }
    }
  }

  Future<File> _resizeImage(File imageFile) async {
    if (!await imageFile.exists()) {
      throw Exception("Arquivo não encontrado: ${imageFile.path}");
    }

    final bytes = await imageFile.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception("Arquivo está vazio: ${imageFile.path}");
    }

    img.Image? originalImage = img.decodeImage(bytes);
    if (originalImage == null) {
      throw Exception("Falha ao carregar imagem");
    }

    const int targetWidth = 500;
    const int targetHeight = 500;

    img.Image resized;

    bool isClose(int value, int target, [int tolerance = 5]) {
      return (value - target).abs() <= tolerance;
    }

    if (isClose(originalImage.width, targetWidth) && isClose(originalImage.height, targetHeight)) {
      resized = originalImage;
    } else {
      resized = img.copyResize(originalImage, width: targetWidth, height: targetHeight);
    }

    final tempDir = await getTemporaryDirectory();
    final resizedImagePath = path.join(tempDir.path, path.basename(imageFile.path));
    final resizedFile = File(resizedImagePath);

    // Se já existir, retorna sem sobrescrever
    if (await resizedFile.exists()) {
      return resizedFile;
    }

    // Caso contrário, salva o redimensionado
    await resizedFile.writeAsBytes(img.encodeJpg(resized, quality: 85));

    return resizedFile;
  }

  bool _isImageFile(String name) {
    final ext = name.toLowerCase();
    return ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.bmp') ||
        ext.endsWith('.webp');
  }

  Future<List<ProductImage>> fetchImagesFromFTP(
    String remoteDir,
    String productId,
    List<ProductImage> imagens, // lista com imagePaths remotos que queremos baixar
    BuildContext context,
  ) async {
    final List<ProductImage> downloadedImages = [];

    try {
      await ftpConnect.connect();
      //await ftpConnect.setTransferType(TransferType.binary);
      await ftpConnect.setTransferType(TransferType.ascii);

      final changed = await ftpConnect.changeDirectory(remoteDir);
      if (!changed) {
        throw Exception("Diretório remoto não encontrado: $remoteDir");
      }

      final tempDir = await createTempProductDirectory(productId); // diretório local temporário

      // Pegamos a lista dos arquivos no FTP, para validar existência
      final files = await ftpConnect.listDirectoryContent();
      final ftpFileNames = files.where((f) => f.type.toString().endsWith('FILE')).map((f) => f.name).toSet();

      int sequence = 1;
      
      await ftpConnect.setTransferType(TransferType.binary);
      // Para cada imagem da lista que você passou, extrair o nome do arquivo e baixar se existir no FTP
      for (final img in imagens) {
        final fileName = path.basename(img.imagePath);

        if (ftpFileNames.contains(fileName)) {
          final localFile = File(path.join(tempDir.path, fileName));

          bool success = await ftpConnect.downloadFile(fileName, localFile);

          if (success) {
            downloadedImages.add(ProductImage(
              imagePath: localFile.path, // caminho local onde foi salvo
              imageSequence: sequence++,
              productId: productId,
            ));
          } else {
            throw Exception("Falha ao baixar arquivo: $fileName");
          }
        } else {
          // Opcional: se o arquivo não existir no FTP, você pode optar por lançar erro ou ignorar
          print("Arquivo $fileName não encontrado no FTP em $remoteDir");
        }
      }

      return downloadedImages;
    } catch (e) {
      CustomSnackBar.show(
        context,
        message: 'Erro ao baixar imagem: $e',
        duration: const Duration(seconds: 3),
        type: SnackBarType.error,
      );
      return [];
    } finally {
      await ftpConnect.disconnect();
    }
  }

  Future<Directory> createTempProductDirectory(String productId) async {
    // Obtém o diretório temporário do app
    final tempDir = await getTemporaryDirectory();

    // Cria o novo caminho com o nome do produto
    final productDirPath = path.join(tempDir.path, productId);

    // Cria a pasta (se não existir)
    final productDir = Directory(productDirPath);
    if (!(await productDir.exists())) {
      await productDir.create(recursive: true); // Cria com permissões adequadas
    }

    return productDir;
  }

}
