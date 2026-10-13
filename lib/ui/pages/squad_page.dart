import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repository/squad_repository.dart';
import '../state/squad_notifier.dart';
import '../../domain/agent.dart';
import '../widgets/common.dart';
import 'daily_contract_page.dart';
import 'my_agent_details_page.dart';

class SquadPage extends StatelessWidget {
  const SquadPage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    // Ao recrutar ou dispensar em outra tela, o SquadNotifier avisa
    // e esta lista se atualiza sozinha.
    final notifier = Provider.of<SquadNotifier>(context);
    final squad = notifier.squad;

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Esquadrão')),
      body: AppBackdrop(
        child: !notifier.loaded
            ? const LoadingView(message: 'Reunindo o esquadrão...')
            : squad.isEmpty
                ? MessageView(
                    icon: Icons.groups,
                    title: 'Esquadrão vazio',
                    message: 'Recrute seu primeiro agente no Contrato Diário. '
                        'Um novo herói fica disponível a cada dia.',
                    actionLabel: 'Ir para o Contrato Diário',
                    onAction: () => _open(context, const DailyContractPage()),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      ContentWidth(child: _CapacityHeader(count: squad.length)),
                      const SizedBox(height: 16),
                      for (final agent in squad)
                        ContentWidth(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _SquadMemberCard(
                              agent: agent,
                              onTap: () => _open(context, MyAgentDetailsPage(agentId: agent.id)),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

class _CapacityHeader extends StatelessWidget {
  final int count;

  const _CapacityHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('$count de ${SquadRepository.maxSize} vagas ocupadas',
                style: const TextStyle(color: AppColors.textMuted)),
            const Spacer(),
            if (count >= SquadRepository.maxSize)
              const Text('Lotado', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: count / SquadRepository.maxSize,
            minHeight: 8,
            backgroundColor: AppColors.panelHigh,
          ),
        ),
      ],
    );
  }
}

/// Card do membro: nome, papel tático (definido pelo maior atributo)
/// e miniatura com cached_network_image.
class _SquadMemberCard extends StatelessWidget {
  final Agent agent;
  final VoidCallback onTap;

  const _SquadMemberCard({required this.agent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final top = agent.powerStats.topStat;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AgentAvatar(agent: agent, size: 60, ringColor: top.color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(agent.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(top.icon, size: 15, color: top.color),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${top.role} · ${top.label} ${agent.powerStats.valueOf(top)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: top.color, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text('${agent.powerStats.rating}',
                      style: const TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      )),
                  const Text('média', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
