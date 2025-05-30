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

  Future<void> saveTagsImagesFTP(String remoteDir, String itemId, List<ProductImage> imagens, List<ProductTag> tags, BuildContext context) async {
    List<ProductImage> imagesForAPI = [];

    try {

      bool changed = await ftpConnect.connect();
      await ftpConnect.setTransferType(TransferType.binary);

      remoteDir = remoteDir.replaceAll(" ", "_");
      final parts = remoteDir.split("/");
      String currentPath = "";

      changed = await ftpConnect.changeDirectory(remoteDir);
      if (!changed) {
        for (var part in parts) {
          currentPath = currentPath.isNotEmpty ? "$currentPath/$part" : part;
          try {
            await ftpConnect.makeDirectory(currentPath);
          } catch (_) {}
        }
        changed = await ftpConnect.changeDirectory(remoteDir);
      }

      await deleteObsoleteImages(remoteDir, itemId, imagens);

      for (int i = 0; i < imagens.length; i++) {
        File image = File(imagens[i].imagePath);
        File resizedImage = await _resizeImage(image);

        // Obter nome original e extensão
        String originalName = path.basenameWithoutExtension(resizedImage.path);
        String extension = path.extension(resizedImage.path);

        // Novo nome mantendo a extensão original
        String newFileName = originalName.toUpperCase().startsWith("${itemId}_".toUpperCase())
          ? "$originalName$extension"
          : "${itemId}_${originalName.toUpperCase()}$extension";

        // Criar arquivo temporário com novo nome
        final tempDir = await getTemporaryDirectory();
        final renamedImage = await resizedImage.copy('${tempDir.path}/$newFileName');

        String imagePath = "$remoteDir/$newFileName";

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

      if (imagesForAPI.isNotEmpty) {
        final response = await OxfordOnlineAPI.postImages(imagesForAPI);

        if (response.statusCode == 200) {
          // sucesso
        } else {
          throw Exception('Erro ao enviar imagens para a API: ${response.statusCode}');
        }
      }

      if (tags.isNotEmpty) {
        final tagResponse = await OxfordOnlineAPI.postTags(tags);
        if (tagResponse.statusCode == 200 || tagResponse.statusCode == 201) {
        } else {
          throw Exception("Erro ao enviar tags para a API: ${tagResponse.statusCode}");
        }

        CustomSnackBar.show(context, message: 'Imagens enviadas com sucesso!',
          duration: const Duration(seconds: 3),type: SnackBarType.success,
        );
        
      }
    } catch (e) {
      CustomSnackBar.show(context, message: 'Erro ao salvar: $e',
        duration: const Duration(seconds: 4),type: SnackBarType.error,
      );
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

  Future<List<ProductImage>> fetchImagesFromFTP(String remoteDir, String productId, BuildContext context) async {
    final List<ProductImage> images = [];

    try {
      await ftpConnect.connect();
      //await ftpConnect.setTransferType(TransferType.ascii);
      await ftpConnect.setTransferType(TransferType.binary);

      final changed = await ftpConnect.changeDirectory(remoteDir);
      if (!changed) {
        throw Exception("Diretório remoto não encontrado: $remoteDir");
      }

      final files = await ftpConnect.listDirectoryContent();

      await ftpConnect.setTransferType(TransferType.binary);

      final tempDir = await createTempProductDirectory(productId); //await getTemporaryDirectory();
      int sequence = 1;

      for (final file in files) {
        final name = file.name;

        if (file.type.toString().endsWith('FILE') &&
            name != '.' &&
            name != '..' &&
            _isImageFile(name.toLowerCase())) {

          bool success = await ftpConnect.downloadFile(name, File(path.join(tempDir.path, name)));

          if (success) {
            images.add(ProductImage(
              imagePath: path.join(tempDir.path, name),
              imageSequence: sequence++,
              productId: productId,
            ));
          } else {
            throw Exception("Falha definitiva ao baixar arquivo: $name");
          }
        }
      }

      return images;
      
    } catch (e) {
      CustomSnackBar.show(context, message: 'Erro ao baixar imagem: $e',
        duration: const Duration(seconds: 3),type: SnackBarType.error,
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
