import 'package:flutter/material.dart';
import 'package:app_oxf_inv/operator/db_settings.dart';

class SettingsProfilePage extends StatefulWidget {
  const SettingsProfilePage({super.key});

  @override
  SettingsProfilePageState createState() => SettingsProfilePageState();
}

class SettingsProfilePageState extends State<SettingsProfilePage> {
  final DBSettings dbHelper = DBSettings.instance;
  List<Map<String, dynamic>> maskData = [];
  List<TextEditingController> controllers = [];

  @override
  void initState() {
    super.initState();
    _loadMaskData();
  }

  Future<void> _loadMaskData() async {
    final masks = await dbHelper.queryAllMasks();
    setState(() {
      maskData = List<Map<String, dynamic>>.from(masks);
      controllers = maskData.map((mask) => TextEditingController(text: mask['mask'])).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
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
                    DataColumn(label: Text("Perfil")),
                    DataColumn(label: Text("Ação")),
                  ],
                  rows: maskData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final mask = entry.value;
                    final controller = controllers[index];
                    return DataRow(cells: [
                      DataCell(
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: TextField(
                            controller: controller,
                            onChanged: (value) {
                              setState(() {
                                maskData[index]['mask'] = value;
                              });
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
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            if (maskData[index]['id'] != null) {
                              await dbHelper.deleteMask(maskData[index]['id']);
                            }
                            setState(() {
                              maskData.removeAt(index);
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
              onPressed: () {
                setState(() {
                  maskData.add({'mask': '', 'id': null});
                  controllers.add(TextEditingController());
                });
              },
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
                    'Adicionar Perfil',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
