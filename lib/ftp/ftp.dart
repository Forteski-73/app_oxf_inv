import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:ftpconnect/ftpconnect.dart';
import 'package:mysql1/mysql1.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/product_image.dart'; 
import 'package:app_oxf_inv/services/remote/oxfordonlineAPI.dart';
import 'package:ftpconnect/ftpconnect.dart';
import '../models/product_tag.dart';

class FTPUploader {

  final ftpConnect = FTPConnect(
    "ftp.oxfordtec.com.br",
    user: "u700242432.oxfordftp",
    pass: "OxforEstrutur@25",
    timeout: 60,
  );

  Future<void> saveTagsImagesFTP(String remoteDir, String itemId, List<File> imagens, List<ProductTag> tags, BuildContext context) async {
    /*final ftpConnect = FTPConnect(
      "ftp.oxfordtec.com.br",
      user: "u700242432.oxfordftp",
      pass: "OxforEstrutur@25",
      timeout: 60,
    );*/

    final dbSettings = ConnectionSettings(
      host: '193.203.175.198',
      port: 3306,
      user: 'u700242432_appprodutos',
      password: 'OxEstrutur@25',
      db: 'u700242432_appprodutos',
    );

    List<ProductImage> imagesForAPI = [];
    MySqlConnection? conn;

    try {
      //conn = await MySqlConnection.connect(dbSettings);

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

          } catch (_) {
            // Diretório já pode existir, ignore o erro
          }
        }
        changed = await ftpConnect.changeDirectory(remoteDir);
      }

      for (int i = 0; i < imagens.length; i++) {
        File image = imagens[i];
        File resizedImage = await _resizeImage(image);

        String fileName = path.basename(resizedImage.path);
        String imagePath = "$remoteDir/$fileName";

        bool uploaded = await ftpConnect.uploadFile(resizedImage);

        imagesForAPI.add(
          ProductImage(
            //imageId: 0,
            imagePath: imagePath,
            imageSequence: i + 1,
            productId: itemId,
          ),
        );
      }

      final response = await OxfordOnlineAPI.postImages(imagesForAPI);

      if (response.statusCode == 200) {
        debugPrint('Imagens enviadas com sucesso para a API');
      } else {
        debugPrint('Erro ao enviar imagens para a API: ${response.statusCode}');
      }

      // Envia tags para a API
      final tagResponse = await OxfordOnlineAPI.postTags(tags);
      if (tagResponse.statusCode == 200 || tagResponse.statusCode == 201) {
        debugPrint('🏷️ Tags enviadas com sucesso para a API.');
      } else {
        debugPrint('❌ Erro ao enviar tags para a API: ${tagResponse.statusCode}');
        debugPrint('Body: ${tagResponse.body}');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Imagens enviadas com sucesso! 📸')),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar imagens: $e')),
      );
    } finally {
      await ftpConnect.disconnect();
      if (conn != null) {
        await conn.close();
      }
      debugPrint("🔌 Desconectado do servidor FTP e banco de dados.");
    }
  }
    
  Future<bool> sendTagsToAPI(String productId, List<String> tags) async {
    try {
      // Cria lista de ProductTag com base nas tags e no productId informado
      List<ProductTag> productTags = tags.map((tag) => ProductTag(tag: tag, productId: productId)).toList();

      // Envia para a API
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
      return false;
    }
  }


  Future<File> _resizeImage(File imageFile) async {
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


    Future<void> createDatabaseAndTables(ConnectionSettings settings) async {
      MySqlConnection? conn;

      try {
        print("🔄 Conectando ao MySQL...");
        conn = await MySqlConnection.connect(settings);
        print("✅ Conectado!");

        // Criar tabela oxf_item
        await conn.query('''
          CREATE TABLE IF NOT EXISTS oxf_item ( 
            id INT AUTO_INCREMENT PRIMARY KEY,
            item VARCHAR(20) NOT NULL UNIQUE, 
            qr_code VARCHAR(20) NOT NULL UNIQUE,
            description VARCHAR(255),
            create_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          );
        ''');
        print("📋 Tabela 'oxf_item' criada.");

        // Criar índice para item e qr_code
        await conn.query('CREATE INDEX idx_item_qr_code ON oxf_item(item, qr_code);');

        // Criar tabela oxf_image
        await conn.query('''
          CREATE TABLE IF NOT EXISTS oxf_image ( 
            id INT AUTO_INCREMENT PRIMARY KEY,
            item_id INT NOT NULL,
            path VARCHAR(255) NOT NULL UNIQUE, 
            update_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            FOREIGN KEY (item_id) REFERENCES oxf_item(id) ON DELETE CASCADE ON UPDATE CASCADE
          );
        ''');
        

        // Criar índice para item_id
        await conn.query('CREATE INDEX idx_item_id ON oxf_image(item_id);');

        print("✅ Estrutura do banco de dados criada com sucesso!");
      } catch (e) {
        print("❌ Erro ao criar banco de dados: $e");
      } finally {
        await conn?.close();
        print("🔌 Conexão encerrada.");
      }
    }
  
  Future<List<File>> fetchImagesFromFTP(String remoteDir) async {

    List<File> localImages = [];

    try {
      print("🔄 Conectando ao servidor FTP para baixar imagens...");
      await ftpConnect.connect();
      await ftpConnect.setTransferType(TransferType.binary);

      final changed = await ftpConnect.changeDirectory(remoteDir);
      if (!changed) {
        throw Exception("❌ Diretório remoto não encontrado: $remoteDir");
      }

      final files = await ftpConnect.listDirectoryContent();
      final imageFiles = files.where((f) => _isImageFile(f.name)).toList();

      final tempDir = await getTemporaryDirectory();

      for (final file in imageFiles) {
        final localFile = File(path.join(tempDir.path, file.name));
        final success = await ftpConnect.downloadFile(file.name, localFile);

        if (success) {
          localImages.add(localFile);
          print("✅ Imagem baixada: ${file.name}");
        } else {
          print("⚠️ Falha ao baixar imagem: ${file.name}");
        }
      }
    } catch (e) {
      print("❌ Erro ao buscar imagens no FTP: $e");
    } finally {
      await ftpConnect.disconnect();
      print("🔌 Desconectado do servidor FTP.");
    }

    return localImages;
  }

  bool _isImageFile(String filename) {
    final lower = filename.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png') || lower.endsWith('.gif');
  }


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

 /*
      print("📂 Diretório remoto definido: $remoteDir");
      print("📁 Diretório não encontrado. Criando...");
      print("✅ Conexão com MySQL estabelecida.");
      print("✅ Modo de transferência binário ativado.");
      print("🔄 Conectando ao servidor FTP...");
      print("🔄 Conectando ao banco de dados...");
      print("✅ Upload concluído: ${resizedImage.path}");
      print("⬆️ Enviando imagem: ${resizedImage.path}");
      print("📉 Reduzindo a resolução da imagem: ${image.path}");
      print("📁 Diretório não encontrado. Criando...");
      print("❌ Erro ao enviar imagens: $e");
      print("📝 Caminho salvo no MySQL: $imagePath");
      print("📷 Tabela 'oxf_image' criada.");
 */

}