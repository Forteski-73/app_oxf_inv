import 'product.dart';
import 'product_image.dart';
import 'product_tag.dart';

class ProductAll extends Product {
  final List<ProductImage> productImages;
  final List<ProductTag> productTags;

  ProductAll({
    String itemBarCode = "",
    String prodBrandId = "",
    String prodBrandDescriptionId = "",
    String prodLinesId = "",
    String prodLinesDescriptionId = "",
    String prodDecorationId = "",
    String prodDecorationDescriptionId = "",
    String itemId = "",
    String name = "",
    String path = "",
    double unitVolumeML = 0.0,
    double itemNetWeight = 0.0,
    String prodFamilyId = "",
    String prodFamilyDescriptionId = "",
    double prodGrossWeight = 0.0,
    double prodTaraWeight = 0.0,
    double prodGrossDepth = 0.0,
    double prodGrossWidth = 0.0,
    double prodGrossHeight = 0.0,
    double prodNrOfItems = 0.0,
    String prodTaxFiscalClassification = "",
    this.productImages = const [],
    this.productTags = const [],
  }) : super(
    itemBarCode: itemBarCode,
    prodBrandId: prodBrandId,
    prodBrandDescriptionId: prodBrandDescriptionId,
    prodLinesId: prodLinesId,
    prodLinesDescriptionId: prodLinesDescriptionId,
    prodDecorationId: prodDecorationId,
    prodDecorationDescriptionId: prodDecorationDescriptionId,
    itemId: itemId,
    name: name,
    path: path,
    unitVolumeML: unitVolumeML,
    itemNetWeight: itemNetWeight,
    prodFamilyId: prodFamilyId,
    prodFamilyDescriptionId: prodFamilyDescriptionId,
    prodGrossWeight: prodGrossWeight,
    prodTaraWeight: prodTaraWeight,
    prodGrossDepth: prodGrossDepth,
    prodGrossWidth: prodGrossWidth,
    prodGrossHeight: prodGrossHeight,
    prodNrOfItems: prodNrOfItems,
    prodTaxFiscalClassification: prodTaxFiscalClassification,
  );

  factory ProductAll.fromMap(Map<String, dynamic> map) {
    return ProductAll(
      itemBarCode: map['itemBarCode'] ?? '',
      prodBrandId: map['prodBrandId'] ?? '',
      prodBrandDescriptionId: map['prodBrandDescriptionId'] ?? '',
      prodLinesId: map['prodLinesId'] ?? '',
      prodLinesDescriptionId: map['prodLinesDescriptionId'] ?? '',
      prodDecorationId: map['prodDecorationId'] ?? '',
      prodDecorationDescriptionId: map['prodDecorationDescriptionId'] ?? '',
      itemId: map['itemId'] ?? '',
      name: map['name'] ?? '',
      unitVolumeML: (map['unitVolumeML'] ?? 0).toDouble(),
      itemNetWeight: (map['itemNetWeight'] ?? 0).toDouble(),
      prodFamilyId: map['prodFamilyId'] ?? '',
      prodFamilyDescriptionId: map['prodFamilyDescriptionId'] ?? '',
      prodGrossWeight: (map['grossWeight'] ?? 0).toDouble(),
      prodTaraWeight: (map['taraWeight'] ?? 0).toDouble(),
      prodGrossDepth: (map['grossDepth'] ?? 0).toDouble(),
      prodGrossWidth: (map['grossWidth'] ?? 0).toDouble(),
      prodGrossHeight: (map['grossHeight'] ?? 0).toDouble(),
      prodNrOfItems: (map['nrOfItems'] ?? 0).toDouble(),
      prodTaxFiscalClassification: map['taxFiscalClassification'] ?? '',
      productImages: (map['productImages'] as List<dynamic>?)
              ?.map((img) => ProductImage.fromMap(img))
              .toList() ??
          [],
      productTags: (map['productTags'] as List<dynamic>?)
              ?.map((tag) => ProductTag.fromMap(tag))
              .toList() ??
          [],
      path: ((map['productImages'] as List<dynamic>?)?.isNotEmpty ?? false)
          ? ProductImage.fromMap(map['productImages'][0]).imagePath : '',
    );
  }

Map<String, dynamic> toMapProduct() {
  return super.toMap(); // Apenas os campos da tabela 'products'
}

  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['productImages'] = productImages.map((img) => img.toMap()).toList();
    map['productTags'] = productTags.map((tag) => tag.toMap()).toList();
    return map;
  }
}