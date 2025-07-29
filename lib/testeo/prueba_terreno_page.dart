import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PruebaTerrenoPage extends StatefulWidget {
  const PruebaTerrenoPage({super.key});

  @override
  State<PruebaTerrenoPage> createState() => _PruebaTerrenoPageState();
}

class _PruebaTerrenoPageState extends State<PruebaTerrenoPage> {
  List<LatLng> topografosSimulados = [];
  List<LatLng> poligonoSimulado = [];
  double? area;
  List<double> distancias = [];
  final Distance distance = Distance();
  final GlobalKey repaintKey = GlobalKey();

  void _onTapMapa(TapPosition pos, LatLng latlng) {
    setState(() {
      topografosSimulados.add(latlng);
    });
  }

  double areaPoligonoMetros(List<LatLng> puntos) {
    if (puntos.length < 3) return 0.0;
    const R = 6378137.0;
    double total = 0.0;
    for (var i = 0; i < puntos.length; i++) {
      var lat1 = puntos[i].latitudeInRad;
      var lon1 = puntos[i].longitudeInRad;
      var j = (i + 1) % puntos.length;
      var lat2 = puntos[j].latitudeInRad;
      var lon2 = puntos[j].longitudeInRad;
      total += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2));
    }
    return (total * R * R / 2).abs();
  }

  void _eliminarTopografo(int idx) {
    setState(() {
      topografosSimulados.removeAt(idx);
      poligonoSimulado.clear();
      area = null;
      distancias = [];
    });
  }

  void _limpiar() {
    setState(() {
      poligonoSimulado.clear();
      topografosSimulados = [];
      area = null;
      distancias = [];
    });
  }

  // Captura el widget del mapa como imagen
  Future<Uint8List?> _capturarPoligonoComoImagen() async {
    try {
      RenderRepaintBoundary boundary =
          repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Error capturando imagen: $e');
      return null;
    }
  }

  Future<void> _subirImagenASupabase(Uint8List bytes) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No hay usuario autenticado')),
    );
    return;
  }

  final filename = '${const Uuid().v4()}.png';
  final storagePath = 'terrenos/$filename';

  try {
    final response = await Supabase.instance.client.storage
        .from('imagenesterrenos')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    // Aquí: Si es String vacío, la subida FALLÓ.
    if (response == null || (response is String && response.isEmpty)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error subiendo la imagen (verifica policies y bucket)')),
        );
      }
      return;
    }

    // Obtén la URL pública
    final url = Supabase.instance.client.storage
        .from('imagenesterrenos')
        .getPublicUrl(storagePath);

    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: URL de imagen vacía')),
      );
      return;
    }

   await Supabase.instance.client.from('terrenos').insert({
  'user_id': user.id,
  'img_url': url,
  'area': area ?? 0,
  'timestamp': DateTime.now().toIso8601String(),
  'puntos': poligonoSimulado
      .map((p) => {'lat': p.latitude, 'lng': p.longitude})
      .toList(),
});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Terreno guardado con imagen!')),
      );
    }
  } catch (e) {
    print('Excepción final subiendo: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error subiendo la imagen: $e')),
      );
    }
  }
}



  void _crearPoligonoSimuladoYSubir() async {
    if (topografosSimulados.length < 3) return;
    setState(() {
      poligonoSimulado = List<LatLng>.from(topografosSimulados);
      List<LatLng> poly = List.from(poligonoSimulado);
      if (poly.isNotEmpty && (poly.first != poly.last)) {
        poly.add(poly.first);
      }
      area = areaPoligonoMetros(poly);
      distancias = [];
      for (int i = 0; i < poly.length - 1; i++) {
        final d = distance.as(
          LengthUnit.Meter,
          poly[i],
          poly[i + 1],
        );
        distancias.add(d);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Polígono simulado creado. Área: ${area!.toStringAsFixed(2)} m². Guardando imagen...',
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 350)); // Para que el widget se pinte

    final bytes = await _capturarPoligonoComoImagen();
    if (bytes != null) {
      await _subirImagenASupabase(bytes);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo capturar la imagen')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prueba de Polígono con Topógrafos Simulados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _limpiar,
            tooltip: 'Limpiar mapa',
          )
        ],
      ),
      body: RepaintBoundary(
        key: repaintKey,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                center: topografosSimulados.isNotEmpty
                    ? topografosSimulados[0]
                    : LatLng(-1.8312, -78.1834),
                zoom: 17,
                onTap: _onTapMapa,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.mapeo_ec',
                ),
                MarkerLayer(
                  markers: topografosSimulados.asMap().entries.map((entry) {
                    int idx = entry.key;
                    LatLng p = entry.value;
                    return Marker(
                      point: p,
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () => _eliminarTopografo(idx),
                        child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 36),
                      ),
                    );
                  }).toList(),
                ),
                if (poligonoSimulado.isNotEmpty)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: poligonoSimulado,
                        color: Colors.blue.withOpacity(0.25),
                        borderColor: Colors.blue,
                        borderStrokeWidth: 3,
                      )
                    ],
                  ),
                if (poligonoSimulado.isNotEmpty)
                  MarkerLayer(
                    markers: poligonoSimulado
                        .map((p) => Marker(
                              point: p,
                              width: 24,
                              height: 24,
                              child: const Icon(Icons.circle, color: Colors.blue, size: 18),
                            ))
                        .toList(),
                  ),
              ],
            ),
            if (poligonoSimulado.isNotEmpty)
              Align(
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 24),
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        'Área: ${area!.toStringAsFixed(2)} m²',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    if (distancias.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 2),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Distancias entre puntos:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            ...distancias.asMap().entries.map((e) => Text(
                                  'Punto ${e.key + 1} - Punto ${e.key + 2}: ${e.value.toStringAsFixed(2)} m',
                                  style: const TextStyle(fontSize: 14),
                                )),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: topografosSimulados.length >= 3
          ? FloatingActionButton.extended(
              onPressed: _crearPoligonoSimuladoYSubir,
              label: const Text("Crear polígono con topógrafos"),
              icon: const Icon(Icons.group),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }
}
