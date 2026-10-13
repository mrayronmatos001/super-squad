import 'stat_type.dart';

// O nome da classe é "Agent" (e não "Hero") porque o Flutter já tem um widget
// chamado Hero, usado em animações de transição. Usar o mesmo nome causaria
// conflito nos imports das telas.

// ---------------------------------------------------------------------------
// Funções auxiliares de leitura do JSON.
// A API às vezes traz campos nulos ou com tipos diferentes; estas funções
// garantem que o app nunca quebre por causa disso.
// ---------------------------------------------------------------------------
int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String _toStr(dynamic value) => value == null ? '' : value.toString();

List<String> _toStrList(dynamic value) =>
    value is List ? value.map((e) => e.toString()).toList() : const [];

Map<String, dynamic> _toMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

// ---------------------------------------------------------------------------
// Atributos de combate
// ---------------------------------------------------------------------------
class PowerStats {
  final int intelligence;
  final int strength;
  final int speed;
  final int durability;
  final int power;
  final int combat;

  const PowerStats({
    required this.intelligence,
    required this.strength,
    required this.speed,
    required this.durability,
    required this.power,
    required this.combat,
  });

  factory PowerStats.fromJson(Map<String, dynamic> json) => PowerStats(
        intelligence: _toInt(json['intelligence']),
        strength: _toInt(json['strength']),
        speed: _toInt(json['speed']),
        durability: _toInt(json['durability']),
        power: _toInt(json['power']),
        combat: _toInt(json['combat']),
      );

  Map<String, dynamic> toJson() => {
        'intelligence': intelligence,
        'strength': strength,
        'speed': speed,
        'durability': durability,
        'power': power,
        'combat': combat,
      };

  /// Valor de um atributo específico. Usado nas batalhas e nas barras.
  int valueOf(StatType stat) => switch (stat) {
        StatType.intelligence => intelligence,
        StatType.strength => strength,
        StatType.speed => speed,
        StatType.durability => durability,
        StatType.power => power,
        StatType.combat => combat,
      };

  /// Cria uma cópia com um atributo alterado (usado no bônus de +1 da missão).
  PowerStats withValue(StatType stat, int value) => PowerStats(
        intelligence: stat == StatType.intelligence ? value : intelligence,
        strength: stat == StatType.strength ? value : strength,
        speed: stat == StatType.speed ? value : speed,
        durability: stat == StatType.durability ? value : durability,
        power: stat == StatType.power ? value : power,
        combat: stat == StatType.combat ? value : combat,
      );

  /// Maior atributo do agente: define o "papel tático" exibido no esquadrão.
  StatType get topStat => StatType.values
      .reduce((best, stat) => valueOf(stat) > valueOf(best) ? stat : best);

  /// Média dos seis atributos, exibida como "avaliação geral" na carta.
  int get rating =>
      ((intelligence + strength + speed + durability + power + combat) / 6).round();
}

// ---------------------------------------------------------------------------
// Aparência
// ---------------------------------------------------------------------------
class Appearance {
  final String gender;
  final String race;
  final List<String> height;
  final List<String> weight;
  final String eyeColor;
  final String hairColor;

  const Appearance({
    required this.gender,
    required this.race,
    required this.height,
    required this.weight,
    required this.eyeColor,
    required this.hairColor,
  });

  factory Appearance.fromJson(Map<String, dynamic> json) => Appearance(
        gender: _toStr(json['gender']),
        race: _toStr(json['race']),
        height: _toStrList(json['height']),
        weight: _toStrList(json['weight']),
        eyeColor: _toStr(json['eyeColor']),
        hairColor: _toStr(json['hairColor']),
      );

  Map<String, dynamic> toJson() => {
        'gender': gender,
        'race': race,
        'height': height,
        'weight': weight,
        'eyeColor': eyeColor,
        'hairColor': hairColor,
      };
}

// ---------------------------------------------------------------------------
// Biografia
// ---------------------------------------------------------------------------
class Biography {
  final String fullName;
  final String alterEgos;
  final List<String> aliases;
  final String placeOfBirth;
  final String firstAppearance;
  final String publisher;
  final String alignment;

  const Biography({
    required this.fullName,
    required this.alterEgos,
    required this.aliases,
    required this.placeOfBirth,
    required this.firstAppearance,
    required this.publisher,
    required this.alignment,
  });

