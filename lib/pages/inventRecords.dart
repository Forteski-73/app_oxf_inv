import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_settings.dart';
import 'package:app_oxf_inv/operator/db_inventory.dart';

class InventoryRecordsPage extends StatefulWidget {
  const InventoryRecordsPage({super.key});

  @override
  InventoryPageState createState() => InventoryPageState();
}

class InventoryPageState extends State<InventoryRecordsPage> {
  Map<String, dynamic> inventoryRecordRow = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaveButtonEnabled = false;
  late Future<Map<String, Map<String, dynamic>>> _settingsFuture;
  final List<TextEditingController> controllers = List.generate(11,(index) => TextEditingController(),);
  final TextEditingController _totalController = TextEditingController(); 

  @override
  void dispose() {
    // Certifique-se de limpar os controladores ao sair
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _settingsFuture = _loadSettings();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await createInventoryRecord();
      setState(() { });
    });

  }
  
  Future<Map<String, Map<String, dynamic>>> _loadSettings() async {
    final rows = await DBSettings.instance.queryAllRows();

    return {
      for (var row in rows) row['nome']: row,
    };
  }

  bool _validateMandatoryFields(Map<String, Map<String, dynamic>> settings) {
  for (var key in settings.keys) {
    final fieldSettings = settings[key];
    final isVisible = fieldSettings?['exibir'] == 1;
    final isRequired = fieldSettings?['obrigatorio'] == 1;
    final controller = controllers[_getControllerIndexForField(key)];

    if (isVisible && isRequired && controller?.text.isEmpty == true) {
      setState(() {
        _isSaveButtonEnabled = false;
      });
      return false;
    }
  }
  setState(() {
    _isSaveButtonEnabled = true;
  });
  return true;
}

  int _getControllerIndexForField(String field) {
    const fieldMap = {
      'Unitizador': 0,
      'Posição': 1,
      'Depósito': 2,
      'Bloco': 3,
      'Quadra': 4,
      'Lote': 5,
      'Andar': 6,
      'Código de Barras': 7,
      'Qtde Padrão da Pilha': 8,
      'Qtde de Pilhas Completas': 9,
      'Qtde de Itens Avulsos': 10,
    };
    return fieldMap[field] ?? -1; // Retorna -1 se o campo não for encontrado
  }

  Future<void> createInventoryRecord() async {
    DBInventory db = DBInventory.instance;
    Map<String, dynamic>? inventory;

    inventory = await db.queryFirstInventoryByStatus();

    if (inventory != null) { 
      _totalController.text = inventory?["total"]?.toString() ?? "0";

      inventoryRecordRow = {
        DBInventory.columnInventoryId:          inventory["_id"] ?? '',
        DBInventory.columnUnitizer:             '',
        DBInventory.columnPosition:             '',
        DBInventory.columnDeposit:              '',
        DBInventory.columnBlockA:               '',
        DBInventory.columnBlockB:               '',
        DBInventory.columnLot:                  '',
        DBInventory.columnFloor:                null,
        DBInventory.columnBarcode:              '',
        DBInventory.columnStandardStackQtd:     null,
        DBInventory.columnNumberCompleteStacks: null,
        DBInventory.columnNumberLooseItems:     null,
      };
    }
  }

  Future<int> saveData(BuildContext context) async {
    Map<String, dynamic>? inventory;
    DBInventory db = DBInventory.instance;
    int st = 0;
    int subTotal = 0, total = 0;

    try {

      subTotal = (int.parse(controllers[8].text)*int.parse(controllers[9].text))+int.parse(controllers[10].text);
      inventory = await db.queryFirstInventoryByStatus();
      // Mapeamento dos dados
      inventoryRecordRow = {
        "inventory_id":           inventory?["_id"] ?? '',
        "unitizer":               controllers[0].text,
        "position":               controllers[1].text,
        "deposit":                controllers[2].text,
        "block_a":                controllers[3].text,
        "block_b":                controllers[4].text,
        "lot":                    controllers[5].text,
        "floor":                  int.tryParse(controllers[6].text) ?? 0,
        "barcode":                controllers[7].text,
        "standard_stack_qtd":     int.tryParse(controllers[8].text) ?? 0,
        "number_complete_stacks": int.tryParse(controllers[9].text) ?? 0,
        "number_loose_items":     int.tryParse(controllers[10].text) ?? 0,
        "total":                  subTotal,

      };

      // Inserção no banco
      st = await db.insertInventoryRecord(inventoryRecordRow);

      if (st > 0) {

        inventory = await db.queryFirstInventoryByStatus();
        _totalController.text = inventory?["total"]?.toString() ?? "0";

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados salvos com sucesso!')),
        );

        // Limpar os campos após salvar
        for (var controller in controllers) {
          controller.clear();
        }

        createInventoryRecord(); createInventoryRecord(); // Prepara o próximo registro

        setState(() {
          _isSaveButtonEnabled = false; // Desabilitar até que os campos obrigatórios sejam preenchidos
        });
      }
      else
      {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar os dados.')),
        );
      }
      setState(() {});
    } catch (e) {
      //print("Erro ao salvar os dados no banco..: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar os dados.')),
      );
    }

    return st;
  }

  void clearFields() {
    // Limpar os campos após salvar
    for (var controller in controllers) {
      controller.clear();
    }
    createInventoryRecord(); createInventoryRecord(); // Prepara o próximo registro

    // Opcional: Habilitar o botão de salvar se necessário
    setState(() {
      _isSaveButtonEnabled = false; // Desabilitar até que os campos obrigatórios sejam preenchidos
    });
  }

  Widget _buildTextField({
    required String label,
    required bool visible,
    required bool enabled,
    required TextEditingController controller, // Torne o controlador obrigatório
    required Map<String, Map<String, dynamic>> settings,
    Icon? suffixIcon
  }) {
    return Visibility(
      visible: visible,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: TextField(
          controller: controller, // Associa o controlador
          enabled: enabled,
          onChanged: (_) => _validateMandatoryFields(settings),
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: suffixIcon,
            border: const OutlineInputBorder()
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criação de Inventário', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView( // SingleChildScrollView para rolar o conteúdo
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<Map<String, Map<String, dynamic>>>( 
            future: _settingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Erro ao carregar inventário.'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Nenhuma inventário encontrado.'));
              }
              final settings = snapshot.data!;
              return Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft, 
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Total de Registros: ${_totalController.text}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                  _buildTextField(
                    label: 'Unitizador',
                    visible: settings['Unitizador']?['exibir'] == 1,
                    enabled: settings['Unitizador']?['obrigatorio'] == 1,
                    controller: controllers[0],
                    settings: settings,
                    suffixIcon: const Icon(Icons.barcode_reader),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    label: 'Posição',
                    visible: settings['Posição']?['exibir'] == 1,
                    enabled: settings['Posição']?['obrigatorio'] == 1,
                    controller: controllers[1],
                    settings: settings,
                    suffixIcon: const Icon(Icons.barcode_reader),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Depósito',
                          visible: settings['Depósito']?['exibir'] == 1,
                          enabled: settings['Depósito']?['obrigatorio'] == 1,
                          controller: controllers[2],
                          settings: settings,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          label: 'Bloco',
                          visible: settings['Bloco']?['exibir'] == 1,
                          enabled: settings['Bloco']?['obrigatorio'] == 1,
                          controller: controllers[3],
                          settings: settings,
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
                          controller: controllers[4],
                          settings: settings,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          label: 'Lote',
                          visible: settings['Lote']?['exibir'] == 1,
                          enabled: settings['Lote']?['obrigatorio'] == 1,
                          controller: controllers[5],
                          settings: settings,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    label: 'Andar',
                    visible: settings['Andar']?['exibir'] == 1,
                    enabled: settings['Andar']?['obrigatorio'] == 1,
                    controller: controllers[6],
                    settings: settings,
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    label: 'Código de Barras',
                    visible: settings['Código de Barras']?['exibir'] == 1,
                    enabled: settings['Código de Barras']?['obrigatorio'] == 1,
                    controller: controllers[7],
                    settings: settings,
                    suffixIcon: const Icon(Icons.barcode_reader),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Qtde Padrão da Pilha',
                          visible: settings['Qtde Padrão da Pilha']?['exibir'] == 1,
                          enabled: settings['Qtde Padrão da Pilha']?['obrigatorio'] == 1,
                          controller: controllers[8],
                          settings: settings,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          label: 'Qtde de Pilhas Completas',
                          visible: settings['Qtde de Pilhas Completas']?['exibir'] == 1,
                          enabled: settings['Qtde de Pilhas Completas']?['obrigatorio'] == 1,
                          controller: controllers[9],
                          settings: settings,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    label: 'Qtde de Itens Avulsos',
                    visible: settings['Qtde de Itens Avulsos']?['exibir'] == 1,
                    enabled: settings['Qtde de Itens Avulsos']?['obrigatorio'] == 1,
                    controller: controllers[10],
                    settings: settings,
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              clearFields();
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: const Text('LIMPAR', style: TextStyle(color: Colors.white),),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: _isSaveButtonEnabled ? Colors.blue : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _isSaveButtonEnabled
                              ? () async {
                                  if (_validateMandatoryFields(settings)) {
                                    int result = await saveData(context);
                                    if(result>0)
                                    {
                                      /*ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Dados salvos!')),
                                      );*/
                                    } else {
                                      /*ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Campos obrigatórios não preenchidos.')),
                                      );*/
                                    }
                                  }
                                }
                              : null,
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text('GRAVAR', style: TextStyle(color: Colors.white),),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
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