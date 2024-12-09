import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class InventoryRecordsPage extends StatefulWidget {
  const InventoryRecordsPage({super.key});

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryRecordsPage> {
  final Map<String, TextEditingController> _controllers = {};
  List<Map<String, dynamic>> _fields = [];
  bool _isSaveButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadFieldsFromDatabase();
  }

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();
    return openDatabase(
      join(databasePath, 'settings.db'),
      onCreate: (db, version) async {
        await db.execute(
          '''CREATE TABLE IF NOT EXISTS settings (
            id INTEGER PRIMARY KEY,
            nome TEXT NOT NULL,
            exibir INTEGER NOT NULL,
            obrigatorio INTEGER NOT NULL
          )''',
        );
      },
      version: 1,
    );
  }

  Future<void> _loadFieldsFromDatabase() async {
    final db = await _openDatabase();
    final results = await db.query('settings');

    setState(() {
      _fields = results.where((row) => row['exibir'] == 1).toList();
      for (var field in _fields) {
        _controllers[field['nome']] = TextEditingController();
      }
    });
  }

  void _checkMandatoryFields() {
    bool allMandatoryFilled = true;

    for (var field in _fields) {
      if (field['obrigatorio'] == 1 &&
          (_controllers[field['nome']]?.text.isEmpty ?? true)) {
        allMandatoryFilled = false;
        break;
      }
    }

    setState(() {
      _isSaveButtonEnabled = allMandatoryFilled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inventário - INV-20241202-001',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Método de pesquisa
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Total de Registros: ${_fields.length}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _fields.length,
                itemBuilder: (context, index) {
                  final field = _fields[index];
                  return _buildInputField(field['nome'], field['obrigatorio'] == 1);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // Limpar campos
                    for (var controller in _controllers.values) {
                      controller.clear();
                    }
                    _checkMandatoryFields();
                  },
                  child: const Text('LIMPAR'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isSaveButtonEnabled ? Colors.blue : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isSaveButtonEnabled
                      ? () {
                          // Gravar ação
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Dados salvos!')),
                          );
                        }
                      : null,
                  child: const Text('GRAVAR'),
                ),
              ],
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

  Widget _buildInputField(String label, bool isMandatory) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _controllers[label],
        onChanged: (value) => _checkMandatoryFields(),
        decoration: InputDecoration(
          labelText: label + (isMandatory ? ' *' : ''),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}