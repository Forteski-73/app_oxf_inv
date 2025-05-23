import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:app_oxf_inv/services/remote/oxfordonlineAPI.dart';
import 'package:csv/csv.dart';
import 'package:app_oxf_inv/widgets/basePage.dart';
import 'package:app_oxf_inv/widgets/customSnackBar.dart';
import 'package:app_oxf_inv/widgets/customButton.dart';
import '../models/product.dart'; 
import 'package:app_oxf_inv/operator/db_product.dart';


class ImportProduct extends StatefulWidget {
  @override
  _ImportProductPage createState() => _ImportProductPage();
}

class _ImportProductPage extends State<ImportProduct> {
  String? filePath;
  final TextEditingController fileController = TextEditingController();
  bool _isImporting = false;
  bool _isImportingCloud = false;

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
  
  Future<void> _importCsvTxtAPI(BuildContext context) async {

    if (filePath == null) {
      CustomSnackBar.show(context,
        message: 'Nenhum arquivo selecionado',
        duration: const Duration(seconds: 3),
        type: SnackBarType.warning,
      );
      return;
    }

    try {
      final file = File(filePath!);
      final input = file.openRead();
      final RegExp invalidChars = RegExp(r'[^\x20-\x7EÀ-ÖØ-öø-ÿ]');
      List<Product> products = [];

      setImporting(cloud: true, local: false);

      if (filePath!.endsWith('.csv')) {
        final fields = await input
            .transform(utf8.decoder)
            .transform(CsvToListConverter(eol: '\n', fieldDelimiter: ';'))
            .toList();

        for (var i = 1; i < fields.length; i++) {
          final row = fields[i].map((e) => e.toString().trim()).toList();
          if (!isValidRow(row, invalidChars)) continue;
          products.add(_mapRowToProduct(row));
        }
      } else if (filePath!.endsWith('.txt')) {
        final contents = await input.transform(utf8.decoder).join();
        final lines = contents.split('\n');

        for (var line in lines) {
          if (line.trim().isEmpty) continue;

          final row = line.split(';').map((e) => e.trim()).toList();
          if (row.length < 20 || !isValidRow(row, invalidChars)) continue;
          products.add(_mapRowToProduct(row));
        }
      } else {
        CustomSnackBar.show(context,
          message: 'O tipo do arquivo é inválido. Use *.csv ou *.txt',
          duration: const Duration(seconds: 3),
          type: SnackBarType.warning,
        );
        return;
      }

      bool allSuccessful = true;
      for (int i = 0; i < products.length; i += 1000) {
        final batch = products.sublist(i, i + 1000 > products.length ? products.length : i + 1000);
        final response = await OxfordOnlineAPI.postProducts(batch);

        if (response.statusCode != 200 && response.statusCode != 201) {
          CustomSnackBar.show(context,
            message: 'Erro na API (lote ${i ~/ 1000 + 1}): ${response.statusCode}\n${response.body}',
            duration: const Duration(seconds: 10),
            type: SnackBarType.error,
          );
          allSuccessful = false;
          break;
        }
      }

      if (allSuccessful) {
        CustomSnackBar.show(context,
          message: 'Importação finalizada com sucesso!',
          duration: const Duration(seconds: 10),
          type: SnackBarType.success,
        );
      }

    } catch (e) {
      CustomSnackBar.show(context,
        message: 'Erro: $e',
        duration: const Duration(seconds: 10),
        type: SnackBarType.error,
      );
    } finally {
      setImporting(cloud: false, local: false);
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


      setImporting(cloud: false, local: true);

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
            DBItems.columnItemBarCode:                  row[0],
            DBItems.columnItemId:                       row[1],
            DBItems.columnName:                         row[2],
            DBItems.columnProdBrandId:                  row[3],
            DBItems.columnProdBrandDescriptionId:       row[4],
            DBItems.columnProdLinesId:                  row[5],
            DBItems.columnProdLinesDescriptionId:       row[6],
            DBItems.columnProdDecorationId:             row[7],
            DBItems.columnProdDecorationDescriptionId:  row[8],
            DBItems.columnProdFamilyId:                 row[9],
            DBItems.columnProdFamilyDescriptionId:      row[10],
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
            DBItems.columnProdDecorationDescriptionId:  row[8],
            DBItems.columnProdFamilyId:                 row[9],
            DBItems.columnProdFamilyDescriptionId:      row[10],
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
      setImporting(cloud: false, local: false);
    }
  }
  
  Product _mapRowToProduct(List<String> row) {
    double parseDouble(String val) =>
        double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
    return Product(
      itemBarCode:                  row[0],
      itemId:                       row[1],
      name:                         row[2],
      prodBrandId:                  row[3],
      prodBrandDescriptionId:       row[4],
      prodLinesId:                  row[5],
      prodLinesDescriptionId:       row[6],
      prodDecorationId:             row[7],
      prodDecorationDescriptionId:  row[8],
      prodFamilyId:                 row[9],
      prodFamilyDescriptionId:      row[10].isEmpty ? '' : row[10],
      unitVolumeML:                 parseDouble(row[11]),
      itemNetWeight:                parseDouble(row[12]),
      prodGrossWeight:              parseDouble(row[13]),
      prodTaraWeight:               parseDouble(row[14]),
      prodGrossDepth:               parseDouble(row[15]),
      prodGrossWidth:               parseDouble(row[16]),
      prodGrossHeight:              parseDouble(row[17]),
      prodNrOfItems:                parseDouble(row[18]),
      prodTaxFiscalClassification:  row[19],
    );
  }

  bool isValidRow(List<String> row, RegExp invalidChars) {
    for (var value in row) {
      if (invalidChars.hasMatch(value)) {
        return false;
      }
    }
    return true;
  }

  void setImporting({bool cloud = false, bool local = false}) {
    setState(() {
      _isImporting = local;
      _isImportingCloud = cloud;
    });
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
              "Selecionar arquivo .CSV ou .TXT",
              1, // tamanho (1 = largura total)
              null, // icone (sem ícone no botão original)
              () => _pickFile(context), // função onPressed
              Colors.blue,
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
              "Importar no dispositivo local",
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
            ),
            const SizedBox(height: 20),
            CustomButton.processButton(
              context,
              "Importar para a nuvem",
              1,
              null,
              _isImportingCloud ? () {} : () => _importCsvTxtAPI(context),
              filePath != null ? Colors.green : Colors.grey,
              childCustom: _isImportingCloud
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
      floatingButtons: null,
    );
  }
}