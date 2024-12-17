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
    var databasesPath = await getDatabasesPath(); // Diretório do banco de dados
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

  // insert
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  // Update
  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    final result = await db.query(table);
    
    return List<Map<String, dynamic>>.from(result); // Converte o resultado para uma lista mutável
  }

  // Delete
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
}