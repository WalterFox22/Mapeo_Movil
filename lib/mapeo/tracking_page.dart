import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class TrackingPageSimple extends StatefulWidget {
  const TrackingPageSimple({super.key});

  @override
  State<TrackingPageSimple> createState() => _TrackingPageSimpleState();
}

class _TrackingPageSimpleState extends State<TrackingPageSimple> {
  String estado = 'No iniciado';
  String ubicacionActual = 'Desconocida';
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _pedirPermisos() async {
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
      throw Exception('Permisos de ubicación denegados');
    }
  }

  Future<void> iniciarRastreo() async {
    await _pedirPermisos();
    setState(() {
      estado = 'Rastreo activo';
    });

    // Cada 10 segundos obtiene ubicación y la sube
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition();
        setState(() {
          ubicacionActual = '${position.latitude}, ${position.longitude}';
        });

        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          await Supabase.instance.client.from('ubicaciones').insert({
            'id': const Uuid().v4(),
            'user_id': user.id,
            'lat': position.latitude,
            'lng': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      } catch (e) {
        setState(() {
          ubicacionActual = 'Error: $e';
        });
      }
    });
  }

  Future<void> detenerRastreo() async {
    _timer?.cancel();
    setState(() {
      estado = 'Rastreo detenido';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rastreo sencillo')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Estado: $estado'),
            const SizedBox(height: 10),
            Text('Ubicación actual: $ubicacionActual'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: iniciarRastreo,
              child: const Text('Iniciar rastreo'),
            ),
            ElevatedButton(
              onPressed: detenerRastreo,
              child: const Text('Detener rastreo'),
            ),
          ],
        ),
      ),
    );
  }
}
