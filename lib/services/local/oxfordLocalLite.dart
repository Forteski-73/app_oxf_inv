import 'package:sqflite/sqflite.dart';
import 'package:app_oxf_inv/widgets/customSnackBar.dart';
import 'package:app_oxf_inv/operator/db_product.dart';
import 'package:app_oxf_inv/models/product_image.dart';
import 'package:app_oxf_inv/models/product_tag.dart';
import 'package:app_oxf_inv/models/product.dart';
import 'package:app_oxf_inv/models/product_all.dart';
import 'package:app_oxf_inv/ftp/ftp.dart';
import 'package:path/path.dart' as path;

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

  Future<void> saveAllProductsLocally(List<ProductAll> products, context) async {
    final db = await DBItems.instance.database;
    final ftp = FTPUploader();
    List<ProductImage> imgs = [];

    for (final product in products) {
      try {

        imgs.clear();
        // Determina o diretório a partir da primeira imagem
        final directory = product.productImages.isNotEmpty
            ? path.dirname(product.productImages.first.imagePath)
            : '';
        
        if (directory.isNotEmpty) {
          await DBItems.instance.deleteProductImageFiles(product.itemId);
          imgs = await ftp.fetchImagesFromFTP(directory, product.itemId, context);
        }

        // Se houver imagens, define a primeira como imagem principal
        if (imgs.isNotEmpty) product.path = imgs.first.imagePath;
        
        await db.transaction((txn) async {
          // Insere ou atualiza o produto principal
          await txn.insert(
            DBItems.tableProducts,
            product.toMapProduct(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );

          // Insere ou atualiza imagens do produto
          for (final image in imgs) {
            await txn.insert(
              DBItems.tableProductImages,
              {
                DBItems.columnImagePath: image.imagePath,
                DBItems.columnImageSequence: image.imageSequence,
                DBItems.columnProductId: image.productId,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }

          // Insere ou atualiza tags do produto
          for (final tag in product.productTags) {
            await txn.insert(
              DBItems.tableProductTags,
              {
                DBItems.columnTag: tag.tag,
                DBItems.columnTagProductId: product.itemId,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        });
      } catch (e) {
        CustomSnackBar.show(context, message: 'Erro ao salvar produto ${product.itemId}: $e',
          duration: const Duration(seconds: 4),type: SnackBarType.error,
        );
      }
    }
  }
}
