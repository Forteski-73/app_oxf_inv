import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBInventory {
  // Configuração do banco de dados
  static const _databaseName      = "inventory.db";
  static const _databaseVersion   = 1;
  static const tableInvent        = 'inventory';
  // Tabela Inventory
  static const tableInventory = 'inventory';
  static const columnId       = '_id';
  static const columnCode     = 'code';
  static const columnDate     = 'date';
  static const columnHour     = 'hour';
  static const columnName     = 'name';
  static const columnSector   = 'sector';
  static const columnStatus   = 'status';
  static const columnTotal    = 'total';

  // Tabela Status Options
  static const tableStatusOptions = 'status_options';

  // Tabela Inventory Record
  static const tableInventoryRecord       = 'inventory_record';
  static const columnInventoryId          = 'inventory_id';
  static const columnUnitizer             = 'unitizer';
  static const columnPosition             = 'position';
  static const columnDeposit              = 'deposit';
  static const columnBlockA               = 'block_a';
  static const columnBlockB               = 'block_b';
  static const columnLot                  = 'lot';
  static const columnFloor                = 'floor';
  static const columnBarcode              = 'barcode';
  static const columnStandardStackQtd     = 'standard_stack_qtd';
  static const columnNumberCompleteStacks = 'number_complete_stacks';
  static const columnNumberLooseItems     = 'number_loose_items';
  static const columnSubTotal             = 'total';

  // Singleton
  DBInventory._privateConstructor();
  static final DBInventory instance = DBInventory._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // Criação da tabela Status Options
    await db.execute('''
      CREATE TABLE $tableStatusOptions (
        $columnStatus TEXT PRIMARY KEY
      )
    ''');

    // Inserção de valores padrões na tabela Status Options
    await db.insert(tableStatusOptions, {'status': 'NÃO INICIADO'});
    await db.insert(tableStatusOptions, {'status': 'EM ANDAMENTO'});
    await db.insert(tableStatusOptions, {'status': 'CONCLUÍDO'});

    // Criação da tabela Inventory
    await db.execute('''
      CREATE TABLE $tableInventory (
        $columnId     INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnCode   TEXT NOT NULL,
        $columnDate   TEXT NOT NULL,
        $columnHour   TEXT NOT NULL,
        $columnName   TEXT NOT NULL,
        $columnSector TEXT NOT NULL,
        $columnStatus TEXT NOT NULL,
        $columnTotal  INTEGER,
        FOREIGN KEY ($columnStatus) REFERENCES $tableStatusOptions($columnStatus)
      )
    ''');

    // Criação da tabela Inventory Record
    await db.execute('''
      CREATE TABLE $tableInventoryRecord (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnInventoryId          INTEGER NOT NULL,
        $columnUnitizer             TEXT,
        $columnPosition             TEXT,
        $columnDeposit              TEXT,
        $columnBlockA               TEXT,
        $columnBlockB               TEXT,
        $columnLot                  TEXT,
        $columnFloor                INTEGER,
        $columnBarcode              TEXT,
        $columnStandardStackQtd     INTEGER,
        $columnNumberCompleteStacks INTEGER,
        $columnNumberLooseItems     INTEGER,
        $columnSubTotal             INTEGER,
        FOREIGN KEY ($columnInventoryId) REFERENCES $tableInventory($columnId) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertInventory(Map<String, dynamic> row) async {
    //Database db = await instance.database;
    //return await db.insert(tableInventory, row);
    Database db = await instance.database;
    String code = row[columnCode];

    int id = await db.insert(tableInventory, row);

    // Concatenar o "_id" ao "code" após a inserção
    if (id > 0) {
      // Atualiza o código concatenando o "_id"
      String newCode = "$code-$id";
      id = await db.update(
        tableInventory,
        {columnCode: newCode},
        where: '$columnId = ?',
        whereArgs: [id],
      );
    }
    return id;
  }
  
  Future<int> updateInventory(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(tableInventory, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<int> update(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(tableInvent, row, where: '$columnId = ?', whereArgs: [id]);
  }

  /*Future<List<Map<String, dynamic>>> queryAllInventory() async {
    Database db = await instance.database;
    return await db.query(tableInventory);
  }*/

Future<List<Map<String, dynamic>>> queryAllInventory() async {
  Database db = await instance.database;
  return await db.query(
    tableInventory,
    orderBy: '_id DESC',
  );
}

  Future<Map<String, dynamic>?> queryFirstInventoryByStatus() async {
  Database db = await instance.database;

  List<Map<String, dynamic>> results = await db.query(
    tableInventory,
    where: '${DBInventory.columnStatus} = ? OR ${DBInventory.columnStatus} = ?',
    whereArgs: ['NÃO INICIADO', 'EM ANDAMENTO'],
    orderBy: '${DBInventory.columnId} ASC',
    limit: 1, // Apenas o primeiro
  );

    // Retorna o primeiro registro, ou null caso não haja nenhum registro
    if (results.isNotEmpty) {
    // Cria uma cópia mutável do primeiro item da lista
    return Map<String, dynamic>.from(results.first);
    }
    else {
      return null;
    }
}

  Future<int> deleteInventory(int id) async {
    Database db = await instance.database;
    return await db.delete(tableInventory, where: '$columnId = ?', whereArgs: [id]);
  }

  // Métodos CRUD para Inventory Record
  /*Future<int> insertInventoryRecord(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(tableInventoryRecord, row);
  }*/

  Future<int> insertInventoryRecord(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int st = 0;
    
    int inventoryRecordId = await db.insert(tableInventoryRecord, row);
    if(inventoryRecordId > 0)
    {
      int inventoryId = row[columnInventoryId];

      List<Map<String, dynamic>> inventoryResults = await db.query( // para o total já somado no Inventário
        tableInventory,
        columns: [columnTotal],
        where: '$columnId = ?',
        whereArgs: [inventoryId],
      );

      if (inventoryResults.isNotEmpty) {
        int inventoryTotal = inventoryResults.first[columnTotal] ?? 0;
        int inventoryRecordTotal = row[columnSubTotal] ?? 0;

        int newTotal = inventoryTotal + inventoryRecordTotal; //recalcula o total

        st = await db.update(
          tableInventory,
          {columnTotal: newTotal},
          where: '$columnId = ?',
          whereArgs: [inventoryId],
        );
      }
    }

    return st;
  }

  Future<int> updateInventoryRecord(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(tableInventoryRecord, row, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> queryAllInventoryRecords() async {
    Database db = await instance.database;
    return await db.query(tableInventoryRecord);
  }

  /*Future<int> deleteInventoryRecord(int id) async {
    Database db = await instance.database;
    return await db.delete(tableInventoryRecord, where: '$columnId = ?', whereArgs: [id]);
  }*/
  // deleta a contagem e subtrai do Total
  Future<int> deleteInventoryRecord(int id) async {
    Database db = await instance.database;
    int st = 0;
    // Busca o registro a ser deletado
    List<Map<String, dynamic>> recordResults = await db.query(
      tableInventoryRecord,
      columns: [columnInventoryId, columnSubTotal],
      where: '$columnId = ?',
      whereArgs: [id],
    );

    if (recordResults.isNotEmpty) {
      // Pega o sub-total
      int inventoryId = recordResults.first[columnInventoryId];
      int recordTotal = recordResults.first[columnSubTotal] ?? 0;

      // Busca o registro pai na Inventory
      List<Map<String, dynamic>> inventoryResults = await db.query(
        tableInventory,
        columns: [columnTotal],
        where: '$columnId = ?',
        whereArgs: [inventoryId],
      );

      if (inventoryResults.isNotEmpty) {
        // subtrai o valor do total na Inventory
        int inventoryTotal = inventoryResults.first[columnTotal] ?? 0;
        int newTotal = inventoryTotal - recordTotal;

        await db.update(
          tableInventory,
          {columnTotal: newTotal},
          where: '$columnId = ?',
          whereArgs: [inventoryId],
        );
      }
      // Deleta o registro na tabela inventory_record
      st = await db.delete(tableInventoryRecord, where: '$columnId = ?', whereArgs: [id]);
    }
    return st;
  }

}
