import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _ConfiguracoesScreenState createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<SettingsPage> {
    // Definição da lista de campos
    final List<Map<String, dynamic>> campos = [
      {"nome": "Utilizador",                "exibir": true, "obrigatorio": false},
      {"nome": "Posição",                   "exibir": true, "obrigatorio": false},
      {"nome": "Depósito",                  "exibir": true, "obrigatorio": false},
      {"nome": "Bloco",                     "exibir": true, "obrigatorio": false},
      {"nome": "Quadra",                    "exibir": true, "obrigatorio": false},
      {"nome": "Lote",                      "exibir": true, "obrigatorio": false},
      {"nome": "Andar",                     "exibir": true, "obrigatorio": false},
      {"nome": "Código de Barras",          "exibir": true, "obrigatorio": false},
      {"nome": "Qtde Padrão da Pilha",      "exibir": true, "obrigatorio": false},
      {"nome": "Qtde de Pilhas Completas",  "exibir": true, "obrigatorio": false},
      {"nome": "Qtde de Itens Avulsos",     "exibir": true, "obrigatorio": false},
    ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                        value: campo['exibir'],
                        onChanged: (value) {
                          setState(() {
                            campo['exibir'] = value;
                          });
                        },
                        activeColor: Colors.green,
                      ),
                      //if (campo['obrigatorio'] != null)
                        Switch(
                          value: campo['obrigatorio'],
                          onChanged: (value) {
                            setState(() {
                              campo['obrigatorio'] = value;
                            });
                          },
                          activeColor: Colors.green,
                        )
                      /*else
                        Icon(
                            Icons.block,
                            color: campo['obrigatorio'] != null ? Colors.green : Colors.grey,
                        ),*/
                    ],
                  );
                },
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                "Restaurar Padrão",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
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
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(),
    home: const SettingsPage(),
  ));
}