class ProductImage {
  final int     imageId;
  final String  imagePath;
  final int     imageSequence;
  final String  productId;

  ProductImage({
    this.imageId        = 0,
    this.imagePath      = '',
    this.imageSequence  = 0,
    this.productId      = '',
  });

  // Converte para Map (para inserção no banco)
  Map<String, dynamic> toMap() {
    return {
      //'id':         imageId,
      'path':       imagePath,
      'sequence':   imageSequence,
      'productId':  productId,
    };
  }

  // Cria a partir de um Map (consulta no banco)
  factory ProductImage.fromMap(Map<String, dynamic> map) {
    return ProductImage(
      imageId:        map['id']         ?? 0,
      imagePath:      map['path']       ?? '',
      imageSequence:  map['sequence']   ?? 0,
      productId:      map['productId'] ?? map['productId'] ,
    );
  }
}