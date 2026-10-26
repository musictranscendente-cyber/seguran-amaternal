import 'package:flutter/material.dart';
import 'package:shared/shared.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _cadastro = false;
  bool _ocupado = false;
  String? _erro;

  Future<void> _enviar() async {
    setState(() {
      _ocupado = true;
      _erro = null;
    });
    try {
      if (_cadastro) {
        await _auth.cadastrar(_email.text, _senha.text);
      } else {
        await _auth.entrar(_email.text, _senha.text);
      }
      // O StreamBuilder em main.dart troca de tela sozinho.
    } catch (e) {
      setState(() => _erro = _mensagem(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  String _mensagem(Object e) {
    final s = e.toString();
    if (s.contains('wrong-password') || s.contains('invalid-credential')) {
      return 'E-mail ou senha incorretos.';
    }
    if (s.contains('email-already-in-use')) return 'Este e-mail já tem conta.';
    if (s.contains('weak-password')) return 'Senha muito fraca (mín. 6).';
    if (s.contains('invalid-email')) return 'E-mail inválido.';
    return 'Não foi possível entrar. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.shield, size: 64, color: Color(0xFFE8826E)),
              const SizedBox(height: 8),
              Text('Segurança dos Filhos',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 32),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'E-mail', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _senha,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Senha', border: OutlineInputBorder()),
              ),
              if (_erro != null) ...[
                const SizedBox(height: 12),
                Text(_erro!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _ocupado ? null : _enviar,
                child: _ocupado
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_cadastro ? 'Criar conta' : 'Entrar'),
              ),
              TextButton(
                onPressed: () => setState(() => _cadastro = !_cadastro),
                child: Text(_cadastro
                    ? 'Já tenho conta — entrar'
                    : 'Criar uma conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
