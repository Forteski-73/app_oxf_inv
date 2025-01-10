import 'dart:async'; 
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBInventoryExport {
  static const _databaseName = "export_settings.db";
  static const _databaseVersion = 1;
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
  static const columnQtdePadraoDaPilha      = 'qtdePadraoDaPilha';
  static const columnQtdeDePilhasCompletas  = 'qtdeDePilhasCompletas';
  static const columnQtdeDeItensAvulsos     = 'qtdeDeItensAvulsos';
  static const columnExportToEmail          = 'exportToEmail';
  static const columnExportToFilePath       = 'exportToFilePath';
  static const columnFilePath               = 'filePath';
  static const columnEmail                  = 'email';
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
    var databasesPath = await getDatabasesPath(); // Diretório do banco de dados
    String path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    ); // Abrindo/criando a tabela
  }

  Future<void> _deleteTable(Database db) async {
    try {
      await db.execute('DROP TABLE IF EXISTS $table'); // Deleta a tabela inteira
    } catch (e) {
      print('Erro ao deletar a tabela: $e');
    }
  }

  Future<void> _deleteAllRecords(Database db) async {
    try {
      await db.delete(table); // Deleta todos os registros da tabela
    } catch (e) {
      print('Erro ao deletar todos os registros: $e');
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(''' 
      CREATE TABLE IF NOT EXISTS $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnFileName TEXT,
        $columnUnitizador INTEGER,
        $columnPosicao INTEGER,
        $columnDeposito INTEGER,
        $columnBloco INTEGER,
        $columnQuadra INTEGER,
        $columnLote INTEGER,
        $columnAndar INTEGER,
        $columnCodigoDeBarras INTEGER,
        $columnQtdePadraoDaPilha INTEGER,
        $columnQtdeDePilhasCompletas INTEGER,
        $columnQtdeDeItensAvulsos INTEGER,
        $columnExportToEmail INTEGER,
        $columnExportToFilePath INTEGER,
        $columnFilePath TEXT,
        $columnEmail TEXT,
        $columnUser TEXT,
        $columnPassword TEXT 
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
    bool qtdePadraoDaPilha,
    bool qtdeDePilhasCompletas,
    bool qtdeDeItensAvulsos,
    String fileName,
    bool exportToEmail,
    bool exportToFilePath,
    String filePath,
    String email,
    String user,
    String password
  ) async {
    try {
      final db = await database;

      final existingRecords = await db.query( // Verifica se existe algum registro
        table,
        limit: 1,  // Limita para o primeiro registro
      );

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
            columnQtdePadraoDaPilha:      qtdePadraoDaPilha ? 1 : 0,
            columnQtdeDePilhasCompletas:  qtdeDePilhasCompletas ? 1 : 0,
            columnQtdeDeItensAvulsos:     qtdeDeItensAvulsos ? 1 : 0,
            columnExportToEmail:          exportToEmail ? 1 : 0,
            columnExportToFilePath:       exportToFilePath ? 1 : 0,
            columnFilePath:               filePath,
            columnEmail:                  email,
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
            columnExportToEmail:          exportToEmail ? 1 : 0,
            columnExportToFilePath:       exportToFilePath ? 1 : 0,
            columnFilePath:               filePath,
            columnEmail:                  email,
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
      final result = await db.query(
        table,
        limit: 1,  // Sempre carregamos o primeiro registro (id = 1)
      );
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
          'qtdePadraoDaPilha':      data[columnQtdePadraoDaPilha]     == 1,
          'qtdeDePilhasCompletas':  data[columnQtdeDePilhasCompletas] == 1,
          'qtdeDeItensAvulsos':     data[columnQtdeDeItensAvulsos]    == 1,
          'exportToEmail':          data[columnExportToEmail]         == 1,
          'exportToFilePath':       data[columnExportToFilePath]      == 1,
          'filePath':               data[columnFilePath].toString(),
          'email':                  data[columnEmail].toString(),
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


  // Deserializar os campos selecionados
  Map<String, bool> _deserializeFields(String fieldsString) {
    Map<String, bool> selectedFields = {};
    final fields = fieldsString.split(',');

    for (var field in fields) {
      selectedFields[field] = true; // Por padrão, todos os campos serão selecionados
    }

    return selectedFields;
  }
}