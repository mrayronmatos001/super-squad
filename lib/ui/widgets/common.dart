import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/agent.dart';

// ---------------------------------------------------------------------------
// Imagens com cache (cached_network_image)
// ---------------------------------------------------------------------------

/// Imagem de herói com cache em disco: depois de carregada uma vez,
/// aparece mesmo sem internet.
class AgentImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final BorderRadius borderRadius;

  const AgentImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.topCenter,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: AppColors.panelHigh,
      alignment: Alignment.center,
      child: const Icon(Icons.person_off_outlined, color: AppColors.textMuted),
    );

    return ClipRRect(
      borderRadius: borderRadius,
      child: url.isEmpty
          ? fallback
          : CachedNetworkImage(
              imageUrl: url,
              width: width,
              height: height,
              fit: fit,
              alignment: alignment,
              fadeInDuration: const Duration(milliseconds: 250),
              placeholder: (context, url) => Container(
                width: width,
                height: height,
                color: AppColors.panelHigh,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => fallback,
            ),
    );
  }
}

/// Miniatura circular do agente, com anel colorido opcional.
class AgentAvatar extends StatelessWidget {
  final Agent agent;
  final double size;
  final Color ringColor;

  const AgentAvatar({
    super.key,
    required this.agent,
    this.size = 56,
    this.ringColor = AppColors.line,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor),
      child: ClipOval(
        child: AgentImage(url: agent.thumbnailUrl, width: size, height: size),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Layout
// ---------------------------------------------------------------------------

/// Fundo das telas: grafite com um brilho âmbar discreto no topo.
class AppBackdrop extends StatelessWidget {
  final Widget child;

  const AppBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.9, -1.1),
          radius: 1.3,
          colors: [AppColors.signal.withValues(alpha: 0.10), AppColors.ink],
          stops: const [0, 0.65],
        ),
      ),
      child: child,
    );
  }
}

/// Limita a largura do conteúdo em telas grandes (tablet, paisagem),
/// mantendo o layout centralizado e confortável de ler.
class ContentWidth extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const ContentWidth({super.key, this.maxWidth = 720, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      // heightFactor 1: ocupa só a altura do filho (importante quando usado
      // em lugares com altura livre, como o bottomNavigationBar).
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estados de tela
// ---------------------------------------------------------------------------

class LoadingView extends StatelessWidget {
  final String message;

  const LoadingView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 18),
          Text(message, style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color iconColor;

  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor = AppColors.signal,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(icon, size: 38, color: iconColor),
              ),
              const SizedBox(height: 20),
              Text(title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text(message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted, height: 1.45)),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Textos da API traduzidos para exibição
// ---------------------------------------------------------------------------

String displayValue(String value) {
  final v = value.trim();
  if (v.isEmpty || v == '-' || v == 'null') return '—';
  return v;
}

String translateGender(String gender) => switch (gender.toLowerCase()) {
      'male' => 'Masculino',
      'female' => 'Feminino',
      _ => displayValue(gender),
    };

String translateAlignment(String alignment) => switch (alignment.toLowerCase()) {
      'good' => 'Herói',
      'bad' => 'Vilão',
      'neutral' => 'Neutro',
      _ => displayValue(alignment),
    };

Color alignmentColor(String alignment) => switch (alignment.toLowerCase()) {
      'good' => AppColors.success,
      'bad' => AppColors.danger,
      _ => AppColors.textMuted,
    };

/// Resumo curto de aparência para os cards: "Human · Masculino · 203 cm".
String appearanceSummary(Agent agent) {
  final a = agent.appearance;
  final parts = <String>[
    displayValue(a.race),
    translateGender(a.gender),
    if (a.height.length > 1) displayValue(a.height[1]),
  ].where((p) => p != '—' && p != '0 cm').toList();
  return parts.isEmpty ? 'Aparência desconhecida' : parts.join(' · ');
}
