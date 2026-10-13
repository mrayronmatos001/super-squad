import 'package:flutter/foundation.dart';

import '../../data/repository/daily_contract_repository.dart';
import '../../domain/agent.dart';
import '../../domain/mission.dart';
import 'squad_notifier.dart';

enum RecruitResult { success, squadFull, alreadyInSquad }

/// Estado da tela de Contrato Diário: o agente sorteado do dia,
/// o carregamento e o andamento do recrutamento.
class DailyContractNotifier extends ChangeNotifier {
  final DailyContractRepository _repository;
  final SquadNotifier _squad;

  DailyContractNotifier({
    required DailyContractRepository repository,
    required SquadNotifier squad,
  })  : _repository = repository,
        _squad = squad;

  Agent? _agent;
  bool _loading = true;
  bool _recruiting = false;
  String? _error;
  bool _disposed = false;

  Agent? get agent => _agent;
  bool get loading => _loading;
  bool get recruiting => _recruiting;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();
    try {
      _agent = await _repository.getTodayContract();
    } catch (e) {
      _error = e is NoDataException
          ? e.message
          : 'Não foi possível consultar o contrato de hoje. Verifique a conexão.';
    }
    _loading = false;
    _notify();
  }

  Future<RecruitResult> recruit() async {
    final agent = _agent;
    if (agent == null) return RecruitResult.alreadyInSquad;
    _recruiting = true;
    _notify();
    try {
      await _squad.recruit(agent);
      return RecruitResult.success;
    } on SquadFullException {
      return RecruitResult.squadFull;
    } on AlreadyInSquadException {
      return RecruitResult.alreadyInSquad;
    } finally {
      _recruiting = false;
      _notify();
    }
  }

  /// Evita avisar a tela depois que ela já foi fechada.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
