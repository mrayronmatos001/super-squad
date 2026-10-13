import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../domain/agent.dart';
import 'app_database.dart';

/// Acesso à tabela de membros do esquadrão.
///
/// Cada membro guarda a própria "carta" do herói. Assim, os bônus de +1
/// ganhos nas missões ficam salvos só no agente do jogador, sem alterar o
/// catálogo geral.
class SquadDao {
  final AppDatabase _appDatabase;

  SquadDao(this._appDatabase);

  Future<List<Agent>> getAll() async {
    final db = await _appDatabase.database;
    final rows = await db.query(AppDatabase.squadTable, orderBy: 'recruited_at ASC');
    return rows
        .map((row) => Agent.fromJson(jsonDecode(row['data'] as String) as Map<String, dynamic>))
        .toList();
  }

  Future<int> count() async {
    final db = await _appDatabase.database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM ${AppDatabase.squadTable}');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<bool> contains(int agentId) async {
    final db = await _appDatabase.database;
    final rows = await db.query(
      AppDatabase.squadTable,
      columns: ['agent_id'],
      where: 'agent_id = ?',
      whereArgs: [agentId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> insert(Agent agent) async {
    final db = await _appDatabase.database;
    await db.insert(AppDatabase.squadTable, {
      'agent_id': agent.id,
      'data': jsonEncode(agent.toJson()),
      'recruited_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> update(Agent agent) async {
    final db = await _appDatabase.database;
    await db.update(
      AppDatabase.squadTable,
      {'data': jsonEncode(agent.toJson())},
      where: 'agent_id = ?',
      whereArgs: [agent.id],
    );
  }

  Future<void> delete(int agentId) async {
    final db = await _appDatabase.database;
    await db.delete(AppDatabase.squadTable, where: 'agent_id = ?', whereArgs: [agentId]);
  }
}
