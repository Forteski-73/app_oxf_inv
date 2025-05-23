import 'package:http/http.dart' as http;
import '../utils/globals.dart' as globals;

Future<void> checkInternetConnection() async {
  try {
    final response = await http.get(
      Uri.parse('https://clients3.google.com/generate_204'),
    ).timeout(const Duration(seconds: 2)); // Mais rápido

    globals.isOnline = response.statusCode == 204;
  } catch (_) {
    globals.isOnline = false;
  }
}
