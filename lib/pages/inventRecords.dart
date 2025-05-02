import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_settings.dart';
import 'package:app_oxf_inv/operator/db_inventory.dart';
import 'searchProduct.dart';
import 'package:app_oxf_inv/widgets/basePage.dart';
import 'package:app_oxf_inv/widgets/customSnackBar.dart';
import 'package:app_oxf_inv/widgets/barcodescannerpage.dart';
import 'package:app_oxf_inv/styles/btnStyles.dart';
import 'package:app_oxf_inv/widgets/customButton.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
///import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';


class InventoryRecordsPage extends StatefulWidget {
  InventoryRecordsPage({super.key});
  late String selectedProfile = "";

  @override
  InventoryPageState createState() => InventoryPageState();
}

class InventoryPageState extends State<InventoryRecordsPage> {
  Map<String, dynamic> inventoryRecordRow = {};
  bool _isSaveButtonEnabled = false;
  late Future<Map<String, Map<String, dynamic>>> _settingsFuture = Future.value({});
  final List<TextEditingController> controllers = List.generate(11,(index) => TextEditingController(),);
  final TextEditingController _totalController = TextEditingController();
  final List<FocusNode> focusNodes = List.generate(11, (index) => FocusNode());
  TextEditingController controller = TextEditingController();
  String _barcodeResult = "Nenhum código escaneado";

  @override
  void dispose() {  
    for (var controller in controllers) {
      controller.dispose();
    }

    for (var focus in focusNodes) {
      focus.dispose();
    }

    controller.dispose();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Não da para acessar o 'context' diretamente no initState, então vamos fazer isso depois que o widget for construído
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Acessa os argumentos da rota de forma segura
      widget.selectedProfile = ModalRoute.of(context)?.settings.arguments as String? ?? ''; 
      _settingsFuture = _loadSettings();
      
      await createInventoryRecord();

      // Garante que o estado será atualizado após as operações assíncronas
      setState(() {});
    });

    for (int i = 0; i < focusNodes.length; i++) {
      focusNodes[i].addListener(() {
        if (!focusNodes[i].hasFocus && controllers[i].text != "") {
          // Chama onEditingComplete quando o campo perde o foco
          _onEditingComplete(controllers[i].text, i);
        }
      });
    }
  }

  Future<void> _onEditingComplete(String value, int _id) async {
    bool isValid = await _validateFields(value, _id);
    if (!isValid) {
      setState(() {
        controllers[_id].text = "";
        FocusScope.of(context).requestFocus(focusNodes[_id]);
      });
    }
    else {
      if(_id == 1) {
        String posicao = controllers[_id].text;
        controllers[2].text = posicao.substring(0, 2);
        controllers[3].text = posicao.substring(2, 4);
        controllers[4].text = posicao.substring(4, 5);
        controllers[5].text = posicao.substring(5, 7);
        controllers[6].text = posicao.substring(7, 8);
        setState(() {}); // pra pintar de verde
        //FocusScope.of(context).requestFocus(focusNodes[7]);

        //FocusScope.of(context).requestFocus(focusNodes[7]); // Dá o foco no campo desejado
        //Future.delayed(Duration(milliseconds: 100), () {
        //FocusScope.of(context).unfocus(); // Remove o foco e esconde o teclado
        //});
      }
    }
  }

  Future<Map<String, Map<String, dynamic>>> _loadSettings() async {
    final rows = await DBSettings.instance.querySettingForProfile(widget.selectedProfile);

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

      st = await db.insertInventoryRecord(inventoryRecordRow);

      if (st > 0) {
        inventory = await db.queryFirstInventoryByStatus();
        _totalController.text = inventory?["total"]?.toString() ?? "0";

        CustomSnackBar.show(context, message: "Dados salvos com sucesso!",
          duration: const Duration(seconds: 3),type: SnackBarType.success,
        );

        if (controllers[0].text.isNotEmpty && controllers[1].text.isEmpty) {
          saveMoreRecords(context);
        } else {
          for (var i = 0; i < controllers.length; i++) { // limpa tudo
              controllers[i].clear();
          }
          FocusScope.of(context).requestFocus(focusNodes[7]); // foco no item
        }

        createInventoryRecord(); // Prepara o próximo registro createInventoryRecord();

        setState(() {
          _isSaveButtonEnabled = false; // Desabilita até que os campos obrigatórios sejam preenchidos
        });
      } else {
        CustomSnackBar.show(context, message: "Erro ao salvar os dados.",
          duration: const Duration(seconds: 4),type: SnackBarType.error,
        );
      }
      setState(() {});
    } catch (e) {
      CustomSnackBar.show(context, message: "Erro ao salvar os dados: $e",
        duration: const Duration(seconds: 4),type: SnackBarType.error,
      );
    }

    return st;
  }

