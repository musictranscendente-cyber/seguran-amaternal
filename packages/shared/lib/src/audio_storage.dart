import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

/// Envia clipes de áudio da escuta para o Firebase Storage e devolve a URL.
class AudioStorage {
  AudioStorage({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> enviar(
    String familiaId,
    String criancaId,
    File arquivo,
  ) async {
    final nome = '${DateTime.now().millisecondsSinceEpoch}.m4a';
    final ref = _storage
        .ref('familias/$familiaId/criancas/$criancaId/audio/$nome');
    await ref.putFile(arquivo);
    return ref.getDownloadURL();
  }
}
