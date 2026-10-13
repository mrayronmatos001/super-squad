import 'dart:math';

import '../../domain/agent.dart';
import '../../domain/mission.dart';
import '../../domain/stat_type.dart';
import '../database/squad_dao.dart';

/// Regras de negócio do esquadrão.
class SquadRepository {
  /// O esquadrão suporta no máximo 15 agentes.
  static const maxSize = 15;

  /// Mínimo de agentes para iniciar uma missão.
  static const minForMission = 5;

  final SquadDao _squadDao;
  final Random _random = Random();

  SquadRepository({required SquadDao squadDao}) : _squadDao = squadDao;

  Future<List<Agent>> getSquad() => _squadDao.getAll();

  Future<int> count() => _squadDao.count();

  Future<bool> contains(int agentId) => _squadDao.contains(agentId);

  /// Adiciona o agente à tabela do esquadrão, respeitando as regras:
  /// sem duplicados e no máximo [maxSize] agentes.
  Future<void> recruit(Agent agent) async {
    if (await _squadDao.contains(agent.id)) throw const AlreadyInSquadException();
    if (await _squadDao.count() >= maxSize) throw const SquadFullException();
    await _squadDao.insert(agent);
  }

  /// Remove o agente do banco local, liberando uma vaga.
  Future<void> dismiss(int agentId) => _squadDao.delete(agentId);

  /// Bônus da missão cumprida: +1 em um atributo aleatório do agente.
  /// Atributos já em 100 (o máximo da escala) ficam de fora do sorteio.
  /// Devolve null se todos os atributos já estiverem em 100.
  Future<StatBoost?> boostRandomStat(Agent agent) async {
    final candidates =
        StatType.values.where((stat) => agent.powerStats.valueOf(stat) < 100).toList();
    if (candidates.isEmpty) return null;

    final stat = candidates[_random.nextInt(candidates.length)];
    final boosted = agent.copyWith(
      powerStats: agent.powerStats.withValue(stat, agent.powerStats.valueOf(stat) + 1),
    );
    await _squadDao.update(boosted);
    return StatBoost(agent: boosted, stat: stat);
  }
}
