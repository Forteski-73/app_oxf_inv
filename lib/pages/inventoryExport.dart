import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:app_oxf_inv/operator/db_inventory.dart';
import 'package:app_oxf_inv/operator/db_inventoryExport.dart';
import 'package:ftpconnect/ftpconnect.dart';

class InventoryExportPage extends StatefulWidget {
  final int inventoryId;
  const InventoryExportPage({Key? key, required this.inventoryId}) : super(key: key);

  @override
  _InventoryExportPage createState() => _InventoryExportPage();
}

class _InventoryExportPage extends State<InventoryExportPage> {
  final TextEditingController _fileNameController = TextEditingController();
  final List<String> _fields = ['Unitizador', 'Posição', 'Depósito', 'Bloco', 'Quadra', 'Lote', 'Andar',
    'Código de Barras', 'Qtde Padrão da Pilha', 'Qtde de Pilhas Completas', 'Qtde de Itens Avulsos'];
  Map<String, bool> _selectedFields               = {};
  Map<String, dynamic> _inventory                 = {};
  List<Map<String, dynamic>> _records             = [];
  String _separator                               = ';';
  final TextEditingController _emailController    = TextEditingController();
  TextEditingController _fileHostController       = TextEditingController();
  TextEditingController _filePathController       = TextEditingController();
  final TextEditingController _userController     = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _exportToEmail                             = true;
  bool _exportToFilePath                          = false;
  late DBInventory _dbInventory;
  late DBInventoryExport _dbInventoryExport;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dbInventory = DBInventory.instance;
    _dbInventoryExport = DBInventoryExport.instance;


