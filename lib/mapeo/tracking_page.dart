import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_background/flutter_background.dart';

class TrackingPageSimple extends StatefulWidget {
  const TrackingPageSimple({super.key});

  @override
  State<TrackingPageSimple> createState() => _TrackingPageSimpleState();
}

class _TrackingPageSimpleState extends State<TrackingPageSimple> {
  bool _isTracking = false;
  String _currentLocation = 'Aún no se ha iniciado el rastreo.';
  String _errorMessage = '';
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    FlutterBackground.disableBackgroundExecution();
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
    try {
      await _pedirPermisos();

      // --- Inicializar flutter_background con notificación ---
    final androidConfig = const FlutterBackgroundAndroidConfig(
  notificationTitle: "Rastreo activo",
  notificationText: "La app está rastreando tu ubicación en segundo plano.",
);


      final backgroundInit = await FlutterBackground.initialize(androidConfig: androidConfig);
      if (backgroundInit) {
        await FlutterBackground.enableBackgroundExecution();
      }

      setState(() {
        _isTracking = true;
        _errorMessage = '';
        _currentLocation = 'Buscando ubicación inicial...';
      });

      _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
        try {
          final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          if (mounted) {
            setState(() {
              _currentLocation = '${position.latitude}, ${position.longitude}';
            });
          }

          final user = Supabase.instance.client.auth.currentUser;
          if (user != null) {
            await Supabase.instance.client.from('ubicaciones').insert({
              'id': const Uuid().v4(),
              'user_id': user.id,
              'lat': position.latitude,
              'lng': position.longitude,
              'timestamp': DateTime.now().toUtc().toIso8601String(),
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Error al obtener ubicación: $e';
            });
          }
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> detenerRastreo() async {
    _timer?.cancel();
    if (await FlutterBackground.isBackgroundExecutionEnabled) {
      await FlutterBackground.disableBackgroundExecution();
    }
    setState(() {
      _isTracking = false;
      _currentLocation = 'El rastreo ha sido detenido.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Rastreo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 0, 0, 0), Color.fromARGB(255, 26, 26, 26)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusIndicator(),
                _buildLocationInfoCard(),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Column(
      children: [
        Icon(
          _isTracking ? Icons.gps_fixed : Icons.gps_not_fixed,
          color: _isTracking ? Colors.greenAccent : Colors.white54,
          size: 100,
        ),
        const SizedBox(height: 16),
        Text(
          _isTracking ? 'RASTREO ACTIVO' : 'RASTREO DETENIDO',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _isTracking ? Colors.greenAccent : Colors.white,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ÚLTIMA UBICACIÓN REGISTRADA:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            _currentLocation,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.amberAccent, fontSize: 14),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text('Iniciar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 18),
          ),
          onPressed: _isTracking ? null : iniciarRastreo,
        ),
        const SizedBox(width: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.stop),
          label: const Text('Detener'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade800,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle: const TextStyle(fontSize: 18),
          ),
          onPressed: !_isTracking ? null : detenerRastreo,
        ),
      ],
    );
  }
}
