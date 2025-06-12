import 'package:flutter/material.dart';
import 'package:app_oxf_inv/services/remote/oxfordonlineAPI.dart';
import 'package:app_oxf_inv/services/local/oxfordLocalLite.dart';
import 'package:app_oxf_inv/models/product_all.dart';
import 'package:app_oxf_inv/models/product_image.dart';
import 'package:app_oxf_inv/models/product_tag.dart';

class ProductSearchController extends ChangeNotifier {
  final OxfordOnlineAPI api;
  final OxfordLocalLite db;

  List<ProductAll> allProducts = [];
  ProductAll? selectedProduct;
  List<ProductAll> filteredProducts = [];
  bool isLoading = false;
  String searchTerm = "";

  ProductSearchController({required this.api, required this.db});

  Future<void> loadProducts({required bool isOnline, required BuildContext context}) async {
    isLoading = true;
    notifyListeners();

    try {
      if (isOnline) {
        allProducts = await api.getProducts(localDb: db);
      } else {
        allProducts = await db.fetchLast10Products();
      }
      _filterProducts();
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateSearchTerm(String value) {
    searchTerm = value;
    _filterProducts();
  }

  void _filterProducts() {
    if (searchTerm.isEmpty) {
      filteredProducts = List.from(allProducts);
    } else {
      filteredProducts = allProducts
          .where((product) =>
              product.name.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<void> loadProductDetails(String productId) async {
    selectedProduct = allProducts.firstWhere(
      (p) => p.itemId == productId,
      orElse: () => ProductAll(itemId: productId, name: 'Produto não encontrado'),
    );

    selectedProduct!.productImages ??= [];
    selectedProduct!.productTags ??= [];

    notifyListeners();
  }

  List<ProductImage> get imagesData => selectedProduct?.productImages ?? [];
  List<ProductTag> get tags => selectedProduct?.productTags ?? [];

  void addImages(List<ProductImage> novasImagens) {
    if (selectedProduct == null) return;

    selectedProduct!.productImages ??= [];

    int nextSequence = selectedProduct!.productImages!.length + 1;

    for (var img in novasImagens) {
      final novaImagem = ProductImage(
        imageId: img.imageId,
        imagePath: img.imagePath,
        imageSequence: nextSequence++,
        productId: img.productId,
        sync: img.sync,
      );
      selectedProduct!.productImages!.add(novaImagem);
    }

    notifyListeners();
  }

  void removeImageAtIndex(int index) {
    if (selectedProduct == null) return;

    final imagens = selectedProduct!.productImages;
    if (imagens != null && index >= 0 && index < imagens.length) {
      imagens.removeAt(index);

      // Recria lista com nova sequência
      selectedProduct!.productImages = List<ProductImage>.generate(
        imagens.length,
        (i) => ProductImage(
          imageId: imagens[i].imageId,
          imagePath: imagens[i].imagePath,
          imageSequence: i + 1,
          productId: imagens[i].productId,
          sync: imagens[i].sync,
        ),
      );

      notifyListeners();
    }
  }

  void reorderImages(int oldIndex, int newIndex) {
    if (selectedProduct == null) return;

    final imagens = selectedProduct!.productImages;
    if (imagens == null || oldIndex < 0 || newIndex < 0 || oldIndex >= imagens.length || newIndex > imagens.length) {
      return;
    }

    final image = imagens.removeAt(oldIndex);
    imagens.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, image);

    selectedProduct!.productImages = List<ProductImage>.generate(
      imagens.length,
      (i) => ProductImage(
        imageId: imagens[i].imageId,
        imagePath: imagens[i].imagePath,
        imageSequence: i + 1,
        productId: imagens[i].productId,
        sync: imagens[i].sync,
      ),
    );

    notifyListeners();
  }

  void addTag(ProductTag newTag) {
    if (selectedProduct == null) return;

    selectedProduct!.productTags ??= [];

    bool exists = selectedProduct!.productTags!
        .any((tag) => tag.tag.toLowerCase() == newTag.tag.toLowerCase());

    if (!exists) {
      selectedProduct!.productTags!.add(newTag);
      notifyListeners();
    }
  }

  void removeTag(ProductTag tagToRemove) {
    if (selectedProduct == null) return;

    selectedProduct!.productTags?.removeWhere((tag) => tag.tag == tagToRemove.tag);
    notifyListeners();
  }
}

/*import 'package:flutter/material.dart';
import 'package:app_oxf_inv/services/remote/oxfordonlineAPI.dart';
import 'package:app_oxf_inv/services/local/oxfordLocalLite.dart';
import 'package:app_oxf_inv/models/product_all.dart';

class ProductSearchController extends ChangeNotifier {
  final OxfordOnlineAPI api;
  final OxfordLocalLite db;

  List<ProductAll> allProducts = [];
  ProductAll? selectedProduct;
  List<ProductAll> filteredProducts = [];
  bool isLoading = false;
  String searchTerm = "";

  ProductSearchController({required this.api, required this.db});

  Future<void> loadProducts({required bool isOnline, required BuildContext context}) async {
    isLoading = true;
    notifyListeners();

    try {
      if (isOnline) {
        allProducts = await api.getProducts(localDb: db);
      } else {
        allProducts = await db.fetchLast10Products();
        
      }
      _filterProducts();
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateSearchTerm(String value) {
    searchTerm = value;
    _filterProducts();
  }

  void _filterProducts() {
    if (searchTerm.isEmpty) {
      filteredProducts = List.from(allProducts);
    } else {
      filteredProducts = allProducts
          .where((product) =>
              product.name.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<void> loadProductDetails(String productId) async {
    selectedProduct = allProducts.firstWhere(
      (p) => p.itemId == productId,
      orElse: () => ProductAll(itemId: productId, name: 'Produto não encontrado'),
    );
    notifyListeners();
  }

}
*/