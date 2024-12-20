import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
//import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:app_oxf_inv/operator/db_inventory.dart';

class InventoryExportPage extends StatefulWidget {
  final int inventoryId;
  const InventoryExportPage({Key? key, required this.inventoryId}) : super(key: key);

  @override
  _InventoryExportPage createState() => _InventoryExportPage();
}

class _InventoryExportPage extends State<InventoryExportPage> {
  final TextEditingController _fileNameController = TextEditingController();
  final List<String> _fields = [
    'Unitizador', 'Posição', 'Depósito', 'Bloco', 'Quadra', 'Lote', 'Andar', 'Código de Barras', 
    'Qtde Padrão da Pilha', 'Qtde de Pilhas Completas', 'Qtde de Itens Avulsos'
  ];
  final Map<String, bool> _selectedFields = {};
  String _separator = ';';
  final TextEditingController _emailController = TextEditingController();
  bool _exportToEmail = true;
  bool _exportToFilePath = false;
  TextEditingController _filePathController = TextEditingController();
  late DBInventory _dbInventory;
  Map<String, dynamic> _inventory = {};
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dbInventory = DBInventory.instance;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchInventoryDetails();
      }
    });

    // Inicializa os chk box
    for (var field in _fields) {
      _selectedFields[field] = true;
    }
  }

  Future<void> _fetchInventoryDetails() async {
    try {
      final inventoryResult = await _dbInventory.database.then((db) => db.query(
        DBInventory.tableInventory,
        where: '${DBInventory.columnId} = ?',
        whereArgs: [widget.inventoryId],
      ));

      final recordsResult = await _dbInventory.database.then((db) => db.query(
        DBInventory.tableInventoryRecord,
        where: '${DBInventory.columnInventoryId} = ?',
        whereArgs: [widget.inventoryId],
      ));

      setState(() {
        _inventory = inventoryResult.isNotEmpty ? inventoryResult.first : {};
        _records = recordsResult;
        _isLoading = false;

        // Atualiza o nome do arquivo após carregar os dados
        if (_inventory.isNotEmpty) {
          _fileNameController.text = '${_inventory[DBInventory.columnCode] ?? ''}.xlsx';
        }
        _filePathController.text = r'\\srvapp02\Studio\Publico\teste_inventario\';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> exportToExcel(BuildContext context) async {
    try {
      Database db = await DBInventory.instance.database;
      List<Map<String, dynamic>> inventoryRecords = await db.query(
        DBInventory.tableInventoryRecord,
        where: '${DBInventory.columnInventoryId} = ?',
        whereArgs: [widget.inventoryId],
      );

      var excel = Excel.createExcel();
      excel.rename('Sheet1', 'Inventário');
      var sheet = excel['Inventário'];

      // Colunas do cabeçalho
      List<String> selectedHeaders = _fields.where((field) => _selectedFields[field] == true).toList();
      sheet.appendRow(selectedHeaders.map((field) => TextCellValue(field)).toList());

      // Adiciona os registros
      for (var record in inventoryRecords) {
        List<CellValue?> row = [];
        for (var field in selectedHeaders) {
          var value = record[_mapFieldToColumnName(field)];
          if (value is int) {
            row.add(IntCellValue(value));
          } else if (value != null) {
            row.add(TextCellValue(value.toString()));
          } else {
            row.add(null); // Permite valores nulos
          }
        }
        sheet.appendRow(row);
      }

      if (_exportToEmail) {
        await _sendEmailWithAttachment(context, excel.encode());
      } else {
        // Salva o arquivo em pasta
        final Directory directory = Directory(_filePathController.text);
        if (await directory.exists()) {
          String filePath = join(directory.path, _fileNameController.text);
          var file = File(filePath);
          List<int> bytes = excel.encode() ?? [];
          await file.writeAsBytes(bytes);

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Arquivo exportado para: $filePath')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao salvar o arquivo')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar: $e')));
    }
  }

  Future<void> _sendEmailWithAttachment(BuildContext context, List<int>? excelFile) async {
    if (excelFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar o arquivo Excel')));
      return;
    }

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/${_fileNameController.text}';
    final file = File(filePath);
    await file.writeAsBytes(excelFile);

    /*final Email email = Email(
      body: 'Segue o arquivo Excel com os dados do inventário.',
      subject: 'Exportação de Inventário',
      recipients: [_emailController.text],
      attachmentPaths: [filePath],
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email); //diones.forteski@oxfordporcelanas.com.br
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('E-mail enviado com sucesso!')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao enviar e-mail: $e')));
    }*/
  }

  String _mapFieldToColumnName(String field) {
    switch (field) {
      case 'Unitizador':
        return DBInventory.columnUnitizer;
      case 'Posição':
        return DBInventory.columnPosition;
      case 'Depósito':
        return DBInventory.columnDeposit;
      case 'Bloco':
        return DBInventory.columnBlockA;
      case 'Quadra':
        return DBInventory.columnBlockB;
      case 'Lote':
        return DBInventory.columnLot;
      case 'Andar':
        return DBInventory.columnFloor;
      case 'Código de Barras':
        return DBInventory.columnBarcode;
      case 'Qtde Padrão da Pilha':
        return DBInventory.columnStandardStackQtd;
      case 'Qtde de Pilhas Completas':
        return DBInventory.columnNumberCompleteStacks;
      case 'Qtde de Itens Avulsos':
        return DBInventory.columnNumberLooseItems;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Exportação de Dados: ${_inventory[DBInventory.columnId] ?? ''}", style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                margin: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Definição de campos para exportar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ..._fields.map((field) {
                        return CheckboxListTile(
                          title: Text(field),
                          value: _selectedFields[field],
                          onChanged: (bool? value) {
                            setState(() {
                              _selectedFields[field] = value ?? false;
                            });
                          },
                          activeColor: Colors.black,
                          checkColor: Colors.white,
                          tileColor: Colors.white,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 4,
                margin: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Destino do Arquivo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      RadioListTile<bool>(
                        title: TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
                          enabled: _exportToEmail,
                        ),
                        activeColor: Colors.black,
                        tileColor: Colors.white,
                        value: true,
                        groupValue: _exportToEmail,
                        onChanged: (value) {
                          setState(() {
                            _exportToEmail = true;
                            _exportToFilePath = false;
                          });
                        },
                      ),
                      RadioListTile<bool>(
                        title: TextField(
                          controller: _filePathController,
                          decoration: const InputDecoration(labelText: 'Salvar em Pasta na Rede', border: OutlineInputBorder()),
                          enabled: _exportToFilePath,
                        ),
                        activeColor: Colors.black,
                        tileColor: Colors.white,
                        value: true,
                        groupValue: _exportToFilePath,
                        onChanged: (value) {
                          setState(() {
                            _exportToFilePath = true;
                            _exportToEmail = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 15.0),
        child: ElevatedButton(
          onPressed: () {
            exportToExcel(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.open_in_browser, color: Colors.white, size: 24),
              SizedBox(width: 8),
              Text('Exportar Agora', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
