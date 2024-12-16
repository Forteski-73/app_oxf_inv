import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_inventory.dart';
import 'inventoryExport.dart';

class InventoryHistoryDetail extends StatefulWidget {
  final int inventoryId;

  const InventoryHistoryDetail({Key? key, required this.inventoryId}) : super(key: key);

  @override
  _InventoryHistoryDetailState createState() => _InventoryHistoryDetailState();
}

class _InventoryHistoryDetailState extends State<InventoryHistoryDetail> {
  late DBInventory _dbInventory;
  Map<String, dynamic> _inventory = {};
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dbInventory = DBInventory.instance;
    _fetchInventoryDetails();
  }

  Future<void> _fetchInventoryDetails() async {
    try {
      // Buscar os detalhes do inventário
      final inventoryResult = await _dbInventory.database.then((db) => db.query(
            DBInventory.tableInventory,
            where: '${DBInventory.columnId} = ?',
            whereArgs: [widget.inventoryId],
          ));

      // Buscar os registros do inventário
      final recordsResult = await _dbInventory.database.then((db) => db.query(
            DBInventory.tableInventoryRecord,
            where: '${DBInventory.columnInventoryId} = ?',
            whereArgs: [widget.inventoryId],
          ));

      setState(() {
        _inventory = inventoryResult.isNotEmpty ? inventoryResult.first : {};
        _records = recordsResult;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar os dados: $e')),
      );
    }
  }

  @override
    Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _inventory['code'] ?? 'Detalhes do Inventário',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: _inventory[DBInventory.columnStatus] == 'CONCLUÍDO'
                        ? Colors.green.shade100
                        : _inventory[DBInventory.columnStatus] == 'EM ANDAMENTO'
                            ? Colors.orange.shade100
                            : _inventory[DBInventory.columnStatus] == 'NÃO INICIADO'
                                ? Colors.blue.shade100
                                : Colors.grey.shade100,  // Cor padrão caso o status seja desconhecido
                    child: ListTile(
                      title: Text(
                        _inventory[DBInventory.columnStatus] ?? 'Status não disponível',
                        style: TextStyle(
                          color: _inventory[DBInventory.columnStatus] == 'CONCLUÍDO'
                              ? Colors.green
                              : _inventory[DBInventory.columnStatus] == 'EM ANDAMENTO'
                                  ? Colors.orange
                                  : _inventory[DBInventory.columnStatus] == 'NÃO INICIADO'
                                      ? Colors.blue
                                      : Colors.grey, // Cor para status desconhecido
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Código do Inventário: ${_inventory[DBInventory.columnCode] ?? ''}\n'
                        'Data de criação: ${_inventory[DBInventory.columnDate] ?? ''}\n'
                        'Nome do Inventário: ${_inventory[DBInventory.columnName] ?? ''}\n'
                        'Setor: ${_inventory[DBInventory.columnSector] ?? ''}\n'
                        'Total: ${_inventory[DBInventory.columnTotal] ?? ''}',
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  const Text(
                    'Itens do Inventário',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  if (_records.isEmpty)
                    Text('Nenhum item encontrado.')
                  else
                    ..._records.map((record) {
                      return Card(
                        child: ListTile(
                          title: Text(
                            'Sequência: ${record[DBInventory.columnId] ?? ''}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Unitizador: ${record[DBInventory.columnUnitizer] ?? ''}\n'
                            'Depósito: ${record[DBInventory.columnDeposit] ?? ''}\n'
                            'Código de Barras: ${record[DBInventory.columnBarcode] ?? ''}\n'
                            'Total: ${record[DBInventory.columnTotal] ?? ''}',
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
          // Botão fixo na parte inferior
          Positioned(
            bottom: 5, // Ajuste a posição vertical conforme necessário
            left: 10,
            right: 10,
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InventoryExportPage(
                        inventoryId: _inventory[DBInventory.columnId] as int,
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min, // Ajusta o tamanho para caber no conteúdo
                  children: [
                    Icon(Icons.open_in_browser, color: Colors.white),
                    SizedBox(width: 8), // Espaçamento entre ícone e texto
                    Text("Exportar dados", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
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

