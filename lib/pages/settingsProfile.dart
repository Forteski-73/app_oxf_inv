import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_settings.dart';
import 'settings.dart';
import 'package:app_oxf_inv/widgets/basePage.dart';
import 'package:app_oxf_inv/widgets/customButton.dart';
import 'package:app_oxf_inv/widgets/customSnackBar.dart';

class SettingsProfilePage extends StatefulWidget {
  const SettingsProfilePage({super.key});

  @override
  SettingsProfilePageState createState() => SettingsProfilePageState();
}

class SettingsProfilePageState extends State<SettingsProfilePage> {
  final DBSettings dbHelper = DBSettings.instance;
  List<Map<String, dynamic>> profilesData = [];
  List<TextEditingController> controllers = [];

  @override
  void initState() {
    super.initState();
    _loadSettingsProfileData();
  }

  Future<void> _UpdateSettingsProfileData(int profileId, String profileName) async {
    if (profileId > 0 && profileName.isNotEmpty) {
      Map<String, dynamic> updatedData = {
        '_id': profileId,
        'profile': profileName,
      };

      await dbHelper.updateSettingsProfile(updatedData);

      setState(() {
        final index = profilesData.indexWhere((profile) => profile['_id'] == profileId);
        if (index != -1) {
          profilesData[index]['profile'] = profileName;
          controllers[index].text = profileName;
        }
      });
    }
  }

  Future<void> _loadSettingsProfileData() async {
    final profiles = await dbHelper.queryAllSettingsProfiles();
    setState(() {
      profilesData = profiles.map((e) => Map<String, dynamic>.from(e)).toList();
      controllers = profilesData.map((profile) => TextEditingController(text: profile['profile'])).toList();
    });
  }

  Future<void> _addProfile() async {
    int newId = await dbHelper.insertSettingsProfile({'profile': ''});
    setState(() {
      profilesData.add({'profile': '', '_id': newId});
      controllers.add(TextEditingController());
    });
  }

