import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'escuta_screen.dart';
import 'mapa_screen.dart';

/// Menu de recursos de uma criança (layout de referência).
class PainelCrianca extends StatelessWidget {
  const PainelCrianca({
    super.key,
    required this.familiaId,
    required this.crianca,
  });

  final String familiaId;
  final Crianca crianca;

  FamiliaService get _familia => FamiliaService();

  @override
  Widget build(BuildContext context) {
    final itens = <_Item>[
      _Item(Icons.play_circle_outline, 'Escuta Online', () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              EscutaScreen(familiaId: familiaId, criancaId: crianca.id),
        ));
      }),
      _Item(Icons.place_outlined, 'Locais no Mapa', () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              MapaScreen(familiaId: familiaId, criancaId: crianca.id),
        ));
      }),
      _Item(Icons.route_outlined, 'Movimentação', () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              MapaScreen(familiaId: familiaId, criancaId: crianca.id),
        ));
      }),
      _Item(Icons.notifications_active_outlined, 'Sinal Sonoro', () async {
        await _familia.enviarComando(
            familiaId, crianca.id, TipoComando.sinalSonoro);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Sinal sonoro enviado ao aparelho.')));
        }
      }),
      _Item(Icons.shield_outlined, 'Proteção do Aparelho', () {
        showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('Proteção contra desinstalação'),
            content: Text(
              'No aparelho da criança, ative o app como "Administrador do '
              'dispositivo" em Configurações. Com o ícone visível, o Android '
              'passa a exigir que ele seja desativado antes de desinstalar — '
              'protegido por senha/PIN do aparelho.',
            ),
            actions: [CloseButton()],
          ),
        );
      }),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(crianca.nome)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            for (final i in itens)
              Card(
                child: InkWell(
                  onTap: i.onTap,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(i.icone, size: 36),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(i.titulo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Item {
  final IconData icone;
  final String titulo;
  final VoidCallback onTap;
  _Item(this.icone, this.titulo, this.onTap);
}
