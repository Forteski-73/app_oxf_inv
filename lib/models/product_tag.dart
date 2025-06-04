class ProductTag {
  final String tag;
  final String productId;
  final int    sync;

  ProductTag({
    this.tag       = '',
    this.productId = '',
    this.sync      = 0,
  });

  // Converte para Map para inserção no banco ou envio via API
  Map<String, dynamic> toMap() {
    return {
      'valueTag':  tag,
      'productId': productId,
      'sync':      sync,
    };
  }

  // Cria a partir de um Map da consulta no banco
  factory ProductTag.fromMap(Map<String, dynamic> map) {
    return ProductTag(
      tag:        map['valueTag']   ?? '',
      productId:  map['productId']  ?? map['productId'],
      sync:       map['sync']       ?? 0,
    );
  }
}