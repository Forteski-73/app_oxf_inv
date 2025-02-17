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
  bool _isImporting = false;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum arquivo selecionado", style: TextStyle(fontSize: 18))),
      );
      return;
    }

    setState(() {
      _isImporting = true; // Ativa o carregamento
    });

    try {
      final file = File(filePath!);
      final input = file.openRead();

      final db = DBItems.instance;
      final RegExp invalidChars = RegExp(r'[^\x20-\x7EÀ-ÖØ-öø-ÿ]'); // Permite ASCII visível e acentos comuns

      if (filePath!.endsWith('.csv')) {
        final fields = await input
            .transform(utf8.decoder) // Agora força UTF-8
            .transform(CsvToListConverter(eol: '\n', fieldDelimiter: ';'))
            .toList();

        for (var i = 1; i < fields.length; i++) {
          final row = fields[i].map((e) => e.toString().trim()).toList();

          if (!isValidRow(row, invalidChars)) {
            print("Linha ignorada (caracteres inválidos): $row");
            continue;
          }

          await db.insertProduct({
            DBItems.columnItemBarCode: row[0],
            DBItems.columnItemId: row[1],
            DBItems.columnName: row[2],
            DBItems.columnProdBrandId: row[3],
            DBItems.columnProdBrandDescriptionId: row[4],
            DBItems.columnProdLinesId: row[5],
            DBItems.columnProdLinesDescriptionId: row[6],
            DBItems.columnProdDecorationId: row[7],
            DBItems.columnProdDecorationDescriptionId: row[8],
            DBItems.columnProdFamilyId: row[9],
            DBItems.columnProdFamilyDescription: row[10],
            DBItems.columnUnitVolumeML: double.tryParse(row[11]) ?? 0.0,
            DBItems.columnItemNetWeight: double.tryParse(row[12]) ?? 0.0,
          });
        }
      } else if (filePath!.endsWith('.txt')) {
        final contents = await input.transform(utf8.decoder).join(); // Agora lê .txt como UTF-8
        final lines = contents.split('\n');

        for (var line in lines) {
          if (line.trim().isEmpty) continue;

          final row = line.split(';').map((e) => e.trim()).toList();

          if (row.length < 13 || !isValidRow(row, invalidChars)) {
            print("Linha ignorada (inválida ou com caracteres estranhos): $line");
            continue;
          }

          await db.insertProduct({
            DBItems.columnItemBarCode: row[0],
            DBItems.columnItemId: row[1],
            DBItems.columnName: row[2],
            DBItems.columnProdBrandId: row[3],
            DBItems.columnProdBrandDescriptionId: row[4],
            DBItems.columnProdLinesId: row[5],
            DBItems.columnProdLinesDescriptionId: row[6],
            DBItems.columnProdDecorationId: row[7],
            DBItems.columnProdDecorationDescriptionId: row[8],
            DBItems.columnProdFamilyId: row[9],
            DBItems.columnProdFamilyDescription: row[10],
            DBItems.columnUnitVolumeML: double.tryParse(row[11]) ?? 0.0,
            DBItems.columnItemNetWeight: double.tryParse(row[12]) ?? 0.0,
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("O tipo do arquivo é inválido. Use *.csv ou *.txt", style: TextStyle(fontSize: 18))),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Arquivo ${fileController.text} importado com sucesso!", style: const TextStyle(fontSize: 18))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao importar o arquivo: $e", style: TextStyle(fontSize: 18))),
      );
    } finally {
      setState(() {
        _isImporting = false; // Desativa o carregamento
      });
    }
  }


  /// Método auxiliar para verificar se a linha contém caracteres estranhos
  bool isValidRow(List<String> row, RegExp invalidChars) {
    for (var value in row) {
      if (invalidChars.hasMatch(value)) {
        return false; // Contém caracteres inválidos
      }
    }
    return true; // Linha válida
  }



  // Função para exibir a popup de informações
  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Informações de Layout"),
          content: const Text(
            "Os arquivos suportados para importação são:\n\n"
            "- CSV (com separador `;`)\n"
            "- TXT (com separador `;`)\n\n"
            "Cada linha do arquivo deve ter os seguintes campos:\n"
            "1. Código de barras\n"
            "2. ID do produto\n"
            "3. Nome\n"
            "4. ID da marca\n"
            "5. Descrição da marca\n"
            "6. ID da linha\n"
            "7. Descrição da linha\n"
            "8. ID da decoração\n"
            "9. Descrição da decoração\n"
            "10. ID da família\n"
            "11. Descrição da família\n"
            "12. Volume\n"
            "13. Peso líquido\n",
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
              style: TextStyle(color: Colors.white,fontSize: 12,),
            ),
            SizedBox(height: 2),
            Text('Importar CSV',
              style: TextStyle(color: Colors.white, fontSize: 20, ),
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
              onPressed: _isImporting ? null : _importCsvTxt,
              style: ElevatedButton.styleFrom(
                backgroundColor: filePath != null ? Colors.green : Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isImporting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(width: 10),
                        Text('Importando...', style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : const Text("Importar", style: TextStyle(fontSize: 16, color: Colors.white)),
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