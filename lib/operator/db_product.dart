import 'dart:async'; 
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/product_all.dart';
import '../../models/product_image.dart';
import 'dart:io';
import '../../models/product_tag.dart';
import '../utils/globals.dart' as globals;

class DBItems {
  static const _databaseName        = "product.db";
  static const _databaseVersion     = 1;
  static const tableProducts        = 'products';
  static const tableProductImages   = 'product_images';
  static const tableProductTags    = 'product_tags';

  // Campos da tabela products
  static const columnItemBarCode                  = 'itemBarCode';
  static const columnProdBrandId                  = 'prodBrandId';
  static const columnProdBrandDescriptionId       = 'prodBrandDescriptionId';
  static const columnProdLinesId                  = 'prodLinesId';
  static const columnProdLinesDescriptionId       = 'prodLinesDescriptionId';
  static const columnProdDecorationId             = 'prodDecorationId';
  static const columnProdDecorationDescriptionId  = 'prodDecorationDescriptionId';
  static const columnItemId                       = 'itemId';
  static const columnName                         = 'name';
  static const columnPath                         = 'path';
  static const columnUnitVolumeML                 = 'unitVolumeML';
  static const columnItemNetWeight                = 'itemNetWeight';
  static const columnProdFamilyId                 = 'prodFamilyId';
  static const columnProdFamilyDescriptionId      = 'prodFamilyDescriptionId';
  
  static const columnGrossWeight                  = 'grossWeight';
  static const columnTaraWeight                   = 'taraWeight';
  static const columnGrossDepth                   = 'grossDepth';
  static const columnGrossWidth                   = 'grossWidth';
  static const columnGrossHeight                  = 'grossHeight';
  static const columnNrOfItems                    = 'nrOfItems';
  static const columnTaxFiscalClassification      = 'taxFiscalClassification';

    // Campos da tabela product_images
  static const columnImageId           = '_id';
  static const columnImagePath         = 'path';
  static const columnImageSequence     = 'sequence';
  static const columnProductId         = 'productId';

    // Campos da tabela product_tags
  static const columnTagId        = '_id';
  static const columnTag          = 'valueTag';
  static const columnTagProductId = 'productId';

