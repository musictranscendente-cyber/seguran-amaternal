import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'services/location_reporter.dart';

// App instalado no aparelho da criança.
//
// TRANSPARÊNCIA (regra do projeto):
//  - Mantém uma NOTIFICAÇÃO PERSISTENTE enquanto o monitoramento está ativo.
//  - O ícone do app permanece VISÍVEL (não é ocultado).
//  - Quando a escuta online é acionada, o indicador de microfone do Android
//    aparece normalmente — não há captura silenciosa.
//
// É isso que diferencia controle parental de spyware.

// TODO: substituir pelos IDs reais vindos do pareamento com a conta do
// responsável (QR code / código). Fixos só para desenvolvimento.
const _familiaIdDemo = 'familia_demo';
const _criancaIdDemo = 'crianca_demo';

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
      home: const StatusPage(),
    );
  }
}

class StatusPage extends StatefulWidget {
  const StatusPage({super.key});

  @override
  State<StatusPage> createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  bool _ativo = false;

  Future<void> _alternar() async {
    if (_ativo) {
      await ServicoLocalizacao.parar();
    } else {
      await ServicoLocalizacao.iniciar(
        familiaId: _familiaIdDemo,
        criancaId: _criancaIdDemo,
      );
    }
    setState(() => _ativo = !_ativo);
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
            Icon(
              _ativo ? Icons.shield : Icons.shield_outlined,
              size: 64,
              color: _ativo ? const Color(0xFFE8826E) : null,
            ),
            const SizedBox(height: 16),
            Text(
              _ativo ? 'Monitoramento ativo' : 'Monitoramento parado',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Este aparelho está vinculado à conta do responsável. '
              'A localização é compartilhada e o microfone pode ser acionado '
              'remotamente — quando isso acontece, o indicador de microfone do '
              'sistema aparece no alto da tela.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _alternar,
              icon: Icon(_ativo ? Icons.stop : Icons.play_arrow),
              label: Text(_ativo ? 'Parar' : 'Ativar monitoramento'),
            ),
          ],
        ),
      ),
    );
  }
}
