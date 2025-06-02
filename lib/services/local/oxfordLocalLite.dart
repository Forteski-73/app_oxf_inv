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
    final dbprod = DBItems.instance;
    final ftp = FTPUploader();
    List<ProductImage> listImgs = [];

      for (final product in products) {

        try {

          await dbprod.deleteProductImageFiles(product.itemId);
          await dbprod.deleteProduct(product.itemId);

          listImgs.clear();
          //await db.transaction((txn) async {
            final directory = product.productImages.isNotEmpty
                ? path.dirname(product.productImages.first.imagePath)
                : '';

            if (directory.isNotEmpty) { // Determina o diretório a partir da primeira imagem
              listImgs = await ftp.fetchImagesFromFTP(directory, product.itemId, product.productImages, context);
            }

            // Se houver imagens, define a primeira como imagem principal
            if (listImgs.isNotEmpty) product.path = listImgs.first.imagePath;

            int insertedId = await dbprod.insertProduct(product.toMapProduct());
            if (insertedId > 0) {
              for (final image in listImgs) {
                await dbprod.insertProductImage(image.toMap());
              }

              for (final tag in product.productTags) {
                await dbprod.insertProductTag(tag.toMap());
              }
            } else {
              throw Exception("Erro ao inserir o produto: ${product.itemId} - ${product.name}");
            }
        } catch (e) {
          CustomSnackBar.show(context, message: 'Erro ao salvar produto ${product.itemId}: $e',
            duration: const Duration(seconds: 4),type: SnackBarType.error,
          );
        }
      }
  }
}
