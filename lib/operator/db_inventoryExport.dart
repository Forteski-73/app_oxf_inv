import 'dart:async'; 
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBInventoryExport {
  static const _databaseName = "export_settings.db";
  static const _databaseVersion = 2;
  static const table = 'export_settings';

  // Definindo as colunas da tabela 'export_settings'
  static const columnId                     = 'id';
  static const columnFileName               = 'fileName';
  static const columnUnitizador             = 'unitizador';
  static const columnPosicao                = 'posicao';
  static const columnDeposito               = 'deposito';
  static const columnBloco                  = 'bloco';
  static const columnQuadra                 = 'quadra';
  static const columnLote                   = 'lote';
  static const columnAndar                  = 'andar';
  static const columnCodigoDeBarras         = 'codigoDeBarras';
  static const columnProduto                = 'produto';
  static const columnNome                   = 'nome';
  static const columnQtdePadraoDaPilha      = 'qtdePadraoDaPilha';
  static const columnQtdeDePilhasCompletas  = 'qtdeDePilhasCompletas';
  static const columnQtdeDeItensAvulsos     = 'qtdeDeItensAvulsos';
  static const columnTotal                  = 'total';
  static const columnExportToEmail          = 'exportToEmail';
  static const columnExportToFilePath       = 'exportToFilePath';
  static const columnEmail                  = 'email';
  static const columnFilePath               = 'filePath';
  static const columnFileType               = 'FileType';
  static const columnHost                   = 'host';
  static const columnUser                   = 'user';
  static const columnPassword               = 'password';

  // Instanciando o construtor DB
  DBInventoryExport._privateConstructor();
  static final DBInventoryExport instance = DBInventoryExport._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

Future<Database> _initDatabase() async {
  var databasesPath = await getDatabasesPath();
  String path = join(databasesPath, _databaseName);

  return await openDatabase(
    path,
    version: _databaseVersion,
    onCreate: _onCreate,
    onUpgrade: (Database db, int oldVersion, int newVersion) async {
      if (oldVersion < 2) {
        await db.execute('ALTER TABLE $table ADD COLUMN $columnProduto INTEGER');
        await db.execute('ALTER TABLE $table ADD COLUMN $columnNome INTEGER');
      }
    },
  );
}

  Future<void> _deleteTable(Database db) async {
    try {
      await db.execute('DROP TABLE IF EXISTS $table'); // Deleta a tabela inteira
    } catch (e) {
      print('Erro ao deletar a tabela: $e');
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(''' 
      CREATE TABLE IF NOT EXISTS $table (
        $columnId                       INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnFileName                 TEXT,
        $columnUnitizador               INTEGER,
        $columnPosicao                  INTEGER,
        $columnDeposito                 INTEGER,
        $columnBloco                    INTEGER,
        $columnQuadra                   INTEGER,
        $columnLote                     INTEGER,
        $columnAndar                    INTEGER,
        $columnCodigoDeBarras           INTEGER,
        $columnProduto                  INTEGER,
        $columnNome                     INTEGER,
        $columnQtdePadraoDaPilha        INTEGER,
        $columnQtdeDePilhasCompletas    INTEGER,
        $columnQtdeDeItensAvulsos       INTEGER,
        $columnTotal                    INTEGER,
        $columnExportToEmail            INTEGER,
        $columnExportToFilePath         INTEGER,
        $columnEmail                    TEXT,
        $columnFilePath                 TEXT,
        $columnFileType                 TEXT,
        $columnHost                     TEXT,
        $columnUser                     TEXT,
        $columnPassword                 TEXT 
      );
    ''');
  }

  Future<void> saveExportSettings(
    bool unitizador,
    bool posicao,
    bool deposito,
    bool bloco,
    bool quadra,
    bool lote,
    bool andar,
    bool codigoDeBarras,
    bool produto,
    bool nome,
    bool qtdePadraoDaPilha,
    bool qtdeDePilhasCompletas,
    bool qtdeDeItensAvulsos,
    bool total,
    String fileName,
    bool exportToEmail,
    bool exportToFilePath,
    String email,
    String filePath,
    String fileType,
    String host,
    String user,
    String password
  ) async {
    try {
      final db = await database;
      
      // Verifica se existe algum registro
      final existingRecords = await db.query(table, limit: 1,); // Limita para o primeiro registro

      // Se a tabela estiver vazia, faz o insert
      if (existingRecords.isEmpty) {
        await db.insert(
          table,
          {
            columnFileName:               fileName,
            columnUnitizador:             unitizador ? 1 : 0,
            columnPosicao:                posicao ? 1 : 0,
            columnDeposito:               deposito ? 1 : 0,
            columnBloco:                  bloco ? 1 : 0,
            columnQuadra:                 quadra ? 1 : 0,
            columnLote:                   lote ? 1 : 0,
            columnAndar:                  andar ? 1 : 0,
            columnCodigoDeBarras:         codigoDeBarras ? 1 : 0,
            columnProduto:                produto ? 1 : 0,
            columnNome:                   nome ? 1 : 0,
            columnQtdePadraoDaPilha:      qtdePadraoDaPilha ? 1 : 0,
            columnQtdeDePilhasCompletas:  qtdeDePilhasCompletas ? 1 : 0,
            columnQtdeDeItensAvulsos:     qtdeDeItensAvulsos ? 1 : 0,
            columnTotal:                  total ? 1 : 0,
            columnExportToEmail:          exportToEmail ? 1 : 0,
            columnExportToFilePath:       exportToFilePath ? 1 : 0,
            columnEmail:                  email,
            columnFilePath:               filePath,
            columnFileType:                fileType,
            columnHost:                   host,
            columnUser:                   user,
            columnPassword:               password
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        await db.update( // Atualiza o primeiro registro encontrado
          table,
          {
            columnFileName:               fileName,
            columnUnitizador:             unitizador ? 1 : 0,
            columnPosicao:                posicao ? 1 : 0,
            columnDeposito:               deposito ? 1 : 0,
            columnBloco:                  bloco ? 1 : 0,
            columnQuadra:                 quadra ? 1 : 0,
            columnLote:                   lote ? 1 : 0,
            columnAndar:                  andar ? 1 : 0,
            columnCodigoDeBarras:         codigoDeBarras ? 1 : 0,
            columnQtdePadraoDaPilha:      qtdePadraoDaPilha ? 1 : 0,
            columnQtdeDePilhasCompletas:  qtdeDePilhasCompletas ? 1 : 0,
            columnQtdeDeItensAvulsos:     qtdeDeItensAvulsos ? 1 : 0,
            columnTotal:                  total ? 1 : 0,
            columnExportToEmail:          exportToEmail ? 1 : 0,
            columnExportToFilePath:       exportToFilePath ? 1 : 0,
            columnEmail:                  email,
            columnFilePath:               filePath,
            columnFileType:               fileType,
            columnHost:                   host,
            columnUser:                   user,
            columnPassword:               password
          },
          where: '$columnId = 1',  // Sempre atualiza o primeiro registro
        );
      }
    } catch (e) {
      print('Erro ao salvar configurações de exportação: $e');
    }
  }

  Future<Map<String, dynamic>> loadExportSettings() async {

    try {
      final db = await database;
      
      //_deleteAllRecords(db);
      //_deleteTable(db);
      //_onCreate(db,1);
      
      final result = await db.query(table, limit: 1, );  // Sempre carregamos o primeiro registro (id = 1)

      Map<String, dynamic> settings = {};
      if (result.isNotEmpty) {
        final data = result.first;
        settings = {
          'fileName':               data[columnFileName].toString(),
          'unitizador':             data[columnUnitizador]            == 1,
          'posicao':                data[columnPosicao]               == 1,
          'deposito':               data[columnDeposito]              == 1,
          'bloco':                  data[columnBloco]                 == 1,
          'quadra':                 data[columnQuadra]                == 1,
          'lote':                   data[columnLote]                  == 1,
          'andar':                  data[columnAndar]                 == 1,
          'codigoDeBarras':         data[columnCodigoDeBarras]        == 1,
          'produto':                data[columnProduto]               == 1,
          'nome':                   data[columnNome]                  == 1,
          'qtdePadraoDaPilha':      data[columnQtdePadraoDaPilha]     == 1,
          'qtdeDePilhasCompletas':  data[columnQtdeDePilhasCompletas] == 1,
          'qtdeDeItensAvulsos':     data[columnQtdeDeItensAvulsos]    == 1,
          'total':                  data[columnTotal]                 == 1,
          'exportToEmail':          data[columnExportToEmail]         == 1,
          'exportToFilePath':       data[columnExportToFilePath]      == 1,
          'email':                  data[columnEmail].toString(),
          'filePath':               data[columnFilePath].toString(),
          'fileType':               data[columnFileType].toString(),
          'host':                   data[columnHost].toString(),
          'user':                   data[columnUser].toString(),
          'password':               data[columnPassword].toString(),
        };
        return settings;
      } else {
        return {};
      }
    } catch (e) {
      print('Erro ao carregar configurações de exportação: $e');
      return {};
    }
  }

  // Chama o método de deletar a tabela
  Future<void> deleteTable() async {
    try {
      final db = await database;
      await _deleteTable(db);  // Deleta a tabela 'export_settings'
      print('Tabela deletada com sucesso.');
    } catch (e) {
      print('Erro ao deletar a tabela: $e');
    }
  }
}