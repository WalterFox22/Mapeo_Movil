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
    if (ubicaciones.isEmpty || !mounted) return;
    final points = ubicaciones.map((u) => LatLng(u['lat'] as double, u['lng'] as double)).toList();
    if (points.length == 1) {
      _mapController.move(points.first, 16);
    } else if (points.length > 1) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitBounds(bounds, options: const FitBoundsOptions(padding: EdgeInsets.all(70)));
    }
  }

  Future<void> cargarUbicaciones() async {
    setState(() => loading = true);
    try {
      final ahora = DateTime.now().toUtc();
      final response = await Supabase.instance.client
          .from('ubicaciones')
          .select('user_id, lat, lng, timestamp, users(rol, email)')
          .order('timestamp', ascending: false);
      final datos = response as List;
      final Map<String, Map<String, dynamic>> latestByUser = {};
      for (final u in datos) {
        if (u['users'] != null && u['users']['rol'] == 'topografo') {
          final rawFecha = u['timestamp'] ?? '';
          final fecha = DateTime.tryParse(rawFecha)?.toUtc();
          // Solo usuarios con ubicación en el último minuto
          if (fecha != null && ahora.difference(fecha).inSeconds <= 60) {
            if (!latestByUser.containsKey(u['user_id'])) {
              latestByUser[u['user_id']] = u;
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          ubicaciones = latestByUser.values.toList();
          loading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _ajustarVistaMarkers());
      }
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar ubicaciones: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  
  Future<void> _crearPoligonoDeTopografos() async {
    if (ubicaciones.length < 3) return;
    final puntos = ubicaciones.map((u) => LatLng(u['lat'] as double, u['lng'] as double)).toList();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client.from('terrenos').insert({
        'user_id': user.id,
        'puntos': puntos.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
        'timestamp': DateTime.now().toIso8601String(),
        'tipo': 'topografos',
      });
      setState(() => poligonoActual = puntos);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Polígono creado con éxito')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definimos los colores del tema para fácil acceso
    const Color colorPrimario = Color(0xFF283593); // Índigo
    const Color colorAcento = Color(0xFFD84315);   // Naranja

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0), // Fondo oscuro para el loading
      appBar: AppBar(
        title: const Text('Mapa de Topógrafos'),
        backgroundColor: colorPrimario, // Color del tema
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarUbicaciones,
            tooltip: 'Recargar ubicaciones',
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(-1.83, -78.18),
                    initialZoom: 7,
                    onMapReady: _ajustarVistaMarkers,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                  ),
                  children: [
                    // --- 1. MAPA BASE OSCURO ---
                    TileLayer(
                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                      userAgentPackageName: 'com.example.mapeo_ec',
                    ),
                    
                    // --- 2. CAPA DEL POLÍGONO CON NUEVOS COLORES ---
                    if (poligonoActual.isNotEmpty)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: poligonoActual,
                            color: colorAcento.withOpacity(0.3),
                            borderStrokeWidth: 4,
                            borderColor: colorAcento,
                            isFilled: true,
                          ),
                        ],
                      ),

                    // --- 3. CAPA DE MARCADORES PERSONALIZADOS ---
                    MarkerLayer(
                      markers: ubicaciones.map((u) {
                        final correo = u['users']?['email'] ?? 'Topógrafo';
                        return Marker(
                          point: LatLng(u['lat'] as double, u['lng'] as double),
                          width: 80,
                          height: 80,
                          child: _buildSurveyorMarker(correo, colorAcento),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: ubicaciones.length >= 3 && !loading
          ? FloatingActionButton.extended(
              onPressed: _crearPoligonoDeTopografos,
              label: const Text("Crear polígono"),
              icon: const Icon(Icons.polyline),
              backgroundColor: colorAcento,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  // --- WIDGET PARA LOS MARCADORES PERSONALIZADOS ---
  Widget _buildSurveyorMarker(String email, Color color) {
    return Tooltip(
      message: email,
      child: Icon(
        Icons.person_pin_circle,
        color: color,
        size: 45,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.7),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
    );
  }
}
