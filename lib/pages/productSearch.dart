import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:app_oxf_inv/operator/db_product.dart';
import '../models/product.dart';
import 'productDetail.dart';

class ProductSearchPage extends StatefulWidget {
  const ProductSearchPage({super.key});

  @override
  _ProductSearchPage createState() => _ProductSearchPage();
}

class _ProductSearchPage extends State<ProductSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allProducts       = [];
  List<Map<String, dynamic>> _filteredProducts  = [];
  final String _apiUrl  = "http://wsintegrador.oxfordporcelanas.com.br:90/api/produtoEstrutura/";
  //final String _apiUrl  = "http://wsintegradordev.oxfordporcelanas.com.br:92/v1/produtos/GetAPIProdutos?familia=0002&marca=oxford&linha=FLAMINGO&decoracao=FLAMINGO&situacao=FORA&ordem=0&pagina=0&qtpagina=1";
  final String _token   = "4d24e4ff-85d62cca-d0cad84f-440e706e";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts(); 
  }

  /// Carregar todos os produtos
  Future<void> _loadProducts() async {
    try {
      final products = await DBItems.instance.getAllProducts1();
      setState(() {
        _allProducts = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false; // Caso haja erro, também para o carregamento
      });
      _showError('Erro ao carregar produtos do banco de dados: $e');
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // Expressão regular
        final regex = RegExp(query, caseSensitive: false);

        return regex.hasMatch(product['ItemBarCode'].toString()) ||
              regex.hasMatch(product['ItemID'].toString()) ||
              regex.hasMatch(product['Name'].toString());
      }).toList();
    });
  }

  Future<void> _searchAndSaveProduct(String productId) async {
    if (productId.isNotEmpty) {
      try {
        final response = await http.get(
          Uri.parse('$_apiUrl$productId'),
          //Uri.parse(_apiUrl),

          headers: {
            'Authorization': 'Bearer $_token',
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> data = json.decode(response.body);
          
          final Map<String, dynamic> product = {
            DBItems.columnItemBarCode:                  data['ItemBarCode'],
            DBItems.columnProdBrandId:                  data['ProdBrandId'],
            DBItems.columnProdBrandDescriptionId:       data['ProdBrandDescriptionId'],
            DBItems.columnProdLinesId:                  data['ProdLinesId'],
            DBItems.columnProdLinesDescriptionId:       data['EditProdLinesDescription'],
            DBItems.columnProdDecorationId:             data['ProdDecorationId'],
            DBItems.columnProdDecorationDescriptionId:  data['EditProdDecorationDescription'],
            DBItems.columnItemId:                       data['ItemID'],
            DBItems.columnName:                         data['Name'],
            DBItems.columnUnitVolumeML:                 data['UnitVolumeML'],
            DBItems.columnItemNetWeight:                data['ItemNetWeight'],
            DBItems.columnProdFamilyId:                 data['ProdFamilyId'],
            DBItems.columnProdFamilyDescription:        data['ProdFamilyDescription'],
            //DBItems.columnImageUrl:                     data['ImageUrl'],
          };

          // Salvar o produto no banco
          await DBItems.instance.insertProduct(product);

          setState(() {
            _allProducts.add(product); // Adiciona o produto à lista local
            _filteredProducts = _allProducts;
          });

        } else {
          _showError('Erro ao buscar produto. Código: ${response.statusCode}');
        }
      } catch (e) {
        _showError('Erro ao buscar produto: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: const TextStyle(fontSize: 18))));
  }

  void _searchProduct(String productId) {
    String searchText = _searchController.text.trim();
    if (searchText.isNotEmpty) {
      _filterProducts(searchText);
      if(_filteredProducts.isEmpty)
      {
        _searchAndSaveProduct(productId);
        _filterProducts(searchText);
      }
    }
  }

  Widget _alignRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        children: [
          Expanded(
            flex: 2, // Quanto de espaço por rótulo
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3, // Ocupa o restante do espaço
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aplicativo de Consulta de Estrutura de Produtos. ACEP',
            style: TextStyle(color: Colors.white,fontSize: 12,),
          ),
          SizedBox(height: 2),
          Text('Pesquisar Produtos',
            style: TextStyle(color: Colors.white, fontSize: 20, ),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _filterProducts(value);
              },
              decoration: InputDecoration(
                labelText: 'Pesquisar',
                border: const OutlineInputBorder(),
                prefixIcon: InkWell(
                  onTap: () {
                    _searchProduct(_searchController.text);
                  },
                  child: const Icon(Icons.search),
                ),
              ),
            ),
          ),

          _isLoading
          ? const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              ),
            )
          : Expanded(
              child: ListView.builder(
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8.0),
                      title: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          product['Name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      subtitle: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: product['path'] != null && product['path'].isNotEmpty
                                ? Image.network(
                                    product['path'],
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                                    },
                                  )
                                : const Icon(Icons.broken_image, size: 100, color: Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 110,
                                      child: Text(
                                        'Cód. de Barras:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        product['ItemBarCode'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 110,
                                      child: Text(
                                        'Item:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        product['ItemID'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 110,
                                      child: Text(
                                        'Linha:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${product['ProdLinesId'] ?? ''} - ${product['ProdLinesDescriptionId'] ?? ''}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const SizedBox(
                                      width: 110,
                                      child: Text(
                                        'Decoração:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        product['ProdDecorationDescriptionId'] ?? '',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        final productObj = Product(
                          itemBarCode: product['ItemBarCode'],
                          itemId: product['ItemID'],
                          name: product['Name'],
                          prodLinesId: product['ProdLinesId'],
                          prodLinesDescriptionId: product['ProdLinesDescriptionId'],
                          prodDecorationDescriptionId: product['ProdDecorationDescriptionId'],
                          unitVolumeML: product['UnitVolumeML'],
                          itemNetWeight: product['ItemNetWeight'],
                          prodFamilyId: product['ProdFamilyId'],
                          prodFamilyDescription: product['ProdFamilyDescription'],
                          prodBrandDescriptionId: product['ProdBrandDescriptionId'],
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailsPage(product: productObj),
                          ),
                        );
                      },
                    ),
                  );
                },
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
}



/*import 'package:flutter/material.dart';
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
*/

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
/*
import 'package:flutter/material.dart';
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
    _filePathController.text = 'ftp://representantes@oxserver.oxford.ind.br/Ox_imagens/'; // Endereço FTP ftp://representantes@oxserver.oxford.ind.br/Ox_imagens/
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
      final ftpClient = FTPConnect('ftp://oxserver.oxford.ind.br', user: 'representantes', pass: 'repres..ox');

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