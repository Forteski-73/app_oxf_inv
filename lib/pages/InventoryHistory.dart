import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_inventory.dart';
import 'InventRecordsHistory.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: const InventoryHistory(),
  ));
}

// Tela de Histórico de Inventário
class InventoryHistory extends StatefulWidget {
  const InventoryHistory({super.key});

  @override
  State<InventoryHistory> createState() => _InventoryHistoryState();
}

class _InventoryHistoryState extends State<InventoryHistory> {
  List<Map<String, dynamic>> inventoryData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInventoryData();
  }

  Future<void> _fetchInventoryData() async {
    // Obtém os dados do banco de dados
    try {
      List<Map<String, dynamic>> data = await DBInventory.instance.queryAllInventory();
      setState(() {
        inventoryData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Erro ao buscar dados do banco: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inventário - Histórico',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : inventoryData.isEmpty
              ? const Center(child: Text('Nenhum inventário encontrado.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: inventoryData.length,
                  itemBuilder: (context, index) {
                    final inventory = inventoryData[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Barra superior colorida
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: inventory[DBInventory.columnStatus] == 'EM ANDAMENTO'
                                  ? Colors.orange
                                  : inventory[DBInventory.columnStatus] == 'CONCLUÍDO'
                                      ? Colors.green
                                      : Colors.blue,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Text(
                              inventory[DBInventory.columnStatus] ?? 'NÃO INICIADO', // Atualiza com o valor do status
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          // Conteúdo do Card
                          SizedBox(
                            height: 95,
                            child: Row(
                              children: [
                                // Espaço para indicar a linha lateral colorida
                                Container(
                                  width: 12,
                                  height: double.infinity,
                                  /*color: inventory[DBInventory.columnStatus] == 'CONCLUÍDO'
                                      ? Colors.green
                                      : Colors.orange,*/
                                ),
                                // Conteúdo do ListTile
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => InventoryHistoryDetail(
                                            inventoryId: inventory[DBInventory.columnId] as int,
                                          ),
                                        ),
                                      );
                                    },
                                    child: ListTile(
                                      title: Text(inventory[DBInventory.columnName] as String),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(inventory[DBInventory.columnCode] as String),
                                          Text('${inventory[DBInventory.columnDate]} - ${inventory[DBInventory.columnStatus]}'),
                                          Text('Total de itens: ${inventory[DBInventory.columnTotal].toString()}'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 16.0),
                                    child: Icon(Icons.navigate_next_sharp),
                                  ),
                                ),
                              ],
                            ),
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
                      Text("Oxford Porcelanas", style: TextStyle(fontSize: 14),),
                      Text( "Versão: 1.0", style: TextStyle(fontSize: 14),),
                    ],
                  ),
              ),
    );
  }

  /*@override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inventário - Histórico',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : inventoryData.isEmpty
              ? const Center(child: Text('Nenhum inventário encontrado.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: inventoryData.length,
                  itemBuilder: (context, index) {
                    final inventory = inventoryData[index];
                    return Card(
                      child: SizedBox(
                        height: 100,
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: double.infinity,
                              color: inventory[DBInventory.columnStatus] == 'CONCLUÍDO'
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            // Conteúdo do ListTile
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => InventoryHistoryDetail(
                                        inventoryId: inventory[DBInventory.columnId] as int,
                                      ),
                                    ),
                                  );
                                },
                                child: ListTile(
                                  title: Text(inventory[DBInventory.columnName] as String),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(inventory[DBInventory.columnCode] as String),
                                      Text('${inventory[DBInventory.columnDate]} - ${inventory[DBInventory.columnStatus]}'),
                                      Text('Total de itens: ${inventory[DBInventory.columnTotal].toString()}'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: EdgeInsets.only(right: 16.0),
                                child: Icon(Icons.arrow_forward),
                              ),
                            ),
                          ],
                        ),
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
  }*/
}

