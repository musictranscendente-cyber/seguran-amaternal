import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'models.dart';

/// Acesso ao Firestore para os dados de uma família.
class FamiliaService {
  FamiliaService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _familias =>
      _db.collection('familias');

  DocumentReference<Map<String, dynamic>> _crianca(
          String familiaId, String criancaId) =>
      _familias.doc(familiaId).collection('criancas').doc(criancaId);

  // ---- RESPONSÁVEL: estrutura e pareamento ----

  /// Garante que o responsável tenha uma família e devolve o id dela.
  Future<String> obterOuCriarFamilia(String ownerUid) async {
    final existentes = await _familias
        .where('ownerUid', isEqualTo: ownerUid)
        .limit(1)
        .get();
    if (existentes.docs.isNotEmpty) return existentes.docs.first.id;

    final ref = await _familias.add({
      'ownerUid': ownerUid,
      'criadoEm': DateTime.now().toIso8601String(),
    });
    return ref.id;
  }

  /// Cadastra uma criança e devolve um código de pareamento de 6 dígitos
  /// para digitar no aparelho dela.
  Future<({String criancaId, String codigo})> cadastrarCrianca(
    String familiaId,
    String ownerUid,
    String nome,
  ) async {
    final criancaRef =
        await _familias.doc(familiaId).collection('criancas').add({
      'nome': nome,
      'childUid': null,
      'escutaAtiva': false,
    });

    final codigo = (Random.secure().nextInt(900000) + 100000).toString();
    await _db.collection('pareamentos').doc(codigo).set({
      'familiaId': familiaId,
      'criancaId': criancaRef.id,
      'ownerUid': ownerUid,
      'expiraEm':
          DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      'usado': false,
    });

    return (criancaId: criancaRef.id, codigo: codigo);
  }

  /// Lista as crianças da família, em tempo real.
  Stream<List<Crianca>> criancas(String familiaId) => _familias
      .doc(familiaId)
      .collection('criancas')
      .snapshots()
      .map((s) => s.docs.map((d) => Crianca.fromMap(d.id, d.data())).toList());

  // ---- CRIANÇA: vincular aparelho ----

  /// Usa um código de pareamento para vincular este aparelho (childUid).
  /// Devolve (familiaId, criancaId) em caso de sucesso.
  Future<({String familiaId, String criancaId})> vincularPorCodigo(
    String codigo,
    String childUid,
  ) async {
    final par = await _db.collection('pareamentos').doc(codigo).get();
    final data = par.data();
    if (data == null) {
      throw Exception('Código inválido.');
    }
    if (data['usado'] == true) {
      throw Exception('Este código já foi utilizado.');
    }
    final expira = DateTime.parse(data['expiraEm'] as String);
    if (DateTime.now().isAfter(expira)) {
      throw Exception('Código expirado. Gere um novo no app do responsável.');
    }

    final familiaId = data['familiaId'] as String;
    final criancaId = data['criancaId'] as String;

    await _crianca(familiaId, criancaId).update({'childUid': childUid});
    await par.reference.update({'usado': true});

    return (familiaId: familiaId, criancaId: criancaId);
  }

  // ---- LOCALIZAÇÃO ----

  Future<void> reportarLocalizacao(
    String familiaId,
    String criancaId,
    LocalizacaoReportada loc,
  ) async {
    final crianca = _crianca(familiaId, criancaId);
    final batch = _db.batch();
    batch.set(crianca, {'ultimaLocalizacao': loc.toMap()},
        SetOptions(merge: true));
    batch.set(crianca.collection('historico').doc(), loc.toMap());
    await batch.commit();
  }

  Stream<LocalizacaoReportada?> localizacaoAtual(
          String familiaId, String criancaId) =>
      _crianca(familiaId, criancaId).snapshots().map((doc) {
        final loc = doc.data()?['ultimaLocalizacao'] as Map<String, dynamic>?;
        return loc == null ? null : LocalizacaoReportada.fromMap(loc);
      });

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
          .map((s) =>
              s.docs.map((d) => LocalizacaoReportada.fromMap(d.data())).toList());

  // ---- COMANDOS (sinal sonoro, atualizar localização) ----

  Future<void> enviarComando(
          String familiaId, String criancaId, TipoComando tipo) =>
      _crianca(familiaId, criancaId).collection('comandos').add(
          Comando(tipo: tipo, criadoEm: DateTime.now()).toMap());

  Stream<List<({String id, Comando comando})>> comandosPendentes(
          String familiaId, String criancaId) =>
      _crianca(familiaId, criancaId)
          .collection('comandos')
          .where('executado', isEqualTo: false)
          .orderBy('criadoEm')
          .snapshots()
          .map((s) => s.docs
              .map((d) => (id: d.id, comando: Comando.fromMap(d.data())))
              .toList());

  Future<void> marcarComandoExecutado(
          String familiaId, String criancaId, String comandoId) =>
      _crianca(familiaId, criancaId)
          .collection('comandos')
          .doc(comandoId)
          .update({'executado': true});

  // ---- ESCUTA ONLINE ----

  /// Liga/desliga a escuta. É uma flag pública no documento da criança:
  /// o aparelho reage gravando e enviando clipes, e o indicador de
  /// microfone do Android fica visível enquanto isso dura.
  Future<void> definirEscuta(
          String familiaId, String criancaId, bool ativa) =>
      _crianca(familiaId, criancaId).update({'escutaAtiva': ativa});

  Stream<bool> escutaAtiva(String familiaId, String criancaId) =>
      _crianca(familiaId, criancaId)
          .snapshots()
          .map((d) => d.data()?['escutaAtiva'] as bool? ?? false);

  Future<void> registrarClipe(
          String familiaId, String criancaId, String url) =>
      _crianca(familiaId, criancaId).collection('audio').add(
          ClipeAudio(id: '', url: url, quando: DateTime.now()).toMap());

  Stream<List<ClipeAudio>> clipes(String familiaId, String criancaId,
          {int limite = 30}) =>
      _crianca(familiaId, criancaId)
          .collection('audio')
          .orderBy('quando', descending: true)
          .limit(limite)
          .snapshots()
          .map((s) =>
              s.docs.map((d) => ClipeAudio.fromMap(d.id, d.data())).toList());
}
