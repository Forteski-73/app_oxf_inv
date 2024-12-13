import 'package:app_oxf_inv/operator/db_inventory.dart';
import 'package:flutter/material.dart';

  void main() {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      //theme: ThemeData.dark(), 
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
    'Unitizador',
    'Posição',
    'Depósito',
    'Bloco',
    'Quadra',
    'Lote',
    'Andar',
    'Código de Barras',
    'Qtde Padrão da Pilha',
    'Qtde de Pilhas Completas',
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
    _fetchInventoryDetails();

    _filePathController.text = r'\\vmfs\ERP\RFID-Coletor\Inventarios\arquivo.xlsx';
    for (var field in _fields) {
      _selectedFields[field] = true;
    }
  }

  Future<void> _fetchInventoryDetails() async {
    try {
      // Buscar os detalhes do inventário
      final inventoryResult = await _dbInventory.database.then((db) => db.query(
            DBInventory.tableInventory,
            where: '${DBInventory.columnId} = ?',
            whereArgs: [widget.inventoryId],
          ));

      // Buscar os registros do inventário
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar os dados: $e')),
      );
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
              // Card para o nome do arquivo
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
                      //labelStyle: TextStyle(color: Colors.black),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      /*focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2.0),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),*/
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: const TextStyle(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card para definição de campos
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

              // Card para separador de campos
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
                        'Separador de campos',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      RadioListTile<String>(
                        title: const Text('Ponto (.)'),
                        activeColor: Colors.black,
                        tileColor: Colors.white,
                        value: '.',
                        groupValue: _separator,
                        onChanged: (value) {
                          setState(() {
                            _separator = value ?? '.';
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Vírgula (,)'),
                        activeColor: Colors.black,
                        tileColor: Colors.white,
                        value: ',',
                        groupValue: _separator,
                        onChanged: (value) {
                          setState(() {
                            _separator = value ?? ',';
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Ponto e vírgula (;)'),
                        activeColor: Colors.black,
                        tileColor: Colors.white,
                        value: ';',
                        groupValue: _separator,
                        onChanged: (value) {
                          setState(() {
                            _separator = value ?? ';';
                          });
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Tabulação'),
                        activeColor: Colors.black,
                        tileColor: Colors.white,
                        value: '\t',
                        groupValue: _separator,
                        onChanged: (value) {
                          setState(() {
                            _separator = value ?? '\t';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card para destino do arquivo
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
                          enabled: _exportToEmail, // Habilita o campo se o E-mail for selecionado
                        ),
                        activeColor: Colors.black,
                        tileColor: Colors.white,
                        value: true,
                        groupValue: _exportToEmail, // Controla a seleção do radio
                        onChanged: (value) {
                          setState(() {
                            _exportToEmail = true; // Marca o E-mail como selecionado
                            _exportToFilePath = false; // Desmarca "Salvar em Pasta na Rede"
                          });
                        },
                      ),
                      RadioListTile<bool>(
                        title: TextField(
                          controller: _filePathController, // Associado ao controlador para valor
                          decoration: const InputDecoration(
                            labelText: 'Salvar em Pasta na Rede',
                            border: OutlineInputBorder(),
                          ),
                          enabled: _exportToFilePath, // Habilita o campo se "Salvar em Pasta na Rede" for selecionado
                        ),
                        activeColor: Colors.black,
                        tileColor: Colors.white,
                        value: true,
                        groupValue: _exportToFilePath, // Controla a seleção do radio
                        onChanged: (value) {
                          setState(() {
                            _exportToFilePath = true; // Marca "Salvar em Pasta na Rede" como selecionado
                            _exportToEmail = false; // Desmarca o E-mail
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center, 
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Lógica para salvar
                      },
                      child: const Text(
                        'Salvar Configurações',
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
                    const SizedBox(height: 16), // Espaço entre os botões
                    ElevatedButton(
                      onPressed: () {
                        // Lógica para exportar
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
                  ],
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