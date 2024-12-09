import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBSettings {
  static const _databaseName      = "settings.db";
  static const _databaseVersion   = 1;
  static const table              = 'settings';
  static const columnId           = '_id';
  static const columnNome         = 'nome';
  static const columnExibir       = 'exibir';
  static const columnObrigatorio  = 'obrigatorio';

  // Instanciando o construtor DB
  DBSettings._privateConstructor();
  static final DBSettings instance = DBSettings._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Obtendo o diretório para armazenar o banco de dados
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _databaseName);

    // Abrindo ou criando o banco de dados
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  // Create table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY,
        $columnNome TEXT NOT NULL,
        $columnExibir INTEGER NOT NULL,
        $columnObrigatorio INTEGER NOT NULL
      )
    ''');
  }

  // Inserir
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  // Atualizar
  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }
  /*
  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];

    // Construa a string SQL manualmente
    String sql = '''
    UPDATE $table
    SET ${row.keys.map((key) => '$key = ?').join(', ')}
    WHERE $columnId = $id;
    ''';

    // Exiba no console
    //print("SQL de atualização: $sql");
    //print("Valores: ${row.values.toList()}");

    // Execute o comando no banco de dados
    return await db.update(
      table,
      row,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
  */

  // Função para obter todos os campos
  /*Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }*/
  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    final result = await db.query(table);
    
    return List<Map<String, dynamic>>.from(result); // Converte o resultado para uma lista mutável
  }

  // Função para deletar um campo
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}