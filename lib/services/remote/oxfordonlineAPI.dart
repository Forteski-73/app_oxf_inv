import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/product_image.dart';
import '../../models/product.dart';
import '../../models/product_tag.dart'; 

class OxfordOnlineAPI {
  static const String _baseUrl = 'https://oxfordonline.fly.dev/api';
  static const String _token = 'DF9z9WjjyK7PpESh5rV6lrCLuZkctFLP';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  /// Envia uma lista de produtos em lote para a API com autenticação Bearer.
static Future<http.Response> postProducts(List<Product> products) async {
  final url = Uri.parse('$_baseUrl/Product');

  // Converte a lista de Product para uma lista de Map<String, dynamic>
  final List<Map<String, dynamic>> productList = products.map((p) => p.toMap()).toList();

  return await http.post(
    url,
    headers: _headers,
    body: jsonEncode(productList),
  );
}

  /// Envia uma lista de imagens (ProductImage) em lote para a API.
  static Future<http.Response> postImages(List<ProductImage> images) async {
    final url = Uri.parse('$_baseUrl/Image');
    final body = jsonEncode(images.map((img) => img.toMap()).toList());

    return await http.post(
      url,
      headers: _headers,
      body: body,
    );
  }

  /// Busca uma imagem por ID e retorna um objeto ProductImage.
  static Future<ProductImage?> getImageById(int id) async {
    final url = Uri.parse('$_baseUrl/Image/$id');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final map = jsonDecode(response.body);
      return ProductImage.fromMap(map);
    }
    return null;
  }

  /// Busca todas as imagens de um produto e retorna uma lista de ProductImage.
  static Future<List<ProductImage>> getImagesByProductId(String productId) async {
    final url = Uri.parse('$_baseUrl/Image/Product/$productId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => ProductImage.fromMap(json)).toList();
    }

    return [];
  }

  /// Envia uma lista de tags (ProductTag) em lote para a API.
  static Future<http.Response> postTags(List<ProductTag> tags) async {
    final url = Uri.parse('$_baseUrl/Tag');
    final body = jsonEncode(tags.map((tag) => tag.toMap()).toList());

    return await http.post(
      url,
      headers: _headers,
      body: body,
    );
  }

  /// Busca todas as tags de um produto e retorna uma lista de ProductTag.
  static Future<List<ProductTag>> getTagsByProductId(String productId) async {
    final url = Uri.parse('$_baseUrl/Tag/Product/$productId');
    final response = await http.get(url, headers: _headers);

    if (response.statusCode == 200) {
      final List<dynamic> list = jsonDecode(response.body);
      return list.map((json) => ProductTag.fromMap(json)).toList();
    }

    return [];
  }

}