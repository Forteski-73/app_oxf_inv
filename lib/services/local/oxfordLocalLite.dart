import 'package:sqflite/sqflite.dart';
import 'package:app_oxf_inv/operator/db_product.dart';
import 'package:app_oxf_inv/models/product_image.dart';
import 'package:app_oxf_inv/models/product_tag.dart';
import 'package:app_oxf_inv/models/product.dart';

class OxfordLocalLite {
  static final OxfordLocalLite _instance = OxfordLocalLite._internal();

  factory OxfordLocalLite() => _instance;

  OxfordLocalLite._internal();

  Future<Database> get _db async => await DBItems.instance.database;

  /// Retorna todos os produtos como uma lista de objetos Product
  Future<List<Product>> getAllProducts() async {
    final db = await _db;
    final result = await db.query(DBItems.tableProducts);
    return result.map((map) => Product.fromMap(map)).toList();
  }

  /// Retorna todos os produtos com imagem de sequência 1 (se existir), mapeando para Product com campo path preenchido
  Future<List<Product>> getAllProductsWithMainImage() async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT p.*, COALESCE(i.${DBItems.columnImagePath}, '') AS path
      FROM ${DBItems.tableProducts} p
      LEFT JOIN ${DBItems.tableProductImages} i 
        ON p.${DBItems.columnItemId} = i.${DBItems.columnProductId} 
        AND i.${DBItems.columnImageSequence} = 1
    ''');

    return result.map((map) => Product.fromMap(map)).toList();
  }

  /// Retorna os detalhes de um produto por ID como objeto Product ou null se não encontrado
  Future<Product?> getProductDetails(String productId) async {
    final db = await _db;
    final result = await db.query(
      DBItems.tableProducts,
      where: '${DBItems.columnItemId} = ?',
      whereArgs: [productId],
    );
    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  /// Busca produto pelo código de barras e retorna objeto Product ou null se não encontrado
  Future<Product?> getProductByBarCode(String barCode) async {
    final db = await _db;
    final result = await db.query(
      DBItems.tableProducts,
      where: '${DBItems.columnItemBarCode} = ?',
      whereArgs: [barCode],
    );
    if (result.isNotEmpty) {
      return Product.fromMap(result.first);
    }
    return null;
  }

  /// Retorna imagens de um produto por ID como uma lista de objetos ProductImage
  Future<List<ProductImage>> getProductImages(String productId) async {
    final db = await _db;
    final result = await db.query(
      DBItems.tableProductImages,
      where: '${DBItems.columnProductId} = ?',
      whereArgs: [productId],
      orderBy: '${DBItems.columnImageSequence} ASC',
    );

    return result.map((map) => ProductImage.fromMap(map)).toList();
  }

    /// Retorna tags de um produto por ID
  Future<List<ProductTag>> getProductTags(String productId) async {
    final db = await _db;
    final result = await db.query(
      DBItems.tableProductTags,
      where: '${DBItems.columnTagProductId} = ?',
      whereArgs: [productId],
    );

    return result.map((map) => ProductTag.fromMap(map)).toList();
  }

}
