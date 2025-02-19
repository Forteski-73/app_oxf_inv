import 'dart:async'; 
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBItems {
  static const _databaseName        = "product.db";
  static const _databaseVersion     = 1;
  static const tableProducts        = 'products';
  static const tableProductImages   = 'product_images';
  static const tableProductTags    = 'product_tags';

  // Campos da tabela products
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

    // Campos da tabela product_images
  static const columnImageId           = '_id';
  static const columnImagePath         = 'path';
  static const columnImageSequence     = 'sequence';
  static const columnProductId         = 'product_id';

    // Campos da tabela product_tags
  static const columnTagId        = '_id';
  static const columnTag          = 'path';
  static const columnTagProductId = 'product_id';

    // Instancia o construtor DB
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
    ); // Abrindo ou criando a tabela
  }

  Future _onCreate(Database db, int version) async {
    //await db.execute('''DROP TABLE IF EXISTS $tableProductTags;''');
    //await db.execute('''DROP TABLE IF EXISTS $tableProductImages;''');
    //await db.execute('''DROP TABLE IF EXISTS $tableProducts;''');

    // Criando a tabela de produtos
    await db.execute('''
      CREATE TABLE $tableProducts (
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

    // Criando a tabela de imagens de produto
    await db.execute('''
      CREATE TABLE $tableProductImages (
        $columnImageId           INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnImagePath         TEXT UNIQUE,
        $columnImageSequence     INTEGER,
        $columnProductId         TEXT,
        FOREIGN KEY ($columnProductId) REFERENCES $tableProducts($columnItemId) ON DELETE CASCADE
      );
    ''');

    // Criando a tabela de tags do produto
    await db.execute('''
      CREATE TABLE $tableProductTags (
        $columnTagId        INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTag          TEXT UNIQUE,
        $columnTagProductId TEXT,
        FOREIGN KEY ($columnTagProductId) REFERENCES $tableProducts($columnItemId) ON DELETE CASCADE
      );
    ''');
  }

  // Métodos para a tabela de produtos (já existentes)
  Future<int> insertProduct(Map<String, dynamic> product) async {
    Database db = await instance.database;
    return await db.insert(
      tableProducts,
      product,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    Database db = await instance.database;
    return List<Map<String, dynamic>>.from(await db.query(tableProducts));
  }

Future<List<Map<String, dynamic>>> getAllProducts1() async {
  Database db = await instance.database;
  
  // Consulta que retorna todos os produtos junto com o caminho da imagem da sequência 1
  final List<Map<String, dynamic>> products = await db.rawQuery('''
    SELECT p.*, COALESCE(i.$columnImagePath, '') AS $columnImagePath
    FROM $tableProducts p
    LEFT JOIN $tableProductImages i 
      ON p.$columnItemId = i.$columnProductId 
      AND i.$columnImageSequence = 1
  ''');
  
  return products;
}

  Future<int> updateProduct(Map<String, dynamic> product) async {
    Database db = await instance.database;
    return await db.update(
      tableProducts,
      product,
      where: '$columnItemId = ?',
      whereArgs: [product[columnItemId]],
    );
  }

  Future<int> deleteProduct(String itemId) async {
    Database db = await instance.database;
    return await db.delete(
      tableProducts,
      where: '$columnItemId = ?',
      whereArgs: [itemId],
    );
  }

  Future<int> deleteAllProducts() async {
    Database db = await instance.database;
    return await db.delete(tableProducts);
  }

  // Métodos para a tabela de imagens de produto
  Future<int> insertProductImage(Map<String, dynamic> image) async {
    Database db = await instance.database;
    return await db.insert(
      tableProductImages,
      image,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getProductTags(String productId) async {
    Database db = await instance.database;
    return List<Map<String, dynamic>>.from(await db.query(
      tableProductTags,
      where: '$columnProductId = ?',
      whereArgs: [productId],
    ));
  }

  Future<int> insertProductTag(Map<String, dynamic> tag) async {
    
    Database db = await instance.database;
    return await db.insert(
      tableProductTags,
      tag,
      conflictAlgorithm: ConflictAlgorithm.replace,  // Se já existir substitui
    );
  }

  Future<List<Map<String, dynamic>>> getProductImages(String productId) async {
    Database db = await instance.database;
    return List<Map<String, dynamic>>.from(await db.query(
      tableProductImages,
      where: '$columnProductId = ?',
      whereArgs: [productId],
    ));
  }

  Future<int> updateProductImage(Map<String, dynamic> image) async {
    Database db = await instance.database;
    return await db.update(
      tableProductImages,
      image,
      where: '$columnImageId = ?',
      whereArgs: [image[columnImageId]],
    );
  }

  Future<int> deleteProductImage(int imageId) async {
    Database db = await instance.database;
    return await db.delete(
      tableProductImages,
      where: '$columnImageId = ?',
      whereArgs: [imageId],
    );
  }

  Future<int> deleteProductImagesByProduct(String productId) async {
    Database db = await instance.database;
    return await db.delete(
      tableProductTags,
      where: '$columnProductId = ?',
      whereArgs: [productId],
    );
  }

    Future<int> deleteProductTagsByProduct(String productId) async {
    Database db = await instance.database;
    return await db.delete(
      tableProductImages,
      where: '$columnProductId = ?',
      whereArgs: [productId],
    );
  }

  Future<void> salvarImagens(int sequence, String productId, String path) async {

        // Insere o caminho da imagem e o índice na tabela de imagens
        await insertProductImage({
          columnImagePath: path,
          columnImageSequence: sequence, // O índice da imagem
          columnProductId: productId, // ID do produto
        });
      

  }

Future<void> updateImageSequence(String imagePath, int newSequence) async {
  Database db = await instance.database;
  await db.update(
    tableProductImages,
    {DBItems.columnImageSequence: newSequence},
    where: '${DBItems.columnImagePath} = ?',
    whereArgs: [imagePath],
  );
}

}
