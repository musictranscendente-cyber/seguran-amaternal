import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared/shared.dart';

// Escuta online AO VIVO (WebRTC). O aparelho da criança é o "caller": captura
// o microfone e transmite em tempo real para o responsável. Como o microfone
// fica em uso, o indicador de microfone do Android aparece o tempo todo — a
// escuta nunca é silenciosa.
class WebRtcSender {
  WebRtcSender({
    required this.familiaId,
    required this.criancaId,
    SinalizacaoService? sinal,
  }) : _sinal = sinal ?? SinalizacaoService();

  final String familiaId;
  final String criancaId;
  final SinalizacaoService _sinal;

  RTCPeerConnection? _pc;
  MediaStream? _mic;
  final List<StreamSubscription> _subs = [];
  bool _remoteDefinido = false;

  static const _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
  };

  Future<void> iniciar() async {
    if (_pc != null) return;

    _pc = await createPeerConnection(_config);

    _mic = await navigator.mediaDevices
        .getUserMedia({'audio': true, 'video': false});
    for (final track in _mic!.getTracks()) {
      await _pc!.addTrack(track, _mic!);
    }

    _pc!.onIceCandidate = (c) {
      _sinal.adicionarCandidato(familiaId, criancaId,
          doCaller: true, candidato: c.toMap().cast<String, dynamic>());
    };

    final offer = await _pc!.createOffer({'offerToReceiveAudio': 0});
    await _pc!.setLocalDescription(offer);
    await _sinal.enviarOferta(
        familiaId, criancaId, {'sdp': offer.sdp, 'type': offer.type});

    // Recebe a resposta do responsável.
    _subs.add(_sinal.resposta(familiaId, criancaId).listen((ans) async {
      if (ans == null || _remoteDefinido) return;
      _remoteDefinido = true;
      await _pc!.setRemoteDescription(
          RTCSessionDescription(ans['sdp'] as String, ans['type'] as String));
    }));

    // Recebe os candidatos ICE do responsável (callee).
    _subs.add(_sinal
        .candidatos(familiaId, criancaId, doCaller: false)
        .listen((cand) async {
      await _pc!.addCandidate(RTCIceCandidate(
        cand['candidate'] as String?,
        cand['sdpMid'] as String?,
        cand['sdpMLineIndex'] as int?,
      ));
    }));
  }

  Future<void> parar() async {
    for (final s in _subs) {
      await s.cancel();
    }
    _subs.clear();
    _remoteDefinido = false;
    await _mic?.dispose();
    _mic = null;
    await _pc?.close();
    _pc = null;
    await _sinal.encerrar(familiaId, criancaId);
  }
}
