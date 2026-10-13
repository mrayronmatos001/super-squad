import '../../domain/agent.dart';
import '../../domain/mission.dart';
import '../preferences/daily_contract_store.dart';
import 'agent_repository.dart';
import 'squad_repository.dart';

/// Regra do contrato diário: um único sorteio por dia.
class DailyContractRepository {
  final DailyContractStore _store;
  final AgentRepository _agentRepository;
  final SquadRepository _squadRepository;

  DailyContractRepository({
    required DailyContractStore store,
    required AgentRepository agentRepository,
    required SquadRepository squadRepository,
  })  : _store = store,
        _agentRepository = agentRepository,
        _squadRepository = squadRepository;

  Future<Agent> getTodayContract() async {
    final today = todayKey();

    // 1. Já houve sorteio hoje? Então devolve o MESMO herói.
    final savedId = await _store.getAgentIdFor(today);
    if (savedId != null) {
      try {
        return await _agentRepository.getAgentById(savedId);
      } on NoDataException {
        // Caso raro: o herói salvo não está acessível. Sorteia outro abaixo.
      }
    }

    // 2. Primeiro acesso do dia: sorteia um herói que ainda NÃO está no
    //    esquadrão (só faz sentido oferecer quem está disponível).
    final squadIds = (await _squadRepository.getSquad()).map((a) => a.id).toSet();
    final agent = await _agentRepository.getRandomAgent(exclude: squadIds);

    // 3. Grava a data e o id para não sortear de novo até amanhã.
    await _store.save(day: today, agentId: agent.id);
    return agent;
  }
}
