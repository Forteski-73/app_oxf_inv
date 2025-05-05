import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app_oxf_inv/operator/db_product.dart';
import 'package:csv/csv.dart';
import 'package:app_oxf_inv/widgets/basePage.dart';
import 'package:app_oxf_inv/widgets/customSnackBar.dart';
import 'package:app_oxf_inv/widgets/customButton.dart';


class ImportProduct extends StatefulWidget {
  @override
  _ImportProductPage createState() => _ImportProductPage();
}

class _ImportProductPage extends State<ImportProduct> {
  String? filePath;
  final TextEditingController fileController = TextEditingController();
  bool _isImporting = false;

  Future<void> _pickFile(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );

    if (result != null) {
      setState(() {
        filePath = result.files.single.path;
      });
      
      // Obtém o nome do arquivo, independente do sistema operacional
      fileController.text = filePath!.split(Platform.pathSeparator).last;
    }
  }

  Future<void> _importCsvTxt(BuildContext context) async {
    if (filePath == null) {
      CustomSnackBar.show(context, message: 'Nenhum arquivo selecionado',
        duration: const Duration(seconds: 3),type: SnackBarType.warning,
      );
      return;
    }

    try {
      final file = File(filePath!);
      final input = file.openRead();

      final db = DBItems.instance;
      final RegExp invalidChars = RegExp(r'[^\x20-\x7EÀ-ÖØ-öø-ÿ]'); // Permite ASCII visível e acentos comuns


      setState(() {
        _isImporting = true; // Ativa o carregamento
      });

      if (filePath!.endsWith('.csv')) {
        final fields = await input
            .transform(utf8.decoder)
            .transform(CsvToListConverter(eol: '\n', fieldDelimiter: ';'))
            .toList();

        for (var i = 1; i < fields.length; i++) {
          final row = fields[i].map((e) => e.toString().trim()).toList();

          if (!isValidRow(row, invalidChars)) {
            print("Linha ignorada (caracteres inválidos): $row");
            continue;
          }

          await db.insertProduct({
            DBItems.columnItemBarCode:              row[0],
            DBItems.columnItemId:                   row[1],
            DBItems.columnName:                     row[2],
            DBItems.columnProdBrandId:              row[3],
            DBItems.columnProdBrandDescriptionId:   row[4],
            DBItems.columnProdLinesId:              row[5],
            DBItems.columnProdLinesDescriptionId:   row[6],
            DBItems.columnProdDecorationId:         row[7],
            DBItems.columnProdDecorationDescriptionId: row[8],
            DBItems.columnProdFamilyId:             row[9],
            DBItems.columnProdFamilyDescription:    row[10],
            DBItems.columnUnitVolumeML:             double.tryParse(row[11]) ?? 0.0,
            DBItems.columnItemNetWeight:            double.tryParse(row[12]) ?? 0.0,
            DBItems.columnGrossWeight:              double.tryParse(row[13]) ?? 0.0,
            DBItems.columnTaraWeight:               double.tryParse(row[14]) ?? 0.0,
            DBItems.columnGrossDepth:               double.tryParse(row[15]) ?? 0.0,
            DBItems.columnGrossWidth:               double.tryParse(row[16]) ?? 0.0,
            DBItems.columnGrossHeight:              double.tryParse(row[17]) ?? 0.0,
            DBItems.columnNrOfItems:                double.tryParse(row[18]) ?? 0.0,
            DBItems.columnTaxFiscalClassification:  row[19],
          });
        }
      } else if (filePath!.endsWith('.txt')) {
        final contents = await input.transform(utf8.decoder).join();
        final lines = contents.split('\n');

        for (var line in lines) {
          if (line.trim().isEmpty) continue;

          final row = line.split(';').map((e) => e.trim()).toList();

          if (row.length < 13 || !isValidRow(row, invalidChars)) {
            print("Linha ignorada (inválida ou com caracteres estranhos): $line");
            continue;
          }

          await db.insertProduct({
            DBItems.columnItemBarCode:              row[0],
            DBItems.columnItemId:                   row[1],
            DBItems.columnName:                     row[2],
            DBItems.columnProdBrandId:              row[3],
            DBItems.columnProdBrandDescriptionId:   row[4],
            DBItems.columnProdLinesId:              row[5],
            DBItems.columnProdLinesDescriptionId:   row[6],
            DBItems.columnProdDecorationId:         row[7],
            DBItems.columnProdDecorationDescriptionId: row[8],
            DBItems.columnProdFamilyId:             row[9],
            DBItems.columnProdFamilyDescription:    row[10],
            DBItems.columnUnitVolumeML:             double.tryParse(row[11].replaceAll(',', '.')) ?? 0.0,
            DBItems.columnItemNetWeight:            double.tryParse(row[12].replaceAll(',', '.')) ?? 0.0,
            DBItems.columnGrossWeight:              double.tryParse(row[13].replaceAll(',', '.')) ?? 0.0,
            DBItems.columnTaraWeight:               double.tryParse(row[14].replaceAll(',', '.')) ?? 0.0,
            DBItems.columnGrossDepth:               double.tryParse(row[15].replaceAll(',', '.')) ?? 0.0,
            DBItems.columnGrossWidth:               double.tryParse(row[16].replaceAll(',', '.')) ?? 0.0,
            DBItems.columnGrossHeight:              double.tryParse(row[17].replaceAll(',', '.')) ?? 0.0,
            DBItems.columnNrOfItems:                double.tryParse(row[18].replaceAll(',', '.')) ?? 0.0,
            DBItems.columnTaxFiscalClassification:  row[19],
          });
        }
      } else {
        CustomSnackBar.show(context, message: 'O tipo do arquivo é inválido. Use *.csv ou *.txt',
          duration: const Duration(seconds: 3),type: SnackBarType.warning,
        );
      }

      CustomSnackBar.show(context, message: 'Arquivo ${fileController.text} importado com sucesso!',
        duration: const Duration(seconds: 3),type: SnackBarType.success,
      );

    } catch (e) {
      CustomSnackBar.show(context, message: 'Erro ao importar o arquivo: $e',
        duration: const Duration(seconds: 3),type: SnackBarType.error,
      );
    } finally {
      setState(() {
        _isImporting = false; // Desativa o carregamento
      });
    }
  }

  bool isValidRow(List<String> row, RegExp invalidChars) {
    for (var value in row) {
      if (invalidChars.hasMatch(value)) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: 'Aplicativo de Consulta de Estrutura de Produtos. ACEP',
      subtitle: 'Importar Produtos',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomButton.processButton(
              context,
              "Selecionar arquivo .CSV ou .TXT", // texto
              1, // tamanho (1 = largura total)
              null, // icone (sem ícone no botão original)
              () => _pickFile(context), // função onPressed
              Colors.blue, // cor do botão
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
            CustomButton.processButton(
              context,
              "Importar",
              1,
              null,
              _isImporting ? () {} : () => _importCsvTxt(context),
              filePath != null ? Colors.green : Colors.grey,
              childCustom: _isImporting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(width: 10),
                        Text('Importando..', style: TextStyle(color: Colors.white)),
                      ],
                    )
                  : null,
            )
          ],
        ),
      ),
      floatingButtons: null, // Se desejar, adicione os botões flutuantes aqui
    );
  }
}