import 'package:cloud_firestore/cloud_firestore.dart';

import 'models.dart';

/// Acesso ao Firestore para os dados de uma família.
///
/// Estrutura no Firestore:
///   familias/{familiaId}
///     ownerUid: <uid do responsável>
///     criancas/{criancaId}
///       nome: <string>
///       ultimaLocalizacao: <LocalizacaoReportada>
///       historico/{pontoId}: <LocalizacaoReportada>
///       comandos/{comandoId}: <Comando>
class FamiliaService {
  FamiliaService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _crianca(
    String familiaId,
    String criancaId,
  ) =>
      _db
          .collection('familias')
          .doc(familiaId)
          .collection('criancas')
          .doc(criancaId);

  // ---- Lado da CRIANÇA: envia dados ----

  /// Grava a localização atual e acrescenta um ponto ao histórico.
  Future<void> reportarLocalizacao(
    String familiaId,
    String criancaId,
    LocalizacaoReportada loc,
  ) async {
    final crianca = _crianca(familiaId, criancaId);
    final batch = _db.batch();
    batch.set(
      crianca,
      {'ultimaLocalizacao': loc.toMap()},
      SetOptions(merge: true),
    );
    batch.set(crianca.collection('historico').doc(), loc.toMap());
    await batch.commit();
  }

  /// Marca um comando como executado (ex.: depois de tocar o sinal sonoro).
  Future<void> marcarComandoExecutado(
    String familiaId,
    String criancaId,
    String comandoId,
  ) =>
      _crianca(familiaId, criancaId)
          .collection('comandos')
          .doc(comandoId)
          .update({'executado': true});

  /// Comandos ainda não executados, para o app da criança reagir.
  Stream<List<({String id, Comando comando})>> comandosPendentes(
    String familiaId,
    String criancaId,
  ) =>
      _crianca(familiaId, criancaId)
          .collection('comandos')
          .where('executado', isEqualTo: false)
          .orderBy('criadoEm')
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => (id: d.id, comando: Comando.fromMap(d.data())))
              .toList());

  // ---- Lado do RESPONSÁVEL: lê e comanda ----

  /// Última posição conhecida, em tempo real.
  Stream<LocalizacaoReportada?> localizacaoAtual(
    String familiaId,
    String criancaId,
  ) =>
      _crianca(familiaId, criancaId).snapshots().map((doc) {
        final data = doc.data();
        final loc = data?['ultimaLocalizacao'] as Map<String, dynamic>?;
        return loc == null ? null : LocalizacaoReportada.fromMap(loc);
      });

  /// Histórico de movimentação (mais recentes primeiro).
  Stream<List<LocalizacaoReportada>> historico(
    String familiaId,
    String criancaId, {
    int limite = 100,
  }) =>
      _crianca(familiaId, criancaId)
          .collection('historico')
          .orderBy('quando', descending: true)
          .limit(limite)
          .snapshots()
          .map((snap) =>
              snap.docs.map((d) => LocalizacaoReportada.fromMap(d.data())).toList());

  /// Envia um comando para o aparelho da criança (escuta, sinal, localizar).
  Future<void> enviarComando(
    String familiaId,
    String criancaId,
    TipoComando tipo,
  ) =>
      _crianca(familiaId, criancaId).collection('comandos').add(
            Comando(tipo: tipo, criadoEm: DateTime.now()).toMap(),
          );
}
