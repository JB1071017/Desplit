import 'package:flutter/material.dart';

class MeshNode {
  final String id;
  final String title; // "WEB SERVER", "CO DESKTOP", etc.
  final String username;
  final String gpu;
  final String contribution;
  final String latency;
  final String region;
  final Offset relativePos; // normalized 0.0 to 1.0
  final IconData icon;
  final bool isUser;
  final bool isSpecialRoute; // highlighted orange trajectory in Image 1

  const MeshNode({
    required this.id,
    required this.title,
    required this.username,
    required this.gpu,
    required this.contribution,
    required this.latency,
    required this.region,
    required this.relativePos,
    this.icon = Icons.dns_rounded,
    this.isUser = false,
    this.isSpecialRoute = false,
  });
}

class MeshLink {
  final String fromId;
  final String toId;
  final bool isHighlighted; // Highlighted amber/orange arc
  final double packetSpeed;

  const MeshLink({
    required this.fromId,
    required this.toId,
    this.isHighlighted = false,
    this.packetSpeed = 1.0,
  });
}

class NetworkEventLog {
  final String title;
  final String badgeText;
  final Color badgeColor;
  final String details;
  final String time;

  const NetworkEventLog({
    required this.title,
    required this.badgeText,
    required this.badgeColor,
    required this.details,
    required this.time,
  });
}

class RadarIndicator {
  final String name;
  final double value; // 0.0 to 1.0
  final String displayScore;

  const RadarIndicator({
    required this.name,
    required this.value,
    required this.displayScore,
  });
}
