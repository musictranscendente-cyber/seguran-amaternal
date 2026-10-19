import 'package:flutter/material.dart';

// App instalado no aparelho da criança.
//
// TRANSPARÊNCIA (regra do projeto):
//  - Mantém uma NOTIFICAÇÃO PERSISTENTE enquanto o monitoramento está ativo.
//  - O ícone do app permanece VISÍVEL (não é ocultado).
//  - Quando a escuta online é acionada, o indicador de microfone do Android
//    aparece normalmente — não há captura silenciosa.
//
// É isso que diferencia controle parental de spyware.

void main() => runApp(const AppCrianca());

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

class StatusPage extends StatelessWidget {
  const StatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Segurança dos Filhos')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.shield_outlined, size: 64),
            SizedBox(height: 16),
            Text(
              'Monitoramento ativo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Este aparelho está vinculado à conta do responsável. '
              'A localização é compartilhada e o microfone pode ser acionado '
              'remotamente — quando isso acontece, o indicador de microfone do '
              'sistema aparece no alto da tela.',
            ),
            // TODO: iniciar o serviço em primeiro plano (flutter_foreground_task)
            // que mantém a notificação persistente e escuta a coleção `comandos`
            // no Firestore para localização, sinal sonoro e escuta online.
          ],
        ),
      ),
    );
  }
}
