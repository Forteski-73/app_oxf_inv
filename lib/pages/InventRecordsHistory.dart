import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_inventory.dart';
import 'inventoryExport.dart';
import 'package:app_oxf_inv/widgets/basePage.dart';
import 'package:app_oxf_inv/widgets/customSnackBar.dart';
import 'package:app_oxf_inv/widgets/customButton.dart';

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
  String _searchText = '';
  TextEditingController _searchController = TextEditingController();

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
        _isLoading = false; // Dados carregados, atualiza estado
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // Em caso de erro, para de carregar
      });
      CustomSnackBar.show(context, message: "Erro ao carregar os dados: $e",
        duration: const Duration(seconds: 4),type: SnackBarType.error,
      );
    }
  }

  Widget _alignRow(String label, Widget valueWidget) {
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
            flex: 4,
            child: valueWidget,
          ),
        ],
      ),
    );
  }

  Future<int> _delInvent(int inventoryId) async {
    int st = 0;
    try {
      st = await DBInventory.instance.deleteInventoryAndRecords(inventoryId);

      if(st > 0) {
        CustomSnackBar.show(context, message: 'Registro excluído com sucesso!',
          duration: const Duration(seconds: 3),type: SnackBarType.success,
        );
      }
      else {
        CustomSnackBar.show(context, message: "Erro ao excluir o registro.",
          duration: const Duration(seconds: 4),type: SnackBarType.error,
        );
      }

    } catch (e) {
      CustomSnackBar.show(context, message: "Erro ao excluir registro: $e",
        duration: const Duration(seconds: 4),type: SnackBarType.error,
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

        CustomSnackBar.show(context, message: 'Contagem excluída com sucesso!',
          duration: const Duration(seconds: 3),type: SnackBarType.success,
        );
      }
      else {
        CustomSnackBar.show(context, message: 'Erro ao excluir o registro.',
          duration: const Duration(seconds: 4),type: SnackBarType.error,
        );
      }
    } catch (e) {
      CustomSnackBar.show(context, message: 'Erro ao atualizar os dados: $e',
        duration: const Duration(seconds: 4),type: SnackBarType.error,
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, int recordId, int flag) async {
    final scaffoldContext = context; // Salva o contexto antes de exibir o diálogo pra não dar pau depois
    return showDialog<void>(
      context: scaffoldContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          content: const Text('Deseja realmente excluir este registro?',),
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
                      Navigator.of(dialogContext).pop(); // Fecha o popup
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
                      Navigator.of(dialogContext).pop(); // Fecha o popup
                      if (flag == 0) {
                        int st = await _delInvent(recordId);
                        if (st == 1) {
                          Navigator.pop(context, true);
                        }
                      } else {
                        await _delInventRecord(recordId);
                      }
                    },
                    child: const Text('SIM',
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
    return BasePage(
      title: 'Aplicativo de Consulta de Estrutura de Produtos. ACEP',
      subtitle: _inventory['code'] ?? 'Detalhes do Inventário',
      body: _isLoading // Exibir carregando.. até que os dados estejam prontos
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _inventory.isEmpty // Se o inventário estiver vazio após carregar
              ? const Center(child: Text('Inventário não encontrado.'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('INVENTÁRIO',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Card(
                          color: _inventory[DBInventory.columnStatus] == 'CONCLUÍDO'
                              ? Colors.green.shade100
                              : _inventory[DBInventory.columnStatus] == 'EM ANDAMENTO'
                                  ? Colors.orange.shade100
                                  : _inventory[DBInventory.columnStatus] == 'NÃO INICIADO'
                                      ? Colors.blue.shade100
                                      : Colors.grey.shade100,
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
                                            : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: _inventory.isEmpty
                                ? const Text('Inventário excluído.')
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _alignRow('Código:',  Text('${_inventory[DBInventory.columnCode]}')),
                                      _alignRow('Data:',    Text('${_inventory[DBInventory.columnDate]}')),
                                      _alignRow('Nome:',    Text('${_inventory[DBInventory.columnName]}')),
                                      _alignRow('Setor:',   Text('${_inventory[DBInventory.columnSector]}')),
                                      _alignRow('Total:',   Text('${_inventory[DBInventory.columnTotal] ?? 0}')),
                                    ],
                                  ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await _showDeleteConfirmationDialog(context, _inventory[DBInventory.columnId] as int, 0);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Filtrar por produto',
                              hintText: 'Imformação do produto...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color.fromARGB(255, 160, 241, 171), // Verde ao focar
                                  width: 2.0,
                                ),
                              ),
                              suffixIcon: _searchText.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchText = '');
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchText = value.toLowerCase();
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 6),
                        const Text('ITENS DO INVENTÁRIO',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        ..._records.where((record) {
                          final unitizer    = record[DBInventory.columnUnitizer]?.toString().toLowerCase() ?? '';
                          final item        = record[DBInventory.columnItem]?.toString() ?? '';
                          final barcode     = record[DBInventory.columnBarcode]?.toString().toLowerCase() ?? '';
                          final description = record[DBInventory.columnDescription]?.toString().toLowerCase() ?? '';
                          
                          
                          return unitizer.contains(_searchText) ||
                                item.contains(_searchText) ||
                                barcode.contains(_searchText) ||
                                description.contains(_searchText);
                                
                        }).map((record) {
                          return Card(
                            child: ListTile(
                              title: _alignRow('Sequência:', Text('${record[DBInventory.columnId] ?? ''}')),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _alignRow('Unitizador:', Text('${record[DBInventory.columnUnitizer] ?? ''}')),
                                  _alignRow('Depósito:', Text('${record[DBInventory.columnDeposit] ?? ''}')),
                                  _alignRow('Produto:', Text('${record[DBInventory.columnItem] ?? ''}')),
                                  _alignRow('Código de Barras:', Text('${record[DBInventory.columnBarcode] ?? ''}')),
                                  _alignRow(
                                    'Nome:',
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 350), // limite horizontal
                                        child: Text(
                                          '${record[DBInventory.columnDescription] ?? ''}',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          softWrap: true,
                                        ),
                                      ),
                                    ),
                                  ),
                                  _alignRow('Total:', Text('${record[DBInventory.columnTotal] ?? ''}')),
                                ],
                              ),
                              trailing: SizedBox(
                                width: 15,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(), // remove restrições de tamanho
                                    onPressed: () async {
                                      await _showDeleteConfirmationDialog(context, record[DBInventory.columnId] as int, 1);
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
      floatingButtons: _inventory[DBInventory.columnStatus] == 'CONCLUÍDO'
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CustomButton.processButton(
                context,
                'Exportar dados',
                1,
                Icons.open_in_browser,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InventoryExportPage(
                        inventoryId: _inventory[DBInventory.columnId] as int,
                      ),
                    ),
                  );
                },
                Colors.blue,
              ),
            )
          : null,
    );
  }
}