    for (var field in _fields) {
      _selectedFields[field] = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await _fetchInventoryDetails();
        await _loadExportSettings();
      }
    });
  }

  Future<void> _loadExportSettings() async {
    final settings = await _dbInventoryExport.loadExportSettings();

    if (settings.isNotEmpty) {
      setState(() {
        _selectedFields.addAll(settings['selectedFields'] ?? {});
        _fileNameController.text  = settings['fileName'] ?? '';
        _exportToEmail            = settings['exportToEmail'] ?? true;
        _exportToFilePath         = settings['exportToFilePath'] ?? false;
        _emailController.text     = settings['email'] ?? '';
        _filePathController.text  = settings['filePath'] ?? '';
        _fileHostController.text  = settings['host'] ?? '';
        _userController.text      = settings['user'] ?? '';
        _passwordController.text  = settings['password'] ?? '';

        // Inicializa os checkboxs
          _selectedFields = {
          "Unitizador":               settings['unitizador'],
          "Posição":                  settings['posicao'],
          "Depósito":                 settings['deposito'],
          "Bloco":                    settings['bloco'],
          "Quadra":                   settings['quadra'],
          "Lote":                     settings['lote'],
          "Andar":                    settings['andar'],
          "Código de Barras":         settings['codigoDeBarras'],
          "Qtde Padrão da Pilha":     settings['qtdePadraoDaPilha'],
          "Qtde de Pilhas Completas": settings['qtdeDePilhasCompletas'],
          "Qtde de Itens Avulsos":    settings['qtdeDeItensAvulsos'],
          "exportToFilePath":         settings['exportToFilePath'],
          "exportToEmail":            settings['exportToEmail'],
        };
      });
    }
  }

  Future<void> _fetchInventoryDetails() async {
    try {
      final inventoryResult = await _dbInventory.database.then((db) => db.query(
        DBInventory.tableInventory,
        where: '${DBInventory.columnId} = ?',
        whereArgs: [widget.inventoryId],
      ));

      final recordsResult = await _dbInventory.database.then((db) => db.query(
        DBInventory.tableInventoryRecord,
        where: '${DBInventory.columnInventoryId} = ?',
        whereArgs: [widget.inventoryId],
      ));

      setState(() {
        _inventory = inventoryResult.isNotEmpty ? inventoryResult.first : {};
        _records = recordsResult;
        _isLoading = false;

        // Atualiza o nome do arquivo após carregar os dados
        if (_inventory.isNotEmpty) {
          _fileNameController.text = '${_inventory[DBInventory.columnCode] ?? ''}.xlsx';
        }
        _filePathController.text = '/Ox_imagens/';
        _fileHostController.text = 'oxserver.oxford.ind.br';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> exportToExcel(BuildContext context) async {
    try {
      await _dbInventoryExport.saveExportSettings(
        _selectedFields['Unitizador'] ?? false,
        _selectedFields['Posição'] ?? false,
        _selectedFields['Depósito'] ?? false,
        _selectedFields['Bloco'] ?? false,
        _selectedFields['Quadra'] ?? false,
        _selectedFields['Lote'] ?? false,
        _selectedFields['Andar'] ?? false,
        _selectedFields['Código de Barras'] ?? false,
        _selectedFields['Qtde Padrão da Pilha'] ?? false,
        _selectedFields['Qtde de Pilhas Completas'] ?? false,
        _selectedFields['Qtde de Itens Avulsos'] ?? false,
        _fileNameController.text,
        _exportToEmail,
        _exportToFilePath,
        _emailController.text,
        _filePathController.text,
        _fileHostController.text,
        _userController.text,
        _passwordController.text,
      );

      Database db = await DBInventory.instance.database;

      List<Map<String, dynamic>> inventoryRecords = await db.query(
        DBInventory.tableInventoryRecord,
        where: '${DBInventory.columnInventoryId} = ?',
        whereArgs: [widget.inventoryId],
      );

      var excel = Excel.createExcel();
      excel.rename('Sheet1', 'Inventário');
      var sheet = excel['Inventário'];

      // Colunas do cabeçalho
      List<String> selectedHeaders = _fields.where((field) => _selectedFields[field] == true).toList();
      sheet.appendRow(selectedHeaders.map((field) => TextCellValue(field)).toList());

      // Adiciona os registros
      for (var record in inventoryRecords) {
        List<CellValue?> row = [];
        for (var field in selectedHeaders) {
          var value = record[_mapFieldToColumnName(field)];
          if (value is int) {
            row.add(IntCellValue(value));
          } else if (value != null) {
            row.add(TextCellValue(value.toString()));
          } else {
            row.add(null);
          }
        }
        sheet.appendRow(row);
      }

      if (_exportToEmail) {
        await _sendEmailWithAttachment(context, excel.encode());
      } else {
        await _sendFileNetwork(context, excel);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Erro ao exportar: $e", style: const TextStyle(fontSize: 18)),
      ));
    }
  }

  Future<void> _sendFileNetwork(BuildContext context, Excel excel) async {
    final String fileName = "inventario_${DateTime.now().millisecondsSinceEpoch}.xlsx";

    FTPConnect ftpConnect = FTPConnect(_fileHostController.text, user: _userController.text, pass: _passwordController.text);

    try {
      // Conecta ao servidor FTP
      bool connected = await ftpConnect.connect();
      if (!connected) throw Exception("Falha ao conectar ao servidor FTP.");

      // Gera os bytes do arquivo Excel
      List<int>? fileBytes = excel.save();
      if (fileBytes == null) throw Exception("Erro ao gerar o arquivo Excel.");

      // Cria arquivo temporário
      final directory = await getTemporaryDirectory();
      String filePath = "${directory.path}/$fileName";
      File tempFile = File(filePath);
      await tempFile.writeAsBytes(fileBytes);

      // Muda para o diretório remoto
      bool changedDir = await ftpConnect.changeDirectory(_filePathController.text);
      if (!changedDir) throw Exception("Não foi possível acessar o diretório no servidor.");

      // Faz upload do arquivo
      bool uploaded = await ftpConnect.uploadFile(tempFile);
      if (!uploaded) throw Exception("Falha ao enviar o arquivo para o servidor.");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Arquivo exportado com sucesso para o servidor FTP."),
      ));

      // Exclui arquivo temporário
      await tempFile.delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Erro ao gravar na rede: $e"),
      ));
    } finally {
      ftpConnect.disconnect();
    }
  }

  Future<void> _sendEmailWithAttachment(BuildContext context, List<int>? excelFile) async {
    if (excelFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar o arquivo Excel', style: TextStyle(fontSize: 18))));
      return;
    }

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/${_fileNameController.text}';
    final file = File(filePath);
    await file.writeAsBytes(excelFile);

    // Configuração do servidor SMTP
    String username = 'ax@oxfordporcelanas.com.br';
    String password = 'S3rvic0s.publ1c@c@0';

    final smtpServer = SmtpServer(
      'smtp.oxford.ind.br', // Servidor SMTP
      username: username,
      password: password,
      port: 225,
      ssl: false, // 'false' se não usar TLS/SSL, ou 'true' se sim
      ignoreBadCertificate: true, // Ignora a validação do certificado
    );

    final message = Message()
      ..from = Address(username, 'Diones Forteski')
      ..recipients.add(_emailController.text) // destinatário
      ..subject = 'Exportação de Inventário'
      ..text = 'Segue o arquivo Excel com os dados do inventário.'
      ..attachments.add(FileAttachment(file));

    try {
      final sendStatus = await send(message, smtpServer);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('E-mail enviado com sucesso!', style: TextStyle(fontSize: 18))));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar e-mail: $e', style: TextStyle(fontSize: 18))));
      print('Erro ao enviar e-mail: $e');
    }
  }

  String _mapFieldToColumnName(String field) {
    switch (field) {
      case 'Unitizador':               return DBInventoryExport.columnUnitizador;
      case 'Posição':                  return DBInventoryExport.columnPosicao;
      case 'Depósito':                 return DBInventoryExport.columnDeposito;
      case 'Bloco':                    return DBInventoryExport.columnBloco;
      case 'Quadra':                   return DBInventoryExport.columnQuadra;
      case 'Lote':                     return DBInventoryExport.columnLote;
      case 'Andar':                    return DBInventoryExport.columnAndar;
      case 'Código de Barras':         return DBInventoryExport.columnCodigoDeBarras;
      case 'Qtde Padrão da Pilha':     return DBInventoryExport.columnQtdePadraoDaPilha;
      case 'Qtde de Pilhas Completas': return DBInventoryExport.columnQtdeDePilhasCompletas;
      case 'Qtde de Itens Avulsos':    return DBInventoryExport.columnQtdeDeItensAvulsos;
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Exportação de Dados: ${_inventory[DBInventory.columnId] ?? ''}",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                margin: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Definição de campos para exportar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      ..._fields.map((field) {
                        return CheckboxListTile(
                          title: Text(field),
                          value: _selectedFields[field],
                          onChanged: (bool? value) {
                            setState(() {
                              _selectedFields[field] = value ?? false;
                            });
                          },
                          activeColor: Colors.black,
                          checkColor: Colors.white,
                          tileColor: Colors.white,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                margin: const EdgeInsets.all(16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Destino do Arquivo',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _fileNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome do Arquivo',
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.black),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("E-Mail"),
                              value: "E-Mail",
                              groupValue: _exportToEmail ? "E-Mail" : "Rede",
                              onChanged: (value) {
                                setState(() {
                                  _exportToEmail = true;
                                  _exportToFilePath = false;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Rede"),
                              value: "Rede",
                              groupValue: _exportToEmail ? "E-Mail" : "Rede",
                              onChanged: (value) {
                                setState(() {
                                  _exportToFilePath = true;
                                  _exportToEmail = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_exportToEmail) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: "E-Mail",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (_exportToFilePath) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _filePathController,
                          decoration: const InputDecoration(
                            labelText: "Pasta",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _fileHostController,
                          decoration: const InputDecoration(
                            labelText: "Host",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _userController,
                          decoration: const InputDecoration(
                            labelText: "Usuário",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          obscureText: true,
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: "Senha",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(8.0, 0.0, 8.0, 15.0),
        child: ElevatedButton(
          onPressed: () {
            exportToExcel(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Exportar', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
