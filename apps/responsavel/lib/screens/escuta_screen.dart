import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import '../services/webrtc_receiver.dart';

/// Escuta online AO VIVO (WebRTC). Ao iniciar, liga a flag `escutaAtiva`
/// (o aparelho da criança começa a transmitir o microfone) e abre a conexão
/// para reproduzir o áudio em tempo real.
///
/// Transparência: enquanto a escuta está ligada, o microfone do aparelho da
/// criança fica em uso e o Android exibe o indicador de microfone.
class EscutaScreen extends StatefulWidget {
  const EscutaScreen({
    super.key,
    required this.familiaId,
    required this.criancaId,
  });

  final String familiaId;
  final String criancaId;

  @override
  State<EscutaScreen> createState() => _EscutaScreenState();
}

class _EscutaScreenState extends State<EscutaScreen> {
  final _familia = FamiliaService();
  WebRtcReceiver? _receiver;
  bool _ligada = false;
  bool _conectado = false;
  bool _ocupado = false;

  Future<void> _iniciar() async {
    setState(() => _ocupado = true);
    await _familia.definirEscuta(widget.familiaId, widget.criancaId, true);
    _receiver = WebRtcReceiver(
      familiaId: widget.familiaId,
      criancaId: widget.criancaId,
    );
    await _receiver!.iniciar(onConectado: () {
      if (mounted) setState(() => _conectado = true);
    });
    if (mounted) {
      setState(() {
        _ligada = true;
        _ocupado = false;
      });
    }
  }

  Future<void> _parar() async {
    setState(() => _ocupado = true);
    await _familia.definirEscuta(widget.familiaId, widget.criancaId, false);
    await _receiver?.parar();
    _receiver = null;
    if (mounted) {
      setState(() {
        _ligada = false;
        _conectado = false;
        _ocupado = false;
      });
    }
  }

  @override
  void dispose() {
    // Garante desligar a escuta ao sair da tela.
    if (_ligada) {
      _familia.definirEscuta(widget.familiaId, widget.criancaId, false);
    }
    _receiver?.parar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cor = const Color(0xFFE8826E);
    final String texto;
    if (!_ligada) {
      texto = 'Escuta desligada.';
    } else if (_conectado) {
      texto = 'Conectado — ouvindo ao vivo.\n'
          'O indicador de microfone aparece no aparelho da criança.';
    } else {
      texto = 'Conectando ao aparelho da criança…';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Escuta Online')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _ligada
                    ? (_conectado ? Icons.hearing : Icons.hourglass_top)
                    : Icons.mic_off,
                size: 80,
                color: _ligada ? cor : Colors.grey,
              ),
              const SizedBox(height: 24),
              Text(texto, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: Icon(_ligada ? Icons.stop : Icons.hearing),
                label: Text(_ligada ? 'Parar escuta' : 'Iniciar escuta'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 16),
                ),
                onPressed: _ocupado ? null : (_ligada ? _parar : _iniciar),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
