/// Modelos compartilhados entre o app do responsável e o da criança.
library;

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

/// Contato autorizado a falar com a criança.
class ContatoPermitido {
  final String nome;
  final String telefone;

  const ContatoPermitido({required this.nome, required this.telefone});

  Map<String, dynamic> toMap() => {'nome': nome, 'telefone': telefone};

  factory ContatoPermitido.fromMap(Map<String, dynamic> m) =>
      ContatoPermitido(nome: m['nome'] as String, telefone: m['telefone'] as String);
}

/// Comandos que o responsável envia e o aparelho da criança executa.
/// Todos têm efeito VISÍVEL no aparelho monitorado (notificação / indicador).
enum TipoComando {
  escutaOnline, // abre o microfone — Android exibe indicador de uso do mic
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
