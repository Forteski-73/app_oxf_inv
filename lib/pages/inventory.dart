import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_inventory.dart';
import 'package:intl/intl.dart';

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
  int _statusController = 0;
  Map<String, dynamic>? inventory;

  @override
  void initState() {
    super.initState();

    _codeController.addListener(_updateButtonState);
    _dateController.addListener(_updateButtonState);
    _nameController.addListener(_updateButtonState);
    _sectorController.addListener(_updateButtonState);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await createInventory();
      setState(() {
        // Atualiza o estado para refletir mudanças no inventário
        _codeController.text = inventory?["code"] ?? '';
        _dateController.text = inventory?["date"] ?? '';
        _nameController.text = inventory?["name"] ?? '';
        _sectorController.text = inventory?["sector"] ?? '';
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
              _sectorController.text.isNotEmpty;
      case 1:
        return _statusController == 0 &&
              _codeController.text.isNotEmpty &&
              _dateController.text.isNotEmpty &&
              _nameController.text.isNotEmpty &&
              _sectorController.text.isNotEmpty;

      case 2:
        return _statusController > 0 &&
              _codeController.text.isNotEmpty &&
              _dateController.text.isNotEmpty &&
              _nameController.text.isNotEmpty &&
              _sectorController.text.isNotEmpty;
      case 3:
        return _statusController >= 0 &&
              _codeController.text.isNotEmpty &&
              _dateController.text.isNotEmpty &&
              _nameController.text.isNotEmpty &&
              _sectorController.text.isNotEmpty;
      default:
        return false;
    }
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

  Future<void> createInventory() async {
    String currentDate = DateFormat('yyyyMMdd').format(DateTime.now());
    String code   = 'INV-$currentDate';
    String date   = DateFormat('dd/MM/yyyy').format(DateTime.now());
    DateTime dt   = DateTime.now();
    String hour   = dt.toIso8601String().split('T').last.split('.').first;
    String name   = "";
    String sector = "";

    Map<String, dynamic> inventoryRow = {
      DBInventory.columnCode: code,
      DBInventory.columnDate: date,
      DBInventory.columnHour: hour,
      DBInventory.columnName: name,
      DBInventory.columnSector: sector,
      DBInventory.columnStatus: 'NÃO INICIADO',
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
            Text('Criação de Inventário',
              style: TextStyle(color: Colors.white, fontSize: 20, ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      resizeToAvoidBottomInset: false, // evita o ajuste automático do layout quando o teclado aparece
      body: Column(
        children: [
          // Parte Rolável
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
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
                        // Detalhes do inventário
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Botões Fixos
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: updateControlls(1)
                      ? () async {
                          FocusScope.of(context).unfocus();
                          int result = await startInventory();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: updateControlls(1) ? Colors.blue : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'INICIAR',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: updateControlls(0)
                      ? () async {
                          int result = await startInventory();
                          if (result == 1) {
                            Navigator.pushNamed(context, '/inventoryRecord');
                          }
                        }
                      : null,
                  icon: const Icon(Icons.barcode_reader, color: Colors.white),
                  label: const Text(
                    'REGISTRAR ITENS',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: updateControlls(0) ? Colors.blue : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: updateControlls(2)
                      ? () {
                          _showConfirFinish(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: updateControlls(2) ? Colors.blue : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('FINALIZAR', style: TextStyle(fontSize: 16, color: Colors.white),),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: updateControlls(3)
                      ? () {
                          Navigator.pushReplacementNamed(context, '/management',);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: updateControlls(3) ? Colors.blue : Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('CANCELAR', style: TextStyle(fontSize: 16, color: Colors.white),),
                ),
              ],
            ),
          ),
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Oxford Porcelanas",
                  style: TextStyle(fontSize: 14),
                ),
                Text("Versão: 1.0",
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}