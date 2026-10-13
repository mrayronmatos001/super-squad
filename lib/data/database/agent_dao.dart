import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/agent.dart';
import 'app_database.dart';

/// Acesso à tabela de cache do catálogo (heróis vindos da API).
class AgentDao {
  final AppDatabase _appDatabase;

  AgentDao(this._appDatabase);

  /// Salva (ou atualiza) heróis no cache. O "replace" evita duplicados:
  /// se o id já existir, a linha é substituída pela versão mais nova.
  Future<void> upsertAll(List<Agent> agents) async {
    if (agents.isEmpty) return;
    final db = await _appDatabase.database;
    final batch = db.batch();
    for (final agent in agents) {
      batch.insert(
        AppDatabase.agentsTable,
        {'id': agent.id, 'name': agent.name, 'data': jsonEncode(agent.toJson())},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Página do cache, na mesma ordem da API (por id).
  /// offset = (página - 1) * limite  →  página 1 pula 0, página 2 pula 10...
  Future<List<Agent>> getPage({required int limit, required int offset}) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      AppDatabase.agentsTable,
      orderBy: 'id ASC',
      limit: limit,
      offset: offset,
    );
    return rows.map(_fromRow).toList();
  }

  Future<Agent?> getById(int id) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      AppDatabase.agentsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  /// Sorteia um herói do cache, ignorando os ids em [exclude].
  /// Usado no modo offline (contrato diário e inimigos da missão).
  Future<Agent?> getRandom({Set<int> exclude = const {}}) async {
    final db = await _appDatabase.database;
    final placeholders = List.filled(exclude.length, '?').join(',');
    final rows = await db.query(
      AppDatabase.agentsTable,
      where: exclude.isEmpty ? null : 'id NOT IN ($placeholders)',
      whereArgs: exclude.isEmpty ? null : exclude.toList(),
      orderBy: 'RANDOM()',
      limit: 1,
    );
    return rows.isEmpty ? null : _fromRow(rows.first);
  }

  Agent _fromRow(Map<String, Object?> row) =>
      Agent.fromJson(jsonDecode(row['data'] as String) as Map<String, dynamic>);
}
