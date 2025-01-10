import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_settings.dart';
import 'package:app_oxf_inv/operator/db_inventory.dart';
import 'searchProduct.dart';

class InventoryRecordsPage extends StatefulWidget {
  const InventoryRecordsPage({super.key});

  @override
  InventoryPageState createState() => InventoryPageState();
}

class InventoryPageState extends State<InventoryRecordsPage> {
  Map<String, dynamic> inventoryRecordRow = {};
  bool _isSaveButtonEnabled = false;
  late Future<Map<String, Map<String, dynamic>>> _settingsFuture;
  final List<TextEditingController> controllers = List.generate(11,(index) => TextEditingController(),);
  final TextEditingController _totalController = TextEditingController();

  @override
  void dispose() {  // Certifique-se de limpar os controladores ao sair
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
      final isVisible     = fieldSettings?['exibir'] == 1;
      final isRequired    = fieldSettings?['obrigatorio'] == 1;
      final controller    = controllers[_getControllerIndexForField(key)];

      if (isVisible && isRequired && controller.text.isEmpty == true) {
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
      'Unitizador'  : 0,
      'Posição'     : 1,
      'Depósito'    : 2,
      'Bloco'       : 3,
      'Quadra'      : 4,
      'Lote'        : 5,
      'Andar'       : 6,
      'Código de Barras'         : 7,
      'Qtde Padrão da Pilha'     : 8,
      'Qtde de Pilhas Completas' : 9,
      'Qtde de Itens Avulsos'    : 10,
    };

    return fieldMap[field] ?? -1;
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

  int getValidInt(String? value) {
    // Verifica se o valor é null ou vazio e retorna 0 pra não dar pau
    return (value == null || value.isEmpty) ? 0 : int.parse(value);
  }

  Future<int> saveData(BuildContext context) async {
    Map<String, dynamic>? inventory;
    DBInventory db = DBInventory.instance;
    int st = 0;
    int subTotal = 0;

    try {

      subTotal = (getValidInt(controllers[8].text)*getValidInt(controllers[9].text))+getValidInt(controllers[10].text);
      inventory = await db.queryFirstInventoryByStatus();
      // Mapeia os campos
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
          const SnackBar(content: Text('Dados salvos com sucesso!', style: TextStyle(fontSize: 18))),
        );

        for (var controller in controllers) { // Limpar os campos após salvar
          controller.clear();
        }

        createInventoryRecord(); createInventoryRecord(); // Prepara o próximo registro

        setState(() {
          _isSaveButtonEnabled = false; // Desabilita até que os campos obrigatórios sejam preenchidos
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar os dados.', style: TextStyle(fontSize: 18))),
        );
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar os dados: $e', style: const TextStyle(fontSize: 18))),
      );
    }

    return st;
  }

  void clearFields() {
    for (var controller in controllers) { // Limpar os campos após salvar
      controller.clear();
    }
    createInventoryRecord(); createInventoryRecord(); // Prepara o próximo registro
    setState(() {
      _isSaveButtonEnabled = false; // Desabilita até que os campos obrigatórios sejam preenchidos
    });
  }