  factory Biography.fromJson(Map<String, dynamic> json) => Biography(
        fullName: _toStr(json['fullName']),
        alterEgos: _toStr(json['alterEgos']),
        aliases: _toStrList(json['aliases']),
        placeOfBirth: _toStr(json['placeOfBirth']),
        firstAppearance: _toStr(json['firstAppearance']),
        publisher: _toStr(json['publisher']),
        alignment: _toStr(json['alignment']),
      );

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'alterEgos': alterEgos,
        'aliases': aliases,
        'placeOfBirth': placeOfBirth,
        'firstAppearance': firstAppearance,
        'publisher': publisher,
        'alignment': alignment,
      };
}

// ---------------------------------------------------------------------------
// Trabalho e conexões
// ---------------------------------------------------------------------------
class Work {
  final String occupation;
  final String base;

  const Work({required this.occupation, required this.base});

  factory Work.fromJson(Map<String, dynamic> json) =>
      Work(occupation: _toStr(json['occupation']), base: _toStr(json['base']));

  Map<String, dynamic> toJson() => {'occupation': occupation, 'base': base};
}

class Connections {
  final String groupAffiliation;
  final String relatives;

  const Connections({required this.groupAffiliation, required this.relatives});

  factory Connections.fromJson(Map<String, dynamic> json) => Connections(
        groupAffiliation: _toStr(json['groupAffiliation']),
        relatives: _toStr(json['relatives']),
      );

  Map<String, dynamic> toJson() =>
      {'groupAffiliation': groupAffiliation, 'relatives': relatives};
}

// ---------------------------------------------------------------------------
// Imagens (xs, sm, md, lg) hospedadas no CDN do jsDelivr
// ---------------------------------------------------------------------------
class AgentImages {
  final String xs;
  final String sm;
  final String md;
  final String lg;

  const AgentImages({required this.xs, required this.sm, required this.md, required this.lg});

  factory AgentImages.fromJson(Map<String, dynamic> json) => AgentImages(
        xs: _toStr(json['xs']),
        sm: _toStr(json['sm']),
        md: _toStr(json['md']),
        lg: _toStr(json['lg']),
      );

  Map<String, dynamic> toJson() => {'xs': xs, 'sm': sm, 'md': md, 'lg': lg};
}

// ---------------------------------------------------------------------------
// Agente (herói)
// ---------------------------------------------------------------------------
class Agent {
  final int id;
  final String name;
  final String slug;
  final PowerStats powerStats;
  final Appearance appearance;
  final Biography biography;
  final Work work;
  final Connections connections;
  final AgentImages images;

  const Agent({
    required this.id,
    required this.name,
    required this.slug,
    required this.powerStats,
    required this.appearance,
    required this.biography,
    required this.work,
    required this.connections,
    required this.images,
  });

  /// Converte o Map de um herói (vindo da API ou do banco) em objeto.
  factory Agent.fromJson(Map<String, dynamic> json) => Agent(
        id: _toInt(json['id']),
        name: _toStr(json['name']),
        slug: _toStr(json['slug']),
        powerStats: PowerStats.fromJson(_toMap(json['powerstats'])),
        appearance: Appearance.fromJson(_toMap(json['appearance'])),
        biography: Biography.fromJson(_toMap(json['biography'])),
        work: Work.fromJson(_toMap(json['work'])),
        connections: Connections.fromJson(_toMap(json['connections'])),
        images: AgentImages.fromJson(_toMap(json['images'])),
      );

  /// Converte o objeto de volta para Map, no mesmo formato da API.
  /// É esse Map (em texto JSON) que fica guardado no banco local.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'powerstats': powerStats.toJson(),
        'appearance': appearance.toJson(),
        'biography': biography.toJson(),
        'work': work.toJson(),
        'connections': connections.toJson(),
        'images': images.toJson(),
      };

  Agent copyWith({PowerStats? powerStats}) => Agent(
        id: id,
        name: name,
        slug: slug,
        powerStats: powerStats ?? this.powerStats,
        appearance: appearance,
        biography: biography,
        work: work,
        connections: connections,
        images: images,
      );

  /// Miniatura para cards e avatares.
  String get thumbnailUrl => images.sm.isNotEmpty ? images.sm : images.xs;

  /// Imagem em alta resolução para as telas de detalhes.
  String get portraitUrl => images.lg.isNotEmpty ? images.lg : images.md;
}
