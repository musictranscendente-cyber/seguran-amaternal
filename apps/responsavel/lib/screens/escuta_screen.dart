import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared/shared.dart';

/// Escuta online. Liga a flag `escutaAtiva`; o aparelho da criança grava
/// clipes curtos e envia, que vão tocando aqui conforme chegam.
///
/// Transparência: enquanto a escuta está ligada, o microfone do aparelho da
/// criança fica em uso e o Android exibe o indicador de microfone. Não existe
/// captura silenciosa.
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
  final _player = AudioPlayer();
  String? _ultimoTocado;
  bool _autoReproduzir = true;

  Future<void> _tocar(ClipeAudio clipe) async {
    if (_ultimoTocado == clipe.id) return;
    _ultimoTocado = clipe.id;
    try {
      await _player.setUrl(clipe.url);
      await _player.play();
    } catch (_) {/* clipe indisponível */}
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escuta Online')),
      body: Column(
        children: [
          StreamBuilder<bool>(
            stream: _familia.escutaAtiva(widget.familiaId, widget.criancaId),
            builder: (context, snap) {
              final ativa = snap.data ?? false;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: ativa
                    ? const Color(0xFFE8826E).withOpacity(0.12)
                    : null,
                child: Column(
                  children: [
                    Icon(ativa ? Icons.mic : Icons.mic_off,
                        size: 56,
                        color: ativa ? const Color(0xFFE8826E) : Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      ativa
                          ? 'Escuta ligada — o aparelho está enviando áudio '
                              '(o indicador de microfone aparece lá).'
                          : 'Escuta desligada.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: Icon(ativa ? Icons.stop : Icons.hearing),
                      label: Text(ativa ? 'Parar escuta' : 'Iniciar escuta'),
                      onPressed: () => _familia.definirEscuta(
                          widget.familiaId, widget.criancaId, !ativa),
                    ),
                  ],
                ),
              );
            },
          ),
          SwitchListTile(
            title: const Text('Reproduzir automaticamente'),
            value: _autoReproduzir,
            onChanged: (v) => setState(() => _autoReproduzir = v),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<ClipeAudio>>(
              stream: _familia.clipes(widget.familiaId, widget.criancaId),
              builder: (context, snap) {
                final clipes = snap.data ?? const <ClipeAudio>[];
                if (_autoReproduzir && clipes.isNotEmpty) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _tocar(clipes.first));
                }
                if (clipes.isEmpty) {
                  return const Center(
                      child: Text('Nenhum áudio recebido ainda.'));
                }
                return ListView(
                  children: [
                    for (final c in clipes)
                      ListTile(
                        leading: const Icon(Icons.graphic_eq),
                        title: Text(_hora(c.quando)),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () {
                            _ultimoTocado = null;
                            _tocar(c);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _hora(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
}