Future<void> saveMoreRecords(BuildContext context) async {
  bool next = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: const Text("Encerrar contagem desse unitizador?",style: TextStyle(fontSize: 18,),),
        actionsAlignment: MainAxisAlignment.center, // Centraliza os botões
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue, // Fundo azul
              padding: const EdgeInsets.all(16), // Espaçamento interno
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Borda arredondada
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8), // Espaçamento entre ícone e texto
                Text("NÃO", style: TextStyle(color: Colors.white, fontSize: 16), // Texto branco
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue, // Fundo azul
              padding: const EdgeInsets.all(16), // Espaçamento interno
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), // Borda arredondada
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.done, color: Colors.white), // Ícone
                SizedBox(width: 8), // Espaçamento entre ícone e texto
                Text(
                  "SIM",
                  style: TextStyle(color: Colors.white, fontSize: 16), // Texto branco
                ),
              ],
            ),
          ),
        ],
      );
    },
  ) ?? false;

    if (next) {
      for (var controller in controllers) { // Limpar os campos após salvar
        controller.clear();
      }
      FocusScope.of(context).requestFocus(focusNodes[0]);
    } else {
      for (var i = 0; i < controllers.length; i++) { // Mantém Unitizador e Localização
        if (i > 6) {
          controllers[i].clear();
        }
      }
      FocusScope.of(context).requestFocus(focusNodes[7]);
    }
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

  Future<bool> _validateFields(String value, int id) async {

    String  field_name;
    String  field_type;
    int     min_size;
    int     max_size;
    bool    st = true;
    int     id_field = (id+1);

    // Obtém o profileId com base no nome do perfil
    final profileId = await DBSettings.instance.getProfileIdByProfile(widget.selectedProfile);

    List<Map<String, dynamic>> resultDT = await DBSettings.instance.queryFieldDataTypeSettingsBySettingId(profileId, id_field);

    if (resultDT.isNotEmpty) {
      field_name = resultDT[0]['field_name'];
      field_type = resultDT[0]['field_type'];
      min_size   = resultDT[0]['min_size'];
      max_size   = resultDT[0]['max_size'];

      // Validação do tipo de campo
      if (field_type == 'Numérico') {
        if (!RegExp(r'^\d+$').hasMatch(value)) {
          CustomSnackBar.show(context, message: 'O campo ${field_name} deve conter apenas números.',
            duration: const Duration(seconds: 4),type: SnackBarType.warning,
          );
          st = false; // Interrompe a validação se o campo não for numérico
          return st;
        }
      }

      // Validação do tamanho do campo
      if (value.length < min_size || value.length > max_size) {
        
        String msg = 'O campo $field_name deve ter $max_size caracteres.';
        if(min_size != max_size) {
          msg = 'O campo $field_name deve ter entre $min_size e $max_size caracteres.';
        }
        CustomSnackBar.show(context, message: '${msg}',
          duration: const Duration(seconds: 4),type: SnackBarType.warning,
        );
        st = false; // Interrompe a validação se o tamanho não estiver dentro dos limites
        return st;
      }

      /* VALIDAÇÕES DAS MÁSCARAS */
      List<Map<String, dynamic>> result = await DBSettings.instance.queryMasksBySettingId(profileId);
      if (result.isNotEmpty)
      {
        st = false;
        for (var item in result) {
          final mask = item['mask'] as String;
          
          String pattern = generatePattern(mask, field_type);
          final regExp = RegExp(pattern);
          
          if (regExp.hasMatch(value)) { // Verifica a qual padrão a máscara corresponde
            st = true;
            break; // interrompe pois já achou um verdadeiro
          } 
        }
        if(!st) {
          CustomSnackBar.show(context, message: '$field_name inválido.',
            duration: const Duration(seconds: 4),type: SnackBarType.warning,
          );
        }
      }
    }

    return st;
  }

  String generatePattern(String _mask, String  _fieldType) {
    // Expressão para encontrar números e asteriscos  ^3256391\d{6}$  ^3256391\*{6}$
    final regExp = RegExp(r'(\d+)|(\*+)');
    final matches = regExp.allMatches(_mask);

    // Constrói o padrão dinâmico
    StringBuffer pattern = StringBuffer('^');
    for (final match in matches) {
      if (match.group(1) != null) {
        // Adiciona o número fixo
        pattern.write(match.group(1));
      } else if (match.group(2) != null) {
        // Adiciona a quantidade de "*"
        int count = match.group(2)!.length;
        if (_fieldType == 'Numérico') {
          pattern.write(r'\d{' + count.toString() + r'}');
        }
        else {
          pattern.write(r'[a-zA-Z0-9]{' + count.toString() + r'}');
        }
      }
    }
    pattern.write(r'$');
    return pattern.toString();
  }

  Widget _buildTextField({ 
    required int    id,
    required String label,
    required bool   visible,
    required bool   enabled,
    required bool   required,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Map<String, Map<String, dynamic>> settings,
    Widget? suffixIcon, 
    BuildContext? context,
  }) {
    String labelWithAsterisk = label;
    if (required) {
      labelWithAsterisk = '$label *'; // Adiciona o "*" ao label
    }
    
    if (id == 1 || id == 2 || id == 8) { // Quando for barcode
      suffixIcon = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () async {
              String barcode = await scanBarcode(context!); // força para não ser nulo
              if (mounted) { // Verifica se o widget ainda está ativo para evitar erro no retorno da leitura
                controller.text = barcode;
                // Avança para o próximo campo
                if (id == 2) {
                  await _onEditingComplete(barcode, 1);
                }
              }
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
          focusNode: focusNode,
          style: const TextStyle(fontSize: 18),
          enabled: enabled,
          onChanged: (value) {
            _validateMandatoryFields(settings);
          },
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: labelWithAsterisk,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: controller.text.isNotEmpty
                ? const Color.fromARGB(255, 210, 250, 220) // Fundo verde claro quando preenchido
                : Colors.white, // Fundo branco quando vazio
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: const Color.fromARGB(255, 160, 241, 171), // Borda verde ao focar
                width: 2.0,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: controller.text.isNotEmpty
                    ? const Color.fromARGB(255, 210, 250, 220) // Verde se preenchido
                    : Colors.grey, // Cinza se vazio
                width: 1.5,
              ),
            ),
            floatingLabelStyle: const TextStyle(color: Color.fromARGB(255, 70, 69, 69)), // Mantém o título cinza mesmo com foco
          ),
        ),
      ),
    );
  }

