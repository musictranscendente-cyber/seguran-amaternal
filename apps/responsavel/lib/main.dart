import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/criancas_screen.dart';
import 'screens/login_screen.dart';

// App do responsável. Login por e-mail/senha; depois, lista de crianças e o
// painel de cada uma (escuta, mapa, movimentação, sinal sonoro, proteção).

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Usa google-services.json (Android) / GoogleService-Info.plist (iOS).
  // Rode `flutterfire configure` para gerar a configuração do projeto.
  await Firebase.initializeApp();
  runApp(const AppResponsavel());
}

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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          final user = snap.data;
          if (user == null) return const LoginScreen();
          return CriancasScreen(ownerUid: user.uid);
        },
      ),
    );
  }
}
