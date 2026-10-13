import 'agent.dart';
import 'stat_type.dart';

/// Resultado de um round da missão.
enum RoundOutcome {
  victory('Vitória'),
  defeat('Derrota'),
  draw('Empate');

  const RoundOutcome(this.label);
  final String label;
}

/// Um round do Desafio de Crise: o atributo exigido e o inimigo sorteado.
/// [hero] e [outcome] são preenchidos quando o jogador confirma o agente.
class MissionRound {
  final int number;
  final StatType stat;
  final Agent enemy;
  Agent? hero;
  RoundOutcome? outcome;

  MissionRound({required this.number, required this.stat, required this.enemy});

  int get heroValue => hero?.powerStats.valueOf(stat) ?? 0;
  int get enemyValue => enemy.powerStats.valueOf(stat);

  /// Compara o atributo exigido entre o herói e o inimigo.
  RoundOutcome resolve(Agent selectedHero) {
    hero = selectedHero;
    if (heroValue > enemyValue) {
      outcome = RoundOutcome.victory;
    } else if (heroValue < enemyValue) {
      outcome = RoundOutcome.defeat;
    } else {
      outcome = RoundOutcome.draw;
    }
    return outcome!;
  }
}

/// Resultado do bônus de +1 em um atributo após uma missão cumprida.
class StatBoost {
  final Agent agent;
  final StatType stat;

  const StatBoost({required this.agent, required this.stat});

  int get newValue => agent.powerStats.valueOf(stat);
}

// ---------------------------------------------------------------------------
// Exceções das regras de negócio
// ---------------------------------------------------------------------------
class SquadFullException implements Exception {
  const SquadFullException();
  @override
  String toString() => 'O esquadrão atingiu a capacidade máxima.';
}

class AlreadyInSquadException implements Exception {
  const AlreadyInSquadException();
  @override
  String toString() => 'Este agente já faz parte do esquadrão.';
}

/// Lançada quando não há internet e o dado também não está no cache local.
class NoDataException implements Exception {
  final String message;
  const NoDataException(this.message);
  @override
  String toString() => message;
}
