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
  final String prodFamilyDescription;

  // Construtor para inicializar todos os campos do produto
  Product({
    this.itemBarCode = "",
    this.prodBrandId = "",
    this.prodBrandDescriptionId = "",
    this.prodLinesId = "",
    this.prodLinesDescriptionId = "",
    this.prodDecorationId = "",
    this.prodDecorationDescriptionId = "",
    this.itemId = "",
    this.name = "",
    this.path = "",
    this.unitVolumeML = 0.0,
    this.itemNetWeight = 0.0,
    this.prodFamilyId = "",
    this.prodFamilyDescription = "",
  });

  // Método para converter um objeto Product em um mapa para inserção no banco de dados
  Map<String, dynamic> toMap() {
    return {
      'ItemBarCode': itemBarCode,
      'ProdBrandId': prodBrandId,
      'ProdBrandDescriptionId': prodBrandDescriptionId,
      'ProdLinesId': prodLinesId,
      'ProdLinesDescriptionId': prodLinesDescriptionId,
      'ProdDecorationId': prodDecorationId,
      'ProdDecorationDescriptionId': prodDecorationDescriptionId,
      'ItemID': itemId,
      'Name': name,
      'path': path,
      'UnitVolumeML': unitVolumeML,
      'ItemNetWeight': itemNetWeight,
      'ProdFamilyId': prodFamilyId,
      'ProdFamilyDescription': prodFamilyDescription,
    };
  }

  // Método para criar um Product a partir de um mapa (útil para consulta no banco de dados)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      itemBarCode: map['ItemBarCode'] ?? '',
      prodBrandId: map['ProdBrandId'] ?? '',
      prodBrandDescriptionId: map['ProdBrandDescriptionId'] ?? '',
      prodLinesId: map['ProdLinesId'] ?? '',
      prodLinesDescriptionId: map['ProdLinesDescriptionId'] ?? '',
      prodDecorationId: map['ProdDecorationId'] ?? '',
      prodDecorationDescriptionId: map['ProdDecorationDescriptionId'] ?? '',
      itemId: map['ItemID'] ?? '',
      name: map['Name'] ?? '',
      path: map['path'] ?? '',
      unitVolumeML: map['UnitVolumeML']?.toDouble() ?? 0.0,
      itemNetWeight: map['ItemNetWeight']?.toDouble() ?? 0.0,
      prodFamilyId: map['ProdFamilyId'] ?? '',
      prodFamilyDescription: map['ProdFamilyDescription'] ?? '',
    );
  }

  void setPath(String newPath) {
    path = newPath;
  }

}
