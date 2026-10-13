import 'dart:math';

import 'package:dio/dio.dart';

import '../../domain/agent.dart';
import '../../domain/mission.dart';
import '../database/agent_dao.dart';
import '../network/api_client.dart';

/// Uma página de agentes, com informações para a paginação e para a tela.
class AgentPage {
  final List<Agent> agents;
  final bool hasMore;

  /// true quando a página veio do banco local por falta de internet.
  final bool fromCache;

  const AgentPage({required this.agents, required this.hasMore, required this.fromCache});
}

/// Repositório do catálogo geral de heróis.
///
/// Estratégia "offline-first" pedida no trabalho:
/// 1. tenta a API (dados sempre atualizados);
/// 2. salva o resultado no banco local (cache);
/// 3. se não houver internet (DioException), lê do banco local.
class AgentRepository {
  final ApiClient _apiClient;
  final AgentDao _agentDao;
  final Random _random = Random();

  /// Total de heróis na API, usado nos sorteios. Guardado após a 1ª consulta.
  int? _totalCount;

  AgentRepository({required ApiClient apiClient, required AgentDao agentDao})
      : _apiClient = apiClient,
        _agentDao = agentDao;

  Future<AgentPage> getAgents({required int page, int perPage = 10}) async {
    try {
      final result = await _apiClient.getHeroes(page: page, perPage: perPage);
      await _agentDao.upsertAll(result.data);
      _totalCount = result.items;
      return AgentPage(
        agents: result.data,
        hasMore: result.next != null && result.data.isNotEmpty,
        fromCache: false,
      );
    } on DioException {
      final cached = await _agentDao.getPage(limit: perPage, offset: (page - 1) * perPage);
      // Sem internet e sem nada salvo: deixa o erro chegar à tela.
      if (cached.isEmpty && page == 1) rethrow;
      return AgentPage(
        agents: cached,
        hasMore: cached.length == perPage,
        fromCache: true,
      );
    }
  }

  /// Baixa o catálogo completo e salva no banco local, para que o app
  /// funcione por completo sem internet depois da primeira carga.
  /// Chamado ao abrir o app, em segundo plano (sem await).
  Future<void> syncAll() async {
    try {
      final agents = await _apiClient.getAllHeroes();
      await _agentDao.upsertAll(agents);
      _totalCount = agents.length;
    } catch (_) {
      // Sem conexão (ou servidor fora do ar): o app segue com o que já
      // está salvo e tenta de novo na próxima vez que for aberto.
    }
  }

  /// Detalhes de um herói: API primeiro, cache local se estiver offline.
  Future<Agent> getAgentById(int id) async {
    try {
      final agent = await _apiClient.getHero(id);
      await _agentDao.upsertAll([agent]);
      return agent;
    } on DioException {
      final cached = await _agentDao.getById(id);
      if (cached != null) return cached;
      throw const NoDataException('Sem conexão e este agente ainda não está salvo no aparelho.');
    }
  }

  /// Sorteia um herói do catálogo, ignorando os ids em [exclude]
  /// (por exemplo, os membros do esquadrão).
  ///
  /// Online: sorteia uma POSIÇÃO de 1 até o total e pede essa "página" com
  /// 1 item (?_page=posição&_per_page=1). Assim o sorteio funciona mesmo que
  /// os ids da API tenham buracos (não são 1, 2, 3... seguidos).
  /// Offline: sorteia entre os heróis já salvos no banco local.
  Future<Agent> getRandomAgent({Set<int> exclude = const {}}) async {
    try {
      final total = _totalCount ??= (await _apiClient.getHeroes(page: 1, perPage: 1)).items;
      if (total > 0) {
        for (var attempt = 0; attempt < 20; attempt++) {
          final position = _random.nextInt(total) + 1;
          final result = await _apiClient.getHeroes(page: position, perPage: 1);
          if (result.data.isEmpty) continue;
          final agent = result.data.first;
          await _agentDao.upsertAll([agent]);
          // Se sorteou alguém que deve ser ignorado, sorteia novamente.
          if (!exclude.contains(agent.id)) return agent;
        }
      }
    } on DioException {
      // Sem internet: segue para o sorteio no cache local.
    }

    final cached = await _agentDao.getRandom(exclude: exclude);
    if (cached != null) return cached;
    throw const NoDataException(
      'Sem conexão e sem agentes salvos. Abra o catálogo uma vez com internet.',
    );
  }
}
