class Product {
  final String itemBarCode;
  final String prodBrandId;
  final String prodBrandDescriptionId;
  final String prodLinesId;
  final String prodLinesDescriptionId;
  final String prodDecorationId;
  final String prodDecorationDescriptionId;
  final String itemId;
  final String name;
        String path;
  final double unitVolumeML;
  final double itemNetWeight;
  final String prodFamilyId;
  final String prodFamilyDescriptionId;

  final double prodGrossWeight;
  final double prodTaraWeight;
  final double prodGrossDepth;
  final double prodGrossWidth;
  final double prodGrossHeight;
  final double prodNrOfItems;
  final String prodTaxFiscalClassification;

  // Construtor para inicializar todos os campos do produto
  Product({
    this.itemBarCode                  = "",
    this.prodBrandId                  = "",
    this.prodBrandDescriptionId       = "",
    this.prodLinesId                  = "",
    this.prodLinesDescriptionId       = "",
    this.prodDecorationId             = "",
    this.prodDecorationDescriptionId  = "",
    this.itemId                       = "",
    this.name                         = "",
    this.path                         = "",
    this.unitVolumeML                 = 0.0,
    this.itemNetWeight                = 0.0,
    this.prodFamilyId                 = "",
    this.prodFamilyDescriptionId      = "",
    this.prodGrossWeight              = 0.0,
    this.prodTaraWeight               = 0.0,
    this.prodGrossDepth               = 0.0,
    this.prodGrossWidth               = 0.0,
    this.prodGrossHeight              = 0.0,
    this.prodNrOfItems                = 0.0,
    this.prodTaxFiscalClassification  = "",
  });

  // Método para converter um objeto Product em um mapa para inserção no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'itemBarCode': itemBarCode,
      'prodBrandId': prodBrandId,
      'prodBrandDescriptionId': prodBrandDescriptionId,
      'prodLinesId': prodLinesId,
      'prodLinesDescriptionId': prodLinesDescriptionId,
      'prodDecorationId': prodDecorationId,
      'prodDecorationDescriptionId': prodDecorationDescriptionId,
      'itemID': itemId,
      'name': name,
      'path': path,
      'unitVolumeML': unitVolumeML,
      'itemNetWeight': itemNetWeight,
      'prodFamilyId': prodFamilyId,
      'prodFamilyDescriptionId': prodFamilyDescriptionId,
      'grossWeight': prodGrossWeight,
      'taraWeight': prodTaraWeight,
      'grossDepth': prodGrossDepth,
      'grossWidth': prodGrossWidth,
      'grossHeight': prodGrossHeight,
      'nrOfItems': prodNrOfItems,
      'taxFiscalClassification': prodTaxFiscalClassification,

    };
  }

  // Método para criar um Product a partir de um mapa (útil para consulta no banco de dados)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      itemBarCode:                  map['itemBarCode'] ?? '',
      prodBrandId:                  map['prodBrandId'] ?? '',
      prodBrandDescriptionId:       map['prodBrandDescriptionId'] ?? '',
      prodLinesId:                  map['prodLinesId'] ?? '',
      prodLinesDescriptionId:       map['prodLinesDescriptionId'] ?? '',
      prodDecorationId:             map['prodDecorationId'] ?? '',
      prodDecorationDescriptionId:  map['prodDecorationDescriptionId'] ?? '',
      itemId:                       map['itemID'] ?? '',
      name:                         map['name'] ?? '',
      path:                         map['path'] ?? '',
      unitVolumeML:                 map['unitVolumeML']?.toDouble() ?? 0.0,
      itemNetWeight:                map['itemNetWeight']?.toDouble() ?? 0.0,
      prodFamilyId:                 map['prodFamilyId'] ?? '',
      prodFamilyDescriptionId:      map['prodFamilyDescriptionId'] ?? '',

      prodGrossWeight:              map['grossWeight'] ?? '',
      prodTaraWeight:               map['taraWeight'] ?? '',
      prodGrossDepth:               map['grossDepth'] ?? '',
      prodGrossWidth:               map['grossWidth'] ?? '',
      prodGrossHeight:              map['grossHeight'] ?? '',
      prodNrOfItems:                map['nrOfItems'] ?? '',
      prodTaxFiscalClassification:  map['taxFiscalClassification'] ?? '',

    );
  }

  void setPath(String newPath) {
    path = newPath;
  }

}
