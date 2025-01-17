import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBSettings {
  static const _databaseName = "settings.db";
  static const _databaseVersion = 1;

  // Tabela "settings"
  static const tableSettings = 'settings';
  static const columnId = '_id';
  static const columnNome = 'nome';
  static const columnExibir = 'exibir';
  static const columnObrigatorio = 'obrigatorio';

  // Tabela "field_data_type_setting"
  static const tableFieldDataTypeSetting = 'field_data_type_setting';
  static const columnFieldName = 'field_name';
  static const columnFieldType = 'field_type';
  static const columnMinSize = 'min_size';
  static const columnMaxSize = 'max_size';
  static const columnSettingId = 'setting_id'; // FK para a tabela settings

  // Tabela "Mask"
  static const tableMask = 'mask';
  static const columnMask = 'mask';
  static const columnFieldDataTypeSettingId = 'field_data_type_setting_id'; // FK para field_data_type_setting

  // Instanciando o construtor DB
  DBSettings._privateConstructor();
  static final DBSettings instance = DBSettings._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    var databasesPath = await getDatabasesPath(); // Diretório do banco de dados
    String path = join(databasesPath, _databaseName);

    // Abrindo ou criando o banco de dados
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate);
  }

  // Create tables with relationship
  Future _onCreate(Database db, int version) async {
    // Criar tabela "settings"
    await db.execute('''
      CREATE TABLE $tableSettings (
        $columnId INTEGER PRIMARY KEY,
        $columnNome TEXT NOT NULL,
        $columnExibir INTEGER NOT NULL,
        $columnObrigatorio INTEGER NOT NULL
      )
    ''');

    // Criar tabela "field_data_type_setting" com FK para "settings"
    await db.execute('''
      CREATE TABLE $tableFieldDataTypeSetting (
        $columnId INTEGER PRIMARY KEY,
        $columnFieldName TEXT NOT NULL,
        $columnFieldType TEXT CHECK($columnFieldType IN ('Numérico', 'Alfanumérico')),
        $columnMinSize INTEGER CHECK($columnMinSize > 0),
        $columnMaxSize INTEGER CHECK($columnMaxSize >= $columnMinSize),
        $columnSettingId INTEGER NOT NULL,
        FOREIGN KEY ($columnSettingId) REFERENCES $tableSettings($columnId) ON DELETE CASCADE
      )
    ''');

    // Criar tabela "Mask"
    await db.execute('''
      CREATE TABLE $tableMask (
        $columnId INTEGER PRIMARY KEY,
        $columnMask TEXT,
        $columnFieldDataTypeSettingId INTEGER NOT NULL,
        FOREIGN KEY ($columnFieldDataTypeSettingId) REFERENCES $tableFieldDataTypeSetting($columnId) ON DELETE CASCADE
      )
    ''');
  }

  // Métodos CRUD para a tabela "settings"

  Future<int> insertSettings(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableSettings, row);
  }

  Future<int> updateSettings(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(tableSettings, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryAllSettings() async {
    Database db = await instance.database;
    return await db.query(tableSettings);
  }

  Future<int> deleteSettings(int id) async {
    Database db = await instance.database;
    return await db.delete(tableSettings, where: '$columnId = ?', whereArgs: [id]);
  }

  // Métodos CRUD para a tabela "field_data_type_setting"

  Future<int> insertFieldDataTypeSetting(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableFieldDataTypeSetting, row);
  }

  /*Future<int> updateFieldDataTypeSetting(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(tableFieldDataTypeSetting, row, where: '$columnId = ?', whereArgs: [id]);
  }*/

  Future<int> updateFieldDataTypeSetting(Map<String, dynamic> row) async {
  Database db = await instance.database;
  int id = row[DBSettings.columnId];
  return await db.update(DBSettings.tableFieldDataTypeSetting, row, where: '${DBSettings.columnId} = ?', whereArgs: [id]);
}

  Future<List<Map<String, dynamic>>> queryAllFieldDataTypeSettings() async {
    Database db = await instance.database;
    return await db.query(tableFieldDataTypeSetting);
  }

  Future<int> deleteFieldDataTypeSetting(int id) async {
    Database db = await instance.database;
    return await db.delete(tableFieldDataTypeSetting, where: '$columnId = ?', whereArgs: [id]);
  }

  // Método para consultar configurações com seus tipos de dados associados
  Future<List<Map<String, dynamic>>> querySettingsWithFieldDataTypes() async {
    Database db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        s.$columnId AS setting_id, 
        s.$columnNome AS setting_name, 
        f.$columnId AS field_id, 
        f.$columnFieldName AS field_name, 
        f.$columnFieldType AS field_type, 
        f.$columnMinSize AS min_size, 
        f.$columnMaxSize AS max_size
      FROM $tableSettings AS s
      LEFT JOIN $tableFieldDataTypeSetting AS f
      ON s.$columnId = f.$columnSettingId
    ''');
    return result;
  }

  // Métodos CRUD para a tabela "Mask"

  Future<int> insertMask(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableMask, row);
  }

  Future<int> updateMask(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(tableMask, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryAllMasks() async {
    Database db = await instance.database;
    return await db.query(tableMask);
  }

  Future<int> deleteMask(int id) async {
    Database db = await instance.database;
    return await db.delete(tableMask, where: '$columnId = ?', whereArgs: [id]);
  }

  // Método para consultar máscaras associadas aos tipos de dados
  Future<List<Map<String, dynamic>>> queryFieldDataTypeSettingsWithMasks() async {
    Database db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        f.$columnId AS field_id,
        f.$columnFieldName AS field_name,
        f.$columnFieldType AS field_type,
        m.$columnId AS mask_id,
        m.$columnMask AS mask
      FROM $tableFieldDataTypeSetting AS f
      LEFT JOIN $tableMask AS m
      ON f.$columnId = m.$columnFieldDataTypeSettingId
    ''');
    return result;
  }

  // Método para consultar os dados da tabela "field_data_type_setting" por setting_id
  Future<List<Map<String, dynamic>>> queryFieldDataTypeSettingsBySettingId(int settingId) async {
    Database db = await instance.database;
    List<Map<String, Object?>> result;

    // Primeiramente, consulta a tabela 'field_data_type_setting' para verificar se existe o registro com o setting_id
    result = await db.query(
      tableFieldDataTypeSetting,
      where: '$columnSettingId = ?',
      whereArgs: [settingId],
    );
    /*
    // Se o resultado não contiver dados, insere um novo registro na tabela 'field_data_type_setting'
    if (result.isEmpty) {
      // Consulta o nome (columnNome) na tabela settings com o settingId
      List<Map<String, dynamic>> settingsResult = await db.query(
        tableSettings,
        where: '$columnId = ?',
        whereArgs: [settingId],
      );

      // Verificar se o nome foi encontrado
      String? settingName = settingsResult.isNotEmpty ? settingsResult[0][columnNome] : 'null';

      // Preparando os dados para o novo registro
      Map<String, dynamic> newRow = {
        columnSettingId: settingId,  // Definindo o setting_id
        columnFieldName: settingName, // Agora, usamos o nome obtido da tabela 'settings'
        columnFieldType: null,        // Definindo como null, pois não temos dados para esse campo
        columnMinSize: null,          // Definindo como null, pois não temos dados para esse campo
        columnMaxSize: null,          // Definindo como null, pois não temos dados para esse campo
      };

      // Inserir um novo registro na tabela 'field_data_type_setting'
      await db.insert(tableFieldDataTypeSetting, newRow);

      // Após a inserção, consulta novamente para retornar o novo registro
      result = await db.query(
        tableFieldDataTypeSetting,
        where: '$columnSettingId = ?',
        whereArgs: [settingId],
      );
    }*/

    return result;
  }


  /*  // insert
  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableSettings, row);
  }

  // Update
  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(tableSettings, row, where: '$columnId = ?', whereArgs: [id]);
  }*/

  Future<List<Map<String, dynamic>>> querySettingAllRows() async {
    Database db = await instance.database;
    final result = await db.query(tableSettings);
    
    return List<Map<String, dynamic>>.from(result); // Converte o resultado para uma lista mutável
  }

  /*// Delete
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(tableSettings, where: '$columnId = ?', whereArgs: [id]);
  }*/
}
