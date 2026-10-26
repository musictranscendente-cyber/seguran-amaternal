import 'dart:async';

import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared/shared.dart';

import 'audio_streamer.dart';

// Reage, no aparelho da criança, aos comandos e à flag de escuta vindos do
// responsável. Roda enquanto o app está vivo (o serviço em primeiro plano
// mantém o processo ativo).
class CommandListener {
  CommandListener({
    required this.familiaId,
    required this.criancaId,
    FamiliaService? familia,
  }) : _familia = familia ?? FamiliaService();

  final String familiaId;
  final String criancaId;
  final FamiliaService _familia;

  StreamSubscription? _comandosSub;
  StreamSubscription? _escutaSub;
  AudioStreamer? _streamer;

  void iniciar() {
    _comandosSub = _familia
        .comandosPendentes(familiaId, criancaId)
        .listen(_tratarComandos);
    _escutaSub =
        _familia.escutaAtiva(familiaId, criancaId).listen(_tratarEscuta);
  }

  Future<void> _tratarComandos(
      List<({String id, Comando comando})> pendentes) async {
    for (final item in pendentes) {
      switch (item.comando.tipo) {
        case TipoComando.sinalSonoro:
          FlutterRingtonePlayer().playAlarm(volume: 1.0, looping: false);
          break;
        case TipoComando.atualizarLocalizacao:
          await _reportarAgora();
          break;
      }
      await _familia.marcarComandoExecutado(familiaId, criancaId, item.id);
    }
  }

  Future<void> _tratarEscuta(bool ativa) async {
    if (ativa) {
      _streamer ??= AudioStreamer(familiaId: familiaId, criancaId: criancaId);
      await _streamer!.iniciar();
    } else {
      await _streamer?.parar();
    }
  }

  Future<void> _reportarAgora() async {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    await _familia.reportarLocalizacao(
      familiaId,
      criancaId,
      LocalizacaoReportada(
        latitude: pos.latitude,
        longitude: pos.longitude,
        precisaoMetros: pos.accuracy,
        quando: DateTime.now(),
      ),
    );
  }

  Future<void> dispose() async {
    await _comandosSub?.cancel();
    await _escutaSub?.cancel();
    await _streamer?.parar();
  }
}
