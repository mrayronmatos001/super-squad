import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../data/repository/squad_repository.dart';
import '../state/squad_notifier.dart';
import '../widgets/common.dart';
import '../widgets/slanted_shapes.dart';
import 'agents_page.dart';
import 'daily_contract_page.dart';
import 'mission_page.dart';
import 'squad_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    // Provider.of (com listen padrão = true): a tela se redesenha sozinha quando o esquadrão muda
    // (recrutar, dispensar), sem precisar de setState.
    final squad = Provider.of<SquadNotifier>(context);
    final squadCount = squad.count;
    final missionReady = squad.canStartMission;

    final tiles = [
      _MenuTile(
        icon: Icons.travel_explore,
        title: 'Agentes',
        subtitle: 'Catálogo geral de heróis disponíveis',
        accent: const Color(0xFF5B8CFF),
        onTap: () => _open(context, const AgentsPage()),
      ),
      _MenuTile(
        icon: Icons.style,
        title: 'Contrato Diário',
        subtitle: 'Um novo recruta disponível a cada dia',
        accent: AppColors.signal,
        onTap: () => _open(context, const DailyContractPage()),
      ),
      _MenuTile(
        icon: Icons.groups,
        title: 'Meu Esquadrão',
        subtitle: '$squadCount de ${SquadRepository.maxSize} agentes recrutados',
        accent: AppColors.success,
        onTap: () => _open(context, const SquadPage()),
      ),
      _MenuTile(
        icon: Icons.radar,
        title: 'Missões',
        subtitle: missionReady
            ? 'Central tática liberada'
            : 'Requer ${SquadRepository.minForMission} agentes no esquadrão',
        accent: AppColors.danger,
        locked: !missionReady,
        onTap: () => _open(context, const MissionPage()),
      ),
    ];

    return Scaffold(
      body: AppBackdrop(
        child: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
              child: ContentWidth(
                maxWidth: 960,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Header(),
                    const SizedBox(height: 26),
                    _SquadStatusPanel(count: squadCount),
                    const SizedBox(height: 26),
                    if (wide)
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 3.2,
                        children: tiles,
                      )
                    else
                      Column(
                        children: [
                          for (final tile in tiles)
                            Padding(padding: const EdgeInsets.only(bottom: 14), child: tile),
                        ],
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.signal, AppColors.signalDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.shield, color: Colors.black, size: 30),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Super Squad', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 4),
              const Text('Central de comando tático',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 15)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Painel com a ocupação do esquadrão: 15 marcadores, um por vaga.
/// O quinto marcador tem um traço, indicando o mínimo para as missões.
class _SquadStatusPanel extends StatelessWidget {
  final int count;

  const _SquadStatusPanel({required this.count});

  @override
  Widget build(BuildContext context) {
    final missing = SquadRepository.minForMission - count;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontFamily: AppTheme.displayFont,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 4),
                child: Text('/ ${SquadRepository.maxSize} agentes no esquadrão',
                    style: const TextStyle(color: AppColors.textMuted)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < SquadRepository.maxSize; i++)
                Expanded(
                  child: Container(
                    height: 12,
                    // Cada vaga é um paralelogramo, como as barras das cartas.
                    margin: EdgeInsets.only(
                      right: i == SquadRepository.maxSize - 1 ? 0 : 2,
                    ),
                    decoration: ShapeDecoration(
                      color: i < count ? AppColors.signal : AppColors.panelHigh,
                      shape: ParallelogramBorder(
                        slantFactor: 0.6,
                        side: i == SquadRepository.minForMission - 1
                            ? const BorderSide(color: AppColors.textMuted)
                            : BorderSide.none,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            missing > 0
                ? 'Faltam $missing agente(s) para liberar as missões.'
                : 'Esquadrão pronto para missões.',
            style: TextStyle(
              color: missing > 0 ? AppColors.textMuted : AppColors.success,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool locked;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
              Icon(
                locked ? Icons.lock_outline : Icons.chevron_right,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
