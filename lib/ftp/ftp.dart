import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:ftpconnect/ftpconnect.dart';
import 'package:mysql1/mysql1.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FTPUploader {
  Future<void> saveTagsImages(List<File> imagens, BuildContext context) async {
    
    final ftpConnect = FTPConnect(
      "ftp.oxfordtec1.hospedagemdesites.ws",
      user: "oxfordtec1",
      pass: "OxforEstrutur@25",
      timeout: 60,
    );


    final dbSettings = ConnectionSettings(
      host: 'appprodutos.mysql.dbaas.com.br',
      port: 3306,
      user: 'appprodutos',
      password: 'OxEstrutur@25',
      db: 'appprodutos',
    );

    MySqlConnection? conn;

    //createDatabaseAndTables(dbSettings);

    try {

      await ftpConnect.connect();

      await ftpConnect.setTransferType(TransferType.binary);

      conn = await MySqlConnection.connect(dbSettings);


      String remoteDir = "Familia/Marca/Linha/Decoracao";

      bool changed = await ftpConnect.changeDirectory(remoteDir);
      if (!changed) {
        
        await ftpConnect.makeDirectory(remoteDir);
        await ftpConnect.changeDirectory(remoteDir);
      }


      for (File image in imagens) {
        File resizedImage = await _resizeImage(image);

        String fileName = path.basename(resizedImage.path);
        String imagePath = "$remoteDir/$fileName";

        bool uploaded = await ftpConnect.uploadFile(resizedImage);

        if (uploaded) {
          // Inserir no banco de dados
          await conn.query(
            'INSERT INTO oxford_imagens (caminho) VALUES (?)',
            [imagePath],
          );


        } else {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Falha no upload da imagem.')),);

        }
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
      print("🔌 Desconectado do servidor FTP.");
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

        // Criar banco de dados
        //await conn.query('CREATE DATABASE IF NOT EXISTS oxford;');
        //print("📦 Banco de dados 'oxford' criado ou já existente.");

        // Usar o banco de dados
       // await conn.query('USE oxford;');

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