/*
  Future<String> scanBarcode() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        "#ff6666", // Cor do botão de cancelamento
        "Cancelar", // Texto do botão de cancelamento
        true, // Exibir linha guia de escaneamento
        ScanMode.BARCODE, // Modo de escaneamento (BARCODE ou QR_CODE)
      );
    } catch (e) {
      barcodeScanRes = "Falha ao escanear código de barras";
    }

    //if (!mounted) return '';

    /*setState(() {
      _barcodeResult = barcodeScanRes;
    });*/

    return barcodeScanRes;
  }
*/

Future<String> scanBarcode(BuildContext context) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const BarcodeScannerPage(),
    ),
  );

  // Esperar 1 segundo
  //await Future.delayed(const Duration(seconds: 1));

  return result != null ? result as String : 'Falha ao escanear código de barras';
}


@override
Widget build(BuildContext context) {
  return BasePage(
    title: '',
    subtitle: 'Criação de Inventário',
    body: SingleChildScrollView(
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
              return const Center(child: Text('Nenhum inventário encontrado.'));
            }
            final settings = snapshot.data!;
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL DE REGISTROS: ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        /*Text(
                          _totalController.text,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),*/

                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 3.0),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            _totalController.text,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        //const Padding(padding: EdgeInsets.only(bottom: 1.0)),
                      ],
                    ),
                  ),
                 
                ),
                const SizedBox(height: 10),
                _buildTextField(
                  id: 1,
                  label: 'Unitizador',
                  visible: true,
                  enabled: settings['Unitizador']?['exibir'] == 1,
                  required: settings['Unitizador']?['obrigatorio'] == 1,
                  controller: controllers[0],
                  focusNode: focusNodes[0],
                  settings: settings,
                  suffixIcon: const Icon(Icons.barcode_reader),
                ),
                const SizedBox(height: 7),
                _buildTextField(
                  id: 2,
                  label: 'Posição',
                  visible: true,
                  enabled: settings['Posição']?['exibir'] == 1,
                  required: settings['Posição']?['obrigatorio'] == 1,
                  controller: controllers[1],
                  focusNode: focusNodes[1],
                  settings: settings,
                  suffixIcon: const Icon(Icons.barcode_reader),
                  context: context,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        id: 3,
                        label: 'Depósito',
                        visible: true,
                        enabled: settings['Depósito']?['exibir'] == 1,
                        required: settings['Depósito']?['obrigatorio'] == 1,
                        controller: controllers[2],
                        focusNode: focusNodes[2],
                        settings: settings,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        id: 4,
                        label: 'Bloco',
                        visible: true,
                        enabled: settings['Bloco']?['exibir'] == 1,
                        required: settings['Bloco']?['obrigatorio'] == 1,
                        controller: controllers[3],
                        focusNode: focusNodes[3],
                        settings: settings,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        id: 5,
                        label: 'Quadra',
                        visible: true,
                        enabled: settings['Quadra']?['exibir'] == 1,
                        required: settings['Quadra']?['obrigatorio'] == 1,
                        controller: controllers[4],
                        focusNode: focusNodes[4],
                        settings: settings,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        id: 6,
                        label: 'Lote',
                        visible: true,
                        enabled: settings['Lote']?['exibir'] == 1,
                        required: settings['Lote']?['obrigatorio'] == 1,
                        controller: controllers[5],
                        focusNode: focusNodes[5],
                        settings: settings,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                _buildTextField(
                  id: 7,
                  label: 'Andar',
                  visible: true,
                  enabled: settings['Andar']?['exibir'] == 1,
                  required: settings['Andar']?['obrigatorio'] == 1,
                  controller: controllers[6],
                  focusNode: focusNodes[6],
                  settings: settings,
                ),
                const SizedBox(height: 3),
                _buildTextField(
                  id: 8,
                  label: 'Código de Barras',
                  visible: true,
                  enabled: settings['Código de Barras']?['exibir'] == 1,
                  required: settings['Código de Barras']?['obrigatorio'] == 1,
                  controller: controllers[7],
                  focusNode: focusNodes[7],
                  settings: settings,
                  suffixIcon: const Icon(Icons.barcode_reader),
                  context: context,
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        id: 9,
                        label: 'Qtde Padrão da Pilha',
                        visible: true,
                        enabled: settings['Qtde Padrão da Pilha']?['exibir'] == 1,
                        required: settings['Qtde Padrão da Pilha']?['obrigatorio'] == 1,
                        controller: controllers[8],
                        focusNode: focusNodes[8],
                        settings: settings,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTextField(
                        id: 10,
                        label: 'Qtde de Pilhas Completas',
                        visible: true,
                        enabled: settings['Qtde de Pilhas Completas']?['exibir'] == 1,
                        required: settings['Qtde de Pilhas Completas']?['obrigatorio'] == 1,
                        controller: controllers[9],
                        focusNode: focusNodes[9],
                        settings: settings,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                _buildTextField(
                  id: 11,
                  label: 'Qtde de Itens Avulsos',
                  visible: true,
                  enabled: settings['Qtde de Itens Avulsos']?['exibir'] == 1,
                  required: settings['Qtde de Itens Avulsos']?['obrigatorio'] == 1,
                  controller: controllers[10],
                  focusNode: focusNodes[10],
                  settings: settings,
                ),
              ],
            );
          },
        ),
      ),
    ),
    floatingButtons: Padding(
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
            label: const Text(
              'LIMPAR',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
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
                    //if (_validateMandatoryFields(_settingsFuture.data ?? {})) {
                      int result = await saveData(context);
                    //}
                  }
                : null,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text(
              'GRAVAR',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    ),
  );
}


/*
  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: '',
      subtitle: 'Criação de Inventário',
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
                    focusNode: focusNodes[0],
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
                    focusNode: focusNodes[1],
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
                          focusNode: focusNodes[2],
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
                          focusNode: focusNodes[3],
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
                          focusNode: focusNodes[4],
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
                          focusNode: focusNodes[5],
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
                    focusNode: focusNodes[6],
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
                    focusNode: focusNodes[7],
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
                          focusNode: focusNodes[8],
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
                          focusNode: focusNodes[9],
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
                    focusNode: focusNodes[10],
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
    );
  }*/
}