  void _validateFields(String value, int id) {
    const sequence1 = '07891361'; // Primeira sequência válida
    const sequence2 = '7891361';  // Segunda sequência válida
    
    if (value.isEmpty) {
      return;
    }

    // Verifica a sequência "0789361" ou "789361"
    if (id == 8 && !_isSequenceValid(value, sequence1) && !_isSequenceValid(value, sequence2)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código inválido.',
          style: TextStyle(color: Colors.white, fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
          backgroundColor: Color.fromARGB(255, 247, 94, 83),
        ),
      );
      _clearField(id);
    }
    return;
  }

  bool _isSequenceValid(String value, String sequence) {
    for (int i = 0; i < sequence.length; i++) {
      if(i < value.length) {
        if (value[i] != sequence[i]) {
          return false;
        }
      }
    }
    return true; // barcode válido
  }

  void _clearField(int id) {
    if(id == 8) {
      controllers[7].text = "";
    }
  }

  Widget _buildTextField({ 
    required int    id,
    required String label,
    required bool   visible,
    required bool   enabled,
    required bool   required,
    required TextEditingController controller,
    required Map<String, Map<String, dynamic>> settings,
    Widget? suffixIcon, 
    BuildContext? context,
  }) {
    String labelWithAsterisk = label;
    if (required) {
      labelWithAsterisk = '$label *'; // Adiciona o "*" ao label
    }
    
    if (id == 8) { // Quando for barcode
      suffixIcon = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.barcode_reader),
            onPressed: () {
              // Por hora não tem ação para o ícone barcode_reader, apenas ilustrativo
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              if (context != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchProduct(
                      onProductSelected: (selectedProduct) {
                        controller.text = selectedProduct;
                      },
                    ),
                  ),
                );
              }
            },
          ),
        ],
      );
    }

    return Visibility(
      visible: visible,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: TextField(
          controller: controller,
          style: const TextStyle(fontSize: 18),
          enabled: enabled,
          onChanged: (value) {
            _validateMandatoryFields(settings);
            _validateFields(value, id);
          },
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: labelWithAsterisk,
            suffixIcon: suffixIcon,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0), // Ajuste a altura
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
      body: SingleChildScrollView( // coloca scroll para rolar o conteúdo
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: FutureBuilder<Map<String, Map<String, dynamic>>>( 
            future: _settingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total de Registros: ',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            _totalController.text,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold,),
                          ),
                          const Padding( padding: EdgeInsets.only(right: 1)),
                        ],
                      ),
                    ),
                  ),
                  _buildTextField(
                    id:         1,
                    label:      'Unitizador',
                    visible:    true,
                    enabled:    settings['Unitizador']?['exibir'] == 1,
                    required:   settings['Unitizador']?['obrigatorio'] == 1,
                    controller: controllers[0],
                    settings:   settings,
                    suffixIcon: const Icon(Icons.barcode_reader),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    id: 2,
                    label:      'Posição',
                    visible:    true,
                    enabled:    settings['Posição']?['exibir'] == 1,
                    required:   settings['Posição']?['obrigatorio'] == 1,
                    controller: controllers[1],
                    settings:   settings,
                    suffixIcon: const Icon(Icons.barcode_reader),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          id:         3,
                          label:      'Depósito',
                          visible:    true,
                          enabled:    settings['Depósito']?['exibir'] == 1,
                          required:   settings['Depósito']?['obrigatorio'] == 1,
                          controller: controllers[2],
                          settings:   settings,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          id:         4,
                          label:      'Bloco',
                          visible:    true,
                          enabled:    settings['Bloco']?['exibir'] == 1,
                          required:   settings['Bloco']?['obrigatorio'] == 1,
                          controller: controllers[3],
                          settings:   settings,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          id:         5,
                          label:      'Quadra',
                          visible:    true,
                          enabled:    settings['Quadra']?['exibir'] == 1,
                          required:   settings['Quadra']?['obrigatorio'] == 1,
                          controller: controllers[4],
                          settings:   settings,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          id:         6,
                          label:      'Lote',
                          visible:    true,
                          enabled:    settings['Lote']?['exibir'] == 1,
                          required:   settings['Lote']?['obrigatorio'] == 1,
                          controller: controllers[5],
                          settings:   settings,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    id:         7,
                    label:      'Andar',
                    visible:    true,
                    enabled:    settings['Andar']?['exibir'] == 1,
                    required:   settings['Andar']?['obrigatorio'] == 1,
                    controller: controllers[6],
                    settings:   settings,
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    id:         8,
                    label:      'Código de Barras',
                    visible:    true,
                    enabled:    settings['Código de Barras']?['exibir'] == 1,
                    required:   settings['Código de Barras']?['obrigatorio'] == 1,
                    controller: controllers[7],
                    settings:   settings,
                    suffixIcon: const Icon(Icons.barcode_reader),
                    context:    context,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          id:         9,
                          label:      'Qtde Padrão da Pilha',
                          visible:    true,
                          enabled:    settings['Qtde Padrão da Pilha']?['exibir'] == 1,
                          required:   settings['Qtde Padrão da Pilha']?['obrigatorio'] == 1,
                          controller: controllers[8],
                          settings:   settings,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTextField(
                          id:         10,
                          label:      'Qtde de Pilhas Completas',
                          visible:    true,
                          enabled:    settings['Qtde de Pilhas Completas']?['exibir'] == 1,
                          required:   settings['Qtde de Pilhas Completas']?['obrigatorio'] == 1,
                          controller: controllers[9],
                          settings:   settings,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    id:         11,
                    label:      'Qtde de Itens Avulsos',
                    visible:    true,
                    enabled:    settings['Qtde de Itens Avulsos']?['exibir'] == 1,
                    required:   settings['Qtde de Itens Avulsos']?['obrigatorio'] == 1,
                    controller: controllers[10],
                    settings:   settings,
                  ),
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
                              FocusScope.of(context).unfocus();
                              clearFields();
                            },
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: const Text('LIMPAR', style: TextStyle(color: Colors.white, fontSize: 16,),),
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
                                  FocusScope.of(context).unfocus();
                                  if (_validateMandatoryFields(settings)) {
                                    int result = await saveData(context);
                                  }
                                }
                              : null,
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text('GRAVAR', style: TextStyle(color: Colors.white, fontSize: 16,),),
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
      // Retirado o radapé para melhor aproveitamento de espaço em tela
      /*bottomNavigationBar: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Oxford Porcelanas", style: TextStyle(fontSize: 14)),
            Text("Versão: 1.0", style: TextStyle(fontSize: 14)),
          ],
        ),
      ),*/
    );
  }
}