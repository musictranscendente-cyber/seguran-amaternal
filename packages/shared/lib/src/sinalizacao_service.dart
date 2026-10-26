import 'package:cloud_firestore/cloud_firestore.dart';

/// Canal de sinalização WebRTC usando o Firestore (sem servidor próprio).
///
/// A oferta (criança) e a resposta (responsável) ficam no documento
///   familias/{f}/criancas/{c}/chamada/atual
/// e os candidatos ICE nas subcoleções `candCaller` (criança) e
/// `candCallee` (responsável).
///
/// Os mapas trafegam como JSON puro — a conversão para os tipos do
/// flutter_webrtc é feita em cada app, para manter este pacote sem
/// dependência de plugin de mídia.
class SinalizacaoService {
  SinalizacaoService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _chamada(
          String familiaId, String criancaId) =>
      _db
          .collection('familias')
          .doc(familiaId)
          .collection('criancas')
          .doc(criancaId)
          .collection('chamada')
          .doc('atual');

  // ---- Oferta / Resposta ----

  Future<void> enviarOferta(
          String f, String c, Map<String, dynamic> offer) =>
      _chamada(f, c).set({'offer': offer, 'answer': null});

  Stream<Map<String, dynamic>?> oferta(String f, String c) => _chamada(f, c)
      .snapshots()
      .map((d) => (d.data()?['offer'] as Map?)?.cast<String, dynamic>());

  Future<void> enviarResposta(
          String f, String c, Map<String, dynamic> answer) =>
      _chamada(f, c).set({'answer': answer}, SetOptions(merge: true));

  Stream<Map<String, dynamic>?> resposta(String f, String c) => _chamada(f, c)
      .snapshots()
      .map((d) => (d.data()?['answer'] as Map?)?.cast<String, dynamic>());

  // ---- Candidatos ICE ----

  Future<void> adicionarCandidato(
    String f,
    String c, {
    required bool doCaller,
    required Map<String, dynamic> candidato,
  }) =>
      _chamada(f, c)
          .collection(doCaller ? 'candCaller' : 'candCallee')
          .add(candidato);

  /// Emite apenas os candidatos recém-adicionados pela outra ponta.
  Stream<Map<String, dynamic>> candidatos(
    String f,
    String c, {
    required bool doCaller,
  }) =>
      _chamada(f, c)
          .collection(doCaller ? 'candCaller' : 'candCallee')
          .snapshots()
          .expand((snap) => snap.docChanges
              .where((ch) => ch.type == DocumentChangeType.added)
              .map((ch) => ch.doc.data()!));

  // ---- Encerramento ----

  Future<void> encerrar(String f, String c) async {
    final ref = _chamada(f, c);
    for (final sub in ['candCaller', 'candCallee']) {
      final docs = await ref.collection(sub).get();
      for (final d in docs.docs) {
        await d.reference.delete();
      }
    }
    await ref.delete();
  }
}
