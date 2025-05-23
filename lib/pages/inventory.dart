import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_inventory.dart';
import 'package:app_oxf_inv/operator/db_settings.dart';
import 'package:intl/intl.dart';
import 'package:app_oxf_inv/widgets/basePage.dart';
import 'package:app_oxf_inv/widgets/customButton.dart';
import 'package:flutter/services.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  _InventoryPageState createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  // Criar controladores para os campos de texto
  final TextEditingController _codeController   = TextEditingController();
  final TextEditingController _dateController   = TextEditingController();
  final TextEditingController _nameController   = TextEditingController();
  final TextEditingController _sectorController = TextEditingController();
  String _selectedProfile = "";
  int _statusController = 0;
  Map<String, dynamic>? inventory;
  List<String> _profileOptions = [];  // Lista de opções para o Dropdown

  @override
  void initState() {
    super.initState();

    _codeController.addListener(_updateButtonState);
    _dateController.addListener(_updateButtonState);
    _nameController.addListener(_updateButtonState);
    _sectorController.addListener(_updateButtonState);
    _selectedProfile = inventory?["profile"] ?? '';

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await createInventory();

      await _loadProfiles(); // Carrega os perfis do banco de dados

      setState(() {
        // Atualiza o estado para refletir mudanças no inventário
        _codeController.text = inventory?["code"] ?? '';
        _dateController.text = inventory?["date"] ?? '';
        _nameController.text = inventory?["name"] ?? '';
        _sectorController.text = inventory?["sector"] ?? '';
        _selectedProfile = inventory?["profile"] ?? '';
      });
    });
  }

  void _updateButtonState() {
    setState(() {}); // Atualiza a interface quando o texto dos controladores mudar
  }

  bool updateControlls(int flag) {
    switch (flag) {
      case 0:
        return _statusController == 1 &&
              _codeController.text.isNotEmpty &&
              _dateController.text.isNotEmpty &&
              _nameController.text.isNotEmpty &&
              _sectorController.text.isNotEmpty &&
              _selectedProfile.isNotEmpty;
      case 1:
        return _statusController == 0 &&
              _codeController.text.isNotEmpty &&
              _dateController.text.isNotEmpty &&
              _nameController.text.isNotEmpty &&
              _sectorController.text.isNotEmpty &&
              _selectedProfile.isNotEmpty;

      case 2:
        return _statusController > 0 &&
              _codeController.text.isNotEmpty &&
              _dateController.text.isNotEmpty &&
              _nameController.text.isNotEmpty &&
              _sectorController.text.isNotEmpty &&
              _selectedProfile.isNotEmpty;
      case 3:
        return _statusController >= 0 &&
              _codeController.text.isNotEmpty &&
              _dateController.text.isNotEmpty &&
              _nameController.text.isNotEmpty &&
              _sectorController.text.isNotEmpty &&
              _selectedProfile.isNotEmpty;
      default:
        return false;
    }
  }

  // Função para carregar os perfis do banco de dados
  Future<void> _loadProfiles() async {
    DBSettings db = DBSettings.instance;
    List<Map<String, dynamic>> profiles = await db.queryAllSettingsProfiles();

    setState(() {
      _profileOptions = profiles.map((profile) => profile["profile"] as String).toList();
    });
  }

  Future<int> startInventory() async {
    DBInventory db = DBInventory.instance;
    Map<String, dynamic>? inventoryContext = await db.queryFirstInventoryByStatus();
    int st = 0;
    if (inventoryContext != null) { // Atualiza para em andamento
      inventoryContext["status"] = "EM ANDAMENTO";
      st = await updateInventoryStatus(inventoryContext);
      inventory = inventoryContext;
      if(st==1) {
        _updateButtonState();
        _statusController = 1;
      }
    }
    return st;
  }

  Future<int> finishInventory() async {
    DBInventory db = DBInventory.instance;
    Map<String, dynamic>? inventoryContext = await db.queryFirstInventoryByStatus();
    int st = 0;
    if (inventoryContext != null) { // Atualiza para concluído
      inventoryContext["status"] = "CONCLUÍDO";
      st = await updateInventoryStatus(inventoryContext);
      inventory = inventoryContext;
      if(st>0) {
        createInventory();
        _updateButtonState();
      }
    }
    return st;
  }

  String formatNumber(int number) {
    return number.toString().padLeft(2, '0'); // Garante 2 dígitos
  }

  Future<void> createInventory() async {
    final DateTime now  = DateTime.now();
    String currentDate  = DateFormat('yyyyMMdd').format(now);
    String currentTime  = '${formatNumber(now.hour)}${formatNumber(now.minute)}${formatNumber(now.second)}';
    String code         = 'INV-$currentDate$currentTime';
    String date         = DateFormat('dd/MM/yyyy').format(now);
    DateTime dt         = now;
    String hour         = dt.toIso8601String().split('T').last.split('.').first;
    String name         = "";
    String sector       = "";
    String profile      = "";

    Map<String, dynamic> inventoryRow = {
      DBInventory.columnCode: code,
      DBInventory.columnDate: date,
      DBInventory.columnHour: hour,
      DBInventory.columnName: name,
      DBInventory.columnSector: sector,
      DBInventory.columnStatus: 'NÃO INICIADO',
      DBInventory.columnProfile: profile,
      DBInventory.columnTotal: 0,
    };

    DBInventory db = DBInventory.instance;
     inventory = await db.queryFirstInventoryByStatus();
    
    if (inventory == null) { 
      int st = await db.insertInventory(inventoryRow);
      inventory = await db.queryFirstInventoryByStatus();
      _statusController = 0;
    }
    else if(inventory?["status"]=="EM ANDAMENTO"){
      _statusController = 1;
    }
    
    if (inventory != null) { 
      _codeController.text    = inventory?["code"];
      _dateController.text    = '${inventory?["date"]} $hour';
      _nameController.text    = inventory?["name"];
      _sectorController.text  = inventory?["sector"];
      _selectedProfile        = inventory?["profile"] ?? "";
    }
    setState(() {});
  }

  Future<int> updateInventoryStatus(Map<String, dynamic> inventory) async {
    final db = DBInventory.instance;
    int st = await db.update({
      DBInventory.columnId: inventory["_id"],
      DBInventory.columnStatus: inventory["status"]!=''?inventory["status"]:'',
      DBInventory.columnName: inventory["name"]!=''?inventory["name"]:_nameController.text,
      DBInventory.columnSector: inventory["sector"]!=''?inventory["sector"]:_sectorController.text,
      DBInventory.columnProfile: inventory["profile"] != '' ? inventory["profile"] : _selectedProfile,
    });
    return st;
  }

  // Confirmação para finalizar
  void _showConfirFinish(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          content: const Text(
            'Deseja realmente finalizar o inventário?\n'
            'Esta ação bloqueará todas as alterações.', 
            style: TextStyle(fontSize: 18,),
          ),
          actions: [
            Row(
              children: [
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
                      Navigator.of(context).pop(); // Fecha o popup
                    },
                    child: const Text('CANCELAR', style: TextStyle(color: Colors.white),),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      finishInventory();
                      Navigator.of(context).pop(); // Fecha o popup
                    },
                    child: const Text('SIM', style: TextStyle(color: Colors.white),),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
      title: '',
      subtitle: 'Criação de Inventário',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 4.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: inventory?['status'] == 'EM ANDAMENTO'
                          ? Colors.orange
                          : inventory?['status'] == 'CONCLUÍDO'
                              ? Colors.green
                              : Colors.blue,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      inventory?['status'] ?? 'NÃO INICIADO',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              flex: 3,
                              child: TextField(
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Código do Inventário',
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(fontSize: 18),
                                controller: _codeController,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              flex: 2,
                              child: TextField(
                                readOnly: true,
                                decoration: const InputDecoration(
                                  labelText: 'Data de Criação',
                                  border: OutlineInputBorder(),
                                ),
                                style: const TextStyle(fontSize: 18),
                                controller: _dateController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(thickness: 1, color: Colors.grey),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Nome do Inventário',
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 18),
                          controller: _nameController,
                          inputFormatters: [
                            TextInputFormatter.withFunction(
                              (oldValue, newValue) => newValue.copyWith(
                                text: newValue.text.toUpperCase(),
                                selection: newValue.selection,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            labelText: 'Setor',
                            border: OutlineInputBorder(),
                          ),
                          style: const TextStyle(fontSize: 18),
                          controller: _sectorController,
                          inputFormatters: [
                            TextInputFormatter.withFunction(
                              (oldValue, newValue) => newValue.copyWith(
                                text: newValue.text.toUpperCase(),
                                selection: newValue.selection,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 54,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Selecione um perfil de configuração',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                style: const TextStyle(fontSize: 18, color: Colors.black),
                                value: _selectedProfile.isNotEmpty ? _selectedProfile : null,
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedProfile = newValue ?? '';
                                  });
                                },
                                items: _profileOptions.map((String profile) {
                                  return DropdownMenuItem<String>(
                                    value: profile,
                                    child: Text(profile),
                                  );
                                }).toList(),
                                isExpanded: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      floatingButtons: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          CustomButton.processButton(
            context,
            'INICIAR',
            1,
            Icons.play_arrow,
            updateControlls(1)
                ? () {
                    FocusScope.of(context).unfocus();
                    startInventory();
                  }
                : null,
            updateControlls(1) ? null : Colors.grey,
          ),
          const SizedBox(height: 10),
          CustomButton.processButton(
            context,
            'REGISTRAR ITENS',
            1,
            Icons.qr_code_scanner,
            updateControlls(0)
                ? () async {
                    int result = await startInventory();
                    if (result == 1) {
                      Navigator.pushNamed(
                        context,
                        '/inventoryRecord',
                        arguments: {
                          'selectedProfile': _selectedProfile,
                          'inventoryId': inventory?["_id"] ?? 0,
                        },
                      );
                    }
                  }
                : null,
            updateControlls(0) ? null : Colors.grey,
          ),
          const SizedBox(height: 10),
          CustomButton.processButton(
            context,
            'FINALIZAR',
            1,
            Icons.check_circle,
            updateControlls(2)
                ? () {
                    _showConfirFinish(context);
                  }
                : null,
            updateControlls(2) ? null : Colors.grey,
          ),
          const SizedBox(height: 10),
          CustomButton.processButton(
            context,
            'CANCELAR',
            1,
            Icons.cancel,
            updateControlls(3)
                ? () {
                    Navigator.pushReplacementNamed(
                      context,
                      '/management',
                    );
                  }
                : null,
            updateControlls(3) ? null : Colors.grey,
          ),
        ],
      ),

    );
  }
}