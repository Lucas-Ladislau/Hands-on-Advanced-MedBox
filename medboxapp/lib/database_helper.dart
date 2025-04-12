import 'package:medboxapp/main.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'medicina_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'remedios.db');

    return await openDatabase(
    path,
    version: 2, // Atualizado para forçar migração
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE remedios (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nome TEXT NOT NULL,
          horario TEXT NOT NULL,
          numero_compartimento INTEGER NOT NULL
        )
      ''');
    },
    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute('ALTER TABLE remedios ADD COLUMN numero_compartimento INTEGER NOT NULL DEFAULT 1');
      }
    },
  );
}

  // ✅ Listar todos os remédios
  Future<List<Remedio>> listarRemedios() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('remedios');
    return List.generate(maps.length, (i) => Remedio.fromMap(maps[i]));
  }

  // ✅ Atualizar um remédio existente
  Future<int> atualizarRemedio(Remedio remedio) async {
    final db = await database;
    return await db.update(
      'remedios',
      remedio.toMap(),
      where: 'id = ?',
      whereArgs: [remedio.id],
    );
  }

  Future<List<Remedio>> getRemedios() async {
  final db = await database;
  final List<Map<String, dynamic>> maps = await db.query('remedios');
  return List.generate(maps.length, (i) {
    return Remedio.fromMap(maps[i]);
  });
  }

  Future<void> deletarRemedio(int id) async {
    final db = await database;
    await db.delete('remedios', where: 'id = ?', whereArgs: [id]);
  }

  // ✅ Deletar todos os remédios (útil para testes)
  Future<void> deletarTudo() async {
    final db = await database;
    await db.delete('remedios');
  }
}