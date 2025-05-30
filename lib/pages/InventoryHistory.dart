import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_inventory.dart';
import 'package:app_oxf_inv/widgets/basePage.dart';
import 'package:app_oxf_inv/widgets/customSnackBar.dart';
import 'package:app_oxf_inv/styles/btnStyles.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: const InventoryHistory(),
    navigatorObservers: [routeObserver], // Adiciona o observador de rotas
  ));
}

class InventoryHistory extends StatefulWidget {
  const InventoryHistory({super.key});

  @override
  State<InventoryHistory> createState() => _InventoryHistoryState();
}

class _InventoryHistoryState extends State<InventoryHistory> with RouteAware {
  List<Map<String, dynamic>> inventoryData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInventoryData();
  }

  Future<void> _fetchInventoryData() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> data = await DBInventory.instance.queryAllInventory();
      // verifica se os objetos da página já estão montados no contexto
      if (mounted) { 
        setState(() {
          inventoryData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) { 
        setState(() {
          isLoading = false;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar dados do banco: $e', style: const TextStyle(fontSize: 18))));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      routeObserver.subscribe(this, route); // Inscreve o observador de rotas
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // Atualiza os dados quando a página for recarregada a partir da opção de voltar
    _fetchInventoryData();
  }

  @override
  Widget build(BuildContext context) {
    return BasePage(
    title: '',
    subtitle: 'Inventário Histórico',
    body: isLoading
      ? const Center(child: CircularProgressIndicator(color: Colors.white))
      : inventoryData.isEmpty
        ? const Center(child: Text('Nenhum inventário encontrado.'))
        : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Column(
              children: [
                // Aqui você pode colocar outros widgets se necessário.
                ListView.builder(
                  shrinkWrap: true,  // Faz o ListView ocupar apenas o espaço necessário
                  physics: NeverScrollableScrollPhysics(),  // Desabilita rolagem do ListView
                  padding: const EdgeInsets.all(8.0),
                  itemCount: inventoryData.length,
                  itemBuilder: (context, index) {
                    final inventory = inventoryData[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                              inventory[DBInventory.columnStatus] ?? 'NÃO INICIADO',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 95,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: double.infinity,
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () async {
                                      final result = await Navigator.pushNamed(
                                        context, '/inventoryHistoryDetail',
                                        arguments: inventory[DBInventory.columnId] as int,
                                      );
                                      if (result == true) {
                                        _fetchInventoryData(); // Atualiza os dados
                                      }
                                    },
                                    child: ListTile(
                                      title: Text(inventory[DBInventory.columnName] as String),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(inventory[DBInventory.columnCode] as String),
                                          Text('${inventory[DBInventory.columnDate]} - ${inventory[DBInventory.columnStatus]}'),
                                          Text('Total de itens: ${inventory[DBInventory.columnTotal] ?? '0'}'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const Align(
                                  alignment: Alignment.center,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 16.0),
                                    child: Icon(Icons.navigate_next_sharp, size: 30, color: Colors.black),
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
              ],
            ),
          ),
        ),
    );
  }
}