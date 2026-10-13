import 'package:flutter/material.dart';
import 'package:primer_progress_bar/primer_progress_bar.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/agent.dart';
import '../../domain/stat_type.dart';
import 'common.dart';
import 'slanted_shapes.dart';

// ---------------------------------------------------------------------------
// Barras de atributos com primer_progress_bar (tela de detalhes)
// ---------------------------------------------------------------------------

/// Uma barra do primer_progress_bar para cada powerstat
/// (intelligence, strength, speed, durability, power, combat).
///
/// O primer desenha a barra com o formato de paralelogramo
/// ([ParallelogramBorder] no SegmentedBarStyle). Por cima dela, o
/// [PrimerBarOverlayPainter] deixa a ponta inclinada e adiciona o mesmo
/// brilho animado das cartas.
class PowerStatBars extends StatefulWidget {
  final PowerStats stats;

  const PowerStatBars({super.key, required this.stats});

  @override
  State<PowerStatBars> createState() => _PowerStatBarsState();
}

class _PowerStatBarsState extends State<PowerStatBars> with SingleTickerProviderStateMixin {
  static const _barHeight = 13.0;
  static const _trackColor = AppColors.panelHigh;

  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shimmer.stop();
    } else if (!_shimmer.isAnimating) {
      _shimmer.repeat();
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (index, stat) in StatType.values.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(stat.icon, size: 15, color: stat.color),
                    const SizedBox(width: 8),
                    Text(stat.label, style: const TextStyle(fontSize: 13.5)),
                    const Spacer(),
                    Text(
                      '${widget.stats.valueOf(stat)}',
                      style: const TextStyle(
                        fontFamily: AppTheme.displayFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: _barHeight,
                  // A barra cresce do zero até o valor ao abrir a tela.
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: widget.stats.valueOf(stat).clamp(0, 100) / 100),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (context, fill, _) => Stack(
                      fit: StackFit.expand,
                      children: [
                        PrimerProgressBar(
                          // A escala dos atributos vai de 0 a 100.
                          maxTotalValue: 100,
                          showLegend: false,
                          barStyle: const SegmentedBarStyle(
                            size: _barHeight,
                            // O primer exige gap > 0. Como cada barra tem um
                            // único segmento, o espaço nunca aparece.
                            gap: 1,
                            padding: EdgeInsets.zero,
                            backgroundColor: _trackColor,
                            shape: ParallelogramBorder(),
                          ),
                          segments: [
                            Segment(
                              value: (fill * 100).round(),
                              color: stat.color,
                              label: Text(stat.label),
                              valueLabel: Text('${widget.stats.valueOf(stat)}'),
                            ),
                          ],
                        ),
                        IgnorePointer(
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _shimmer,
                              builder: (context, _) => CustomPaint(
                                painter: PrimerBarOverlayPainter(
                                  value: (fill * 100).round() / 100,
                                  phase: (_shimmer.value + index * 0.17) % 1,
                                  trackColor: _trackColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Grade compacta de atributos (cards do catálogo)
// ---------------------------------------------------------------------------

class MiniStatsGrid extends StatelessWidget {
  final PowerStats stats;

  const MiniStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const spacing = 10.0;
      final itemWidth = (constraints.maxWidth - spacing * 2) / 3;
      return Wrap(
        spacing: spacing,
        runSpacing: 8,
        children: [
          for (final stat in StatType.values)
            SizedBox(
              width: itemWidth,
              child: Tooltip(
                message: stat.label,
                child: Row(
                  children: [
                    Icon(stat.icon, size: 13, color: stat.color),
                    const SizedBox(width: 4),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: stats.valueOf(stat).clamp(0, 100) / 100,
                          minHeight: 4,
                          color: stat.color,
                          backgroundColor: AppColors.line,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${stats.valueOf(stat)}',
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Card do catálogo (nome, appearance e powerstats)
// ---------------------------------------------------------------------------

class AgentCard extends StatelessWidget {
  final Agent agent;
  final VoidCallback onTap;

  const AgentCard({super.key, required this.agent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final alignment = agent.biography.alignment;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AgentImage(
                url: agent.thumbnailUrl,
                width: 84,
                height: 112,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            agent.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: translateAlignment(alignment),
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: alignmentColor(alignment),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      appearanceSummary(agent),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayValue(agent.biography.publisher),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.signal),
                    ),
                    const SizedBox(height: 12),
                    MiniStatsGrid(stats: agent.powerStats),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carta do agente (contrato diário e detalhes do meu agente)
// ---------------------------------------------------------------------------

/// Carta no estilo "Top Trumps" dos slides: moldura vermelha, nome, imagem
/// e tabela de atributos. Com [showSummary], mostra também um resumo da
/// ficha (usado em "Detalhes do Meu Agente").
///
/// É um StatefulWidget só para manter o AnimationController que faz o
/// brilho "vivo" percorrer as barras de atributos.
class AgentTradingCard extends StatefulWidget {
  final Agent agent;
  final bool showSummary;

  const AgentTradingCard({super.key, required this.agent, this.showSummary = false});

  @override
  State<AgentTradingCard> createState() => _AgentTradingCardState();
}

class _AgentTradingCardState extends State<AgentTradingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respeita a opção de acessibilidade "remover animações" do aparelho.
    if (MediaQuery.disableAnimationsOf(context)) {
      _shimmer.stop();
    } else if (!_shimmer.isAnimating) {
      _shimmer.repeat();
    }
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final bio = agent.biography;
    final summary = [
      if (displayValue(bio.fullName) != '—') bio.fullName,
      if (displayValue(bio.publisher) != '—') bio.publisher,
      if (displayValue(bio.firstAppearance) != '—') 'Estreia: ${bio.firstAppearance}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.cardFrameLight, AppColors.cardFrameDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardFrameLight.withValues(alpha: 0.30),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardInner,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF35558A), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      agent.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                  Text(
                    'Nº ${agent.id}',
                    style: const TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AspectRatio(
                aspectRatio: 4 / 3.4,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF35558A)),
                  ),
                  child: AgentImage(
                    url: agent.portraitUrl,
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
            if (widget.showSummary && summary.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Text(
                  summary,
                  style: const TextStyle(fontSize: 12.5, height: 1.4, color: AppColors.textMuted),
                ),
              ),
            const SizedBox(height: 12),
            for (final (index, stat) in StatType.values.indexed)
              _CardStatRow(
                stat: stat,
                value: agent.powerStats.valueOf(stat),
                shimmer: _shimmer,
                // Cada barra começa o brilho num ponto diferente,
                // para o movimento não ficar sincronizado e "robótico".
                phaseOffset: index * 0.17,
              ),
            Container(
              margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('Avaliação geral', style: TextStyle(color: AppColors.textMuted)),
                  const Spacer(),
                  Text(
                    '${agent.powerStats.rating}',
                    style: const TextStyle(
                      fontFamily: AppTheme.displayFont,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.signal,
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

class _CardStatRow extends StatelessWidget {
  final StatType stat;
  final int value;
  final Animation<double> shimmer;
  final double phaseOffset;

  const _CardStatRow({
    required this.stat,
    required this.value,
    required this.shimmer,
    required this.phaseOffset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        children: [
          Icon(stat.icon, size: 15, color: stat.color),
          const SizedBox(width: 8),
          SizedBox(
            width: 98,
            child: Text(stat.label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: SizedBox(
              height: 13,
              child: RepaintBoundary(
                // Ao abrir a carta (ou ganhar +1), a barra cresce até o valor.
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: value.clamp(0, 100) / 100),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, fill, _) => AnimatedBuilder(
                    animation: shimmer,
                    builder: (context, _) => CustomPaint(
                      painter: SlantedBarPainter(
                        value: fill,
                        color: stat.color,
                        phase: (shimmer.value + phaseOffset) % 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: Text(
              '$value',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: AppTheme.displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de atributo em forma de paralelogramo inclinado para a direita
/// (como "/"), dividida em 10 segmentos, com um brilho que percorre o
/// preenchimento sem parar.
class SlantedBarPainter extends CustomPainter {
  /// Preenchimento de 0 a 1.
  final double value;
  final Color color;

  /// Posição do brilho animado, de 0 a 1.
  final double phase;

  SlantedBarPainter({required this.value, required this.color, required this.phase});

  /// Paralelogramo de comprimento [length]: o topo é deslocado [slant]
  /// pixels para a direita em relação à base, o que inclina as pontas.
  Path _parallelogram(double length, double slant, double h) => Path()
    ..moveTo(slant, 0)
    ..lineTo(slant + length, 0)
    ..lineTo(length, h)
    ..lineTo(0, h)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final slant = h * 0.8; // inclinação das pontas
    final fullLength = size.width - slant; // comprimento útil da barra

    // Trilho (fundo da barra).
    canvas.drawPath(
      _parallelogram(fullLength, slant, h),
      Paint()..color = Colors.white.withValues(alpha: 0.07),
    );

    if (value <= 0) return;

    final fill = _parallelogram(fullLength * value, slant, h);

    // Brilho externo suave, na cor do atributo.
    canvas.drawPath(
      fill,
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Gradiente que se repete em faixas de 140 px e desliza com [phase]:
    // é isso que dá a impressão de energia correndo pela barra.
    const band = 140.0;
    final dark = Color.lerp(color, Colors.black, 0.35)!;
    final light = Color.lerp(color, Colors.white, 0.55)!;
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          colors: [dark, color, light, color, dark],
          stops: const [0, 0.32, 0.5, 0.68, 1],
          tileMode: TileMode.repeated,
          transform: SlideGradientTransform(band * phase),
        ).createShader(Rect.fromLTWH(0, 0, band, h)),
    );

    canvas.save();
    canvas.clipPath(fill);

    // Reflexo na metade de cima, como um vidro sobre a barra.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, h * 0.42),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    // Divisões a cada 10%, com a mesma inclinação das pontas.
    final divider = Paint()
      ..color = AppColors.cardInner.withValues(alpha: 0.75)
      ..strokeWidth = 1.6;
    for (var i = 1; i < 10; i++) {
      final x = fullLength * i / 10;
      canvas.drawLine(Offset(x + slant, 0), Offset(x, h), divider);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(SlantedBarPainter old) =>
      old.value != value || old.color != color || old.phase != phase;
}

// ---------------------------------------------------------------------------
// Seções com todos os detalhes da API
// ---------------------------------------------------------------------------

class AgentInfoSections extends StatelessWidget {
  final Agent agent;

  const AgentInfoSections({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    final a = agent.appearance;
    final b = agent.biography;
    final w = agent.work;
    final c = agent.connections;

    return Column(
      children: [
        _InfoSection(title: 'Aparência', icon: Icons.face_retouching_natural, rows: {
          'Gênero': translateGender(a.gender),
          'Raça': displayValue(a.race),
          'Altura': a.height.isEmpty ? '—' : a.height.join(' / '),
          'Peso': a.weight.isEmpty ? '—' : a.weight.join(' / '),
          'Olhos': displayValue(a.eyeColor),
          'Cabelo': displayValue(a.hairColor),
        }),
        _InfoSection(title: 'Biografia', icon: Icons.menu_book, rows: {
          'Nome completo': displayValue(b.fullName),
          'Alter egos': displayValue(b.alterEgos),
          'Apelidos': b.aliases.isEmpty ? '—' : b.aliases.join(', '),
          'Nascimento': displayValue(b.placeOfBirth),
          'Primeira aparição': displayValue(b.firstAppearance),
          'Editora': displayValue(b.publisher),
          'Alinhamento': translateAlignment(b.alignment),
        }),
        _InfoSection(title: 'Trabalho', icon: Icons.work_outline, rows: {
          'Ocupação': displayValue(w.occupation),
          'Base': displayValue(w.base),
        }),
        _InfoSection(title: 'Conexões', icon: Icons.hub_outlined, rows: {
          'Afiliações': displayValue(c.groupAffiliation),
          'Parentes': displayValue(c.relatives),
        }),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<String, String> rows;

  const _InfoSection({required this.title, required this.icon, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.signal),
                  const SizedBox(width: 8),
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 12),
              for (final entry in rows.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 132,
                        child: Text(entry.key,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13.5)),
                      ),
                      Expanded(
                        child: Text(entry.value, style: const TextStyle(fontSize: 13.5, height: 1.35)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
