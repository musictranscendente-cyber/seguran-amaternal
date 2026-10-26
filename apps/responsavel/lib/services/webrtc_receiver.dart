import 'dart:async';

import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:shared/shared.dart';

// Recebe o áudio ao vivo do aparelho da criança (WebRTC). O responsável é o
// "callee": espera a oferta, responde e reproduz o áudio recebido.
class WebRtcReceiver {
  WebRtcReceiver({
    required this.familiaId,
    required this.criancaId,
    SinalizacaoService? sinal,
  }) : _sinal = sinal ?? SinalizacaoService();

  final String familiaId;
  final String criancaId;
  final SinalizacaoService _sinal;

  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  RTCPeerConnection? _pc;
  final List<StreamSubscription> _subs = [];

  static const _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
    ],
  };

  /// Começa a ouvir. `onConectado` é chamado quando o áudio começa a chegar.
  Future<void> iniciar({void Function()? onConectado}) async {
    await _renderer.initialize();

    _subs.add(_sinal.oferta(familiaId, criancaId).listen((offer) async {
      if (offer == null || _pc != null) return;
      await _responder(offer, onConectado);
    }));
  }

  Future<void> _responder(
      Map<String, dynamic> offer, void Function()? onConectado) async {
    _pc = await createPeerConnection(_config);

    _pc!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _renderer.srcObject = event.streams.first; // ativa a reprodução do áudio
        onConectado?.call();
      }
    };

    _pc!.onIceCandidate = (c) {
      _sinal.adicionarCandidato(familiaId, criancaId,
          doCaller: false, candidato: c.toMap().cast<String, dynamic>());
    };

    await _pc!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'] as String, offer['type'] as String));

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    await _sinal.enviarResposta(
        familiaId, criancaId, {'sdp': answer.sdp, 'type': answer.type});

    _subs.add(_sinal
        .candidatos(familiaId, criancaId, doCaller: true)
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
    await _pc?.close();
    _pc = null;
    _renderer.srcObject = null;
    await _renderer.dispose();
  }
}
