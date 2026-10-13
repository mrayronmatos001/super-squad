import 'package:flutter/foundation.dart';

import '../../data/repository/squad_repository.dart';
import '../../domain/agent.dart';
import '../../domain/mission.dart';

/// Estado do esquadrão compartilhado por todas as telas.
///
/// As regras de negócio (limite de 15, sem duplicados) continuam no
/// [SquadRepository]. O notifier só chama o repositório, guarda a lista em
/// memória e avisa as telas (notifyListeners) sempre que ela muda. Assim,
/// recrutar no Contrato Diário atualiza a tela inicial automaticamente.
class SquadNotifier extends ChangeNotifier {
  final SquadRepository _repository;

  SquadNotifier(this._repository);

  List<Agent> _squad = [];
  bool _loaded = false;

  List<Agent> get squad => List.unmodifiable(_squad);
  bool get loaded => _loaded;
  int get count => _squad.length;
  bool get isFull => count >= SquadRepository.maxSize;
  bool get canStartMission => count >= SquadRepository.minForMission;

  bool contains(int agentId) => _squad.any((a) => a.id == agentId);

  Agent? byId(int agentId) {
    for (final agent in _squad) {
      if (agent.id == agentId) return agent;
    }
    return null;
  }

  Future<void> load() async {
    _squad = await _repository.getSquad();
    _loaded = true;
    notifyListeners();
  }

  /// Pode lançar [SquadFullException] ou [AlreadyInSquadException].
  Future<void> recruit(Agent agent) async {
    await _repository.recruit(agent);
    await load();
  }

  Future<void> dismiss(int agentId) async {
    await _repository.dismiss(agentId);
    await load();
  }

  Future<StatBoost?> boostRandomStat(Agent agent) async {
    final boost = await _repository.boostRandomStat(agent);
    if (boost != null) await load();
    return boost;
  }
}
