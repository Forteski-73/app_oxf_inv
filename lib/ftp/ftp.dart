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

class FTPUploader {
  final FTPConnect ftpConnect = FTPConnect(
    "ftp.oxfordtec.com.br",
    user: "u700242432.oxfordftp",
    pass: "OxforEstrutur@25",
    timeout: 60,
  );

  Future<void> saveTagsImagesFTP(String remoteDir, String itemId, List<File> imagens, List<ProductTag> tags, BuildContext context) async {
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

      for (int i = 0; i < imagens.length; i++) {
        File image = imagens[i];
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

      final response = await OxfordOnlineAPI.postImages(imagesForAPI);

      if (response.statusCode == 200) {
      } else {
        throw Exception('Erro ao enviar imagens para a API: ${response.statusCode}');
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

  /*
  Future<bool> sendTagsToAPI(String productId, List<String> tags, BuildContext context) async {
    try {
      List<ProductTag> productTags = tags.map((tag) => ProductTag(tag: tag, productId: productId)).toList();
      final response = await OxfordOnlineAPI.postTags(productTags);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Tags enviadas para API com sucesso.');
        return true;
      } else {
        print('Erro ao enviar tags para API. Status: ${response.statusCode}');
        print('Resposta: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Erro ao enviar tags para API: $e');
      CustomSnackBar.show(context, message: 'Erro ao salvar: $e',
        duration: const Duration(seconds: 4),type: SnackBarType.error,
      );
      return false;
    }
  }
  */

  Future<File> _resizeImage(File imageFile) async {

    if (!await imageFile.exists()) {
      throw Exception("Arquivo não encontrado: ${imageFile.path}");
    }

    final bytes = await imageFile.readAsBytes();
    img.Image? originalImage = img.decodeImage(bytes);
    if (originalImage == null) {
      throw Exception("Falha ao carregar imagem");
    }

    img.Image resized = img.copyResize(originalImage, width: 500, height: 500);

    final tempDir = await getTemporaryDirectory();
    final resizedImagePath = path.join(tempDir.path, path.basename(imageFile.path));
    File resizedFile = File(resizedImagePath)..writeAsBytesSync(img.encodeJpg(resized, quality: 85));

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
      await ftpConnect.setTransferType(TransferType.ascii);

      final changed = await ftpConnect.changeDirectory(remoteDir);
      if (!changed) {
        throw Exception("Diretório remoto não encontrado: $remoteDir");
      }

      final files = await ftpConnect.listDirectoryContent();

      await ftpConnect.setTransferType(TransferType.binary);

      final tempDir = await getTemporaryDirectory();
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

  /*
  List<ProductImage> toProductImageList(List<File> files, String itemId, String remoteDir) {
    return List.generate(files.length, (index) {
      final fileName = path.basename(files[index].path);
      return ProductImage(
        imagePath: "$remoteDir/$fileName",
        imageSequence: index + 1,
        productId: itemId,
      );
    });
  }
  */
  /*
  Future<File?> downloadImageToLocal(String remoteFilePath) async {
    try {
      print("🔄 Conectando ao FTP para baixar imagem: $remoteFilePath");
      await ftpConnect.connect();
      await ftpConnect.setTransferType(TransferType.binary);

      final directory = path.dirname(remoteFilePath);
      final fileName = path.basename(remoteFilePath);

      final changed = await ftpConnect.changeDirectory(directory);
      if (!changed) {
        throw Exception("❌ Diretório remoto não encontrado: $directory");
      }

      final tempDir = await getTemporaryDirectory();
      final localFile = File(path.join(tempDir.path, fileName));

      final success = await ftpConnect.downloadFile(fileName, localFile);
      if (success) {
        print("✅ Imagem baixada com sucesso: $fileName");
        return localFile;
      } else {
        print("⚠️ Falha ao baixar imagem: $fileName");
        return null;
      }
    } catch (e) {
      print("❌ Erro ao baixar imagem do FTP: $e");
      return null;
    } finally {
      await ftpConnect.disconnect();
      print("🔌 Conexão com o FTP encerrada.");
    }
  }
  */
}
