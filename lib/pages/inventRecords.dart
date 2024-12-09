import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:app_oxf_inv/operator/db_settings.dart';

class InventoryRecordsPage extends StatefulWidget {
  const InventoryRecordsPage({super.key});

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryRecordsPage> {
  final Map<String, TextEditingController> _controllers = {};
  List<Map<String, dynamic>> _fields = [];
  bool _isSaveButtonEnabled = false;
  late Future<Map<String, Map<String, dynamic>>> _settingsFuture;

  @override
  void initState() {
    super.initState();
    //_loadFieldsFromDatabase();
    _settingsFuture = _loadSettings();
    //_deleteTable(); 
  }

  Future<void> _deleteTable() async {
    await DBSettings.instance.database.then((db) async {

      await db.execute('DROP TABLE IF EXISTS settings');
      print("Tabela deletada com sucesso");
    });
  }

  Future<void> _loadFieldsFromDatabase() async {
    final results = await DBSettings.instance.queryAllRows();
    
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

//*************************** /
  
  Future<Map<String, Map<String, dynamic>>> _loadSettings() async {
    final rows = await DBSettings.instance.queryAllRows();
    return {
      for (var row in rows) row['nome']: row,
    };
  }

  Widget _buildTextField({
    required String label,
    required bool visible,
    required bool enabled,
    Icon? suffixIcon,
  }) {
    return Visibility(
      visible: visible,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: TextField(
          enabled: enabled,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: suffixIcon,
          ),
        ),
      ),
    );
  }

//********************************************/
  @override
 Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventário XXXXXXX', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, Map<String, dynamic>>>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar configurações.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma configuração encontrada.'));
          }

          final settings = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Campo "Unutilizador"
                _buildTextField(
                  label: 'Unitizador',
                  visible: settings['Unitizador']?['exibir'] == 1,
                  enabled: settings['Unitizador']?['obrigatorio'] == 1,
                  suffixIcon: const Icon(Icons.filter_alt),
                ),
                // Campo "Posição"
                _buildTextField(
                  label: 'Posição',
                  visible: settings['Posição']?['exibir'] == 1,
                  enabled: settings['Posição']?['obrigatorio'] == 1,
                  suffixIcon: const Icon(Icons.filter_alt),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Depósito',
                        visible: settings['Depósito']?['exibir'] == 1,
                        enabled: settings['Depósito']?['obrigatorio'] == 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        label: 'Bloco',
                        visible: settings['Bloco']?['exibir'] == 1,
                        enabled: settings['Bloco']?['obrigatorio'] == 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Quadra',
                        visible: settings['Quadra']?['exibir'] == 1,
                        enabled: settings['Quadra']?['obrigatorio'] == 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        label: 'Lote',
                        visible: settings['Lote']?['exibir'] == 1,
                        enabled: settings['Lote']?['obrigatorio'] == 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  label: 'Andar',
                  visible: settings['Andar']?['exibir'] == 1,
                  enabled: settings['Andar']?['obrigatorio'] == 1,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Código de Barras',
                  visible: settings['Código de Barras']?['exibir'] == 1,
                  enabled: settings['Código de Barras']?['obrigatorio'] == 1,
                  suffixIcon: const Icon(Icons.search),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        label: 'Qtde Padrão da Pilha',
                        visible: settings['Qtde Padrão da Pilha']?['exibir'] == 1,
                        enabled: settings['Qtde Padrão da Pilha']?['obrigatorio'] == 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        label: 'Qtde de Pilhas Completas',
                        visible: settings['Qtde de Pilhas Completas']?['exibir'] == 1,
                        enabled: settings['Qtde de Pilhas Completas']?['obrigatorio'] == 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildTextField(
                  label: 'Qtde de Itens Avulsos',
                  visible: settings['Qtde de Itens Avulsos']?['exibir'] == 1,
                  enabled: settings['Qtde de Itens Avulsos']?['obrigatorio'] == 1,
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
          );
        },
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


  /*Widget _buildInputField(String label, bool isMandatory) {
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
}*/