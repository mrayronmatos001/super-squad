import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repository/agent_repository.dart';
import '../../domain/agent.dart';
import '../widgets/agent_widgets.dart';
import '../widgets/common.dart';
import 'agent_details_page.dart';

class AgentsPage extends StatefulWidget {
  const AgentsPage({super.key});

  @override
  State<AgentsPage> createState() => _AgentsPageState();
}

class _AgentsPageState extends State<AgentsPage> {
  static const _pageSize = 10;

  late final AgentRepository _repository;
  late final PagingController<int, Agent> _pagingController;

  /// Se ainda existem páginas para buscar (vem do campo "next" da API).
  bool _hasMore = true;

  /// true quando a última página veio do banco local (sem internet).
  /// ValueNotifier: só o aviso de offline se redesenha quando ele muda.
  final ValueNotifier<bool> _offline = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _repository = Provider.of<AgentRepository>(context, listen: false);
    _pagingController = PagingController<int, Agent>(
      // null = não há mais páginas, e a paginação para.
      getNextPageKey: (state) => _hasMore ? state.nextIntPageKey : null,
      fetchPage: _fetchPage,
    );
  }

  Future<List<Agent>> _fetchPage(int pageKey) async {
    final page = await _repository.getAgents(page: pageKey, perPage: _pageSize);
    _hasMore = page.hasMore;
    _offline.value = page.fromCache;
    return page.agents;
  }

  Future<void> _refresh() async {
    _hasMore = true;
    _pagingController.refresh();
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _offline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agentes')),
      body: Column(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: _offline,
            builder: (context, offline, _) => AnimatedSize(
              duration: const Duration(milliseconds: 250),
              child: offline ? const _OfflineBanner() : const SizedBox(width: double.infinity),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: PagingListener(
                controller: _pagingController,
                builder: (context, state, fetchNextPage) => PagedListView<int, Agent>(
                  state: state,
                  fetchNextPage: fetchNextPage,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  builderDelegate: PagedChildBuilderDelegate<Agent>(
                    itemBuilder: (context, agent, index) => ContentWidth(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AgentCard(
                          agent: agent,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => AgentDetailsPage(agent: agent)),
                          ),
                        ),
                      ),
                    ),
                    firstPageProgressIndicatorBuilder: (_) =>
                        const LoadingView(message: 'Carregando agentes...'),
                    firstPageErrorIndicatorBuilder: (_) => MessageView(
                      icon: Icons.wifi_off,
                      title: 'Não foi possível carregar',
                      message: 'Sem conexão com a API e nenhum agente salvo no aparelho. '
                          'Verifique a internet e tente novamente.',
                      actionLabel: 'Tentar novamente',
                      onAction: fetchNextPage,
                    ),
                    newPageErrorIndicatorBuilder: (_) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextButton.icon(
                        onPressed: fetchNextPage,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Erro ao carregar mais. Tocar para tentar de novo'),
                      ),
                    ),
                    noItemsFoundIndicatorBuilder: (_) => const MessageView(
                      icon: Icons.search_off,
                      title: 'Nenhum agente encontrado',
                      message: 'A API não retornou heróis.',
                    ),
                    noMoreItemsIndicatorBuilder: (_) => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text('Fim do catálogo',
                            style: TextStyle(color: AppColors.textMuted)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.signal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.signal.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off, size: 18, color: AppColors.signal),
          SizedBox(width: 10),
          Expanded(
            child: Text('Sem conexão: exibindo agentes salvos no aparelho.',
                style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
