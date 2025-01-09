import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

void main() {
  runApp(InventorySearchPage());
}
class InventorySearchPage extends StatefulWidget {
  const InventorySearchPage({super.key});

  @override
  _InventorySearchPage createState() => _InventorySearchPage();
}

class _InventorySearchPage extends State<InventorySearchPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enviar E-mail',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EmailPage(),
    );
  }
}

class EmailPage extends StatefulWidget {
  @override
  _EmailPageState createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  String? _macAddress;

  @override
  void initState() {
    super.initState();
    _getMacAddress();
    getDeviceSerialNumber();
  }

Future<String> getDeviceSerialNumber() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String serialNumber = '';

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    serialNumber = androidInfo.serialNumber ?? 'Desconhecido';  // Usa 'serial' ao invés de 'androidId'
    //serialNumber  = androidInfo.device;
  } else {
    serialNumber = 'Não disponível para este sistema';
  }
    setState(() {
      _macAddress = serialNumber;
    });
    print("NÚMERO DE SÉRIE.............: $serialNumber");
  return serialNumber;
}

  Future<void> _getMacAddress() async {
    final info = NetworkInfo();
    String? macAddress;

    try {
      macAddress = await info.getWifiBSSID(); // MAC Address do Wi-Fi
    } catch (e) {
      macAddress = "Erro ao obter MAC Address: $e";
    }
    print("MAC ADDRESSS.............: $macAddress");
    setState(() {
      _macAddress = macAddress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MAC Address / Serial'),
      ),
      body: Center(
        child: Text(
          _macAddress ?? 'Carregando...',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}


/*import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

void main() {
  runApp(InventorySearchPage());
}
class InventorySearchPage extends StatefulWidget {
  const InventorySearchPage({super.key});

  @override
  _InventorySearchPage createState() => _InventorySearchPage();
}

class _InventorySearchPage extends State<InventorySearchPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Enviar E-mail',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EmailPage(),
    );
  }
}

class EmailPage extends StatefulWidget {
  @override
  _EmailPageState createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String _statusMessage = '';

  Future<void> sendEmail() async {
    // Configuração do servidor SMTP (exemplo para Gmail)
    final smtpServer = gmail('dionesforteski@gmail.com', '123>'); // Substitua com suas credenciais

    // Criação da mensagem de e-mail
    final message = Message()
      ..from = Address('dionesforteski@gmail.com', 'Diones') // Substitua com seu e-mail
      ..recipients.add('destinatario@email.com') // Substitua com o destinatário
      ..subject = _subjectController.text
      ..text = _bodyController.text;

    try {
      // Enviando o e-mail
      final sendReport = await send(message, smtpServer);
      setState(() {
        _statusMessage = 'E-mail enviado com sucesso! ID: ${sendReport.mail.toString()}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao enviar e-mail: $e';
      });
    }
    print(_statusMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Enviar E-mail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Assunto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _bodyController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Corpo do E-mail',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: sendEmail,
              child: Text('Enviar E-mail'),
            ),
            const SizedBox(height: 20),
            Text(
              _statusMessage,
              style: TextStyle(
                color: _statusMessage.startsWith('E-mail enviado') ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/

/*import 'package:flutter/material.dart';
import 'package:ftpconnect/ftpconnect.dart'; // Usando ftpconnect
import 'package:excel/excel.dart';
import 'dart:io';

class InventorySearchPage extends StatefulWidget {
  const InventorySearchPage({super.key});

  @override
  _InventorySearchPage createState() => _InventorySearchPage();
}

class _InventorySearchPage extends State<InventorySearchPage> {
  final TextEditingController _filePathController = TextEditingController();
  final TextEditingController _fileNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filePathController.text = 'ftp://ftp.exemplo.com/'; // Endereço FTP
    _fileNameController.text = 'inventario.xlsx'; // Nome do arquivo
  }

  Future<void> saveExcelToFTP(String ftpUrl, String fileName) async {
    try {
      // 1. Criar planilha Excel
      var excel = Excel.createExcel();
      var sheet = excel['Inventário'];
      bool st_ftp = false;

      // 2. Adicionar cabeçalho e dados
      sheet.appendRow([TextCellValue('ID'), TextCellValue('Nome'), TextCellValue('Quantidade')]);
      sheet.appendRow([IntCellValue(1), TextCellValue('Produto A'), IntCellValue(10)]);
      sheet.appendRow([IntCellValue(2), TextCellValue('Produto B'), IntCellValue(20)]);

      // 3. Gerar os bytes do Excel
      List<int>? bytes = excel.encode();
      if (bytes == null) throw Exception('Erro ao gerar bytes do Excel.');

      // 4. Criar um arquivo temporário
      final tempFile = File('${Directory.systemTemp.path}/$fileName');
      await tempFile.writeAsBytes(bytes);

      // 5. Conectar ao servidor FTP
      final ftpClient = FTPConnect('ftp://177.70.21.15', user: 'oxford', pass: 'Oxf2018!');

      // 6. Conectar e fazer upload
      st_ftp = await ftpClient.connect();
      //await ftpClient.uploadFile(tempFile); // para testar

      if(st_ftp){
        // 7. Feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arquivo salvo com sucesso em $ftpUrl$fileName')),
        );
        await ftpClient.disconnect();
      }
      else{
                ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao conectar ao ftp')),
        );
      }
      // 8. Remover o arquivo temporário após o upload
      await tempFile.delete();
    } catch (e) {
      // Tratamento de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar arquivo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salvar Excel na Rede'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _filePathController,
              decoration: const InputDecoration(
                labelText: 'Endereço FTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fileNameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Arquivo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                saveExcelToFTP(
                  _filePathController.text,
                  _fileNameController.text,
                );
              },
              child: const Text('Salvar Arquivo'),
            ),
          ],
        ),
      ),
    );
  }
}*/