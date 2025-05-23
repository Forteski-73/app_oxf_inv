class ProductTag {
  final String tag;
  final String productId;

  ProductTag({
    this.tag = '',
    this.productId = '',
  });

  // Converte para Map para inserção no banco ou envio via API
  Map<String, dynamic> toMap() {
    return {
      'valueTag': tag,
      'productId': productId,
    };
  }

  // Cria a partir de um Map da consulta no banco
  factory ProductTag.fromMap(Map<String, dynamic> map) {
    return ProductTag(
      tag: map['valueTag'] ?? '',
      productId: map['productId'] ?? '',
    );
  }
}