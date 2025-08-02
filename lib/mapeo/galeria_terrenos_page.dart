import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GaleriaTerrenosPage extends StatefulWidget {
  const GaleriaTerrenosPage({super.key});

  @override
  State<GaleriaTerrenosPage> createState() => _GaleriaTerrenosPageState();
}

class _GaleriaTerrenosPageState extends State<GaleriaTerrenosPage> {
  late Future<List<Map<String, dynamic>>> _futureTerrenos;

  @override
  void initState() {
    super.initState();
    _futureTerrenos = _cargarTerrenos();
  }

  Future<List<Map<String, dynamic>>> _cargarTerrenos() async {
    try {
      final response = await Supabase.instance.client
          .from('terrenos')
          .select('id, img_url, area, timestamp')
          .order('timestamp', ascending: false);
      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error cargando terrenos: $e');
      return [];
    }
  }

  void _refresh() {
    setState(() {
      _futureTerrenos = _cargarTerrenos();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería de Terrenos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureTerrenos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay imágenes aún.'));
          }
          final terrenos = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16,
            ),
            itemCount: terrenos.length,
            itemBuilder: (context, i) {
              final t = terrenos[i];
              final url = t['img_url'] as String?;
              final areaRaw = t['area'];
              double? area = areaRaw is int
                  ? areaRaw.toDouble()
                  : areaRaw is double
                      ? areaRaw
                      : null;
              return Card(
                elevation: 2,
                child: InkWell(
                  onTap: () async {
                    final eliminado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TerrenoImagenDetallePage(terreno: t),
                      ),
                    );
                    if (eliminado == true) _refresh();
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                          child: url != null && url.isNotEmpty
                              ? Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image, size: 48),
                                )
                              : const Icon(Icons.image_not_supported, size: 48),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Área: ${area != null ? area.toStringAsFixed(2) : "?"} m²',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              'Fecha: ${t['timestamp']?.toString().substring(0, 10) ?? ""}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TerrenoImagenDetallePage extends StatefulWidget {
  final Map<String, dynamic> terreno;
  const TerrenoImagenDetallePage({super.key, required this.terreno});

  @override
  State<TerrenoImagenDetallePage> createState() =>
      _TerrenoImagenDetallePageState();
}

class _TerrenoImagenDetallePageState extends State<TerrenoImagenDetallePage> {
  bool _esAdmin = false;
  bool _eliminando = false;

  @override
  void initState() {
    super.initState();
    _cargarAdmin();
  }

  Future<void> _cargarAdmin() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final res = await Supabase.instance.client
        .from('users')
        .select('rol')
        .eq('id', user.id)
        .maybeSingle();
    setState(() {
      _esAdmin = res?['rol'] == 'admin';
    });
  }

  Future<void> _eliminar() async {
    setState(() => _eliminando = true);
    final id = widget.terreno['id'];
    final url = widget.terreno['img_url'] as String?;
    try {
      await Supabase.instance.client.from('terrenos').delete().eq('id', id);
      
      if (url != null && url.contains('/storage/v1/object/public/imagenesterrenos/')) {
        
        final ruta = url.split('/storage/v1/object/public/imagenesterrenos/').last;
        await Supabase.instance.client.storage
            .from('imagenesterrenos')
            .remove([ruta]);
      }
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terreno eliminado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _eliminando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error eliminando: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.terreno['img_url'] as String?;
    final areaRaw = widget.terreno['area'];
    double? area =
        areaRaw is int ? areaRaw.toDouble() : areaRaw is double ? areaRaw : null;
    final fecha = widget.terreno['timestamp']?.toString().substring(0, 10) ?? "";

    return Scaffold(
      appBar: AppBar(
          title: const Text('Imagen del Terreno'),
          backgroundColor: Colors.black),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: url != null && url.isNotEmpty
                  ? InteractiveViewer(
                      child: Image.network(url, fit: BoxFit.contain),
                    )
                  : const Icon(Icons.broken_image,
                      color: Colors.white, size: 120),
            ),
            Container(
              width: double.infinity,
              color: Colors.black87,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Área: ${area != null ? area.toStringAsFixed(2) : "?"} m²',
                      style: const TextStyle(fontSize: 16, color: Colors.white)),
                  Text('Fecha: $fecha',
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white70)),
                ],
              ),
            ),
            if (_esAdmin)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  ),
                  icon: _eliminando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.delete),
                  label: Text(_eliminando ? "Eliminando..." : "Eliminar terreno"),
                  onPressed: _eliminando
                      ? null
                      : () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar terreno'),
                              content: const Text(
                                  '¿Estás seguro de que quieres eliminar este terreno? Esto también eliminará la imagen.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancelar')),
                                ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text('Eliminar')),
                              ],
                            ),
                          );
                          if (ok == true) await _eliminar();
                        },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
