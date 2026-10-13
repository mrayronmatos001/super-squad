import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repository/agent_repository.dart';
import '../../domain/agent.dart';
import '../widgets/agent_widgets.dart';
import '../widgets/common.dart';

class AgentDetailsPage extends StatefulWidget {
  final Agent agent;

  const AgentDetailsPage({super.key, required this.agent});

  @override
  State<AgentDetailsPage> createState() => _AgentDetailsPageState();
}

class _AgentDetailsPageState extends State<AgentDetailsPage> {
  /// Os dados são lidos preferencialmente da API; sem internet, o
  /// repositório devolve a versão salva no banco local. A requisição é
  /// criada uma única vez, no initState, e o FutureBuilder exibe o resultado.
  late final Future<Agent> _agentFuture;

  @override
  void initState() {
    super.initState();
    _agentFuture = context
        .read<AgentRepository>()
        .getAgentById(widget.agent.id)
        // Se falhar de vez, mantém os dados recebidos da lista.
        .catchError((Object _) => widget.agent);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Agent>(
      future: _agentFuture,
      // Enquanto a API responde, já mostra os dados que vieram da lista.
      initialData: widget.agent,
      builder: (context, snapshot) {
        final agent = snapshot.data ?? widget.agent;
        return Scaffold(
          body: LayoutBuilder(builder: (context, constraints) {
            if (constraints.maxWidth >= 900) return _buildWide(context, agent);
            return _buildNarrow(context, agent);
          }),
        );
      },
    );
  }

  /// Celular: imagem grande no topo que encolhe ao rolar.
  Widget _buildNarrow(BuildContext context, Agent agent) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 460,
          backgroundColor: AppColors.ink,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(agent.name, style: Theme.of(context).textTheme.titleLarge),
            background: Stack(
              fit: StackFit.expand,
              children: [
                AgentImage(url: agent.portraitUrl),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.transparent, AppColors.ink],
                      stops: [0, 0.55, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          sliver: SliverToBoxAdapter(child: _DetailsContent(agent: agent)),
        ),
      ],
    );
  }

  /// Tablet ou paisagem: imagem fixa à esquerda e ficha rolável à direita.
  Widget _buildWide(BuildContext context, Agent agent) {
    return SafeArea(
      child: Row(
        children: [
          SizedBox(
            width: 400,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: AgentImage(
                      url: agent.portraitUrl,
                      width: double.infinity,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(agent.name, style: Theme.of(context).textTheme.headlineMedium),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 32, 24, 32),
              children: [_DetailsContent(agent: agent)],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsContent extends StatelessWidget {
  final Agent agent;

  const _DetailsContent({required this.agent});

  @override
  Widget build(BuildContext context) {
    final bio = agent.biography;
    return ContentWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(label: translateAlignment(bio.alignment), color: alignmentColor(bio.alignment)),
              _Tag(label: displayValue(bio.publisher), color: AppColors.signal),
              _Tag(
                label: '${agent.powerStats.topStat.role} · ${agent.powerStats.topStat.label}',
                color: agent.powerStats.topStat.color,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Atributos', style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      Text('Média ${agent.powerStats.rating}',
                          style: const TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PowerStatBars(stats: agent.powerStats),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          AgentInfoSections(agent: agent),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}
