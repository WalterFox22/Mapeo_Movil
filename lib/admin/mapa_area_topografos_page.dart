import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AreaTopografosPage extends StatefulWidget {
  const AreaTopografosPage({super.key});

  @override
  State<AreaTopografosPage> createState() => _AreaTopografosPageState();
}

class _AreaTopografosPageState extends State<AreaTopografosPage> {
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
    final response = await Supabase.instance.client
        .from('ubicaciones')
        .select('user_id, lat, lng, timestamp')
        .order('timestamp', ascending: false);

    final Map<String, Map<String, dynamic>> ultimoPorUser = {};
    for (var row in response) {
      final uid = row['user_id'];
      if (!ultimoPorUser.containsKey(uid)) {
        ultimoPorUser[uid] = row;
      }
    }
    final puntosNuevos = ultimoPorUser.values
        .map((r) => LatLng((r['lat'] as num).toDouble(), (r['lng'] as num).toDouble()))
        .toList();

    setState(() {
      puntos = puntosNuevos;
      area = puntos.length >= 3 ? _areaPoligonoMetros(puntos) : null;
    });
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

  void _mostrarDialogoArea(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Área del polígono', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.select_all, color: Colors.amber[200], size: 48),
            const SizedBox(height: 12),
            Text(
              'Área: ${area?.toStringAsFixed(2) ?? "0"} m²',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              '${puntos.length} topógrafos activos',
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cerrar', style: TextStyle(color: Colors.amber)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Colores temáticos
    const colorTierra = Color(0xFF3E2723);
    const colorCielo = Color(0xFF1A237E);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Área de los Topógrafos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [colorTierra, colorCielo],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  center: puntos.isNotEmpty ? puntos[0] : LatLng(-1.83, -78.18),
                  zoom: 17,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.example.mapeo_ec',
                  ),
                  MarkerLayer(
                    markers: puntos
                        .map((p) => Marker(
                              point: p,
                              width: 36,
                              height: 36,
                              child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 30),
                            ))
                        .toList(),
                  ),
                  if (puntos.length >= 3)
                    PolygonLayer(polygons: [
                      Polygon(
                        points: [...puntos, puntos.first],
                        color: Colors.blue.withOpacity(0.32),
                        borderColor: Colors.amber,
                        borderStrokeWidth: 3,
                        isFilled: true,
                      )
                    ]),
                ],
              ),
              // Banner de "Esperando posiciones..." (si no hay)
              if (puntos.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 26),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                    ),
                    child: const Text(
                      'Esperando posiciones de topógrafos...',
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: puntos.length >= 3
          ? FloatingActionButton.extended(
              heroTag: 'mostrar-area',
              backgroundColor: Colors.black87,
              onPressed: () => _mostrarDialogoArea(context),
              icon: const Icon(Icons.select_all, color: Colors.amber),
              label: Text(
                'Área: ${area?.toStringAsFixed(2) ?? "0"} m²',
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }
}
