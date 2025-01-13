import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_settings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  ConfiguracoesScreenState createState() => ConfiguracoesScreenState();
}

class ConfiguracoesScreenState extends State<SettingsPage> {
  late List<Map<String, dynamic>> campos = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final dbHelper = DBSettings.instance;
      List<Map<String, dynamic>> rows = await dbHelper.queryAllRows();

      if (!rows.isNotEmpty) {
        await _insertDefaultValues();
        rows = await dbHelper.queryAllRows();
      }

      setState(() {
        campos = List<Map<String, dynamic>>.from(rows);
      });
  }

  // Insere os valores padrão
  Future<void> _insertDefaultValues() async {
    final dbHelper = DBSettings.instance;

    // Valores padrões
    final List<Map<String, dynamic>> defaultValues = [
      {"_id": 1, "nome": "Unitizador",                "exibir": 1, "obrigatorio": 0},
      {"_id": 2, "nome": "Posição",                   "exibir": 1, "obrigatorio": 0},
      {"_id": 3, "nome": "Depósito",                  "exibir": 1, "obrigatorio": 0},
      {"_id": 4, "nome": "Bloco",                     "exibir": 1, "obrigatorio": 0},
      {"_id": 5, "nome": "Quadra",                    "exibir": 1, "obrigatorio": 0},
      {"_id": 6, "nome": "Lote",                      "exibir": 1, "obrigatorio": 0},
      {"_id": 7, "nome": "Andar",                     "exibir": 1, "obrigatorio": 0},
      {"_id": 8, "nome": "Código de Barras",          "exibir": 1, "obrigatorio": 0},
      {"_id": 9, "nome": "Qtde Padrão da Pilha",      "exibir": 1, "obrigatorio": 0},
      {"_id": 10, "nome": "Qtde de Pilhas Completas", "exibir": 1, "obrigatorio": 0},
      {"_id": 11, "nome": "Qtde de Itens Avulsos",    "exibir": 1, "obrigatorio": 0},
    ];

    for (var campo in defaultValues) {
      await dbHelper.insert(campo);
    }
  }

  Future<void> _updateField(int id, bool exibir, bool obrigatorio) async {
    final dbHelper = DBSettings.instance;
    await dbHelper.update({
      DBSettings.columnId: id,
      DBSettings.columnExibir: exibir ? 1 : 0,
      DBSettings.columnObrigatorio: obrigatorio ? 1 : 0,
    });
    loadData();  // Recarregar os dados após a atualização
  }

  // Restaura os padrões
  Future<void> restoreDefault() async {
    setState(() {
      for (var i = 0; i < campos.length; i++) {
        campos[i] = {...campos[i], 'exibir': 1, 'obrigatorio': 0,};
      }
    });

    // Atualizar as informações
    for (var campo in campos) {
      await _updateField(campo['_id'], true, false);
    }
  }

void _confirmRestoreDefault(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        content: const Text("Deseja mesmo restaurar o padrão?", style: TextStyle(fontWeight: FontWeight.bold,),),
        actions: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('CANCELAR', style: TextStyle(color: Colors.white),),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    restoreDefault();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
      title: const Text('Configurações', style: TextStyle(color: Colors.white)),
      backgroundColor: Colors.black,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: Stack(
      children: [
        // Imagem de fundo
        /*Positioned.fill(
          child: Image.asset('assets/images/oxf_background.png',
            fit: BoxFit.cover,
            alignment: Alignment.topLeft,
          ),
        ),*/
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Cabeçalho das colunas
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Campo',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    Text(
                      'Exibir',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(width: 25),
                    Text(
                      'Obrigatório',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const Divider(), // Espaço abaixo do cabeçalho
              Expanded(
                child: ListView.separated(
                  itemCount: campos.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final campo = campos[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(campo['nome'], style: const TextStyle(fontSize: 16)),
                        ),
                        Switch(
                          value: campo['exibir'] == 1,
                          onChanged: (value) {
                            setState(() {
                              campos[index] = {
                                ...campo, // Copia os valores do mapa atual
                                'exibir': value ? 1 : 0, // Altera o valor
                              };
                            });
                            _updateField(campo['_id'], value, campo['obrigatorio'] == 1);
                          },
                          activeColor: Colors.green,
                        ),
                        const SizedBox(width: 45),
                        Switch(
                          value: campo['obrigatorio'] == 1,
                          onChanged: (value) {
                            setState(() {
                              campos[index] = {
                                ...campo, // Copia os valores do mapa atual
                                'obrigatorio': value ? 1 : 0, // Altera o valor
                              };
                            });
                            _updateField(campo['_id'], campo['exibir'] == 1, value);
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(
                width: double.infinity, 
                child: TextButton(
                  onPressed: () {
                    _confirmRestoreDefault(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min, // Ajusta o tamanho para caber no conteúdo
                    children: [
                      Icon(Icons.refresh, color: Colors.white, size: 30),
                      SizedBox(width: 8),
                      Text("Restaurar Padrão", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
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
  void main() {
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const SettingsPage(),
    ));
  }
}