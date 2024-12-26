import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart'; // Usando ftpconnect
import 'package:excel/excel.dart';
import 'dart:io';

class InventorySearchPage extends StatefulWidget {
  const InventorySearchPage({super.key});

  @override
  _InventorySearchPage createState() => _InventorySearchPage();
}

class _InventorySearchPage extends State<InventorySearchPage> {
  final TextEditingController _filePathController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filePathController.text = 'ftp://ftp.exemplo.com/'; // Endereço FTP
    _fileNameController.text = 'inventario.xlsx'; // Nome do arquivo
  }

  Future<void> saveExcelToFTP(String ftpUrl, String fileName) async {
    try {
      // 1. Criar planilha Excel
      var excel = Excel.createExcel();
      var sheet = excel['Inventário'];
      bool st_ftp = false;

      // 2. Adicionar cabeçalho e dados
      sheet.appendRow([TextCellValue('ID'), TextCellValue('Nome'), TextCellValue('Quantidade')]);
      sheet.appendRow([IntCellValue(1), TextCellValue('Produto A'), IntCellValue(10)]);
      sheet.appendRow([IntCellValue(2), TextCellValue('Produto B'), IntCellValue(20)]);

      // 3. Gerar os bytes do Excel
      List<int>? bytes = excel.encode();
      if (bytes == null) throw Exception('Erro ao gerar bytes do Excel.');

      // 4. Criar um arquivo temporário
      final tempFile = File('${Directory.systemTemp.path}/$fileName');
      await tempFile.writeAsBytes(bytes);

      // 5. Conectar ao servidor FTP
      final ftpClient = FTPConnect('ftp://177.70.21.15', user: 'oxford', pass: 'Oxf2018!');

      // 6. Conectar e fazer upload
      st_ftp = await ftpClient.connect();
      //await ftpClient.uploadFile(tempFile); // para testar

      if(st_ftp){
        // 7. Feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arquivo salvo com sucesso em $ftpUrl$fileName')),
        );
        await ftpClient.disconnect();
      }
      else{
                ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao conectar ao ftp')),
        );
      }
      // 8. Remover o arquivo temporário após o upload
      await tempFile.delete();
    } catch (e) {
      // Tratamento de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar arquivo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salvar Excel na Rede'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _filePathController,
              decoration: const InputDecoration(
                labelText: 'Endereço FTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fileNameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Arquivo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                saveExcelToFTP(
                  _filePathController.text,
                  _fileNameController.text,
                );
              },
              child: const Text('Salvar Arquivo'),
            ),
          ],
        ),
      ),
    );
  }
}
