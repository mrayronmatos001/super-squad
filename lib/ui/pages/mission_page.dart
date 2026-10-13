import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repository/agent_repository.dart';
import '../../data/repository/squad_repository.dart';
import '../../domain/agent.dart';
import '../../domain/mission.dart';
import '../state/mission_notifier.dart';
import '../state/squad_notifier.dart';
import '../widgets/common.dart';
import 'daily_contract_page.dart';

Color outcomeColor(RoundOutcome outcome) => switch (outcome) {
      RoundOutcome.victory => AppColors.success,
      RoundOutcome.defeat => AppColors.danger,
      RoundOutcome.draw => AppColors.warning,
    };

IconData outcomeIcon(RoundOutcome outcome) => switch (outcome) {
      RoundOutcome.victory => Icons.emoji_events,
      RoundOutcome.defeat => Icons.close,
      RoundOutcome.draw => Icons.balance,
    };

/// Cria o MissionNotifier desta tela. Ele é descartado quando a tela fecha,
/// então cada visita à central tática começa do zero.
class MissionPage extends StatelessWidget {
  const MissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MissionNotifier(
        agentRepository: Provider.of<AgentRepository>(context, listen: false),
        squad: Provider.of<SquadNotifier>(context, listen: false),
      ),
      child: const _MissionView(),
    );
  }
}

class _MissionView extends StatelessWidget {
  const _MissionView();

