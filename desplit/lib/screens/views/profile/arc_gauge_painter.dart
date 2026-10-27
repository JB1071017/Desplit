import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class ArcGaugePainter extends CustomPainter {
  final double llmFraction; // 0.0 to 1.0 (LLM & NLP Inference)
  final double visionFraction; // Vision & Diffusion
  final double audioFraction; // Audio & Embeddings
  final bool isLightMode;
  final Color? llmColor;
  final Color? visionColor;
  final Color? audioColor;

  ArcGaugePainter({
    double? llmFraction,
    double? visionFraction,
    double? audioFraction,
    double? easyFraction,
    double? medFraction,
    double? hardFraction,
    this.isLightMode = false,
    this.llmColor,
    this.visionColor,
    this.audioColor,
  })  : llmFraction = llmFraction ?? easyFraction ?? 0.55,
        visionFraction = visionFraction ?? medFraction ?? 0.28,
        audioFraction = audioFraction ?? hardFraction ?? 0.17;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final radius = math.min(size.width, size.height) * 0.44;
    const strokeWidth = 9.0;

    // Track arc (background full gauge 240 degrees)
    const startAngle = 150 * (math.pi / 180);
    const sweepTotal = 240 * (math.pi / 180);

    final trackPaint = Paint()
      ..color = AppColors.isProfessional
          ? const Color(0xFF262B34)
          : (isLightMode
              ? const Color(0xFFE9E5F5)
              : const Color(0xFF231F3D))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    final resolvedLlmColor = llmColor ??
        (AppColors.isProfessional
            ? const Color(0xFF60CDFF)
            : (isLightMode
                ? const Color(0xFF7C3AED)
                : const Color(0xFFC084FC)));

    final resolvedVisionColor = visionColor ??
        (AppColors.isProfessional
            ? const Color(0xFF38BDF8)
            : (isLightMode
                ? const Color(0xFF0284C7)
                : const Color(0xFF38BDF8)));

    final resolvedAudioColor = audioColor ??
        (AppColors.isProfessional
            ? const Color(0xFF10B981)
            : (isLightMode
                ? const Color(0xFF059669)
                : const Color(0xFF00F5A0)));

    // Segment 1: LLM & NLP Inference (Primary Brand Accent)
    final sweepLlm = sweepTotal * llmFraction.clamp(0.0, 1.0);
    if (sweepLlm > 0.01) {
      final llmPaint = Paint()
        ..color = resolvedLlmColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepLlm,
        false,
        llmPaint,
      );
    }

    // Segment 2: Vision & Diffusion
    final sweepVision = sweepTotal * visionFraction.clamp(0.0, 1.0);
    if (sweepVision > 0.01) {
      final visionPaint = Paint()
        ..color = resolvedVisionColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + sweepLlm,
        sweepVision,
        false,
        visionPaint,
      );
    }

    // Segment 3: Audio & Embeddings
    final sweepAudio = sweepTotal * audioFraction.clamp(0.0, 1.0);
    if (sweepAudio > 0.01) {
      final audioPaint = Paint()
        ..color = resolvedAudioColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + sweepLlm + sweepVision,
        sweepAudio,
        false,
        audioPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ArcGaugePainter oldDelegate) {
    return oldDelegate.llmFraction != llmFraction ||
        oldDelegate.visionFraction != visionFraction ||
        oldDelegate.audioFraction != audioFraction ||
        oldDelegate.isLightMode != isLightMode ||
        oldDelegate.llmColor != llmColor ||
        oldDelegate.visionColor != visionColor ||
        oldDelegate.audioColor != audioColor;
  }
}
