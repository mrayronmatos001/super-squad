import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/repository/agent_repository.dart';
import '../../domain/agent.dart';
import '../../domain/mission.dart';
import '../../domain/stat_type.dart';
import 'squad_notifier.dart';

/// Etapas da missão. As etapas "carregando" e "bloqueada" (menos de 5
/// agentes) vêm do [SquadNotifier], por isso não aparecem aqui.
enum MissionStage { briefing, generating, ready, round, finished, error }

/// Resumo do fim da missão, usado no diálogo e no relatório.
class MissionResult {
  final int total;
  final int wins;
  final int losses;
  final int draws;
  final Agent? luckyAgent;
  final StatBoost? boost;

  const MissionResult({
    required this.total,
    required this.wins,
    required this.losses,
    required this.draws,
    this.luckyAgent,
    this.boost,
  });

  /// Missão cumprida: venceu mais da metade dos rounds.
  bool get success => wins > total / 2;

  /// Perdeu a maioria dos rounds (diálogo de erro em vez de aviso).
  bool get majorityLost => losses > total / 2;
}

class MissionNotifier extends ChangeNotifier {
  final AgentRepository _agentRepository;
  final SquadNotifier _squad;
  final Random _random = Random();

  MissionNotifier({required AgentRepository agentRepository, required SquadNotifier squad})
      : _agentRepository = agentRepository,
        _squad = squad;

  MissionStage _stage = MissionStage.briefing;
  List<Agent> _team = [];
  List<MissionRound> _rounds = [];
  int _current = 0;
  final Set<int> _usedAgentIds = {};
  int? _selectedId;
  bool _showingResult = false;
  String? _error;
  MissionResult? _result;
  bool _disposed = false;

  MissionStage get stage => _stage;

  /// Esquadrão no momento em que a missão começou.
  List<Agent> get team => List.unmodifiable(_team);
  List<MissionRound> get rounds => List.unmodifiable(_rounds);
  int get currentIndex => _current;
  MissionRound get currentRound => _rounds[_current];
  Set<int> get usedAgentIds => Set.unmodifiable(_usedAgentIds);
  int? get selectedId => _selectedId;
  bool get showingResult => _showingResult;
  String? get error => _error;
  MissionResult? get result => _result;

  int count(RoundOutcome outcome) => _rounds.where((r) => r.outcome == outcome).length;

  /// Sorteia o Desafio de Crise: de 3 a 5 rounds, cada um com um atributo
  /// e um inimigo do catálogo que NÃO esteja no esquadrão do jogador.
  Future<void> generateChallenge() async {
    _team = _squad.squad;
    _stage = MissionStage.generating;
    _error = null;
    _notify();
    try {
      final roundsCount = 3 + _random.nextInt(3); // 3, 4 ou 5
      final exclude = _team.map((a) => a.id).toSet();
      final rounds = <MissionRound>[];
      for (var i = 0; i < roundsCount; i++) {
        final stat = StatType.values[_random.nextInt(StatType.values.length)];
        final enemy = await _agentRepository.getRandomAgent(exclude: exclude);
        exclude.add(enemy.id); // evita repetir o mesmo inimigo na missão
        rounds.add(MissionRound(number: i + 1, stat: stat, enemy: enemy));
      }
      _rounds = rounds;
      _current = 0;
      _usedAgentIds.clear();
      _selectedId = null;
      _showingResult = false;
      _result = null;
      _stage = MissionStage.ready;
    } catch (e) {
      _error = e is NoDataException
          ? e.message
          : 'Não foi possível sortear os inimigos. Verifique a conexão.';
      _stage = MissionStage.error;
    }
    _notify();
  }

  void start() {
    _stage = MissionStage.round;
    _notify();
  }

  /// Cada agente só pode atuar em um round por missão.
  void select(int agentId) {
    if (_showingResult || _usedAgentIds.contains(agentId)) return;
    _selectedId = agentId;
    _notify();
  }

  /// Compara o atributo exigido entre o herói e o inimigo, mostra o
  /// resultado e avança sozinho para o próximo round.
  /// Devolve o [MissionResult] quando a missão termina; senão, null.
  Future<MissionResult?> confirmAgent() async {
    final id = _selectedId;
    if (id == null || _showingResult) return null;

    final hero = _team.firstWhere((a) => a.id == id);
    currentRound.resolve(hero);
    _usedAgentIds.add(id);
    _showingResult = true;
    _notify();

    await Future.delayed(const Duration(milliseconds: 2600));
    if (_disposed) return null;

    if (_current < _rounds.length - 1) {
      _current++;
      _selectedId = null;
      _showingResult = false;
      _notify();
      return null;
    }

    _showingResult = false;
    _result = await _buildResult();
    _stage = MissionStage.finished;
    _notify();
    return _result;
  }

  Future<MissionResult> _buildResult() async {
    final total = _rounds.length;
    final wins = count(RoundOutcome.victory);
    Agent? lucky;
    StatBoost? boost;

    if (wins > total / 2) {
      // Sorteia um dos heróis que venceram um round: +1 em um atributo.
      final winners = _rounds
          .where((r) => r.outcome == RoundOutcome.victory)
          .map((r) => r.hero!)
          .toList();
      lucky = winners[_random.nextInt(winners.length)];
      boost = await _squad.boostRandomStat(lucky);
      if (boost != null) {
        final boosted = boost.agent;
        _team = [for (final a in _team) a.id == boosted.id ? boosted : a];
      }
    }

    return MissionResult(
      total: total,
      wins: wins,
      losses: count(RoundOutcome.defeat),
      draws: count(RoundOutcome.draw),
      luckyAgent: lucky,
      boost: boost,
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
