import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repository/agent_repository.dart';
import '../../domain/agent.dart';
import '../state/squad_notifier.dart';
import '../widgets/agent_widgets.dart';
import '../widgets/common.dart';

class MyAgentDetailsPage extends StatefulWidget {
  final int agentId;

  const MyAgentDetailsPage({super.key, required this.agentId});

  @override
  State<MyAgentDetailsPage> createState() => _MyAgentDetailsPageState();
}

class _MyAgentDetailsPageState extends State<MyAgentDetailsPage> {
  /// Ficha atualizada da API (ou do cache, se offline). Criada uma única vez
  /// no initState para o FutureBuilder não refazer a requisição a cada build.
  late final Future<Agent?> _freshInfo;

  @override
  void initState() {
    super.initState();
    _freshInfo = context
        .read<AgentRepository>()
        .getAgentById(widget.agentId)
        .then<Agent?>((agent) => agent)
        .catchError((Object _) => null);
  }

  void _confirmDismiss(Agent agent) {
    final squad = Provider.of<SquadNotifier>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    AwesomeDialog(
      context: context,
      dialogType: DialogType.warning,
      animType: AnimType.scale,
      dialogBackgroundColor: AppColors.panel,
      title: 'Dispensar agente?',
      desc: '${agent.name} deixará o esquadrão e a vaga será liberada. '
          'Os bônus conquistados em missões serão perdidos.',
      btnCancelText: 'Cancelar',
      btnOkText: 'Dispensar',
      btnOkColor: AppColors.danger,
      btnCancelColor: AppColors.panelHigh,
      btnCancelOnPress: () {},
      btnOkOnPress: () {},
      // Chamado depois que o diálogo fecha; só age se o usuário confirmou.
      onDismissCallback: (type) async {
        if (type != DismissType.btnOk) return;
        navigator.pop();
        await squad.dismiss(agent.id);
        messenger.showSnackBar(
          SnackBar(content: Text('${agent.name} foi dispensado do esquadrão.')),
        );
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    // Os atributos vêm do esquadrão (com os bônus das missões).
    final local = Provider.of<SquadNotifier>(context).byId(widget.agentId);
    if (local == null) {
      // O agente acabou de ser dispensado e a tela está fechando.
      return const Scaffold(body: SizedBox.shrink());
    }

    return FutureBuilder<Agent?>(
      future: _freshInfo,
      builder: (context, snapshot) {
        final fresh = snapshot.data;
        // Ficha da API/cache, mantendo os atributos do esquadrão.
        final agent = fresh == null ? local : fresh.copyWith(powerStats: local.powerStats);
        return _buildPage(context, agent);
      },
    );
  }

  Widget _buildPage(BuildContext context, Agent agent) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do agente')),
      body: AppBackdrop(
        child: LayoutBuilder(builder: (context, constraints) {
          final card = AgentTradingCard(agent: agent, showSummary: true);
          if (constraints.maxWidth >= 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 440,
                  child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: card),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(8, 20, 24, 24),
                    children: [AgentInfoSections(agent: agent)],
                  ),
                ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              ContentWidth(maxWidth: 440, child: card),
              const SizedBox(height: 24),
              ContentWidth(child: AgentInfoSections(agent: agent)),
            ],
          );
        }),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ContentWidth(
            maxWidth: 440,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _confirmDismiss(agent),
              icon: const Icon(Icons.person_remove),
              label: const Text('Dispensar do Esquadrão'),
            ),
          ),
        ),
      ),
    );
  }
}
