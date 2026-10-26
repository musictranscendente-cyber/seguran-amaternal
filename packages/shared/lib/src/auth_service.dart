import 'package:firebase_auth/firebase_auth.dart';

/// Autenticação. Responsável usa e-mail/senha; aparelho da criança usa
/// login anônimo (só para ter um uid estável que as regras reconhecem).
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get usuario => _auth.currentUser;
  Stream<User?> get mudancas => _auth.authStateChanges();

  Future<User> entrar(String email, String senha) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: senha);
    return cred.user!;
  }

  Future<User> cadastrar(String email, String senha) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: senha);
    return cred.user!;
  }

  Future<User> entrarAnonimo() async {
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  Future<void> sair() => _auth.signOut();
}
