import 'package:flutter/material.dart';
import 'inventRecords.dart';
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
  Map<String, dynamic>? inventory;

  @override
  void initState() {
    super.initState();

    // Chama o método createInventory quando a página é carregada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      createInventory();
    });
  }

  Future<void> startInventory() async {
    // Busca o inventário com status Não Iniciado ou Iniciado
    DBInventory db = DBInventory.instance;
    Map<String, dynamic>? inventory = await db.queryFirstInventoryByStatus();

    if (inventory != null) { // Atualizapara iniciado
      await updateInventoryStatus(inventory["_id"], 'INICIADO');
    }
  }

  Future<void> createInventory() async {
    //String date = DateTime.now().toIso8601String().split('T').first;
    String currentDate = DateFormat('yyyyMMdd').format(DateTime.now());
    String code = 'INV-$currentDate';
    String date = DateFormat('dd/MM/yyyy').format(DateTime.now());
    String hour = DateTime.now().toIso8601String().split('T').last.split('.').first;
    String name = "";
    String sector = "";

    //code = "INV-20242010-001";

    Map<String, dynamic> inventoryRow = {
      DBInventory.columnCode: code,
      DBInventory.columnDate: date,
      DBInventory.columnHour: hour,
      DBInventory.columnName: name,
      DBInventory.columnSector: sector,
      DBInventory.columnStatus: 'NÃO INICIADO', // Set status to INICIADO
    };

    DBInventory db = DBInventory.instance;
     inventory = await db.queryFirstInventoryByStatus();
    
    if (inventory == null) { 
      int st = await db.insertInventory(inventoryRow);
      print("Stuação.........................................: $st");
      inventory = await db.queryFirstInventoryByStatus();
    }
    if (inventory != null) { 
      _codeController.text = inventory?["code"];
      _dateController.text = inventory?["date"];
      _nameController.text = inventory?["name"];
      _sectorController.text = inventory?["sector"];
    }
  }

  Future<void> updateInventoryStatus(int inventoryId, String status) async {
    final db = DBInventory.instance;
    await db.update({
      DBInventory.columnId: inventoryId,
      DBInventory.columnStatus: status,
    });
    //loadData();  // Recarregar os dados após a atualização
  }

  @override
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criação de Inventário', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Card com informações
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'NÃO INICIADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  // Detalhes do inventário
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  labelText: 'Código do Inventário',
                                  border: OutlineInputBorder(),
                                  //controller: inventoryRow.columnCode,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: const TextField(
                                decoration: InputDecoration(
                                  labelText: 'Data de criação',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Divider(thickness: 1, color: Colors.grey), // divider
                        SizedBox(height: 10),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Nome do Inventário',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Setor',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InventoryRecordsPage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'INICIAR',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // método INICIAR
                //iniciarInventory();
                //String nomeInventario = _nomeController.text;
                updateInventoryStatus(inventory?["_id"],"INICIADO");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'FINALIZAR',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // método cancelar
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'CANCELAR',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
      // Rodapé
      bottomNavigationBar: Container(
        color: Colors.grey[200],
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

  void main() {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), 
      home: const InventoryPage(),
    ));
  }
}
