import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Ponto único de acesso ao banco SQLite do app.
///
/// Duas tabelas:
/// - [agentsTable]: cache do catálogo da API (funcionamento offline);
/// - [squadTable]: agentes recrutados para o esquadrão (máximo de 15).
///
/// Nas duas, o herói é guardado como texto JSON na coluna "data". Assim o
/// cache tem TODOS os detalhes do herói (aparência, biografia etc.) e a tela
/// de detalhes funciona sem internet.
class AppDatabase {
  static const _databaseName = 'super_squad.db';
  static const _databaseVersion = 1;

  static const agentsTable = 'agents';
  static const squadTable = 'squad';

  Future<Database>? _database;

  /// Abre o banco na primeira chamada e reaproveita a conexão nas seguintes.
  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        final batch = db.batch();
        batch.execute('''
          CREATE TABLE $agentsTable(
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            data TEXT NOT NULL
          )
        ''');
        batch.execute('''
          CREATE TABLE $squadTable(
            agent_id INTEGER PRIMARY KEY,
            data TEXT NOT NULL,
            recruited_at INTEGER NOT NULL
          )
        ''');
        await batch.commit(noResult: true);
      },
    );
  }
}
