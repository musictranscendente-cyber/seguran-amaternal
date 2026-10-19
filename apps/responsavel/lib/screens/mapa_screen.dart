import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared/shared.dart';

/// Mostra, em tempo real, onde a criança está e a trilha de movimentação.
class MapaScreen extends StatefulWidget {
  const MapaScreen({
    super.key,
    required this.familiaId,
    required this.criancaId,
    this.service,
  });

  final String familiaId;
  final String criancaId;
  final FamiliaService? service;

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  late final FamiliaService _service = widget.service ?? FamiliaService();
  GoogleMapController? _mapa;
  bool _mostrarTrilha = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locais no Mapa'),
        actions: [
          IconButton(
            tooltip: _mostrarTrilha ? 'Ocultar trajeto' : 'Mostrar trajeto',
            icon: Icon(_mostrarTrilha ? Icons.route : Icons.route_outlined),
            onPressed: () => setState(() => _mostrarTrilha = !_mostrarTrilha),
          ),
        ],
      ),
      body: StreamBuilder<LocalizacaoReportada?>(
        stream: _service.localizacaoAtual(widget.familiaId, widget.criancaId),
        builder: (context, snapAtual) {
          final atual = snapAtual.data;
          if (snapAtual.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (atual == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Ainda não recebemos a localização do aparelho.\n'
                  'Verifique se o app está instalado e com GPS ligado na criança.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final posAtual = LatLng(atual.latitude, atual.longitude);

          return StreamBuilder<List<LocalizacaoReportada>>(
            stream: _mostrarTrilha
                ? _service.historico(widget.familiaId, widget.criancaId)
                : Stream<List<LocalizacaoReportada>>.value(
                    const <LocalizacaoReportada>[]),
            builder: (context, snapHist) {
              final trilha = snapHist.data ?? const <LocalizacaoReportada>[];
              return GoogleMap(
                initialCameraPosition:
                    CameraPosition(target: posAtual, zoom: 16),
                onMapCreated: (c) => _mapa = c,
                myLocationButtonEnabled: false,
                markers: {
                  Marker(
                    markerId: const MarkerId('crianca'),
                    position: posAtual,
                    infoWindow: InfoWindow(
                      title: 'Última posição',
                      snippet: _quandoTexto(atual.quando),
                    ),
                  ),
                },
                polylines: {
                  if (_mostrarTrilha && trilha.length > 1)
                    Polyline(
                      polylineId: const PolylineId('trajeto'),
                      width: 4,
                      color: const Color(0xFFE8826E),
                      points: trilha
                          .map((p) => LatLng(p.latitude, p.longitude))
                          .toList(),
                    ),
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.my_location),
        label: const Text('Atualizar'),
        onPressed: () => _service.enviarComando(
          widget.familiaId,
          widget.criancaId,
          TipoComando.atualizarLocalizacao,
        ),
      ),
    );
  }

  String _quandoTexto(DateTime q) {
    final diff = DateTime.now().difference(q);
    if (diff.inMinutes < 1) return 'agora mesmo';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    return 'em ${q.day}/${q.month} ${q.hour}:${q.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _mapa?.dispose();
    super.dispose();
  }
}
