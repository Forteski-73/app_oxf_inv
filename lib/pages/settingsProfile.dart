import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_settings.dart';
import 'settings.dart';
import 'package:app_oxf_inv/widgets/basePage.dart';
import 'package:app_oxf_inv/widgets/customButton.dart';
import 'package:app_oxf_inv/widgets/customSnackBar.dart';
import 'package:flutter/services.dart';

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
        CustomSnackBar.show(context, message: 'Configuração excluída com sucesso!',
          duration: const Duration(seconds: 3),type: SnackBarType.success,
        );
      } else {
        CustomSnackBar.show(context, message: 'Erro ao excluir o registro.',
          duration: const Duration(seconds: 3),type: SnackBarType.error,
        );
      }
    } catch (e) {
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
                          inputFormatters: [
                            TextInputFormatter.withFunction(
                              (oldValue, newValue) => newValue.copyWith(
                                text: newValue.text.toUpperCase(),
                                selection: newValue.selection,
                              ),
                            ),
                          ],
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
        Colors.blue,
      ),

    );
  }
}