import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'mapeo/tracking_page.dart'; 
import 'mapeo/mapa_topografos_page.dart'; 
import 'mapeo/terrenos_page.dart'; 
import 'testeo/prueba_terreno_page.dart'; 

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Bienvenido ${user?.email ?? ''}'),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.location_on),
              label: const Text('Probar rastreo de ubicación'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrackingPageSimple()),
                );
              },
            ),
            ElevatedButton.icon(
  icon: const Icon(Icons.map),
  label: const Text('Ver mapa topógrafos'),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapaTopografosPage()),
    );
  },
),
ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const TerrenosPage()),
  ),
  child: const Text('Ver terrenos guardados'),
),
ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PruebaTerrenoPage()),
  ),
  child: const Text('Probar polígono con topógrafos simulados'),
),
          ],
        ),
      ),
    );
  }
}