  void _openContract(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const DailyContractPage()));
  }

  /// Confirma o agente do round. Quando a missão termina, o notifier
  /// devolve o resultado e a tela exibe o diálogo final.
  Future<void> _confirm(BuildContext context) async {
    final result = await Provider.of<MissionNotifier>(context, listen: false).confirmAgent();
    if (result != null && context.mounted) {
      await _showResultDialog(context, result);
    }
  }

  Future<void> _showResultDialog(BuildContext context, MissionResult result) {
    if (result.success) {
      final lucky = result.boost?.agent ?? result.luckyAgent!;
      return AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        dismissOnTouchOutside: false,
        dialogBackgroundColor: AppColors.panel,
        body: _DialogBody(
          image: AgentAvatar(agent: lucky, size: 116, ringColor: AppColors.success),
          title: 'Missão Cumprida!',
          lines: [
            'O esquadrão venceu ${result.wins} de ${result.total} rounds.',
            result.boost != null
                ? '${lucky.name} recebeu +1 em ${result.boost!.stat.label} '
                    '(agora ${result.boost!.newValue}).'
                : '${lucky.name} já está com todos os atributos no máximo.',
          ],
        ),
        btnOkText: 'Ver relatório',
        btnOkColor: AppColors.success,
        btnOkOnPress: () {},
      ).show();
    }

    return AwesomeDialog(
      context: context,
      dialogType: result.majorityLost ? DialogType.error : DialogType.warning,
      animType: AnimType.scale,
      dismissOnTouchOutside: false,
      dialogBackgroundColor: AppColors.panel,
      body: _DialogBody(
        image: Image.asset('assets/images/defeat.png', height: 140),
        title: 'Operação Fracassada!',
        lines: [
          '${result.wins} vitória(s), ${result.losses} derrota(s) e ${result.draws} empate(s).',
          result.majorityLost
              ? 'As ameaças venceram a maioria dos rounds.'
              : 'O esquadrão não venceu mais da metade dos rounds.',
        ],
      ),
      btnOkText: 'Ver relatório',
      btnOkColor: result.majorityLost ? AppColors.danger : AppColors.warning,
      btnOkOnPress: () {},
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    final mission = Provider.of<MissionNotifier>(context);
    final squad = Provider.of<SquadNotifier>(context);
    final inRound = mission.stage == MissionStage.round;

    return Scaffold(
      appBar: AppBar(
        title: Text(inRound
            ? 'Round ${mission.currentIndex + 1} de ${mission.rounds.length}'
            : 'Missões'),
      ),
      body: AppBackdrop(child: _buildStage(context, mission, squad)),
      bottomNavigationBar: inRound ? _buildConfirmBar(context, mission) : null,
    );
  }

  Widget _buildStage(BuildContext context, MissionNotifier mission, SquadNotifier squad) {
    // Antes de a missão começar, depende do esquadrão carregado e com 5+ agentes.
    if (mission.stage == MissionStage.briefing) {
      if (!squad.loaded) return const LoadingView(message: 'Verificando o esquadrão...');
      if (!squad.canStartMission) {
        return MessageView(
          icon: Icons.lock_outline,
          title: 'Esquadrão insuficiente',
          message: 'É preciso ter pelo menos ${SquadRepository.minForMission} agentes '
              'para iniciar uma missão. Seu esquadrão tem ${squad.count}.',
          actionLabel: 'Ir para o Contrato Diário',
          onAction: () => _openContract(context),
        );
      }
    }

    switch (mission.stage) {
      case MissionStage.briefing:
        return _buildBriefing(context, mission, squad);
      case MissionStage.generating:
        return const LoadingView(message: 'Interceptando ameaças...');
      case MissionStage.error:
        return MessageView(
          icon: Icons.wifi_off,
          title: 'Falha ao sortear o desafio',
          message: mission.error ?? 'Tente novamente.',
          actionLabel: 'Tentar novamente',
          onAction: mission.generateChallenge,
        );
      case MissionStage.ready:
        return _buildChallengeIntro(context, mission);
      case MissionStage.round:
        return _buildRound(context, mission);
      case MissionStage.finished:
        return _buildSummary(context, mission);
    }
  }

  Widget _buildBriefing(BuildContext context, MissionNotifier mission, SquadNotifier squad) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: ContentWidth(
        maxWidth: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.danger.withValues(alpha: 0.18), AppColors.panel],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.radar, color: AppColors.danger, size: 40),
                  const SizedBox(height: 12),
                  Text('Central Tática', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Teste o nível tático do seu esquadrão contra ameaças sorteadas do catálogo geral.',
                    style: TextStyle(color: AppColors.textMuted, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _RuleRow(icon: Icons.casino, text: 'Cada Desafio de Crise tem de 3 a 5 rounds.'),
            const _RuleRow(
                icon: Icons.track_changes,
                text: 'Cada round exige um atributo e traz um inimigo com atributos ocultos.'),
            const _RuleRow(
                icon: Icons.person_pin,
                text: 'Escale um agente por round. Cada agente atua uma única vez por missão.'),
            const _RuleRow(
                icon: Icons.emoji_events,
                text: 'Vença mais da metade dos rounds: um vencedor ganha +1 em um atributo.'),
            const SizedBox(height: 24),
            Text('${squad.count} agentes disponíveis para escalação',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: mission.generateChallenge,
              icon: const Icon(Icons.radar),
              label: const Text('Gerar Desafio de Crise'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeIntro(BuildContext context, MissionNotifier mission) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: ContentWidth(
        maxWidth: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text('Desafio de Crise',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 6),
            Text(
              '${mission.rounds.length} rounds',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.displayFont,
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 24),
            for (final round in mission.rounds)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.panelHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('${round.number}',
                              style: const TextStyle(
                                fontFamily: AppTheme.displayFont,
                                fontWeight: FontWeight.w700,
                              )),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Text('Inimigo desconhecido',
                              style: TextStyle(color: AppColors.textMuted)),
                        ),
                        Icon(round.stat.icon, size: 18, color: round.stat.color),
                        const SizedBox(width: 6),
                        Text(round.stat.label,
                            style: TextStyle(color: round.stat.color, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: mission.start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar missão'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRound(BuildContext context, MissionNotifier mission) {
    final scoreboard = _Scoreboard(rounds: mission.rounds, current: mission.currentIndex);
    final enemyPanel = _EnemyPanel(round: mission.currentRound);
    final grid = _AgentGrid(
      squad: mission.team,
      usedIds: mission.usedAgentIds,
      selectedId: mission.selectedId,
      enabled: !mission.showingResult,
      onSelect: mission.select,
    );
    const gridTitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Escale um agente',
            style: TextStyle(
              fontFamily: AppTheme.displayFont,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            )),
        SizedBox(height: 4),
        Text('Agentes esmaecidos já atuaram nesta missão.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
      ],
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 900) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(children: [scoreboard, const SizedBox(height: 16), enemyPanel]),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [gridTitle, const SizedBox(height: 14), grid],
                  ),
                ),
              ),
            ],
          ),
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: ContentWidth(
          maxWidth: 600,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              scoreboard,
              const SizedBox(height: 14),
              enemyPanel,
              const SizedBox(height: 22),
              gridTitle,
              const SizedBox(height: 14),
              grid,
            ],
          ),
        ),
      );
    });
  }

  Widget _buildConfirmBar(BuildContext context, MissionNotifier mission) {
    final round = mission.currentRound;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ContentWidth(
          maxWidth: 600,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: mission.showingResult && round.outcome != null
                ? _ResultBanner(key: ValueKey('result-${round.number}'), round: round)
                : FilledButton.icon(
                    key: const ValueKey('confirm'),
                    onPressed: mission.selectedId == null ? null : () => _confirm(context),
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(mission.selectedId == null
                        ? 'Selecione um agente'
                        : 'Confirmar agente'),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, MissionNotifier mission) {
    final result = mission.result;
    final success = result?.success ?? false;
    final boost = result?.boost;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: ContentWidth(
        maxWidth: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              success ? 'Missão Cumprida!' : 'Operação Fracassada!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: success ? AppColors.success : AppColors.danger,
                  ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                for (final outcome in RoundOutcome.values) ...[
                  Expanded(child: _SummaryCounter(outcome: outcome, value: mission.count(outcome))),
                  if (outcome != RoundOutcome.values.last) const SizedBox(width: 10),
                ],
              ],
            ),
            if (boost != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    AgentAvatar(agent: boost.agent, size: 46, ringColor: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${boost.agent.name} recebeu +1 em ${boost.stat.label} '
                        '(agora ${boost.newValue}).',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text('Relatório dos rounds', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final round in mission.rounds) _RoundReport(round: round),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: mission.generateChallenge,
              icon: const Icon(Icons.replay),
              label: const Text('Nova missão'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Voltar à central'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Componentes da tela de missão
// ---------------------------------------------------------------------------

class _RuleRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RuleRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.signal),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}

/// Placar: round atual, contadores e um marcador colorido por round.
class _Scoreboard extends StatelessWidget {
  final List<MissionRound> rounds;
  final int current;

  const _Scoreboard({required this.rounds, required this.current});

  @override
  Widget build(BuildContext context) {
    int count(RoundOutcome o) => rounds.where((r) => r.outcome == o).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                for (final outcome in RoundOutcome.values) ...[
                  Icon(outcomeIcon(outcome), size: 16, color: outcomeColor(outcome)),
                  const SizedBox(width: 4),
                  Text('${count(outcome)}',
                      style: TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontWeight: FontWeight.w700,
                        color: outcomeColor(outcome),
                      )),
                  const SizedBox(width: 14),
                ],
                const Spacer(),
                Text('${rounds.length} rounds', style: const TextStyle(color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var i = 0; i < rounds.length; i++)
                  Expanded(
                    child: Container(
                      height: 8,
                      margin: EdgeInsets.only(right: i == rounds.length - 1 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: rounds[i].outcome != null
                            ? outcomeColor(rounds[i].outcome!)
                            : AppColors.panelHigh,
                        borderRadius: BorderRadius.circular(4),
                        border: i == current && rounds[i].outcome == null
                            ? Border.all(color: AppColors.signal, width: 1.5)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Inimigo da rodada: imagem e nome, sem mostrar os atributos.
class _EnemyPanel extends StatelessWidget {
  final MissionRound round;

  const _EnemyPanel({required this.round});

  @override
  Widget build(BuildContext context) {
    final enemy = round.enemy;
    final stat = round.stat;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            AgentImage(
              url: enemy.images.md.isNotEmpty ? enemy.images.md : enemy.thumbnailUrl,
              width: 108,
              height: 140,
              borderRadius: BorderRadius.circular(14),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: AppColors.danger),
                      SizedBox(width: 6),
                      Text('Inimigo da rodada',
                          style: TextStyle(color: AppColors.danger, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(enemy.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: stat.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: stat.color.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(stat.icon, size: 18, color: stat.color),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text('Atributo em disputa: ${stat.label}',
                              style: TextStyle(color: stat.color, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid 3x5 com as miniaturas do esquadrão (nome e imagem circular).
class _AgentGrid extends StatelessWidget {
  final List<Agent> squad;
  final Set<int> usedIds;
  final int? selectedId;
  final bool enabled;
  final ValueChanged<int> onSelect;

  const _AgentGrid({
    required this.squad,
    required this.usedIds,
    required this.selectedId,
    required this.enabled,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.82,
      children: [
        for (final agent in squad)
          _AgentPickTile(
            agent: agent,
            used: usedIds.contains(agent.id),
            selected: selectedId == agent.id,
            onTap: enabled && !usedIds.contains(agent.id) ? () => onSelect(agent.id) : null,
          ),
      ],
    );
  }
}

class _AgentPickTile extends StatelessWidget {
  final Agent agent;
  final bool used;
  final bool selected;
  final VoidCallback? onTap;

  const _AgentPickTile({
    required this.agent,
    required this.used,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: used ? 0.35 : 1,
      child: Material(
        color: selected ? AppColors.signal.withValues(alpha: 0.12) : AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.signal : AppColors.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AgentAvatar(
                      agent: agent,
                      size: 62,
                      ringColor: selected ? AppColors.signal : AppColors.line,
                    ),
                    if (used)
                      const Positioned(
                        right: -2,
                        bottom: -2,
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: AppColors.panelHigh,
                          child: Icon(Icons.lock, size: 13, color: AppColors.textMuted),
                        ),
                      ),
                    if (selected)
                      const Positioned(
                        right: -2,
                        bottom: -2,
                        child: CircleAvatar(
                          radius: 11,
                          backgroundColor: AppColors.signal,
                          child: Icon(Icons.check, size: 14, color: Colors.black),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  agent.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, height: 1.2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Resultado do round: os valores dos dois lados são revelados.
class _ResultBanner extends StatelessWidget {
  final MissionRound round;

  const _ResultBanner({super.key, required this.round});

  @override
  Widget build(BuildContext context) {
    final outcome = round.outcome!;
    final color = outcomeColor(outcome);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(outcomeIcon(outcome), color: color, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(outcome.label,
                    style: TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: color,
                    )),
                Text(
                  '${round.hero?.name} ${round.heroValue} × ${round.enemyValue} ${round.enemy.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ),
    );
  }
}

class _SummaryCounter extends StatelessWidget {
  final RoundOutcome outcome;
  final int value;

  const _SummaryCounter({required this.outcome, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = outcomeColor(outcome);
    final label = switch (outcome) {
      RoundOutcome.victory => 'Vitórias',
      RoundOutcome.defeat => 'Derrotas',
      RoundOutcome.draw => 'Empates',
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                fontFamily: AppTheme.displayFont,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: color,
              )),
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _RoundReport extends StatelessWidget {
  final MissionRound round;

  const _RoundReport({required this.round});

  @override
  Widget build(BuildContext context) {
    final outcome = round.outcome;
    final hero = round.hero;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (hero != null) AgentAvatar(agent: hero, size: 42),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${hero?.name ?? '—'} × ${round.enemy.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${round.stat.label}: ${round.heroValue} × ${round.enemyValue}',
                        style: TextStyle(color: round.stat.color, fontSize: 12.5)),
                  ],
                ),
              ),
              if (outcome != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: outcomeColor(outcome).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(outcome.label,
                      style: TextStyle(
                        color: outcomeColor(outcome),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      )),
                ),
              const SizedBox(width: 8),
              AgentAvatar(agent: round.enemy, size: 42, ringColor: AppColors.danger),
            ],
          ),
        ),
      ),
    );
  }
}

/// Conteúdo dos diálogos de fim de missão (awesome_dialog).
class _DialogBody extends StatelessWidget {
  final Widget image;
  final String title;
  final List<String> lines;

  const _DialogBody({required this.image, required this.title, required this.lines});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          image,
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 10),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(line,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, height: 1.4)),
            ),
        ],
      ),
    );
  }
}
