import 'package:flutter/material.dart';

/// Os seis atributos (powerstats) de cada herói da API.
///
/// Cada atributo carrega:
/// - [key]: nome do campo no JSON da API;
/// - [label]: nome em português para exibir na tela;
/// - [role]: "papel tático" do agente cujo maior atributo é este;
/// - [icon] e [color]: identidade visual usada em barras, chips e cartas.
enum StatType {
  intelligence('intelligence', 'Inteligência', 'Estrategista', Icons.psychology, Color(0xFF5B8CFF)),
  strength('strength', 'Força', 'Tanque', Icons.fitness_center, Color(0xFFFF5D5D)),
  speed('speed', 'Velocidade', 'Batedor', Icons.bolt, Color(0xFFFFD23F)),
  durability('durability', 'Durabilidade', 'Guardião', Icons.shield, Color(0xFF3DDC97)),
  power('power', 'Poder', 'Artilheiro', Icons.auto_awesome, Color(0xFFB66DFF)),
  combat('combat', 'Combate', 'Duelista', Icons.sports_martial_arts, Color(0xFFFF8A3D));

  const StatType(this.key, this.label, this.role, this.icon, this.color);

  final String key;
  final String label;
  final String role;
  final IconData icon;
  final Color color;
}
