import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  ConfiguracoesScreenState createState() => ConfiguracoesScreenState();
}

class ConfiguracoesScreenState extends State<SettingsPage> {
  late List<Map<String, dynamic>> campos = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final dbHelper = DBSettings.instance;
    List<Map<String, dynamic>> rows = await dbHelper.querySettingAllRows();

    if (!rows.isNotEmpty) {
      await _insertDefaultValues();
      rows = await dbHelper.querySettingAllRows();
    }

    setState(() {
      campos = List<Map<String, dynamic>>.from(rows);
    });
  }

  Future<void> _insertDefaultValues() async {
    final dbHelper = DBSettings.instance;

    final List<Map<String, dynamic>> defaultValues = [
      {"_id": 1, "nome": "Unitizador", "exibir": 1, "obrigatorio": 0},
      {"_id": 2, "nome": "Posição", "exibir": 1, "obrigatorio": 0},
      {"_id": 3, "nome": "Depósito", "exibir": 1, "obrigatorio": 0},
      {"_id": 4, "nome": "Bloco", "exibir": 1, "obrigatorio": 0},
      {"_id": 5, "nome": "Quadra", "exibir": 1, "obrigatorio": 0},
      {"_id": 6, "nome": "Lote", "exibir": 1, "obrigatorio": 0},
      {"_id": 7, "nome": "Andar", "exibir": 1, "obrigatorio": 0},
      {"_id": 8, "nome": "Código de Barras", "exibir": 1, "obrigatorio": 0},
      {"_id": 9, "nome": "Qtde Padrão da Pilha", "exibir": 1, "obrigatorio": 0},
      {"_id": 10, "nome": "Qtde de Pilhas Completas", "exibir": 1, "obrigatorio": 0},
      {"_id": 11, "nome": "Qtde de Itens Avulsos", "exibir": 1, "obrigatorio": 0},
    ];

    for (var campo in defaultValues) {
      await dbHelper.insertSettings(campo);
    }
  }

  Future<void> _updateField(int id, bool exibir, bool obrigatorio) async {
    final dbHelper = DBSettings.instance;
    await dbHelper.updateSettings({
      DBSettings.columnId: id,
      DBSettings.columnExibir: exibir ? 1 : 0,
      DBSettings.columnObrigatorio: obrigatorio ? 1 : 0,
    });
    loadData();
  }

  Future<void> restoreDefault() async {
    setState(() {
      for (var i = 0; i < campos.length; i++) {
        campos[i] = {
          ...campos[i],
          'exibir': 1,
          'obrigatorio': 0,
        };
      }
    });

    for (var campo in campos) {
      await _updateField(campo['_id'], true, false);
    }
  }

  void _confirmRestoreDefault(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          content: const Text(
            "Deseja mesmo restaurar o padrão?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      restoreDefault();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'SIM',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _showFieldDetailsDialog(BuildContext context, int settingId, String name) async {
    final dbHelper = DBSettings.instance;
    final fieldData = await dbHelper.queryFieldDataTypeSettingsBySettingId(settingId);

    Map<String, dynamic> field  = {};
    String fieldName            = name;
    String fieldType            = "";
    String minSize              = "";
    String maxSize              = "";

    if (fieldData.isNotEmpty) {
      field       = fieldData.first;
      fieldName   = field['field_name'];
      fieldType   = field['field_type'] ?? '';
      minSize     = field['min_size'].toString();
      maxSize     = field['max_size'].toString();
    }

    // Lista para armazenar as linhas do grid (máscaras) e os TextEditingControllers
    List<Map<String, dynamic>>  maskData = [];
    List<TextEditingController> controllers = [];  // Para controlar os campos de texto

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: EdgeInsets.zero, // Remove o padding padrão
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // Sem borda arredondada
          ),
          content: Container(
            width: double.infinity, // A largura vai ocupar toda a tela
            height: double.infinity, // A altura vai ocupar toda a tela
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: TextEditingController(text: fieldName),
                    decoration: const InputDecoration(
                      labelText: "Nome do Campo",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      fieldName = value;
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: fieldType.isNotEmpty ? fieldType : null,
                    decoration: const InputDecoration(
                      labelText: "Tipo",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Numérico',
                        child: Text('Numérico'),
                      ),
                      DropdownMenuItem(
                        value: 'Alfanumérico',
                        child: Text('Alfanumérico'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        fieldType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: minSize),
                    decoration: const InputDecoration(
                      labelText: "Tam. Mínimo",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      minSize = value;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: maxSize),
                    decoration: const InputDecoration(
                      labelText: "Tam. Máximo",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      maxSize = value;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Mini Grid - DataTable
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text("Máscara")),
                        DataColumn(label: Text("Ação")),
                      ],
                      rows: maskData.asMap().map<int, DataRow>((index, mask) {
                        final controller = controllers[index];
                        return MapEntry(
                          index,
                          DataRow(cells: [
                            DataCell(
                              TextField(
                                controller: controller,
                                onChanged: (value) {
                                  mask['mask'] = value;  // Atualiza a máscara
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Digite a Máscara',
                                ),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    maskData.removeAt(index);
                                    controllers.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ]),  
                        );
                      }).values.toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        maskData.add({'mask': '', 'id': null});     // Adiciona nova linha
                        controllers.add(TextEditingController());   // Adiciona controlador para a nova máscara
                      });
                    },
                    child: const Text('Adicionar Máscara'),
                  ),
                ],
              ),
            ),
          ),
          actions: [  // Agora, actions dentro de AlertDialog
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'CANCELAR',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Atualizando os dados na tabela "field_data_type_setting"
                await dbHelper.updateFieldDataTypeSetting({
                  DBSettings.columnId: settingId,
                  DBSettings.columnFieldName: fieldName,
                  DBSettings.columnFieldType: fieldType,
                  DBSettings.columnMinSize: minSize,
                  DBSettings.columnMaxSize: maxSize,
                });

                // Salvando os dados na tabela "mask"
                for (var mask in maskData) {
                  if (mask['mask'] != null && mask['mask']!.isNotEmpty) {
                    await dbHelper.insertMask({
                      DBSettings.columnMask: mask['mask'],
                      DBSettings.columnFieldDataTypeSettingId: settingId,
                    });
                  }
                }
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.blue),
              ),
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
        title: const Text('Configurações', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Campo',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Text(
                        'Exibir',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(width: 25),
                      Text(
                        'Obrigatório',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.separated(
                    itemCount: campos.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final campo = campos[index];
                      return InkWell(
                        onTap: () {
                          _showFieldDetailsDialog(context, campo['_id'], campo['nome']);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(campo['nome'], style: const TextStyle(fontSize: 16)),
                            ),
                            Switch(
                              value: campo['exibir'] == 1,
                              onChanged: (value) {
                                setState(() {
                                  campos[index] = {
                                    ...campo,
                                    'exibir': value ? 1 : 0,
                                  };
                                });
                                _updateField(campo['_id'], value, campo['obrigatorio'] == 1);
                              },
                              activeColor: Colors.green,
                            ),
                            const SizedBox(width: 45),
                            Switch(
                              value: campo['obrigatorio'] == 1,
                              onChanged: (value) {
                                setState(() {
                                  campos[index] = {
                                    ...campo,
                                    'obrigatorio': value ? 1 : 0,
                                  };
                                });
                                _updateField(campo['_id'], campo['exibir'] == 1, value);
                              },
                              activeColor: Colors.green,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      _confirmRestoreDefault(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 30),
                        SizedBox(width: 8),
                        Text("Restaurar Padrão",
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: const SettingsPage(),
  ));
}
