import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapaTopografosPage extends StatefulWidget {
  const MapaTopografosPage({super.key});

  @override
  State<MapaTopografosPage> createState() => _MapaTopografosPageState();
}

class _MapaTopografosPageState extends State<MapaTopografosPage> {
  final MapController _mapController = MapController();
  List<Map<String, dynamic>> ubicaciones = [];
  bool loading = true;
  List<LatLng> poligonoActual = [];

  @override
  void initState() {
    super.initState();
    cargarUbicaciones();
  }

  void _ajustarVistaMarkers() {
    if (ubicaciones.isEmpty) return;
    final points = ubicaciones
        .map((u) => LatLng(u['lat'] as double, u['lng'] as double))
        .toList();

    if (points.length == 1) {
      _mapController.move(points.first, 16);
    } else {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitBounds(
        bounds,
        options: const FitBoundsOptions(padding: EdgeInsets.all(70)),
      );
    }
  }

  Future<void> cargarUbicaciones() async {
    setState(() => loading = true);

    try {
      final response = await Supabase.instance.client
          .from('ubicaciones')
          .select('user_id, lat, lng, timestamp, users(rol, email)')
          .order('timestamp', ascending: false);

      final datos = response as List;
      final Map<String, Map<String, dynamic>> latestByUser = {};

      for (final u in datos) {
        if (u['users'] != null && u['users']['rol'] == 'topografo') {
          if (!latestByUser.containsKey(u['user_id'])) {
            latestByUser[u['user_id']] = u;
          }
        }
      }

      setState(() {
        ubicaciones = latestByUser.values.toList();
        loading = false;
      });

      if (ubicaciones.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay ubicaciones de topógrafos'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      // Zoom automático luego de actualizar el mapa
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ajustarVistaMarkers();
      });
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ubicaciones: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _crearPoligonoDeTopografos() async {
    if (ubicaciones.length < 3) return;

    final puntos = ubicaciones
        .map((u) => LatLng(u['lat'] as double, u['lng'] as double))
        .toList();

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client.from('terrenos').insert({
        'user_id': user.id,
        'puntos': puntos.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'tipo': 'topografos',
      });

      setState(() {
        poligonoActual = puntos;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Polígono creado con ubicaciones de topógrafos')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Topógrafos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarUbicaciones,
            tooltip: 'Recargar ubicaciones',
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                onMapReady: _ajustarVistaMarkers,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.mapeo_ec',
                ),
                MarkerLayer(
                  markers: ubicaciones.map((u) {
                    final correo = u['users']?['email'] ?? 'Topógrafo';
                    return Marker(
                      point: LatLng(u['lat'] as double, u['lng'] as double),
                      width: 40,
                      height: 40,
                      child: Tooltip(
                        message: correo,
                        child: const Icon(Icons.person_pin_circle, color: Colors.red, size: 36),
                      ),
                    );
                  }).toList(),
                ),
                if (poligonoActual.isNotEmpty)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: poligonoActual,
                        color: Colors.blue.withOpacity(0.25),
                        borderStrokeWidth: 3,
                        borderColor: Colors.blue,
                      ),
                    ],
                  ),
                if (poligonoActual.isNotEmpty)
                  MarkerLayer(
                    markers: poligonoActual.map((p) {
                      return Marker(
                        point: p,
                        width: 24,
                        height: 24,
                        child: const Icon(Icons.circle, color: Colors.blue, size: 18),
                      );
                    }).toList(),
                  ),
              ],
            ),
      floatingActionButton: ubicaciones.length >= 3
          ? FloatingActionButton.extended(
              onPressed: _crearPoligonoDeTopografos,
              label: const Text("Crear polígono con topógrafos"),
              icon: const Icon(Icons.group),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }
}
