import 'package:flutter/material.dart';
import 'package:app_oxf_inv/services/remote/oxfordonlineAPI.dart';
import 'package:app_oxf_inv/services/local/oxfordLocalLite.dart';
import 'package:app_oxf_inv/models/product_all.dart';


class ProductSearchController extends ChangeNotifier {
  final OxfordOnlineAPI api;
  final OxfordLocalLite db;

  List<ProductAll> allProducts = [];
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

  void updateProductPath({required int productId, required String newPath}) {
    final index = allProducts.indexWhere((product) => product.itemId == productId);
    if (index != -1) {
      allProducts[index].path = newPath;
      notifyListeners();
    }
  }

}
