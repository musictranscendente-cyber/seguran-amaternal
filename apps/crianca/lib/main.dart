import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

import 'services/command_listener.dart';
import 'services/location_reporter.dart';
import 'services/vinculo.dart';

// App instalado no aparelho da criança.
//
// TRANSPARÊNCIA (regra do projeto):
//  - Notificação PERSISTENTE enquanto o monitoramento está ativo.
//  - Ícone do app VISÍVEL (nunca ocultado).
//  - Escuta online usa o microfone real → o indicador do Android aparece.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AppCrianca());
}

class AppCrianca extends StatelessWidget {
  const AppCrianca({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Segurança dos Filhos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE8826E)),
        useMaterial3: true,
      ),
      home: const Raiz(),
    );
  }
}

class Raiz extends StatefulWidget {
  const Raiz({super.key});

  @override
  State<Raiz> createState() => _RaizState();
}

class _RaizState extends State<Raiz> {
  Vinculo? _vinculo;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final v = await Vinculo.carregar();
    setState(() {
      _vinculo = v;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final v = _vinculo;
    if (v == null) {
      return PareamentoScreen(onVinculado: (novo) {
        setState(() => _vinculo = novo);
      });
    }
    return StatusPage(vinculo: v);
  }
}

/// Tela de pareamento: digita o código gerado no app do responsável.
class PareamentoScreen extends StatefulWidget {
  const PareamentoScreen({super.key, required this.onVinculado});

  final void Function(Vinculo) onVinculado;

  @override
  State<PareamentoScreen> createState() => _PareamentoScreenState();
}

class _PareamentoScreenState extends State<PareamentoScreen> {
  final _codigo = TextEditingController();
  final _familia = FamiliaService();
  final _auth = AuthService();
  bool _ocupado = false;
  String? _erro;

  Future<void> _vincular() async {
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      final user = _auth.usuario ?? await _auth.entrarAnonimo();
      final r = await _familia.vincularPorCodigo(_codigo.text.trim(), user.uid);
      await Vinculo.salvar(r.familiaId, r.criancaId);
      widget.onVinculado(Vinculo(r.familiaId, r.criancaId));
    } catch (e) {
      setState(() => _erro = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vincular aparelho')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Digite o código de 6 dígitos gerado no app do responsável '
              '(em "Minhas crianças").',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codigo,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, letterSpacing: 8),
              decoration: const InputDecoration(
                hintText: '000000',
                border: OutlineInputBorder(),
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(_erro!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _ocupado ? null : _vincular,
              child: _ocupado
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Vincular'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tela principal quando o aparelho já está vinculado.
class StatusPage extends StatefulWidget {
  const StatusPage({super.key, required this.vinculo});

  final Vinculo vinculo;

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  CommandListener? _listener;
  bool _ativo = false;

  Future<void> _ativar() async {
    await ServicoLocalizacao.iniciar(
      familiaId: widget.vinculo.familiaId,
      criancaId: widget.vinculo.criancaId,
    );
    _listener = CommandListener(
      familiaId: widget.vinculo.familiaId,
      criancaId: widget.vinculo.criancaId,
    )..iniciar();
    setState(() => _ativo = true);
  }

  Future<void> _parar() async {
    await ServicoLocalizacao.parar();
    await _listener?.dispose();
    _listener = null;
    setState(() => _ativo = false);
  }

  @override
  void dispose() {
    _listener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Segurança dos Filhos')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_ativo ? Icons.shield : Icons.shield_outlined,
                size: 64, color: _ativo ? const Color(0xFFE8826E) : null),
            const SizedBox(height: 16),
            Text(_ativo ? 'Monitoramento ativo' : 'Monitoramento parado',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Este aparelho está vinculado à conta do responsável. '
              'A localização é compartilhada e o microfone pode ser acionado '
              'remotamente — quando isso acontece, o indicador de microfone do '
              'sistema aparece no alto da tela.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _ativo ? _parar : _ativar,
              icon: Icon(_ativo ? Icons.stop : Icons.play_arrow),
              label: Text(_ativo ? 'Parar' : 'Ativar monitoramento'),
            ),
          ],
        ),
      ),
    );
  }
}
