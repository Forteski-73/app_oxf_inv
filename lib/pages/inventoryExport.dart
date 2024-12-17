import 'package:app_oxf_inv/operator/db_inventory.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(MaterialApp(debugShowCheckedModeBanner: false,));
}

class InventoryExportPage extends StatefulWidget {
  final int inventoryId;
  const InventoryExportPage({Key? key, required this.inventoryId}) : super(key: key);

  @override
  _InventoryExportPage createState() => _InventoryExportPage();
}

class _InventoryExportPage extends State<InventoryExportPage> {
  final TextEditingController _fileNameController = TextEditingController();
  final List<String> _fields = [
    'Unitizador', 'Posição', 'Depósito', 'Bloco', 'Quadra', 'Lote',
    'Andar', 'Código de Barras', 'Qtde Padrão da Pilha', 'Qtde de Pilhas Completas',
    'Qtde de Itens Avulsos'
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

  _filePathController.text = r'\\srvapp02\Studio\Publico\';

  // Initialize selected fields to true
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
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      //ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar os dados: $e')));
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

      sheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('Unitizer'),
        TextCellValue('Position'),
        TextCellValue('Deposit'),
        TextCellValue('Block A'),
        TextCellValue('Block B'),
        TextCellValue('Lot'),
        TextCellValue('Floor'),
        TextCellValue('Barcode'),
        TextCellValue('Standard Stack Quantity'),
        TextCellValue('Complete Stacks'),
        TextCellValue('Loose Items'),
        TextCellValue('Subtotal'),
      ]);

      for (var record in inventoryRecords) {
        sheet.appendRow([
          IntCellValue(record[DBInventory.columnId] as int),
          TextCellValue(record[DBInventory.columnUnitizer] as String),
          TextCellValue(record[DBInventory.columnPosition] as String),
          TextCellValue(record[DBInventory.columnDeposit] as String),
          TextCellValue(record[DBInventory.columnBlockA] as String),
          TextCellValue(record[DBInventory.columnBlockB] as String),
          TextCellValue(record[DBInventory.columnLot] as String),
          IntCellValue(record[DBInventory.columnFloor] as int),
          TextCellValue(record[DBInventory.columnBarcode] as String),
          IntCellValue( record[DBInventory.columnStandardStackQtd] as int),
          IntCellValue(record[DBInventory.columnNumberCompleteStacks] as int),
          IntCellValue(record[DBInventory.columnNumberLooseItems] as int),
          IntCellValue(record[DBInventory.columnSubTotal] as int)
        ]);
      }

      // Salvar o arquivo Excel
      //var directory = await getApplicationDocumentsDirectory();
      final Directory directory = Directory(_filePathController.text);
      if (await directory.exists()) {
        String filePath = join(directory.path, 'Inventario_${widget.inventoryId}.xlsx');
        var file = File(filePath);
        List<int> bytes = excel.encode() ?? [];
        await file.writeAsBytes(bytes);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Arquivo exportado para: $filePath')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao salvar o arquivo')));
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao exportar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Exportação de Dados: ${_inventory[DBInventory.columnId] ?? ''}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome do arquivo
              Card(
                elevation: 4,
                margin: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _fileNameController,
                    decoration: const InputDecoration(
                      labelText: 'Defina o nome do arquivo',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Campos para exportar
              Card(
                elevation: 4,
                margin: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Definição de campos para exportar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      ..._fields.map((field) {
                        return CheckboxListTile(
                          title: Text(
                            field,
                            style: const TextStyle(color: Colors.black),
                          ),
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
              const SizedBox(height: 16),

              // Destino do arquivo
              Card(
                elevation: 4,
                color: Colors.white,
                margin: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Destino do arquivo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      RadioListTile<bool>(
                        title: TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            border: OutlineInputBorder(),
                          ),
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
                          decoration: const InputDecoration(
                            labelText: 'Salvar em Pasta na Rede',
                            border: OutlineInputBorder(),
                          ),
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
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    exportToExcel(context);
                  },
                  child: const Text(
                    'Exportar Agora',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(double.infinity, 50),
                    padding: const EdgeInsets.all(10),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Oxford Porcelanas", style: TextStyle(fontSize: 14)),
            Text("Versão: 1.0", style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
