import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared/shared.dart';

// Serviço em primeiro plano que roda no aparelho da criança.
//
// Mantém uma NOTIFICAÇÃO PERSISTENTE enquanto está ativo — é isso que torna o
// monitoramento transparente e dentro da política do Google Play. O usuário do
// aparelho sempre vê que está sendo acompanhado.

/// Ponto de entrada do isolate do serviço em primeiro plano.
@pragma('vm:entry-point')
void iniciarCallbackReporter() {
  FlutterForegroundTask.setTaskHandler(ReporterLocalizacaoHandler());
}

class ReporterLocalizacaoHandler extends TaskHandler {
  FamiliaService? _service;
  String? _familiaId;
  String? _criancaId;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // O serviço roda em um isolate separado: Firebase precisa ser iniciado aqui.
    await Firebase.initializeApp();
    _service = FamiliaService();

    final dados = await FlutterForegroundTask.getData<String>(key: 'familiaId');
    _familiaId = dados;
    _criancaId =
        await FlutterForegroundTask.getData<String>(key: 'criancaId');
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    final familiaId = _familiaId;
    final criancaId = _criancaId;
    final service = _service;
    if (familiaId == null || criancaId == null || service == null) return;

    final permitido = await _garantirPermissao();
    if (!permitido) return;

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    await service.reportarLocalizacao(
      familiaId,
      criancaId,
      LocalizacaoReportada(
        latitude: pos.latitude,
        longitude: pos.longitude,
        precisaoMetros: pos.accuracy,
        quando: DateTime.now(),
      ),
    );

    FlutterForegroundTask.updateService(
      notificationTitle: 'Segurança dos Filhos',
      notificationText: 'Localização compartilhada • ${_hora(timestamp)}',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  Future<bool> _garantirPermissao() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    return p == LocationPermission.always ||
        p == LocationPermission.whileInUse;
  }

  String _hora(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// Configura e inicia o serviço em primeiro plano.
class ServicoLocalizacao {
  static Future<void> iniciar({
    required String familiaId,
    required String criancaId,
    Duration intervalo = const Duration(minutes: 1),
  }) async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'monitoramento',
        channelName: 'Monitoramento ativo',
        channelDescription:
            'Mostra que o aparelho está sendo acompanhado pelo responsável.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(intervalo.inMilliseconds),
        autoRunOnBoot: true,
        allowWakeLock: true,
      ),
    );

    await FlutterForegroundTask.saveData(key: 'familiaId', value: familiaId);
    await FlutterForegroundTask.saveData(key: 'criancaId', value: criancaId);

    await FlutterForegroundTask.startService(
      notificationTitle: 'Segurança dos Filhos',
      notificationText: 'Monitoramento ativo',
      callback: iniciarCallbackReporter,
    );
  }

  static Future<void> parar() => FlutterForegroundTask.stopService();
}
