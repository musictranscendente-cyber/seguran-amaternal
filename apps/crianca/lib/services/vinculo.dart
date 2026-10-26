import 'package:shared_preferences/shared_preferences.dart';

/// Guarda localmente o vínculo deste aparelho com a família.
class Vinculo {
  Vinculo(this.familiaId, this.criancaId);

  final String familiaId;
  final String criancaId;

  static const _kFamilia = 'familiaId';
  static const _kCrianca = 'criancaId';

  static Future<Vinculo?> carregar() async {
    final p = await SharedPreferences.getInstance();
    final f = p.getString(_kFamilia);
    final c = p.getString(_kCrianca);
    if (f == null || c == null) return null;
    return Vinculo(f, c);
  }

  static Future<void> salvar(String familiaId, String criancaId) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kFamilia, familiaId);
    await p.setString(_kCrianca, criancaId);
  }
}