  Future<void> _delProfileRecord(int recordId) async {
    int st = 0;
    try {
      st = await dbHelper.deleteSettingsProfile(recordId);
      if (st > 0) {
        /*ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuração excluída com sucesso!', style: TextStyle(fontSize: 18))),
        );*/
        CustomSnackBar.show(context, message: 'Configuração excluída com sucesso!',
          duration: const Duration(seconds: 3),type: SnackBarType.success,
        );
      } else {
        /*ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir o registro.', style: TextStyle(fontSize: 18))),
        );*/
        CustomSnackBar.show(context, message: 'Erro ao excluir o registro.',
          duration: const Duration(seconds: 3),type: SnackBarType.error,
        );
      }
    } catch (e) {
      /*ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar os dados: $e', style: const TextStyle(fontSize: 18))),
      );*/
      CustomSnackBar.show(context, message: 'Erro ao atualizar os dados: $e',
        duration: const Duration(seconds: 4),type: SnackBarType.error,
      );
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, int recordId) async {
    final scaffoldContext = context;
    return showDialog<void>(
      context: scaffoldContext,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: const Text('Deseja realmente excluir este registro?'),
          actions: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('CANCELAR', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      await _delProfileRecord(recordId);
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('SIM', style: TextStyle(color: Colors.white)),
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
      title: "Aplicativo de Consulta de Estrutura de Produtos. ACEP",
      subtitle: "Configurações",
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              child: DataTable(
                columnSpacing: 20.0,
                columns: const [
                  DataColumn(
                    label: Text("Lista de Configurações", style: TextStyle(fontSize: 18)),
                  ),
                  DataColumn(label: Text("")),
                  DataColumn(label: Text("")),
                ],
                rows: profilesData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = controllers[index];

                  return DataRow(cells: [
                    DataCell(
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: TextField(
                          controller: controller,
                          onChanged: (value) async {
                            profilesData[index]['profile'] = value;
                            if (profilesData[index]['_id'] != null) {
                              _UpdateSettingsProfileData(profilesData[index]['_id'], profilesData[index]['profile']);
                            }
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: '',
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.blue, size: 30),
                        onPressed: () {
                          if (profilesData.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SettingsPage(
                                  profileId: profilesData[index]['_id'],
                                ),
                              ),
                            );
                          } else {
                            /*ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Adicione um perfil primeiro.')),
                            );*/
                            CustomSnackBar.show(context, message: 'Adicione um perfil primeiro.',
                              duration: const Duration(seconds: 4),type: SnackBarType.warning,
                            );
                          }
                        },
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          if (profilesData[index]['_id'] != null) {
                            _showDeleteConfirmationDialog(context, profilesData[index]['_id']);
                          }
                          setState(() {
                            profilesData.removeAt(index);
                            controllers.removeAt(index);
                          });
                        },
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),

      floatingButtons: CustomButton.processButton(
        context,
        "Adicionar",
        1,
        Icons.playlist_add,
        _addProfile,
      ),

    );
  }
}



/*
import 'package:flutter/material.dart'; 
import 'package:app_oxf_inv/operator/db_settings.dart';
import 'settings.dart';

class SettingsProfilePage extends StatefulWidget {
  const SettingsProfilePage({super.key});

  @override
  SettingsProfilePageState createState() => SettingsProfilePageState();
}

class SettingsProfilePageState extends State<SettingsProfilePage> {
  final DBSettings dbHelper = DBSettings.instance;
  List<Map<String, dynamic>> profilesData = [];
  List<TextEditingController> controllers = [];

  @override
  void initState() {
    super.initState();
    _loadSettingsProfileData();
  }

Future<void> _UpdateSettingsProfileData(int profileId, String profileName) async {
  if (profileId > 0 && profileName.isNotEmpty) {
    Map<String, dynamic> updatedData = {
      '_id': profileId,
      'profile': profileName,
    };

    await dbHelper.updateSettingsProfile(updatedData);

    setState(() {
      final index = profilesData.indexWhere((profile) => profile['id'] == profileId);
      if (index != -1) {
        profilesData[index]['profile'] = profileName;
        controllers[index].text = profileName; // Atualiza o campo de texto com o novo valor
      }
    });
  }
}

  Future<void> _loadSettingsProfileData() async {
    final profiles = await dbHelper.queryAllSettingsProfiles();
    setState(() {
      profilesData = profiles.map((e) => Map<String, dynamic>.from(e)).toList(); // Copia cada mapa para torná-lo mutável
      controllers = profilesData.map((profile) => TextEditingController(text: profile['profile'])).toList();
    });
  }

  Future<void> _addProfile() async {
    // Insere no banco e obtém o ID gerado
    int newId = await dbHelper.insertSettingsProfile({'profile': ''});

    setState(() {
      profilesData.add({'profile': '', '_id': newId});
      controllers.add(TextEditingController());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aplicativo de Consulta de Estrutura de Produtos. ACEP',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            SizedBox(height: 2),
            Text(
              'Configurações',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: DataTable(
                  columnSpacing: 20.0,
                  columns: const [
                    DataColumn(
                      label: Text(
                        "Lista de Configurações",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        "",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                  rows: profilesData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = controllers[index];
                    
                    return DataRow(cells: [
                      DataCell(
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          child: TextField(
                            controller: controller,
                            onChanged: (value) async {
                              profilesData[index]['profile'] = value;
                              if (profilesData[index]['_id'] != null) {
                                _UpdateSettingsProfileData(profilesData[index]['_id'],profilesData[index]['profile']);
                              }
                            },
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              labelText: '',
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.settings, color: Colors.blue, size: 30),
                          onPressed: () {
                            if (profilesData.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettingsPage(
                                    profileId: profilesData[index]['_id'],
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Adicione um perfil primeiro.')),
                              );
                            }
                          },
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            if (profilesData[index]['_id'] != null) {
                              // Remove do banco de dados
                              _showDeleteConfirmationDialog(context, profilesData[index]['_id']);
                            }
                            setState(() {
                              profilesData.removeAt(index);
                              controllers.removeAt(index);
                            });
                          },
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.playlist_add, color: Colors.white, size: 30),
                  SizedBox(width: 5),
                  Text(
                    'Adicionar',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
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

   Future<void> _showDeleteConfirmationDialog(BuildContext context, int recordId) async {
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
                      await _delProfileRecord(recordId);
                      Navigator.of(dialogContext).pop(); // Fecha o popup
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


  Future<void> _delProfileRecord(int recordId) async {
    int st = 0;
    try {
      st = await DBSettings.instance.deleteSettingsProfile(recordId);
      if(st > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuração excluída com sucesso!', style: TextStyle(fontSize: 18))),
        );
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir o registro.', style: TextStyle(fontSize: 18))),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar os dados: $e', style: const TextStyle(fontSize: 18))),
      );
    }
  }

}
*/