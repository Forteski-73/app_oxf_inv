import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBSettings {
  static const _databaseName = "settings.db";
  static const _databaseVersion = 1;

  // Tabela "settings_profile"
  static const tableSettingsProfile = 'settings_profile';
  static const columnProfile = 'profile';

  // Tabela "settings"
  static const tableSettings = 'settings';
  static const columnId = '_id';
  static const sequence = 'sequence';
  static const columnNome = 'nome';
  static const columnExibir = 'exibir';
  static const columnObrigatorio = 'obrigatorio';
  static const columnProfileId = 'profile_id'; // FK para settings_profile

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
      CREATE TABLE $tableSettingsProfile (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnProfile TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSettings (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $sequence INTEGER NOT NULL,
        $columnNome TEXT NOT NULL,
        $columnExibir INTEGER NOT NULL,
        $columnObrigatorio INTEGER NOT NULL,
        $columnProfileId INTEGER NOT NULL,
        FOREIGN KEY ($columnProfileId) REFERENCES $tableSettingsProfile($columnId) ON DELETE CASCADE
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

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $tableSettingsProfile (
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnProfile TEXT NOT NULL
        )
      ''');

      await db.execute('''
        ALTER TABLE $tableSettings ADD COLUMN $columnProfileId INTEGER NOT NULL DEFAULT 1;
      ''');

      await db.execute('''
        CREATE INDEX idx_settings_profile ON $tableSettings($columnProfileId);
      ''');
    }
  }

  Future<void> resetDatabase() async {
    Database db = await instance.database;

    // Excluir as tabelas existentes
    await db.execute('DROP TABLE IF EXISTS $tableMask');
    await db.execute('DROP TABLE IF EXISTS $tableFieldDataTypeSetting');
    await db.execute('DROP TABLE IF EXISTS $tableSettings');
    await db.execute('DROP TABLE IF EXISTS $tableSettingsProfile');

    // Chamar o método _onCreate para recriar as tabelas
    await _onCreate(db, _databaseVersion);

    // chamar em qualquer lugar para resetar o banco
    //await DBSettings.instance.resetDatabase();
  }

  Future<int> insertSettingsProfile(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableSettingsProfile, row);
  }


  Future<List<Map<String, dynamic>>> queryAllSettingsProfiles() async {
    
    //await DBSettings.instance.resetDatabase();

    Database db = await instance.database;
    return await db.query(tableSettingsProfile);
  }

  Future<int> updateSettingsProfile(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.update(tableSettingsProfile, row, where: '$columnId = ?', whereArgs: [row[columnId]]);
  }

  Future<int> deleteSettingsProfile(int id) async {
    Database db = await instance.database;
    return await db.delete(tableSettingsProfile, where: '$columnId = ?', whereArgs: [id]);
  }

  // Métodos CRUD para a tabela "settings"

  Future<int> insertSettings(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableSettings, row);
  }

  Future<int> updateSettings(int profileId, Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(
      tableSettings, 
      row, 
      where: '$columnId = ? AND $profileId = ?',
      whereArgs: [id, profileId],
    );
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
    int id = row[DBSettings.columnSettingId];

    // Verifica se o registro existe antes de atualizar
    List<Map<String, dynamic>> existingRows = await db.query(
      DBSettings.tableFieldDataTypeSetting,
      where: '${DBSettings.columnSettingId} = ?',
      whereArgs: [id],
    );

    if (existingRows.isEmpty) {
      // Se o registro não existir, insere-o antes de atualizar
      await insertFieldDataTypeSetting(row);
    } else {
      // Caso contrário, atualiza o registro existente
      await db.update(
        DBSettings.tableFieldDataTypeSetting,
        row,
        where: '${DBSettings.columnSettingId} = ?',
        whereArgs: [id],
      );
    }

    return 1; // Retorna 1 para indicar sucesso
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

    result = await db.query(
      tableFieldDataTypeSetting,
      where: '$columnSettingId = ?',
      whereArgs: [settingId],
    );

    return result;
  }

  // Método para consultar máscaras associadas a um settingId
  Future<List<Map<String, dynamic>>> queryMasksBySettingId(int settingId) async {
    Database db = await instance.database;
    final result = await db.rawQuery('''
      SELECT 
        m.$columnId AS id,
        m.$columnMask AS mask,
        m.$columnFieldDataTypeSettingId AS field_data_type_setting_id
      FROM $tableMask AS m
      INNER JOIN $tableFieldDataTypeSetting AS f
      ON m.$columnFieldDataTypeSettingId = f.$columnId
      WHERE f.$columnSettingId = ?
    ''', [settingId]);

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

  Future<List<Map<String, dynamic>>> querySettingAllRows(int profileId) async {
    final db = await database;
    return await db!.query(
      DBSettings.tableSettings,
      where: '${DBSettings.columnProfileId} = ?', // Adicione a coluna profileId na sua tabela
      whereArgs: [profileId],
    );
  }

  /*// Delete
  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(tableSettings, where: '$columnId = ?', whereArgs: [id]);
  }*/
}
