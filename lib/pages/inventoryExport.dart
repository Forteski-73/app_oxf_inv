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
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';

class InventoryExportPage extends StatefulWidget {
  final int inventoryId;
  const InventoryExportPage({Key? key, required this.inventoryId}) : super(key: key);

  @override
  _InventoryExportPage createState() => _InventoryExportPage();
}

class _InventoryExportPage extends State<InventoryExportPage> {
  final TextEditingController _fileNameController = TextEditingController();
  final List<String> _fields = ['Unitizador', 'Posição', 'Depósito', 'Bloco', 'Quadra', 'Lote', 'Andar',
    'Código de Barras', 'Qtde Padrão da Pilha', 'Qtde de Pilhas Completas', 'Qtde de Itens Avulsos', 'Total'];
  Map<String, bool>           _selectedFields     = {};
  Map<String, dynamic>        _inventory          = {};
  String                      _separator          = ';';
  final TextEditingController _emailController    = TextEditingController();
  final TextEditingController _fileHostController = TextEditingController();
  final TextEditingController _filePathController = TextEditingController();
  final TextEditingController _userController     = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _userTemp     = TextEditingController();
  final TextEditingController _passwordTemp = TextEditingController();
  String                      _fileFormat         = "TXT";
  bool                        _exportToEmail      = true;
  bool                        _exportToFilePath   = false;
  bool                        _isExporting        = false;
  bool                        _isAuthorized       = false;
  bool                        _dialogShown        = false; 
  late DBInventory            _dbInventory;
  late DBInventoryExport      _dbInventoryExport;

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

  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dialogShown) {
      // Usando addPostFrameCallback para adiar a execução de _checkCredentials
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkCredentials();  // Exibe a caixa de diálogo
      });
      _dialogShown = true;  // Garantir que o diálogo seja exibido apenas uma vez
    }
  }

  Future<void> _loadExportSettings() async {
    final settings = await _dbInventoryExport.loadExportSettings();

    if (settings.isNotEmpty) {
      setState(() {
        _selectedFields.addAll(settings['selectedFields'] ?? {});
        //_fileNameController.text  = settings['fileName'] ?? '';
        _exportToEmail            = settings['exportToEmail'] ?? true;
        _exportToFilePath         = settings['exportToFilePath'] ?? false;
        _emailController.text     = settings['email'] ?? '';
        _filePathController.text  = settings['filePath'] ?? '';
        _fileFormat               = settings['fileType'] ?? '';
        _fileHostController.text  = settings['host'] ?? 'oxserver.oxford.ind.br';
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
          "Total":                    settings['total'],
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

        // Atualiza o nome do arquivo após carregar os dados
        if (_inventory.isNotEmpty) {
          _fileNameController.text = '${_inventory[DBInventory.columnCode] ?? ''}';
        }
        _filePathController.text = '/Ox_imagens/';
        _fileHostController.text = 'oxserver.oxford.ind.br';
      });
    } catch (e) {
      setState(() {

      });
    }
  }

 Future<void> _ExportSettings() async {
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
        _selectedFields['Total'] ?? false,
        _fileNameController.text,
        _exportToEmail,
        _exportToFilePath,
        _emailController.text,
        _filePathController.text,
        _fileFormat,
        _fileHostController.text,
        _userController.text,
        _passwordController.text,
      );
  }

  Future<void> exportFile(BuildContext context) async {
    setState(() {
      _isExporting = true;
    });
    try {
      await _ExportSettings();

      // Obter os registros do banco de dados
      Database db = await DBInventory.instance.database;
      List<Map<String, dynamic>> inventoryRecords = await db.query(
        DBInventory.tableInventoryRecord,
        where: '${DBInventory.columnInventoryId} = ?',
        whereArgs: [widget.inventoryId],
      );

      // Definir os cabeçalhos
      List<String> selectedHeaders = _fields.where((field) => _selectedFields[field] == true).toList();
      List<String> lines = [];

      // Adiciona o cabeçalho somente se o formato for CSV
      if (_fileFormat == 'CSV') {
        lines.add(selectedHeaders.join(_separator));  // Cabeçalho
      }

      // Criar as linhas do arquivo
      for (var record in inventoryRecords) {
        List<String> row = [];
        for (var field in selectedHeaders) {
          var value = record[_mapFieldToColumnName(field)];
          row.add(value != null ? value.toString() : "");
        }
        lines.add(row.join(_separator));
      }

      // Criar o conteúdo do arquivo
      String fileContent = lines.join("\n");
      Uint8List fileBytes = Uint8List.fromList(fileContent.codeUnits);

      if (_exportToEmail) {
        await _sendEmailWithAttachment(context, fileBytes, _fileFormat == 'CSV' ?
          "${_fileNameController.text}.csv" : "${_fileNameController.text}.txt");
      } else {
        await _sendFileNetwork(context, fileBytes, _fileFormat == 'CSV' ? 
          "${_fileNameController.text}.csv" : "${_fileNameController.text}.txt");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Erro ao exportar: $e", style: const TextStyle(fontSize: 18)),
      ));
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _sendFileNetwork(BuildContext context, List<int> fileBytes, String fileName) async {
    FTPConnect ftpConnect = FTPConnect(_fileHostController.text, user: _userController.text, pass: _passwordController.text);

    try {
      // Conecta ao servidor FTP
      bool connected = await ftpConnect.connect();
      if (!connected) throw Exception("Falha ao conectar ao servidor FTP.");

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

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Arquivo exportado com sucesso para o servidor FTP."),
      ));

      // Exclui o arquivo temporário
      await tempFile.delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Erro ao gravar na rede: $e"),
      ));
    } finally {
      ftpConnect.disconnect();
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }


  Future<void> _sendEmail() async {
    try {
      // Criar um arquivo temporário para anexar (exemplo de .txt)
      final Directory tempDir = await getTemporaryDirectory();
      final File file = File('${tempDir.path}/example.txt');
      await file.writeAsString('Este é um arquivo de exemplo.');

      final Email email = Email(
        recipients: ['dionesforteski@email.com'],
        subject: 'Example Subject',
        body: 'Olá, este é um e-mail enviado do meu app Flutter!',
        attachmentPaths: [file.path], // Caminho do arquivo anexo
        isHTML: false,
      );

      await FlutterEmailSender.send(email);
    } catch (error) {
      print('Erro ao enviar e-mail: $error');
    }
  }

  Future<void> sendEmail() async {
    
    /* browser
    
    final Uri _url = Uri.parse('https://flutter.dev');

    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }*/

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'dionesforteski@email.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Example Subject & Symbols are allowed!',
        'body': 'Olá, este é um e-mail enviado do meu app Flutter!',
      }),
    );

  launchUrl(emailLaunchUri);

    /*final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'dionesforteski@email.com',
      queryParameters: {
        'subject': 'Assunto do Email',
        'body': 'Olá, este é um e-mail enviado do meu app Flutter!',
      },
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
    } else {
      print("Não foi possível abrir o aplicativo de e-mail.");
    }*/
  }

  Future<void> _sendEmailWithAttachment(BuildContext context, List<int>? fileBytes, String fileName) async {

    _sendEmail();
  /*
    if (fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao gerar o arquivo', style: TextStyle(fontSize: 18))),
      );
      return;
    }

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

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
      ..text = 'Segue o arquivo com os dados do inventário.'
      ..attachments.add(FileAttachment(file));

    try {
      final sendStatus = await send(message, smtpServer);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('E-mail enviado com sucesso!', style: TextStyle(fontSize: 18))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar e-mail: $e', style: TextStyle(fontSize: 18))),
      );
      print('Erro ao enviar e-mail: $e');
    }
  */

  }

  String _mapFieldToColumnName(String field) {
    switch (field) {
      case 'Unitizador':               return 'unitizer';
      case 'Posição':                  return 'position';
      case 'Depósito':                 return 'deposit';
      case 'Bloco':                    return 'block_a';
      case 'Quadra':                   return 'block_b';
      case 'Lote':                     return 'lot';
      case 'Andar':                    return 'floor';
      case 'Código de Barras':         return 'barcode';
      case 'Qtde Padrão da Pilha':     return 'standard_stack_qtd';
      case 'Qtde de Pilhas Completas': return 'number_complete_stacks';
      case 'Qtde de Itens Avulsos':    return 'number_loose_items';
      case 'Total':                    return 'total';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Aplicativo de Consulta de Estrutura de Produtos. ACEP',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              "Exportar Inventário: ${_inventory[DBInventory.columnCode] ?? ''}",
              style: const TextStyle(color: Colors.white),
            ),
          ],
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
                          onChanged: _isAuthorized ? (bool? value) {
                                  setState(() {
                                    _selectedFields[field] = value ?? false;
                                  });
                                }
                              : null, // Desabilita a interação se não autorizado
                          activeColor: Colors.black,
                          checkColor: Colors.white,
                          tileColor: Colors.white,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8,),
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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Arquivo",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _fileNameController,
                        decoration: const InputDecoration(
                          labelText: "Nome do Arquivo",
                          border: OutlineInputBorder(),
                        ),
                        enabled: _isAuthorized,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text(".TXT"),
                              value: "TXT",
                              groupValue: _fileFormat,
                              onChanged: _isAuthorized
                                  ? (value) {
                                      setState(() {
                                        _fileFormat = value ?? "";
                                      });
                                    }
                                  : null, // Desabilita a interação se não autorizado
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text(".CSV"),
                              value: "CSV",
                              groupValue: _fileFormat,
                              onChanged: _isAuthorized
                                  ? (value) {
                                      setState(() {
                                        _fileFormat = value ?? "";
                                      });
                                    }
                                  : null, // Desabilita a interação se não autorizado
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
                            child: RadioListTile<String>(
                              title: const Text("E-Mail"),
                              value: "E-Mail",
                              groupValue: _exportToEmail ? "E-Mail" : "Rede",
                              onChanged: _isAuthorized
                                  ? (value) {
                                    setState(() {
                                      _exportToEmail = true;
                                      _exportToFilePath = false;
                                      });
                                    }
                                  : null, // Desabilita a interação se não autorizado
                            ),
                          ),

                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Rede"),
                              value: "Rede",
                              groupValue: _exportToEmail ? "E-Mail" : "Rede",
                              onChanged: _isAuthorized
                                  ? (value) {
                                    setState(() {
                                  _exportToFilePath = true;
                                  _exportToEmail = false;
                                });
                              }: null, 
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
                          enabled: _isAuthorized,
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
                          enabled: _isAuthorized,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _fileHostController,
                          decoration: const InputDecoration(
                            labelText: "Host",
                            border: OutlineInputBorder(),
                          ),
                          enabled: _isAuthorized,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _userController,
                          decoration: const InputDecoration(
                            labelText: "Usuário",
                            border: OutlineInputBorder(),
                          ),
                          enabled: _isAuthorized,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          obscureText: true,
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: "Senha",
                            border: OutlineInputBorder(),
                          ),
                          enabled: _isAuthorized,
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
          onPressed: _isExporting
              ? null 
              : () {
                  exportFile(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: const Size(double.infinity, 50),
          ),
          child: _isExporting
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(width: 10),
                    Text('Exportando...', style: TextStyle(fontSize: 16, color: Colors.white),),
                  ],
                )
              : const Text('Exportar', style: TextStyle(fontSize: 16, color: Colors.white),),
        ),
      ),
    );
  }

  void _checkCredentials() {
    showDialog(
      context: context,
      barrierDismissible: false, // Não permite fechar a caixa sem preencher
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          title: const Text('Autenticação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _userTemp,
                decoration: const InputDecoration(
                  labelText: 'Usuário',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordTemp,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Verifica as credenciais informadas
                      if (_userTemp.text == "admin" && _passwordTemp.text == "ti2025") {
                        Navigator.of(context).pop();
                        setState(() {
                          _isAuthorized = true; // Permite interagir com os cards
                        });
                      } else {
                        Navigator.of(context).pop();
                        setState(() {
                          _isAuthorized = false; // Desabilita os cards
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 8), 
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _isAuthorized = false; // Desabilita os cards
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Pular',
                      style: TextStyle(fontSize: 16, color: Colors.white),
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
}
