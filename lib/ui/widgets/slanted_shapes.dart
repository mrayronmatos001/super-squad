import 'package:flutter/material.dart';

/// Borda em forma de paralelogramo inclinado para a direita (como "/").
///
/// Por ser um [ShapeBorder], pode ser usada em qualquer lugar que aceite
/// um formato: ShapeDecoration, Card, botões e também no
/// SegmentedBarStyle do primer_progress_bar.
class ParallelogramBorder extends ShapeBorder {
  final BorderSide side;

  /// Inclinação das pontas, proporcional à altura (0.8 = 80% da altura).
  final double slantFactor;

  const ParallelogramBorder({this.side = BorderSide.none, this.slantFactor = 0.8});

  /// O topo é deslocado para a direita em relação à base.
  Path _path(Rect rect) {
    final slant = rect.height * slantFactor;
    return Path()
      ..moveTo(rect.left + slant, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right - slant, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(_path(rect.deflate(side.width / 2)), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) =>
      ParallelogramBorder(side: side.scale(t), slantFactor: slantFactor);
}

/// Camada desenhada POR CIMA da barra do primer_progress_bar.
///
/// O primer desenha o trilho e o preenchimento colorido, recortados pela
/// [ParallelogramBorder]. Mas ele corta o fim do preenchimento na vertical;
/// esta camada:
/// 1. "apaga" um triângulo na ponta, deixando o fim inclinado como o resto;
/// 2. adiciona o reflexo de vidro, as divisões a cada 10% e o brilho animado.
class PrimerBarOverlayPainter extends CustomPainter {
  /// Preenchimento de 0 a 1 (o mesmo valor passado ao primer).
  final double value;

  /// Posição do brilho animado, de 0 a 1.
  final double phase;

  /// Mesma cor de fundo usada no SegmentedBarStyle (precisa ser opaca).
  final Color trackColor;

  final double slantFactor;

  PrimerBarOverlayPainter({
    required this.value,
    required this.phase,
    required this.trackColor,
    this.slantFactor = 0.8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (value <= 0) return;
    final w = size.width;
    final h = size.height;
    final slant = h * slantFactor;
    final track = const ParallelogramBorder().getOuterPath(Offset.zero & size);

    // Fim do preenchimento desenhado pelo primer (corte vertical).
    final fx = w * value;

    // 1. Ponta inclinada: cobre com a cor do trilho o triângulo entre o
    //    corte vertical e a diagonal.
    canvas.save();
    canvas.clipPath(track);
    canvas.drawPath(
      Path()
        ..moveTo(fx, 0)
        ..lineTo(fx + 1, 0)
        ..lineTo(fx + 1, h)
        ..lineTo(fx - slant, h)
        ..close(),
      Paint()..color = trackColor,
    );
    canvas.restore();

    // Área preenchida que sobrou, já com a ponta inclinada.
    final fill = Path.combine(
      PathOperation.intersect,
      track,
      Path()
        ..moveTo(0, 0)
        ..lineTo(fx, 0)
        ..lineTo(fx - slant, h)
        ..lineTo(0, h)
        ..close(),
    );

    canvas.save();
    canvas.clipPath(fill);

    // 2. Brilho de luz que percorre a barra sem parar.
    const band = 140.0;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.42),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.3, 0.5, 0.7],
          tileMode: TileMode.repeated,
          transform: SlideGradientTransform(band * phase),
        ).createShader(Rect.fromLTWH(0, 0, band, h)),
    );

    // Reflexo na metade de cima, como um vidro sobre a barra.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.42),
      Paint()..color = Colors.white.withValues(alpha: 0.16),
    );

    // Divisões a cada 10%, com a mesma inclinação das pontas.
    final fullLength = w - slant;
    final divider = Paint()
      ..color = trackColor.withValues(alpha: 0.8)
      ..strokeWidth = 1.6;
    for (var i = 1; i < 10; i++) {
      final x = fullLength * i / 10;
      canvas.drawLine(Offset(x + slant, 0), Offset(x, h), divider);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(PrimerBarOverlayPainter old) =>
      old.value != value || old.phase != phase || old.trackColor != trackColor;
}

/// Desloca um gradiente na horizontal (usado nas animações de brilho).
class SlideGradientTransform extends GradientTransform {
  final double dx;

  const SlideGradientTransform(this.dx);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}
