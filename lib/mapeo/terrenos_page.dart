import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TerrenosPage extends StatefulWidget {
  const TerrenosPage({super.key});

  @override
  State<TerrenosPage> createState() => _TerrenosPageState();
}

class _TerrenosPageState extends State<TerrenosPage> {
  List<Map<String, dynamic>> terrenos = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    cargarTerrenos();
  }

  Future<void> cargarTerrenos() async {
    setState(() => loading = true);

    try {
      final response = await Supabase.instance.client
          .from('terrenos')
          .select('id, user_id, puntos, timestamp, tipo, area, users(email)')
          .order('timestamp', ascending: false);

      setState(() {
        terrenos = response as List<Map<String, dynamic>>;
        loading = false;
      });

      if (terrenos.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay terrenos guardados')),
        );
      }
    } catch (e) {
      setState(() => loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar terrenos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terrenos Guardados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarTerrenos,
            tooltip: 'Recargar terrenos',
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : terrenos.isEmpty
              ? const Center(child: Text('No hay terrenos guardados'))
              : ListView.builder(
                  itemCount: terrenos.length,
                  itemBuilder: (context, index) {
                    final terreno = terrenos[index];
                    final List puntos = terreno['puntos'];
                    final email = terreno['users']?['email'] ?? '';
                    final fecha = DateTime.parse(terreno['timestamp']);
                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        title: Text('Terreno #${terreno['id'].toString().substring(0, 6)}'),
                        subtitle: Text(
                          'Usuario: $email\n'
                          'Fecha: ${fecha.day}/${fecha.month}/${fecha.year}\n'
                          'Puntos: ${puntos.length}\n'
                          'Área: ${terreno['area'] != null ? terreno['area'].toStringAsFixed(2) : 'N/A'} m²',
                        ),
                        trailing: Icon(Icons.map, color: Colors.green[700]),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TerrenoDetallePage(terreno: terreno),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class TerrenoDetallePage extends StatelessWidget {
  final Map<String, dynamic> terreno;

  const TerrenoDetallePage({super.key, required this.terreno});

  @override
  Widget build(BuildContext context) {
    final List puntos = terreno['puntos'];
    final List<LatLng> poligono = puntos
        .map<LatLng>((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del Terreno'),
      ),
      body: FlutterMap(
        options: MapOptions(
          center: poligono.isNotEmpty ? poligono.first : LatLng(-1.83, -78.18),
          zoom: 16,
          bounds: poligono.isNotEmpty ? LatLngBounds.fromPoints(poligono) : null,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.mapeo_ec',
          ),
          if (poligono.isNotEmpty)
            PolygonLayer(
              polygons: [
                Polygon(
                  points: poligono,
                  color: Colors.green.withOpacity(0.25),
                  borderColor: Colors.green,
                  borderStrokeWidth: 3,
                )
              ],
            ),
          if (poligono.isNotEmpty)
            MarkerLayer(
              markers: poligono
                  .map((p) => Marker(
                        point: p,
                        width: 24,
                        height: 24,
                        child: const Icon(Icons.circle, color: Colors.green, size: 18),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}
