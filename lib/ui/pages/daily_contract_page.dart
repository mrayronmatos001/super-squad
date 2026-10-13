import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repository/daily_contract_repository.dart';
import '../../data/repository/squad_repository.dart';
import '../state/daily_contract_notifier.dart';
import '../state/squad_notifier.dart';
import '../widgets/agent_widgets.dart';
import '../widgets/common.dart';

/// O notifier desta tela é criado aqui e descartado quando ela fecha.
class DailyContractPage extends StatelessWidget {
  const DailyContractPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DailyContractNotifier(
        repository: Provider.of<DailyContractRepository>(context, listen: false),
        squad: Provider.of<SquadNotifier>(context, listen: false),
      )..load(),
      child: const _DailyContractView(),
    );
  }
}

class _DailyContractView extends StatelessWidget {
  const _DailyContractView();

  Future<void> _recruit(BuildContext context) async {
    final contract = Provider.of<DailyContractNotifier>(context, listen: false);
    final squad = Provider.of<SquadNotifier>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final name = contract.agent?.name ?? 'Agente';

    final result = await contract.recruit();
    switch (result) {
      case RecruitResult.success:
        messenger.showSnackBar(SnackBar(
          content: Text('$name entrou para o esquadrão (${squad.count}/${SquadRepository.maxSize}).'),
        ));
      case RecruitResult.squadFull:
        messenger.showSnackBar(const SnackBar(
          content: Text('O esquadrão atingiu a capacidade máxima de 15 agentes.'),
        ));
      case RecruitResult.alreadyInSquad:
        break;
    }
  }

  /// Tempo até a meia-noite, quando um novo contrato é sorteado.
  String _timeUntilNextContract() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    return 'Novo contrato em $hours h ${minutes.toString().padLeft(2, '0')} min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contrato Diário')),
      body: AppBackdrop(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final contract = Provider.of<DailyContractNotifier>(context);
    final squad = Provider.of<SquadNotifier>(context);
    final agent = contract.agent;

    if (contract.loading) {
      return const LoadingView(message: 'Consultando o mural de contratos...');
    }
    if (contract.error != null || agent == null) {
      return MessageView(
        icon: Icons.wifi_off,
        title: 'Contrato indisponível',
        message: contract.error ?? 'Tente novamente em instantes.',
        actionLabel: 'Tentar novamente',
        onAction: contract.load,
      );
    }

    final inSquad = squad.contains(agent.id);
    final full = squad.isFull;
    final squadCount = squad.count;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: ContentWidth(
        maxWidth: 440,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(_timeUntilNextContract(),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const Spacer(),
                Text('$squadCount/${SquadRepository.maxSize}',
                    style: const TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(width: 4),
                const Icon(Icons.groups, size: 18, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 16),
            // Apenas nome, imagem e power stats, como pede o enunciado.
            AgentTradingCard(agent: agent),
            const SizedBox(height: 24),
            if (inSquad)
              const FilledButton(
                onPressed: null,
                child: Text('Já está no seu esquadrão'),
              )
            else if (full)
              const FilledButton(
                onPressed: null,
                child: Text('Esquadrão lotado (15/15)'),
              )
            else
              FilledButton.icon(
                onPressed: contract.recruiting ? null : () => _recruit(context),
                icon: contract.recruiting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
                      )
                    : const Icon(Icons.person_add_alt_1),
                label: const Text('Recrutar para o Esquadrão'),
              ),
            if (full && !inSquad) ...[
              const SizedBox(height: 12),
              const Text(
                'O esquadrão atingiu a capacidade máxima. Dispense um agente em '
                '"Meu Esquadrão" para liberar uma vaga.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.danger, fontSize: 13.5, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
