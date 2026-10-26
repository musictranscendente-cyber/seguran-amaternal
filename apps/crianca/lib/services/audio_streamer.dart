import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:shared/shared.dart';

// Escuta online — grava clipes curtos e envia para o Storage enquanto a flag
// `escutaAtiva` estiver ligada. Como usa o microfone de verdade, o Android 12+
// mostra o indicador de microfone no alto da tela o tempo todo: a escuta NUNCA
// é silenciosa. É assim que fica dentro da política de monitoramento.
class AudioStreamer {
  AudioStreamer({
    required this.familiaId,
    required this.criancaId,
    FamiliaService? familia,
    AudioStorage? storage,
    this.duracaoClipe = const Duration(seconds: 15),
  })  : _familia = familia ?? FamiliaService(),
        _storage = storage ?? AudioStorage();

  final String familiaId;
  final String criancaId;
  final FamiliaService _familia;
  final AudioStorage _storage;
  final Duration duracaoClipe;

  final _record = AudioRecorder();
  bool _rodando = false;

  bool get rodando => _rodando;

  Future<void> iniciar() async {
    if (_rodando) return;
    if (!await _record.hasPermission()) return;
    _rodando = true;
    _loop();
  }

  Future<void> parar() async {
    _rodando = false;
    if (await _record.isRecording()) {
      await _record.stop();
    }
  }

  Future<void> _loop() async {
    final dir = await getTemporaryDirectory();
    while (_rodando) {
      final caminho =
          '${dir.path}/escuta_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _record.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
        path: caminho,
      );
      await Future.delayed(duracaoClipe);
      if (!_rodando) {
        if (await _record.isRecording()) await _record.stop();
        break;
      }
      final salvo = await _record.stop();
      if (salvo == null) continue;

      try {
        final url = await _storage.enviar(familiaId, criancaId, File(salvo));
        await _familia.registrarClipe(familiaId, criancaId, url);
      } catch (_) {
        // rede instável: ignora o clipe e segue para o próximo.
      } finally {
        final f = File(salvo);
        if (await f.exists()) await f.delete();
      }
    }
  }
}