  static const columnSync         = 'sync'; // sincronizado com a nuvem?

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
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _databaseName);

    // Use a factory configurada globalmente, que pode ser a do ffi ou a padrão do sqflite
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: _onCreate,
      ),
    );
  }

  Future _onCreate(Database db, int version) async {

    //await db.execute('DROP TABLE IF EXISTS $tableProductImages');
    //await db.execute('DROP TABLE IF EXISTS $tableProductTags');
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
        $columnPath                         TEXT,
        $columnUnitVolumeML                 REAL,
        $columnItemNetWeight                REAL,
        $columnProdFamilyId                 TEXT,
        $columnProdFamilyDescriptionId      TEXT,

        $columnGrossWeight                  REAL,
        $columnTaraWeight                   REAL,
        $columnGrossDepth                   REAL,
        $columnGrossWidth                   REAL,
        $columnGrossHeight                  REAL,
        $columnNrOfItems                    REAL,
        $columnTaxFiscalClassification      TEXT
      );
    ''');

    await db.execute('CREATE INDEX idx_prod_brand_id ON $tableProducts ($columnProdBrandId);');
    await db.execute('CREATE INDEX idx_prod_brand_desc_id ON $tableProducts ($columnProdBrandDescriptionId);');
    await db.execute('CREATE INDEX idx_prod_lines_id ON $tableProducts ($columnProdLinesId);');
    await db.execute('CREATE INDEX idx_prod_lines_desc_id ON $tableProducts ($columnProdLinesDescriptionId);');
    await db.execute('CREATE INDEX idx_prod_decoration_id ON $tableProducts ($columnProdDecorationId);');
    await db.execute('CREATE INDEX idx_prod_decoration_desc_id ON $tableProducts ($columnProdDecorationDescriptionId);');
    await db.execute('CREATE INDEX idx_prod_family_id ON $tableProducts ($columnProdFamilyId);');
    await db.execute('CREATE INDEX idx_prod_family_desc ON $tableProducts ($columnProdFamilyDescriptionId);');
    await db.execute('CREATE INDEX idx_item_barcode ON $tableProducts ($columnItemBarCode);');

    // Criando a tabela de imagens de produto
    await db.execute('''
      CREATE TABLE $tableProductImages (
        $columnImageId           INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnImagePath         TEXT UNIQUE,
        $columnImageSequence     INTEGER,
        $columnSync              INTEGER,
        $columnProductId         TEXT,
        FOREIGN KEY ($columnProductId) REFERENCES $tableProducts($columnItemId) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX idx_product_images_productId ON $tableProductImages ($columnProductId);');

    // Criando a tabela de tags do produto
    await db.execute('''
      CREATE TABLE $tableProductTags (
        $columnTagId        INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTag          TEXT UNIQUE,
        $columnSync         INTEGER,
        $columnTagProductId TEXT,
        FOREIGN KEY ($columnTagProductId) REFERENCES $tableProducts($columnItemId) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX idx_product_tags_productId ON $tableProductTags ($columnTagProductId);');

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

  Future<List<ProductAll>> getAllProducts1() async {
    final Database db = await instance.database;

    // Consulta os produtos com imagem da sequência 1
    final List<Map<String, dynamic>> productMaps = await db.rawQuery('''
      SELECT p.*, COALESCE(i.$columnImagePath, '') AS $columnImagePath
      FROM $tableProducts p
      LEFT JOIN $tableProductImages i 
        ON p.$columnItemId = i.$columnProductId 
        AND i.$columnImageSequence = 1
      LIMIT 10
    ''');

    List<ProductAll> productAllList = [];

    for (var productMap in productMaps) {
      final String itemId = productMap[columnItemId];

      // Busca imagens adicionais do produto
      final List<Map<String, dynamic>> imageMaps = await db.query(
        tableProductImages,
        where: '$columnProductId = ?',
        whereArgs: [itemId],
      );

      final List<ProductImage> images = imageMaps
          .map((imgMap) => ProductImage.fromMap(imgMap))
          .toList();

      // Busca tags do produto
      final List<Map<String, dynamic>> tagMaps = await db.query(
        tableProductTags,
        where: '$columnProductId = ?',
        whereArgs: [itemId],
      );

      final List<ProductTag> tags = tagMaps
          .map((tagMap) => ProductTag.fromMap(tagMap))
          .toList();

      // Cria o ProductAll combinando produto base, imagens e tags
      final productAll = ProductAll.fromMap({
        ...productMap,
        'productImages': images.map((e) => e.toMap()).toList(),
        'productTags': tags.map((e) => e.toMap()).toList(),
      });

      productAllList.add(productAll);
    }

    return productAllList;
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
      orderBy: '$columnImageSequence ASC',
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

  Future<Map<String, dynamic>> getProductDetails(String productId) async {
    Database db = await instance.database;

    // Consulta para obter os detalhes do produto com base no itemId
    final List<Map<String, dynamic>> productDetails = await db.query(
      tableProducts,
      where: '$columnItemId = ?',
      whereArgs: [productId],
    );
      return productDetails.first;
    
  }

  Future<Map<String, dynamic>?> getProductByBarCode(String barCode) async {
    Database db = await instance.database;

    final List<Map<String, dynamic>> result = await db.query(
      tableProducts,
      where: '$columnItemBarCode = ?',
      whereArgs: [barCode],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }

  Future<void> deleteProductImageFiles(String productId) async {
    
    try {
      
      final List<Map<String, dynamic>> images = await getProductImages(productId);

      for (var img in images) {
        final String? imagePath = img[columnImagePath] as String?;
        if (imagePath == null || imagePath.isEmpty) continue;

        final file = File(imagePath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (e) {
            print('Erro ao deletar o arquivo $imagePath: $e');
          }
        }
      }
    } catch (e) {
      print('Erro ao acessar o banco ou listar imagens: $e');
    }
  }

  Future<int> deleteImagesByProductId(String productId) async {
    final db = await database;
    return await db.delete(
      tableProductImages,
      where: '$columnProductId = ?',
      whereArgs: [productId],
    );
  }

  Future<void> saveCompleteProduct(ProductAll productAll) async {
    final db = DBItems.instance;

    // 1. Insere/atualiza o produto base na tabela 'products'
    await db.insertProduct(productAll.toMapProduct());

    // 2. Remove imagens antigas do produto
    await db.deleteProductImagesByProduct(productAll.itemId);

    // 3. Insere novas imagens
    for (int i = 0; i < productAll.productImages.length; i++) {
      await db.insertProductImage({
        DBItems.columnImagePath: productAll.productImages[i].imagePath,
        DBItems.columnImageSequence: productAll.productImages[i].imageSequence,
        DBItems.columnSync: globals.isOnline ? 1 : 0,
        DBItems.columnProductId: productAll.itemId,
      });
    }

    // 4. Remove tags antigas do produto
    await db.deleteProductTagsByProduct(productAll.itemId);

    // 5. Insere novas tags
    for (final tag in productAll.productTags) {
      await db.insertProductTag({
        DBItems.columnTag: tag.tag,
        DBItems.columnSync: globals.isOnline ? 1 : 0,
        DBItems.columnTagProductId: productAll.itemId,
      });
    }
  }


  //-----------------------MÉTODO PARA NÃO SINCRONIZADOS//------------------------

  Future<Map<String, List<ProductImage>>> getUnsyncedImages() async {
    final db = await database;

    // Usando db.query e selecionando colunas explicitamente
    final List<Map<String, dynamic>> results = await db.query(
      tableProductImages,
      columns: [
        columnImageId,
        columnProductId,
        columnImagePath,
        columnImageSequence,
      ],
      where: '$columnSync = ?',
      whereArgs: [0],
      orderBy: '$columnProductId, $columnImageSequence',
    );

    // Agrupando com fold para manter o padrão funcional
    final images = results.fold<Map<String, List<ProductImage>>>(
      {},
      (map, row) {
        final productId = row[columnProductId] as String;
        final image = ProductImage.fromMap(row);
        map.putIfAbsent(productId, () => []).add(image);
        return map;
      },
    );

    return images;
  }

  Future<Map<String, List<ProductTag>>> getUnsyncedTags() async {
    final db = await database;

    final List<Map<String, dynamic>> results = await db.query(
      tableProductTags,
      columns: [
        columnTagId,
        columnTag,
        columnTagProductId,
      ],
      where: '$columnSync = ?',
      whereArgs: [0],
      orderBy: '$columnTagProductId',
    );

    final tags = results.fold<Map<String, List<ProductTag>>>(
      {},
      (map, row) {
        final productId = row[columnTagProductId] as String;
        final tag = ProductTag.fromMap(row);
        map.putIfAbsent(productId, () => []).add(tag);
        return map;
      },
    );

    return tags;
  }


  //------------------------------------------------------------------------------

}
