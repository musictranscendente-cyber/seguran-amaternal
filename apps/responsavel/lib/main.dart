import 'package:flutter/material.dart';

// App do responsável. Tela de menu equivalente ao layout de referência:
// escuta online, locais no mapa, movimentação, sinal sonoro e contatos.
// A escuta abre o microfone no aparelho da criança COM o indicador do
// Android visível — não há captura oculta.

void main() => runApp(const AppResponsavel());

class AppResponsavel extends StatelessWidget {
  const AppResponsavel({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Segurança dos Filhos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE8826E)),
        useMaterial3: true,
      ),
      home: const MenuPage(),
    );
  }
}

class _ItemMenu {
  final IconData icone;
  final String titulo;
  const _ItemMenu(this.icone, this.titulo);
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  static const _itens = <_ItemMenu>[
    _ItemMenu(Icons.play_circle_outline, 'Escuta Online'),
    _ItemMenu(Icons.place_outlined, 'Locais no Mapa'),
    _ItemMenu(Icons.route_outlined, 'Movimentação da Criança'),
    _ItemMenu(Icons.contacts_outlined, 'Contatos Permitidos'),
    _ItemMenu(Icons.notifications_active_outlined, 'Sinal Sonoro'),
    _ItemMenu(Icons.shield_outlined, 'Proteção do Aparelho'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            for (final item in _itens)
              Card(
                child: InkWell(
                  onTap: () {
                    // TODO: navegar para a tela de cada recurso.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(item.titulo)),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icone, size: 36),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          item.titulo,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
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
