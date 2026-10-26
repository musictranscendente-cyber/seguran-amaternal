/// Modelos compartilhados entre o app do responsável e o da criança.
library;

/// Perfil de uma criança monitorada.
class Crianca {
  final String id;
  final String nome;
  final String? childUid;
  final bool escutaAtiva;
  final LocalizacaoReportada? ultimaLocalizacao;

  const Crianca({
    required this.id,
    required this.nome,
    this.childUid,
    this.escutaAtiva = false,
    this.ultimaLocalizacao,
  });

  factory Crianca.fromMap(String id, Map<String, dynamic> m) => Crianca(
        id: id,
        nome: m['nome'] as String? ?? 'Criança',
        childUid: m['childUid'] as String?,
        escutaAtiva: m['escutaAtiva'] as bool? ?? false,
        ultimaLocalizacao: m['ultimaLocalizacao'] == null
            ? null
            : LocalizacaoReportada.fromMap(
                (m['ultimaLocalizacao'] as Map).cast<String, dynamic>()),
      );
}

/// Posição reportada pelo aparelho da criança.
class LocalizacaoReportada {
  final double latitude;
  final double longitude;
  final double precisaoMetros;
  final DateTime quando;

  const LocalizacaoReportada({
    required this.latitude,
    required this.longitude,
    required this.precisaoMetros,
    required this.quando,
  });

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'precisaoMetros': precisaoMetros,
        'quando': quando.toIso8601String(),
      };

  factory LocalizacaoReportada.fromMap(Map<String, dynamic> m) =>
      LocalizacaoReportada(
        latitude: (m['latitude'] as num).toDouble(),
        longitude: (m['longitude'] as num).toDouble(),
        precisaoMetros: (m['precisaoMetros'] as num).toDouble(),
        quando: DateTime.parse(m['quando'] as String),
      );
}

/// Clipe de áudio da escuta online (URL no Firebase Storage).
class ClipeAudio {
  final String id;
  final String url;
  final DateTime quando;

  const ClipeAudio({required this.id, required this.url, required this.quando});

  Map<String, dynamic> toMap() => {
        'url': url,
        'quando': quando.toIso8601String(),
      };

  factory ClipeAudio.fromMap(String id, Map<String, dynamic> m) => ClipeAudio(
        id: id,
        url: m['url'] as String,
        quando: DateTime.parse(m['quando'] as String),
      );
}

/// Comandos pontuais que o responsável envia e o aparelho executa.
/// Todos têm efeito VISÍVEL no aparelho monitorado.
enum TipoComando {
  sinalSonoro, // toca alarme para localizar o aparelho
  atualizarLocalizacao,
}

class Comando {
  final TipoComando tipo;
  final DateTime criadoEm;
  final bool executado;

  const Comando({
    required this.tipo,
    required this.criadoEm,
    this.executado = false,
  });

  Map<String, dynamic> toMap() => {
        'tipo': tipo.name,
        'criadoEm': criadoEm.toIso8601String(),
        'executado': executado,
      };

  factory Comando.fromMap(Map<String, dynamic> m) => Comando(
        tipo: TipoComando.values.byName(m['tipo'] as String),
        criadoEm: DateTime.parse(m['criadoEm'] as String),
        executado: m['executado'] as bool? ?? false,
      );
}
