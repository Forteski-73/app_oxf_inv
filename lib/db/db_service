import 'package:mysql1/mysql1.dart';

class DBService {
  late MySqlConnection _conn;

  // Inicializa a conexão com o banco de dados
  Future<void> connect() async {
    final settings = ConnectionSettings(
      host: '193.203.175.198',
      port: 3306,
      user: 'u700242432_appprodutos',
      password: 'OxEstrutur@25',
      db: 'u700242432_appprodutos',
    );

    try {
      _conn = await MySqlConnection.connect(settings);
    } catch (e) {
      print('Erro ao conectar ao banco de dados: $e');
      rethrow;
    }
  }

  // Busca todos os registros da tabela "settings"
  Future<List<Map<String, dynamic>>> getAllSettings() async {
    try {
      final results = await _conn.query('SELECT * FROM settings');
      return results
          .map((row) => {
                '_id': row['_id'],
                'sequence': row['sequence'],
                'name': row['name'],
                'display': row['display'] == 1,
                'required': row['required'] == 1,
                'profile_id': row['profile_id'],
              })
          .toList();
    } catch (e) {
      print('Erro ao buscar settings: $e');
      return [];
    }
  }

  // Fecha a conexão
  Future<void> close() async {
    await _conn.close();
    print('Conexão encerrada.');
  }
}
