import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_settings.dart';
import 'package:app_oxf_inv/widgets/basePage.dart';
import 'package:app_oxf_inv/widgets/customButton.dart';
import 'package:app_oxf_inv/widgets/customSnackBar.dart';

  class SettingsPage extends StatefulWidget {
    final int profileId;

    const SettingsPage({super.key, required this.profileId});

    @override
    ConfiguracoesScreenState createState() => ConfiguracoesScreenState();
  }

class ConfiguracoesScreenState extends State<SettingsPage> {
  late List<Map<String, dynamic>> campos = [];
  
  List<Map<String, dynamic>> maskData = [];
  List<TextEditingController> controllers = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final dbHelper = DBSettings.instance;
    List<Map<String, dynamic>> rows = await dbHelper.querySettingAllRows(widget.profileId); 

    if (!rows.isNotEmpty) {
      await _insertDefaultValues(widget.profileId);
      rows = await dbHelper.querySettingAllRows(widget.profileId);
    }

    setState(() {
      campos = List<Map<String, dynamic>>.from(rows);
    });
  }

  Future<void> _insertDefaultValues(int profileId) async {
    final dbHelper = DBSettings.instance;
    
    final List<Map<String, dynamic>> defaultValues = [
      {"sequence": 1, "nome": "Unitizador",  "exibir": 1, "obrigatorio": 0, "profile_id": profileId},
      {"sequence": 2, "nome": "Posição",     "exibir": 1, "obrigatorio": 0, "profile_id": profileId},
      {"sequence": 3, "nome": "Depósito",    "exibir": 1, "obrigatorio": 0, "profile_id": profileId},
      {"sequence": 4, "nome": "Bloco",       "exibir": 1, "obrigatorio": 0, "profile_id": profileId},
      {"sequence": 5, "nome": "Quadra",      "exibir": 1, "obrigatorio": 0, "profile_id": profileId},
      {"sequence": 6, "nome": "Lote",        "exibir": 1, "obrigatorio": 0, "profile_id": profileId},
      {"sequence": 7, "nome": "Andar",       "exibir": 1, "obrigatorio": 0, "profile_id": profileId},
      {"sequence": 8, "nome": "Código de Barras",          "exibir": 1, "obrigatorio": 0, "profile_id": profileId},
      {"sequence": 9, "nome": "Qtde Padrão da Pilha",      "exibir": 1, "obrigatorio": 0, "profile_id": profileId},
      {"sequence": 10, "nome": "Qtde de Pilhas Completas", "exibir": 1, "obrigatorio": 0, "profile_id": profileId},
      {"sequence": 11, "nome": "Qtde de Itens Avulsos",    "exibir": 1, "obrigatorio": 0, "profile_id": profileId},
    ];

    for (var campo in defaultValues) {
      await dbHelper.insertSettings(campo); 
    }
  }

  Future<void> _updateField(int id, bool exibir, bool obrigatorio) async {
    final dbHelper = DBSettings.instance;
    await dbHelper.updateSettings(widget.profileId,{
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
      final dbHelper = DBSettings.instance;
      dbHelper.deleteFieldDataTypeSettingsByProfileId(widget.profileId);
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
                      style: TextStyle(fontSize: 16, color: Colors.white),
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
                      style: TextStyle(fontSize: 16, color: Colors.white),
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

  Future<void> _showFieldDetailsDialog(BuildContext context, int perfilId, int settingId, String name) async {
    final dbHelper = DBSettings.instance;

    final fieldData = await dbHelper.getFieldDataTypeSettings(perfilId, settingId);

    Map<String, dynamic> field = {};
    String fieldName = name;
    String fieldType = "";
    String minSize = "";
    String maxSize = "";

    if (fieldData.isNotEmpty) {
      field = fieldData.first;
      fieldName = field['field_name'];
      fieldType = field['field_type'] ?? '';
      minSize = field['min_size'].toString();
      maxSize = field['max_size'].toString();
    }

    // Recuperar máscaras do banco de dados
    final maskList = field['_id'] != null ? await dbHelper.getMaskData(field['setting_id']) : null;

    // Inicializar as máscaras e seus controladores
    List<Map<String, dynamic>> maskData = maskList != null 
        ? maskList.map((mask) => {
              'mask': mask['mask'],
              '_id': mask['_id'], // ID da máscara para possíveis operações futuras
            }).toList()
        : [];

    List<TextEditingController> controllers = maskData
        .map((mask) => TextEditingController(text: mask['mask']))
        .toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              insetPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              // Column para incluir a barra superior com título
              titlePadding: EdgeInsets.zero,  // Remover o padding da title
              title: Container(
                color: Colors.black,
                padding: const EdgeInsets.all(16),
                child: const Text('Configuração do Campo',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              content: Container(
                width: double.infinity,
                height: double.infinity,
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome do Campo
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
                      // Tipo do Campo
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
                          setDialogState(() {
                            fieldType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      // Tamanho Mínimo
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
                      // Tamanho Máximo
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
                      // DataTable - Mini Grid
Container(
  width: double.infinity,
  child: SingleChildScrollView(
    //scrollDirection: Axis.horizontal,
    child: DataTable(
      columnSpacing: 24,
      headingRowHeight: 40,
      dataRowHeight: 50,
      columns: const [
        DataColumn(label: Text("Máscara")),
        DataColumn(label: Text("Ação")),
      ],
      rows: maskData.asMap().entries.map((entry) {
        final index = entry.key;
        final mask = entry.value;
        final controller = controllers[index];

        return DataRow(cells: [
          DataCell(
            Container( // Força o TextField a ter largura mínima
              width: MediaQuery.of(context).size.width * 0.6, // ocupa 90% da largura da tela
              child: TextField(
                controller: controller,
                onChanged: (value) {
                  setDialogState(() {
                    mask['mask'] = value;
                  });
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  labelText: '',
                ),
              ),
            ),
          ),
          DataCell(
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                if (mask['_id'] != null) {
                  await dbHelper.deleteMask(mask['_id']);
                }
                setDialogState(() {
                  maskData.removeAt(index);
                  controllers.removeAt(index);
                });
              },
            ),
          ),
        ]);
      }).toList(),
    ),
  ),
),

                      const SizedBox(height: 8),
                      
                      /*
                      Container(
                        width: double.infinity,  // Faz o botão ocupar toda a largura
                        
                        child: ElevatedButton(
                          onPressed: () {
                            setDialogState(() {
                              maskData.add({'mask': '', '_id': null});
                              controllers.add(TextEditingController());
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.max,  // Garante que o Row ocupe toda a largura
                            children: [
                              Icon(Icons.playlist_add, color: Colors.white, size: 30),
                              SizedBox(width: 5),
                              Text('Adicionar Máscara', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      */
                      CustomButton.processButton(
                        context,
                        "Adicionar Máscara",
                        1,
                        Icons.playlist_add,
                        () {
                          setDialogState(() {
                            maskData.add({'mask': '', '_id': null});
                            controllers.add(TextEditingController());
                          });
                        },
                      ),

                    ],
                  ),
                ),
              ),
                actions: [
                  Row(
                    children: [
                      // Botão Cancelar
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'CANCELAR',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botão OK
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                            backgroundColor: Colors.blue, 
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            // Atualizar os dados no banco
                            int id = await dbHelper.saveFieldDataTypeSetting({
                              DBSettings.columnSettingId: settingId,
                              DBSettings.columnFieldName: fieldName,
                              DBSettings.columnFieldType: fieldType,
                              DBSettings.columnMinSize: minSize,
                              DBSettings.columnMaxSize: maxSize,
                            });

                            if (id > 0) {
                              // Salvar as máscaras no banco
                              for (var mask in maskData) {
                                if (mask['mask'] != null && mask['mask']!.isNotEmpty) {
                                  if (mask['_id'] != null) {
                                    // Atualizar máscara existente
                                    await dbHelper.updateMask({
                                      DBSettings.columnId: mask['_id'],
                                      DBSettings.columnMask: mask['mask'],
                                    });
                                  } else {
                                    // Inserir nova máscara
                                    await dbHelper.insertMask({
                                      DBSettings.columnMask: mask['mask'],
                                      DBSettings.columnFieldDataTypeSettingId: id,
                                    });
                                  }
                                }
                              }
                            }
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'OK',
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
        },
      );
    }

@override
Widget build(BuildContext context) {
  return BasePage(
    title: 'Aplicativo de Consulta de Estrutura de Produtos. ACEP',
    subtitle: 'Configurações',
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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

        // REMOVIDO O Expanded AQUI
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(), // evita scroll dentro do scroll
          shrinkWrap: true, // permite renderizar dentro do Column
          itemCount: campos.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final campo = campos[index];
            return InkWell(
              onTap: () {
                _showFieldDetailsDialog(
                    context, widget.profileId, campo['_id'], campo['nome']);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Icon(Icons.more_vert,
                              size: 20, color: Colors.black),
                          Text(campo['nome'],
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
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
                      _updateField(
                          campo['_id'], value, campo['obrigatorio'] == 1);
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
                      _updateField(
                          campo['_id'], campo['exibir'] == 1, value);
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ),
    floatingButtons: SizedBox(
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
          minimumSize: const Size(double.infinity, 45),
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
  );
}


/*
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
            Text('Configurações',
              style: TextStyle(color: Colors.white, fontSize: 20, ),
            ),
          ],
        ),
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
                          _showFieldDetailsDialog(context, widget.profileId, campo['_id'], campo['nome']);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: SingleChildScrollView( // Permite rolagem horizontal
                                scrollDirection: Axis.horizontal, // Define a
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start, // Alinha o texto à esquerda
                                  children: [
                                    const Icon(
                                      Icons.more_vert, // Ícone de seta para a direita
                                      size: 20, // Tamanho do ícone
                                      color: Colors.black, // Cor do ícone
                                    ),
                                    Text(
                                      campo['nome'], 
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
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
                      minimumSize: const Size(double.infinity, 45),
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
  */
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: const SettingsPage(profileId: 1),
  ));
}