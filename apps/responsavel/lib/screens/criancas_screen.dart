import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'painel_crianca.dart';

/// Lista as crianças da família e permite cadastrar uma nova (gerando o
/// código de pareamento para digitar no aparelho dela).
class CriancasScreen extends StatefulWidget {
  const CriancasScreen({super.key, required this.ownerUid});

  final String ownerUid;

  @override
  State<CriancasScreen> createState() => _CriancasScreenState();
}

class _CriancasScreenState extends State<CriancasScreen> {
  final _familia = FamiliaService();
  final _auth = AuthService();
  String? _familiaId;

  @override
  void initState() {
    super.initState();
    _familia.obterOuCriarFamilia(widget.ownerUid).then((id) {
      if (mounted) setState(() => _familiaId = id);
    });
  }

  Future<void> _adicionar() async {
    final nome = await _perguntarNome();
    if (nome == null || nome.trim().isEmpty) return;
    final r = await _familia.cadastrarCrianca(
        _familiaId!, widget.ownerUid, nome.trim());
    if (!mounted) return;
    _mostrarCodigo(nome.trim(), r.codigo);
  }

  Future<String?> _perguntarNome() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova criança'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Criar')),
        ],
      ),
    );
  }

  void _mostrarCodigo(String nome, String codigo) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Código de $nome'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite este código no app instalado no aparelho da '
                'criança (válido por 24h):'),
            const SizedBox(height: 16),
            Text(codigo,
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6)),
          ],
        ),
        actions: [
          FilledButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Ok')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final familiaId = _familiaId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas crianças'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            icon: const Icon(Icons.logout),
            onPressed: _auth.sair,
          ),
        ],
      ),
      floatingActionButton: familiaId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _adicionar,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
            ),
      body: familiaId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Crianca>>(
              stream: _familia.criancas(familiaId),
              builder: (context, snap) {
                final lista = snap.data ?? const <Crianca>[];
                if (lista.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhuma criança cadastrada.\n'
                        'Toque em "Adicionar" para começar.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView(
                  children: [
                    for (final c in lista)
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFE8826E),
                          child: Text(
                            c.nome.isNotEmpty ? c.nome[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(c.nome),
                        subtitle: Text(c.childUid == null
                            ? 'Aguardando vínculo do aparelho'
                            : 'Aparelho vinculado'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PainelCrianca(
                                familiaId: familiaId, crianca: c),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
