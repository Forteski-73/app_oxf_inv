import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBItems {
  static const _databaseName = "product.db";
  static const _databaseVersion = 1;
  static const table = 'products';

  // Definindo as colunas da tabela 'products'
  static const columnItemId                         = 'ItemId';
  static const columnItemBarCode                    = 'ItemBarCode';
  static const columnMSBProdBrandDescriptionId      = 'MSBProdBrandDescriptionId';
  static const columnMSBProdBrandId                 = 'MSBProdBrandId';
  static const columnMSBProdDecorationCodeId        = 'MSBProdDecorationCodeId';
  static const columnMSBProdDecorationDescriptionId = 'MSBProdDecorationDescriptionId';
  static const columnMSBProdFamilyDescriptionId     = 'MSBProdFamilyDescriptionId';
  static const columnMSBProdFamilyId                = 'MSBProdFamilyId';
  static const columnMSBProdLinesDescriptionId      = 'MSBProdLinesDescriptionId';
  static const columnMSBProdLinesId                 = 'MSBProdLinesId';
  static const columnMSBProdQualityDescriptionId    = 'MSBProdQualityDescriptionId';
  static const columnMSBProdQualityId               = 'MSBProdQualityId';
  static const columnMSBProdSituationDescriptionId  = 'MSBProdSituationDescriptionId';
  static const columnMSBProdSituationId             = 'MSBProdSituationId';
  static const columnGrossHeight                    = 'GrossHeight';
  static const columnGrossWidth                     = 'GrossWidth';
  static const columnGrossDepth                     = 'GrossDepth';
  static const columnNameAlias                      = 'NameAlias';
  static const columnNetWeight                      = 'NetWeight';

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

    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate); // Abrindo/criando a tabela
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnItemId                     TEXT PRIMARY KEY,
        $columnItemBarCode                TEXT,
        $columnMSBProdBrandDescriptionId  TEXT,
        $columnMSBProdBrandId             TEXT,
        $columnMSBProdDecorationCodeId    TEXT,
        $columnMSBProdDecorationDescriptionId TEXT,
        $columnMSBProdFamilyDescriptionId     TEXT,
        $columnMSBProdFamilyId                TEXT,
        $columnMSBProdLinesDescriptionId      TEXT,
        $columnMSBProdLinesId                 TEXT,
        $columnMSBProdQualityDescriptionId    TEXT,
        $columnMSBProdQualityId               TEXT,
        $columnMSBProdSituationDescriptionId  TEXT,
        $columnMSBProdSituationId             TEXT,
        $columnGrossHeight  REAL,
        $columnGrossWidth   REAL,
        $columnGrossDepth   REAL,
        $columnNameAlias    TEXT,
        $columnNetWeight    REAL
      );
    ''');
  }

  // Inserir produto
  Future<int> insertProduct(Map<String, dynamic> product) async {
    Database db = await instance.database;
    return await db.insert(table, product, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Pegar todos os produtos
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    Database db = await instance.database;
    return await db.query(table);
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
    return await db.delete(table, where: '$columnItemId = ?', whereArgs: [itemId]);
  }
}
