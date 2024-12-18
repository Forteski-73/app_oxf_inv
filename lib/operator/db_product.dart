import 'dart:async'; 
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBItems {
  static const _databaseName = "product.db";
  static const _databaseVersion = 1;
  static const table = 'products';

  // Definindo as colunas da tabela 'products'
  static const columnItemBarCode                  = 'ItemBarCode';
  static const columnProdBrandId                  = 'ProdBrandId';
  static const columnProdBrandDescriptionId       = 'ProdBrandDescriptionId';
  static const columnProdLinesId                  = 'ProdLinesId';
  static const columnProdLinesDescriptionId       = 'ProdLinesDescriptionId';
  static const columnProdDecorationId             = 'ProdDecorationId';
  static const columnProdDecorationDescriptionId  = 'ProdDecorationDescriptionId';
  static const columnItemId                       = 'ItemID';
  static const columnName                         = 'Name';
  static const columnUnitVolumeML                 = 'UnitVolumeML';
  static const columnItemNetWeight                = 'ItemNetWeight';
  static const columnProdFamilyId                 = 'ProdFamilyId';
  static const columnProdFamilyDescription        = 'ProdFamilyDescription';

  // Instanciando o construtor DB
  DBItems._privateConstructor();
  static final DBItems instance = DBItems._privateConstructor();

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

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnItemBarCode                  TEXT,
        $columnProdBrandId                  TEXT,
        $columnProdBrandDescriptionId       TEXT,
        $columnProdLinesId                  TEXT,
        $columnProdLinesDescriptionId       TEXT,
        $columnProdDecorationId             TEXT,
        $columnProdDecorationDescriptionId  TEXT,
        $columnItemId                       TEXT PRIMARY KEY,
        $columnName                         TEXT,
        $columnUnitVolumeML                 REAL,
        $columnItemNetWeight                REAL,
        $columnProdFamilyId                 TEXT,
        $columnProdFamilyDescription        TEXT
      );
    ''');
  }

  // Inserir produto
  Future<int> insertProduct(Map<String, dynamic> product) async {
    Database db = await instance.database;
    return await db.insert(
      table,
      product,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Pegar todos os produtos
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    Database db = await instance.database;
    //return await db.query(table);
    return List<Map<String, dynamic>>.from(await db.query(table)); // Converte o resultado para uma lista mutável
  }

  // Atualizar produto
  Future<int> updateProduct(Map<String, dynamic> product) async {
    Database db = await instance.database;
    return await db.update(
      table,
      product,
      where: '$columnItemId = ?',
      whereArgs: [product[columnItemId]],
    );
  }

  // Deletar produto
  Future<int> deleteProduct(String itemId) async {
    Database db = await instance.database;
    return await db.delete(
      table,
      where: '$columnItemId = ?',
      whereArgs: [itemId],
    );
  }
}
