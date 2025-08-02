import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AreaTopografosPage extends StatefulWidget {
  const AreaTopografosPage({super.key});

  @override
  State<AreaTopografosPage> createState() => _AreaTopografosPageState();
}

class _AreaTopografosPageState extends State<AreaTopografosPage> {
  final MapController _mapController = MapController();
  final GlobalKey repaintKey = GlobalKey();
  List<Map<String, dynamic>> topografos = [];
  List<LatLng> puntos = [];
  double? area;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cargarYActualizar();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _cargarYActualizar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cargarYActualizar() async {
    final ahora = DateTime.now().toUtc();
    final response = await Supabase.instance.client
        .from('ubicaciones')
        .select('user_id, lat, lng, timestamp, users(rol, email)')
        .order('timestamp', ascending: false);

    final Map<String, Map<String, dynamic>> ultimoPorUser = {};
    for (var row in response) {
      if (row['users'] != null && row['users']['rol'] == 'topografo') {
        final rawFecha = row['timestamp'] ?? '';
        final fecha = DateTime.tryParse(rawFecha)?.toUtc();
        if (fecha != null && ahora.difference(fecha).inSeconds <= 60) {
          final uid = row['user_id'];
          if (!ultimoPorUser.containsKey(uid)) {
            ultimoPorUser[uid] = row;
          }
        }
      }
    }
    final puntosNuevos = ultimoPorUser.values
        .map((r) => LatLng((r['lat'] as num).toDouble(), (r['lng'] as num).toDouble()))
        .toList();

    setState(() {
      topografos = ultimoPorUser.values.toList();
      puntos = puntosNuevos;
      area = puntos.length >= 3 ? _areaPoligonoMetros(puntos) : null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _ajustarVistaMarkers());
  }

  void _ajustarVistaMarkers() {
    if (puntos.isEmpty || !mounted) return;
    if (puntos.length == 1) {
      _mapController.move(puntos.first, 16);
    } else if (puntos.length > 1) {
      final bounds = LatLngBounds.fromPoints(puntos);
      _mapController.fitBounds(bounds, options: const FitBoundsOptions(padding: EdgeInsets.all(80)));
    }
  }

  double _areaPoligonoMetros(List<LatLng> puntos) {
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

      if (response == null || (response is String && response.isEmpty)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error subiendo la imagen (verifica policies y bucket)')),
          );
        }
        return;
      }
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
        'puntos': puntos
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

  void _guardarPoligonoYSubir() async {
    if (puntos.length < 3) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Guardando polígono... Área: ${area?.toStringAsFixed(2) ?? "?"} m²',
        ),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 350));
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
    const Color colorAcento = Color(0xFFD84315);
    const Color colorFondo = Color(0xFF181824);
    const Color colorGlow = Color(0xFFFFD54F);

    return Scaffold(
      backgroundColor: colorFondo,
      appBar: AppBar(
        title: const Text('Área de los Topógrafos'),
        backgroundColor: Colors.indigo[900],
        elevation: 0,
      ),
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 1, 
              child: RepaintBoundary(
                key: repaintKey,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: puntos.isNotEmpty ? puntos[0] : const LatLng(-1.83, -78.18),
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                    onMapReady: _ajustarVistaMarkers,
                  ),
                  children: [
                    TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.mapeo_ec',
                  ),

                    if (puntos.length >= 3)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: [...puntos, puntos.first],
                            color: colorAcento.withOpacity(0.30),
                            borderColor: colorAcento,
                            borderStrokeWidth: 4,
                            isFilled: true,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: puntos.map((p) => Marker(
                        point: p,
                        width: 65,
                        height: 65,
                        child: const Icon(Icons.person_pin_circle, color: Color(0xFFD84315), size: 55),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Positioned(
            left: 18,
            bottom: 28,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.82),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: colorGlow.withOpacity(0.25), blurRadius: 12, spreadRadius: 2)
                ],
                border: Border.all(color: colorGlow.withOpacity(0.11), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_alt_rounded, color: colorGlow, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    '${puntos.length} topógrafos activos',
                    style: const TextStyle(
                      color: colorGlow,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black,
                          blurRadius: 6,
                          offset: Offset(1, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      floatingActionButton: puntos.length >= 3
          ? FloatingActionButton.extended(
              heroTag: 'guardar-poligono',
              backgroundColor: Colors.blue,
              icon: const Icon(Icons.save_alt, color: Colors.white),
              label: const Text("Guardar polígono con imagen"),
              onPressed: _guardarPoligonoYSubir,
            )
          : null,
    );
  }
}
