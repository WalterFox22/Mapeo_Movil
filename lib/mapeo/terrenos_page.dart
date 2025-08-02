import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
      terrenos = response as List<Map<String, dynamic>>;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar terrenos: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> eliminarTerreno(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar terreno?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client.from('terrenos').delete().eq('id', id);
      cargarTerrenos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terreno eliminado')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color colorPrimario = Color(0xFF283593); 
    const Color colorAcento = Color(0xFFD84315); 

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Terrenos Guardados'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarTerrenos,
            tooltip: 'Recargar terrenos',
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 0, 0, 0), Color.fromARGB(255, 36, 36, 36)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : terrenos.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      itemCount: terrenos.length,
                      itemBuilder: (context, index) {
                        return _buildTerrenoCard(terrenos[index]);
                      },
                    ),
        ),
      ),
    );
  }

  Widget _buildTerrenoCard(Map<String, dynamic> terreno) {
    final List puntos = terreno['puntos'] ?? [];
    final email = terreno['users']?['email'] ?? 'Desconocido';
    final fecha = DateTime.parse(terreno['timestamp']);
    final area = terreno['area'] != null ? terreno['area'].toStringAsFixed(2) : 'N/A';
    final id = terreno['id'].toString();

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TerrenoDetallePage(terreno: terreno, onDelete: () => eliminarTerreno(id))),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terreno #${id.substring(0, 6)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Divider(color: Colors.white24, height: 20),
            _buildInfoRow(Icons.person_outline, 'Mapeado por:', email),
            _buildInfoRow(Icons.calendar_today_outlined, 'Fecha:', DateFormat('dd/MM/yyyy, HH:mm').format(fecha)),
            _buildInfoRow(Icons.square_foot, 'Área:', '$area m²'),
            _buildInfoRow(Icons.location_on_outlined, 'Vértices:', '${puntos.length} puntos'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 10),
          Text('$label ', style: const TextStyle(color: Colors.white70, fontSize: 15)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.landscape_outlined, size: 100, color: Colors.white38),
          SizedBox(height: 16),
          Text('No hay terrenos guardados.', style: TextStyle(color: Colors.white70, fontSize: 18)),
        ],
      ),
    );
  }
}


class TerrenoDetallePage extends StatelessWidget {
  final Map<String, dynamic> terreno;
  final VoidCallback onDelete;
  const TerrenoDetallePage({super.key, required this.terreno, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    const Color colorAcento = Color(0xFFD84315); 
    final List puntos = terreno['puntos'] ?? [];
    final List<LatLng> poligono = puntos
        .map<LatLng>((p) => LatLng((p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()))
        .toList();

    final email = terreno['users']?['email'] ?? 'Desconocido';
    final fecha = DateTime.parse(terreno['timestamp']);
    final area = terreno['area'] != null ? terreno['area'].toStringAsFixed(2) : 'N/A';
    final id = terreno['id'].toString();

    return Scaffold(
      appBar: AppBar(
        title: Text('Terreno #${id.substring(0, 6)}'),
        backgroundColor: const Color(0xFF283593),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: "Eliminar",
            onPressed: onDelete,
          ),
          
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 24, 24, 24), Color.fromARGB(255, 42, 42, 42)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: poligono.isNotEmpty ? poligono.first : const LatLng(-1.83, -78.18),
                  initialZoom: 16,
                  bounds: poligono.isNotEmpty ? LatLngBounds.fromPoints(poligono) : null,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.example.mapeo_ec',
                  ),
                  if (poligono.isNotEmpty)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: poligono,
                          color: colorAcento.withOpacity(0.3),
                          borderColor: colorAcento,
                          borderStrokeWidth: 4,
                          isFilled: true,
                        )
                      ],
                    ),
                  if (poligono.isNotEmpty)
                    MarkerLayer(
                      markers: poligono.map((p) => Marker(
                        point: p,
                        width: 10,
                        height: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: colorAcento, width: 2),
                          ),
                        ),
                      )).toList(),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                color: Colors.black.withOpacity(0.70),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _detailRow(Icons.person, "Mapeado por:", email),
                      _detailRow(Icons.calendar_today, "Fecha:", DateFormat('dd/MM/yyyy, HH:mm').format(fecha)),
                      _detailRow(Icons.square_foot, "Área:", "$area m²"),
                      _detailRow(Icons.location_on, "Vértices:", "${puntos.length} puntos"),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 10),
        Text('$label ', style: const TextStyle(color: Colors.white70, fontSize: 15)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
