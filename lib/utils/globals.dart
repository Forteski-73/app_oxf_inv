library app_oxf_inv.globals;
import '../models/product_image.dart'; 
import 'package:path_provider/path_provider.dart';
import 'dart:io';

bool isOnline = false;
List<ProductImage> imagesData = [];
late Directory tempDir;

Future<void> initGlobals() async {
  tempDir = await getTemporaryDirectory();
}