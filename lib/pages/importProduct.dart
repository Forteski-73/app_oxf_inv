import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app_oxf_inv/operator/db_product.dart';
import 'package:csv/csv.dart';

class ImportProduct extends StatefulWidget {
  @override
  _ImportProductPage createState() => _ImportProductPage();
}

class _ImportProductPage extends State<ImportProduct> {
  String? filePath;
  final TextEditingController fileController = TextEditingController();

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'], // Extensões permitidas
    );

    if (result != null) {
      setState(() {
        filePath = result.files.single.path;
        fileController.text = filePath!.split('/').last;  // Para sistemas Unix-like
        fileController.text = fileController.text.split('\\').last;  // Para sistemas Windows
      });
    }
  }

  Future<void> _importCsvTxt() async {
    if (filePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nenhum arquivo selecionado", style: TextStyle(fontSize: 18))),
      );
      return;
    }

    try {
      final file = File(filePath!);
      final input = file.openRead();


  if (filePath!.endsWith('.csv')) {
    final fields = await input
        .transform(utf8.decoder)
        .transform(CsvToListConverter(eol: '\n', fieldDelimiter: ';')) // Definindo o separador como ";"
        .toList();

    final db = DBItems.instance;

    for (var i = 1; i < fields.length; i++) {
      final row = fields[i];
      await db.insertProduct({
        DBItems.columnItemBarCode:                    row[0].toString(),
        DBItems.columnItemId:                         row[1].toString(),
        DBItems.columnName:                           row[2].toString(),
        DBItems.columnProdBrandId:                    row[3].toString(),
        DBItems.columnProdBrandDescriptionId:         row[4].toString(),
        DBItems.columnProdLinesId:                    row[5].toString(),
        DBItems.columnProdLinesDescriptionId:         row[6].toString(),
        DBItems.columnProdDecorationId:               row[7].toString(),
        DBItems.columnProdDecorationDescriptionId:    row[8].toString(),
        DBItems.columnProdFamilyId:                   row[9].toString(),
        DBItems.columnProdFamilyDescription:          row[10].toString(),
        DBItems.columnUnitVolumeML:                   row[11],
        DBItems.columnItemNetWeight:                  row[12],
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Arquivo ${fileController.text} importado com sucesso!", style: TextStyle(fontSize: 18))),
    );
  } 
  else if (filePath!.endsWith('.txt')) { // Arquivo .txt com separação por ";"

    final contents = await input.transform(utf8.decoder).join();

    final db = DBItems.instance;

    final lines = contents.split('\n'); // Divide o conteúdo em linhas
    
    // Percorre as linhas
    for (var line in lines) {
      if (line.trim().isEmpty) continue; // Ignora linhas vazias

      final row = line.split(';');

      if (row.length >= 13) {
        await db.insertProduct({
          DBItems.columnItemBarCode:                  row[0].trim(),
          DBItems.columnItemId:                       row[1].trim(),
          DBItems.columnName:                         row[2].trim(),
          DBItems.columnProdBrandId:                  row[3].trim(),
          DBItems.columnProdBrandDescriptionId:       row[4].trim(),
          DBItems.columnProdLinesId:                  row[5].trim(),
          DBItems.columnProdLinesDescriptionId:       row[6].trim(),
          DBItems.columnProdDecorationId:             row[7].trim(),
          DBItems.columnProdDecorationDescriptionId:  row[8].trim(),
          DBItems.columnProdFamilyId:                 row[9].trim(),
          DBItems.columnProdFamilyDescription:        row[10].trim(),
          DBItems.columnUnitVolumeML:                 double.tryParse(row[11].trim()) ?? 0.0,
          DBItems.columnItemNetWeight:                double.tryParse(row[12].trim()) ?? 0.0,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Linha com formato inválido: $line', style: TextStyle(fontSize: 18))),
        );
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Arquivo ${fileController.text} importado com sucesso!", style: TextStyle(fontSize: 18))),
    );
  }
  else{
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("O tipo do arquivo é inválido. Use *.csv ou *.txt", style: TextStyle(fontSize: 18))),);
  }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao importar o arquivo: $e", style: TextStyle(fontSize: 18))),
      );
    }
  }

  @override
Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Importar CSV',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Selecionar arquivo .CSV ou .TXT", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: fileController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: "Arquivo selecionado",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _importCsvTxt,
              style: ElevatedButton.styleFrom(
                backgroundColor: filePath != null ? Colors.green : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text("Importar", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Oxford Porcelanas",
              style: TextStyle(fontSize: 14),
            ),
            Text(
              "Versão: 1.0",
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

