import 'package:flutter/material.dart';
import '../models/product.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:reorderables/reorderables.dart';
import 'package:app_oxf_inv/operator/db_product.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path/path.dart' as path;

class FTPUploader {
  Future<void> saveTagsImages(List<File> imagens, BuildContext context) async {
    final ftpConnect = FTPConnect(
      "ftp.oxfordtec.com.br",
      user: "oxfordtec1",
      pass: "OxforEstrutur@25",
      timeout: 60,
    );

    try {
      await ftpConnect.connect();

      String remoteDir = "Familia/Marca/Linha/Decoracao"; // Ajuste conforme necessário

      // Tenta mudar para o diretório, se falhar, cria
      bool changed = await ftpConnect.changeDirectory(remoteDir);
      if (!changed) {
        await ftpConnect.makeDirectory(remoteDir);
        await ftpConnect.changeDirectory(remoteDir);
      }

      for (File image in imagens) {
        await ftpConnect.uploadFile(image);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imagens enviadas para o servidor com sucesso.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar imagens para o servidor: $e')),
      );
    } finally {
      await ftpConnect.disconnect();
    }
  }
}