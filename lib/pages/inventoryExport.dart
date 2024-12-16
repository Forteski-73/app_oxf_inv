import 'package:app_oxf_inv/operator/db_inventory.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
  ));
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
  String _separator = '.';
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
      _fetchInventoryDetails(context);
    });

    _filePathController.text = r'\\srvapp02\Studio\Publico\arquivo_INV.xlsx';

    for (var field in _fields) {
      _selectedFields[field] = true;
    }
  }

  Future<void> _fetchInventoryDetails(BuildContext context) async {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar os dados: $e')));
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
      var sheet = excel['Inventário'];
      sheet.appendRow([
        'ID', 'Unitizer', 'Position', 'Deposit', 'Block A', 'Block B',
        'Lot', 'Floor', 'Barcode', 'Standard Stack Quantity',
        'Complete Stacks', 'Loose Items', 'Subtotal'
      ]);

      for (var record in inventoryRecords) {
        sheet.appendRow([
          record[DBInventory.columnId],
          record[DBInventory.columnUnitizer],
          record[DBInventory.columnPosition],
          record[DBInventory.columnDeposit],
          record[DBInventory.columnBlockA],
          record[DBInventory.columnBlockB],
          record[DBInventory.columnLot],
          record[DBInventory.columnFloor],
          record[DBInventory.columnBarcode],
          record[DBInventory.columnStandardStackQtd],
          record[DBInventory.columnNumberCompleteStacks],
          record[DBInventory.columnNumberLooseItems],
          record[DBInventory.columnSubTotal]
        ]);
      }

      // Salvar o arquivo Excel
      var directory = await getApplicationDocumentsDirectory();
      if (await directory.exists()) {
        String filePath = join(directory.path, 'arquivo.xlsx');
        var file = File(filePath);
        List<int> bytes = excel.encode() ?? [];
        await file.writeAsBytes(bytes);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Arquivo exportado para: $filePath')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar o arquivo')));
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
