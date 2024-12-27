import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_inventory.dart';
import 'inventoryExport.dart';
import 'InventoryHistory.dart';

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

  Widget _alignRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        children: [
          Expanded(
            flex: 2, // Quanto de espaço por rótulo
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3, // Ocupa o restante do espaço
            child: Text(value),
          ),
        ],
      ),
    );
  }

    Widget _alignTitle(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold),),
          ),
        ],
      ),
    );
  }

  /*Future<void> _deleteRecord(int recordId) async {
    await DBInventory.instance.deleteInventoryRecord(recordId);
    // Recarrega os dados do inventário e dos registros
    final inventory = await DBInventory.instance.queryFirstInventoryByStatus();
    final records = await DBInventory.instance.queryAllInventoryRecords();
    
    setState(() { // Atualiza o estado para refletir as alterações
      _inventory = inventory ?? {};
      _records = records;
    });
  }*/

  Future<int> _delInvent(int inventoryId) async {
    int st = 0;
    try {
      st = await DBInventory.instance.deleteInventoryAndRecords(inventoryId);

      if(st > 0) {
        // Exibição de feedback ao usuário
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro excluído com sucesso!')),
        );
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir o registro.')),
        );
      }

    } catch (e) {
      // Em caso de erro, exibir uma mensagem
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir registro: $e')),
      );
    }

    return st;
  }

  Future<void> _delInventRecord(int recordId) async {
    int st = 0;
    try {
      st = await DBInventory.instance.deleteInventoryRecord(recordId);
      if(st > 0) {
        // Recarrega os dados do inventário atual e seus registros
        final inventoryResult = await _dbInventory.database.then((db) => db.query(
              DBInventory.tableInventory,
              where: '${DBInventory.columnId} = ?',
              whereArgs: [widget.inventoryId],
            ));

        final inventoryRecordsResult = await _dbInventory.database.then((db) => db.query(
              DBInventory.tableInventoryRecord,
              where: '${DBInventory.columnInventoryId} = ?',
              whereArgs: [widget.inventoryId],
            ));

        setState(() { // Atualiza o estado com os dados mais recentes
          _inventory = inventoryResult.isNotEmpty ? inventoryResult.first : {};
          _records = inventoryRecordsResult;
        });

        ScaffoldMessenger.of(context).showSnackBar( // mostra mensagem de sucesso
          const SnackBar(content: Text('Contagem excluída com sucesso!')),
        );
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir o registro.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar os dados: $e')),
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, int recordId, int flag) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        content: const Text(
          'Deseja realmente excluir este registro?',
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
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(color: Colors.white),
                  ),
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
                  onPressed: () async {
                    Navigator.of(context).pop(); // Fecha o popup

                    if (flag == 0) { 
                      int st = await _delInvent(recordId);
                      if (st == 1) {
                        // Substitui a página atual pela InventoryRecordsPage
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InventoryHistory(), // Navega para a página de inventário
                          ),
                        );
                      }
                    } else {
                      await _delInventRecord(recordId);
                    }
                  },
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
                              : Colors.grey.shade100, // Cor padrão caso o status seja desconhecido
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _alignRow('Código do Inventário:', '${_inventory[DBInventory.columnCode]}'),
                        _alignRow('Data de criação:', '${_inventory[DBInventory.columnDate]}'),
                        _alignRow('Nome do Inventário:', '${_inventory[DBInventory.columnName]}'),
                        _alignRow('Setor:', '${_inventory[DBInventory.columnSector]}'),
                        _alignRow('Total:', '${_inventory[DBInventory.columnTotal]}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min, // Limita o tamanho da linha
                      children: [
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _showDeleteConfirmationDialog(context, _inventory[DBInventory.columnId] as int, 0);
                          },
                        ),
                      ],
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
                        title: _alignRow('Sequência:', '${record[DBInventory.columnId] ?? ''}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _alignRow('Unitizador:', '${record[DBInventory.columnUnitizer] ?? ''}'),
                            _alignRow('Depósito:', '${record[DBInventory.columnDeposit] ?? ''}'),
                            _alignRow('Código de Barras:', '${record[DBInventory.columnBarcode] ?? ''}'),
                            _alignRow('Total:', '${record[DBInventory.columnTotal] ?? ''}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _showDeleteConfirmationDialog(context, record[DBInventory.columnId] as int, 1);
                          },
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

            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min, // Altura seja mínima necessária
        children: [
          // Primeiro "bottom bar"
          if (_inventory[DBInventory.columnStatus] == 'CONCLUÍDO')
          Container(
            padding: const EdgeInsets.all(8.0), // Padding ao redor do botão
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InventoryExportPage (
                        inventoryId: _inventory[DBInventory.columnId] as int,
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min, // Ajusta o tamanho para caber no conteúdo
                  children: [
                    Icon(Icons.open_in_browser, color: Colors.white, size: 30),
                    SizedBox(width: 8), // Espaçamento entre ícone e texto
                    Text("Exportar dados", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 4),
          // Segundo "bottom bar"
          Container(
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
        ],
      ),
    );
  }
}

